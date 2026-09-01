//
//  EstimateSummary.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/20/26.
//

import SwiftUI
import SwiftData

struct EstimateSummary: View {
    let isFederal: Bool
    let taxPeriodInput: [TaxPeriodInput]
    let estimateCycle: EstimationCycle
    
    @State private var selectedRowID: String?
    
    let federalDisplayConfigs: [TaxEstimateResultMap] = [
        TaxEstimateResultMap(keyPath: \.taxableIncome, displayName: "Annualized Taxable Income"),
        TaxEstimateResultMap(keyPath: \.totalTax, displayName: "Annualized Total Tax"),
        TaxEstimateResultMap(keyPath: \.marginalTaxRate, displayName: "Marginal Tax Rate", formatStyle: .percent),
        TaxEstimateResultMap(keyPath: \.taxesPaid, displayName: "Taxes Paid YTD"),
        TaxEstimateResultMap(keyPath: \.taxEstimate, displayName: "Estimated Tax Due"),
    ]
    
    let stateDisplayConfigs: [TaxEstimateResultMap] = [
        TaxEstimateResultMap(keyPath: \.taxableIncome, displayName: "Annualized Taxable Income"),
        TaxEstimateResultMap(keyPath: \.totalTax, displayName: "Annualized Total Tax"),
        TaxEstimateResultMap(keyPath: \.taxesPaid, displayName: "Taxes Paid YTD"),
        TaxEstimateResultMap(keyPath: \.taxEstimate, displayName: "Estimated Tax Due"),
    ]
    
    var body: some View {
            // Identify the tax entity and extract the data rows to present.
        let taxEntity = isFederal ? TaxEntity.federal : TaxEntity.state
        let configs = isFederal ? federalDisplayConfigs : stateDisplayConfigs
        let rows = summaryRows(taxPeriodInput: taxPeriodInput, configs: configs, taxEntity: taxEntity)
        
        VStack(alignment: .leading) {
            Table(rows, selection: $selectedRowID) {
                EstimateColumns.makeColumns(taxEntity: taxEntity, estimateCycle: estimateCycle)
            }
            .id(estimateCycle)
            .navigationDestination(item: $selectedRowID) { id in
                EstimateDrillDown(isFederal: isFederal, taxPeriodInput: taxPeriodInput, estimateCycle: estimateCycle)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: CGFloat(rows.count) * 28 + 30)
        }
        .frame(maxWidth: .infinity, minHeight: 160)
    }
}

    // Support functions, structures for the view.
struct TaxEstimateResultMap {
    let displayName: String
    let formatStyle: RowFormatStyle
    private let extract: (TaxPeriodInput, TaxEstimate?) -> Double
    
        // Existing usage pattern: pull a single Double straight off the TaxEstimate.
    init(keyPath: KeyPath<TaxEstimate, Double>, displayName: String, formatStyle: RowFormatStyle = .currency) {
        self.displayName = displayName
        self.formatStyle = formatStyle
        self.extract = { _, estimate in estimate?[keyPath: keyPath] ?? 0.0 }
    }
    
        // Custom calculation that can pull from both the period's input and its estimate.
    init(displayName: String, formatStyle: RowFormatStyle = .currency, extract: @escaping (TaxPeriodInput, TaxEstimate?) -> Double) {
        self.displayName = displayName
        self.formatStyle = formatStyle
        self.extract = extract
    }
    
    func value(input: TaxPeriodInput, estimate: TaxEstimate?) -> Double {
        extract(input, estimate)
    }
}

struct TaxSummaryRow: Identifiable {
    let label: String
    let values: [String: Double]
    let formatStyle: RowFormatStyle
    var id: String { label }
    
    subscript(key: String) -> Double {
        return values[key] ?? 0.0
    }
}
extension TaxSummaryRow: TaxRowProvider {}

func taxResults(from taxPeriodInput: [TaxPeriodInput], taxEntity: TaxEntity) -> [TaxEstimate] {
    taxPeriodInput
        .flatMap { $0.taxEstimates }
        .filter { $0.taxEntity == taxEntity.rawValue }
}

func summaryRows(taxPeriodInput: [TaxPeriodInput], configs: [TaxEstimateResultMap], taxEntity: TaxEntity) -> [TaxSummaryRow] {
    let results = taxResults(from: taxPeriodInput, taxEntity: taxEntity)
    
    return configs.map { config in
        var rowValues: [String: Double] = [:]           // Explicitly type the dictionary here
        
        for inputRecord in taxPeriodInput {
            let period = inputRecord.taxPeriodId
            let estimate = results.first(where: { $0.taxPeriodInput?.taxPeriodId == period })
            rowValues[period] = config.value(input: inputRecord, estimate: estimate)
        }
        return TaxSummaryRow(label: config.displayName, values: rowValues, formatStyle: config.formatStyle)
    }
}

