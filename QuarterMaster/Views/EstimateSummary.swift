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
    @State private var showDrillDown = false
    
    let taxDisplayConfigs = [
        TaxEstimateResultMap(keyPath: \.taxableIncome, displayName: "Annualized Taxable Income"),
        TaxEstimateResultMap(keyPath: \.totalTax, displayName: "Annualized Total Tax"),
        TaxEstimateResultMap(keyPath: \.taxesPaid, displayName: "Taxes Paid YTD"),
        TaxEstimateResultMap(keyPath: \.taxEstimate, displayName: "Estimated Tax Due"),
    ]
    
    var body: some View {
            // Identify the tax entity and extract the data rows to present.
        let taxEntity = isFederal ? TaxEntity.federal : TaxEntity.state
        let rows = summaryRows(taxPeriodInput: taxPeriodInput, configs: taxDisplayConfigs, taxEntity: taxEntity)
        
        VStack(alignment: .leading) {
            Table(rows, selection: $selectedRowID) {
                EstimateColumns.makeColumns(taxEntity: taxEntity, estimateCycle: estimateCycle)
            }
            .id(estimateCycle)
            
            .onChange(of: selectedRowID) { _, newValue in
                if newValue != nil { showDrillDown = true }
            }
            .navigationDestination(isPresented: $showDrillDown) {
                EstimateDrillDown(isFederal: isFederal, taxPeriodInput: taxPeriodInput, estimateCycle: estimateCycle)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(height: CGFloat(rows.count) * 28 + 30)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}

    // Support functions, structures for the view.
struct TaxEstimateResultMap {
    let keyPath: KeyPath<TaxEstimate, Double>
    let displayName: String
}

struct TaxSummaryRow: Identifiable {
    let label: String
    let values: [String: Double]
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
            
                // Ensure value extracted is a Double. If the keyPath returns an optional, coalesce it to 0.0
            let estimateValue: Double = estimate?[keyPath: config.keyPath] ?? 0.0
            rowValues[period] = estimateValue
        }
        return TaxSummaryRow(label: config.displayName, values: rowValues)
    }
}

