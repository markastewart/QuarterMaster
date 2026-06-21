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
    let quarterlyData: [QuarterlyInput]
    
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
            let rows = summaryRows(quarterlyData: quarterlyData, configs: taxDisplayConfigs, taxEntity: taxEntity)
            
            Table(rows, selection: $selectedRowID) {
                TableColumn("") { Text($0.label).bold() }.width(min: 200)
                TableColumn("1Q") { Text($0.q1, format: .currency(code: "USD").precision(.fractionLength(0))) }.alignment(.center)
                TableColumn("2Q") { Text($0.q2, format: .currency(code: "USD").precision(.fractionLength(0))) }.alignment(.center)
                TableColumn("3Q") { Text($0.q3, format: .currency(code: "USD").precision(.fractionLength(0))) }.alignment(.center)
                TableColumn("4Q") { Text($0.q4, format: .currency(code: "USD").precision(.fractionLength(0))) }.alignment(.center)
            }
            .onChange(of: selectedRowID) { _, newValue in
                if newValue != nil { showDrillDown = true }
            }
            .navigationDestination(isPresented: $showDrillDown) {
                EstimateDrillDown(title: taxEntity.rawValue, isFederal: isFederal,quarterlyData: quarterlyData)
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

struct TaxSummaryRow: Identifiable, Hashable {
    let label: String
    let q1: Double
    let q2: Double
    let q3: Double
    let q4: Double
    var id: String { label }
}

func taxResults(from quarterlyData: [QuarterlyInput], taxEntity: TaxEntity) -> [TaxEstimate] {
    quarterlyData
        .flatMap { $0.taxEstimates }
        .filter { $0.taxEntity == taxEntity.rawValue }
}

func summaryRows(quarterlyData: [QuarterlyInput], configs: [TaxEstimateResultMap], taxEntity: TaxEntity) -> [TaxSummaryRow] {
    let results = taxResults(from: quarterlyData, taxEntity: taxEntity)
    
    return configs.map { config in
        TaxSummaryRow(
            label: config.displayName,
            q1: results.first(where: { $0.quarterlyInput?.quarterID == Quarter.first.rawValue })?[keyPath: config.keyPath] ?? 0,
            q2: results.first(where: { $0.quarterlyInput?.quarterID == Quarter.second.rawValue })?[keyPath: config.keyPath] ?? 0,
            q3: results.first(where: { $0.quarterlyInput?.quarterID == Quarter.third.rawValue })?[keyPath: config.keyPath] ?? 0,
            q4: results.first(where: { $0.quarterlyInput?.quarterID == Quarter.fourth.rawValue })?[keyPath: config.keyPath] ?? 0
        )
    }
}
