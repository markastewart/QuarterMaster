//
//  EstimateDrillDown.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/19/26.
//

import SwiftUI
import SwiftData

struct EstimateDrillDown: View {
    let title: String
    let viewModel: DashboardVM
    let isFederal: Bool
    
    let taxDisplayConfigs = [
        EstimateSummary.TaxSummaryLabels(keyPath: \.taxableIncome, displayName: "Annualized Taxable Income"),
        EstimateSummary.TaxSummaryLabels(keyPath: \.totalTax, displayName: "Annualized Total Tax"),
        EstimateSummary.TaxSummaryLabels(keyPath: \.taxesPaid, displayName: "Taxes Paid YTD"),
        EstimateSummary.TaxSummaryLabels(keyPath: \.taxEstimate, displayName: "Estimated Tax Due"),
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.headline).padding(.bottom, 4)
            
            let taxEntity = isFederal ? TaxEntity.federal : TaxEntity.state
            let rows = viewModel.summaryRows(for: taxDisplayConfigs, taxEntity: taxEntity)
            
            Table(rows) {
                TableColumn("") { Text($0.label).bold() }
                    .width(min: 150)
                
                TableColumn("1Q") { Text($0.q1, format: .currency(code: "USD").precision(.fractionLength(0))) }.alignment(.center)
                TableColumn("2Q") { Text($0.q2, format: .currency(code: "USD").precision(.fractionLength(0))) }.alignment(.center)
                TableColumn("3Q") { Text($0.q3, format: .currency(code: "USD").precision(.fractionLength(0))) }.alignment(.center)
                TableColumn("4Q") { Text($0.q4, format: .currency(code: "USD").precision(.fractionLength(0))) }.alignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
    }
}
