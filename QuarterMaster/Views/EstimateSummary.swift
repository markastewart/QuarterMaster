//
//  EstimateSummary.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/20/26.
//

import SwiftUI

struct EstimateSummary: View {
    let title: String
    let viewModel: DashboardVM
    let isFederal: Bool
    
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
            let rows = viewModel.summaryRows(for: taxDisplayConfigs, taxEntity: taxEntity)
            
            Table(rows, selection: $selectedRowID) {
                TableColumn("") { Text($0.label).bold() }.width(min: 200)
                
                TableColumn("1Q") { Text($0.q1, format: .currency(code: "USD").precision(.fractionLength(0))) }.alignment(.center)
                TableColumn("2Q") { Text($0.q2, format: .currency(code: "USD").precision(.fractionLength(0))) }.alignment(.center)
                TableColumn("3Q") { Text($0.q3, format: .currency(code: "USD").precision(.fractionLength(0))) }.alignment(.center)
                TableColumn("4Q") { Text($0.q4, format: .currency(code: "USD").precision(.fractionLength(0))) }.alignment(.center)
            }
            .onChange(of: selectedRowID) { _, newValue in
                if newValue != nil {
                    showDrillDown = true
                }
            }
            .navigationDestination(isPresented: $showDrillDown) {
                EstimateDrillDown(title: taxEntity.rawValue, viewModel: viewModel, isFederal: isFederal)
            }
            .frame(height: CGFloat(rows.count) * 28 + 30)
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}
