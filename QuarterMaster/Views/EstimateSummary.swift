//
//  EstimateSummary.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/20/26.
//

import SwiftUI
import SwiftData

struct EstimateSummary: View {
    let title: String
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
        VStack(alignment: .leading) {
            Text(title).font(.headline).padding(.bottom, 4)
            
            let taxEntity = isFederal ? TaxEntity.federal : TaxEntity.state
            
                // Extract data rows to present
            let rows = summaryRows(taxPeriodInput: taxPeriodInput, configs: taxDisplayConfigs, taxEntity: taxEntity)
            
            summaryTable(rows: rows, estimateCycle: estimateCycle)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
    
    @ViewBuilder
    func summaryTable(rows: [TaxSummaryRow], estimateCycle: EstimationCycle) -> some View {
        Table(rows, selection: $selectedRowID) {
            makeColumns(estimateCycle: estimateCycle)
        }
        .id(estimateCycle)
        
        .onChange(of: selectedRowID) { _, newValue in
            if newValue != nil { showDrillDown = true }
        }
        .navigationDestination(isPresented: $showDrillDown) {
            let taxEntity = isFederal ? TaxEntity.federal : TaxEntity.state
            EstimateDrillDown(title: taxEntity.rawValue, isFederal: isFederal, taxPeriodInput: taxPeriodInput)
        }
        .frame(height: CGFloat(rows.count) * 28 + 30)
    }
    
    @TableColumnBuilder<TaxSummaryRow, Never>
    func makeColumns(estimateCycle: EstimationCycle) -> some TableColumnContent<TaxSummaryRow, Never> {
        
        TableColumn("") { row in
            Text(row.label).bold()
        }
        .width(min: 200)
        
        if estimateCycle == .quarterly {
            
            TableColumn("\(TaxPeriod.first.rawValue)") { row in
                Text(row[TaxPeriod.first.rawValue], format: .currency(code: "USD").precision(.fractionLength(0)))
            }
            .alignment(.center)
            
            TableColumn("\(TaxPeriod.second.rawValue)") { row in
                Text(row[TaxPeriod.second.rawValue], format: .currency(code: "USD").precision(.fractionLength(0)))
            }
            .alignment(.center)
            
            TableColumn("\(TaxPeriod.third.rawValue)") { row in
                Text(row[TaxPeriod.third.rawValue], format: .currency(code: "USD").precision(.fractionLength(0)))
            }
            .alignment(.center)
            
            TableColumn("\(TaxPeriod.fourth.rawValue)") { row in
                Text(row[TaxPeriod.fourth.rawValue], format: .currency(code: "USD").precision(.fractionLength(0)))
            }
            .alignment(.center)
        }
        else {
            TableColumn("\(TaxPeriod.annual.rawValue)") { row in
                Text(row[TaxPeriod.annual.rawValue], format: .currency(code: "USD").precision(.fractionLength(0)))
            }
            TableColumn("") { _ in Text("") } // Invisible spacer
            TableColumn("") { _ in Text("") } // Invisible spacer
            TableColumn("") { _ in Text("") } // Invisible spacer
        }
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
    
    subscript(key: String) -> Double {       // Explicitly return a Double
        return values[key] ?? 0.0
    }
}

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
            
                // Ensure the value extracted is a Double. If the keyPath returns an optional, coalesce it to 0.0
            let estimateValue: Double = estimate?[keyPath: config.keyPath] ?? 0.0
            rowValues[period] = estimateValue
        }
        return TaxSummaryRow(label: config.displayName, values: rowValues)
    }
}

