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
    @Query(sort: \QuarterlyInput.quarterID) private var allQuarterlyData: [QuarterlyInput]
    
    let federalDrilldownConfigs: [DrilldownRowConfig] = [
        DrilldownRowConfig(displayName: "Interest") { input, _ in input?.interest ?? 0 },
        DrilldownRowConfig(displayName: "Ordinary Dividends") { input, _ in input?.ordinaryDividends ?? 0},
        DrilldownRowConfig(displayName: "Qualified Dividends *") { input, _ in input?.qualifiedDividends ?? 0},
        DrilldownRowConfig(displayName: "IRA Distributions") { input, _ in input?.iraDistributions ?? 0 },
        DrilldownRowConfig(displayName: "Pension & Annuities") { input, _ in input?.pensionAnnuities ?? 0 },
        DrilldownRowConfig(displayName: "Taxable Social Security") { _, estimate in estimate?.taxableSocialSecurity ?? 0 },
        DrilldownRowConfig(displayName: "Capital Gains") { _, estimate in estimate?.taxableCapitalGains ?? 0 },
        DrilldownRowConfig(displayName: "Other Income") { input, _ in input?.otherIncome ?? 0 },
        DrilldownRowConfig(displayName: "Adjusted Gross Income") { _, estimate in estimate?.adjustedGrossIncome ?? 0 },
        DrilldownRowConfig(displayName: "Additional Deductions") { _, estimate in estimate?.additionalDeductions ?? 0 },
        DrilldownRowConfig(displayName: "Total Deductions") { _, estimate in estimate?.totalDeductions ?? 0 },
        DrilldownRowConfig(displayName: "Taxable Income") { _, estimate in estimate?.taxableIncome ?? 0 },
        DrilldownRowConfig(displayName: "Total Tax") { _, estimate in estimate?.totalTax ?? 0 },
        DrilldownRowConfig(displayName: "Total Payments") { _, estimate in estimate?.taxesPaid ?? 0 },
        DrilldownRowConfig(displayName: "Tax Balance") { _, estimate in estimate?.taxEstimate ?? 0 }
    ]
    
    let stateDrilldownConfigs: [DrilldownRowConfig] = [
        DrilldownRowConfig(displayName: "Federal AGI") { _, estimate in estimate?.fedAGI ?? 0 },
        DrilldownRowConfig(displayName: "Additions *") { _, estimate in estimate?.incomeAdditions ?? 0},
        DrilldownRowConfig(displayName: "Deductions") { _, estimate in estimate?.totalDeductions ?? 0 },
        DrilldownRowConfig(displayName: "Ohio Adjusted Gross Income") { _, estimate in estimate?.adjustedGrossIncome ?? 0 },
        DrilldownRowConfig(displayName: "Taxable Income") { _, estimate in estimate?.taxableIncome ?? 0 },
        DrilldownRowConfig(displayName: "Total Ohio tax liability") { _, estimate in estimate?.totalTax ?? 0 },
        DrilldownRowConfig(displayName: "Total Payments") { _, estimate in estimate?.taxesPaid ?? 0 },
        DrilldownRowConfig(displayName: "Tax Balance") { _, estimate in estimate?.taxEstimate ?? 0 }
    ]
    
    var body: some View {
        let entity = isFederal ? TaxEntity.federal : TaxEntity.state
        let drilldownConfigs = isFederal ? federalDrilldownConfigs : stateDrilldownConfigs
        
        let rows = viewModel.drilldownRows(configs: drilldownConfigs, taxEntity: entity, quarterlyData: allQuarterlyData)
        
        VStack {
            Table(rows) {
                TableColumn("") { Text($0.label).bold() }.width(min: 200)
                TableColumn("1Q") { Text($0.q1, format: .currency(code: "USD").precision(.fractionLength(0))) }.alignment(.center)
                TableColumn("2Q") { Text($0.q2, format: .currency(code: "USD").precision(.fractionLength(0))) }.alignment(.center)
                TableColumn("3Q") { Text($0.q3, format: .currency(code: "USD").precision(.fractionLength(0))) }.alignment(.center)
                TableColumn("4Q") { Text($0.q4, format: .currency(code: "USD").precision(.fractionLength(0))) }.alignment(.center)
            }
            .frame(minWidth: 500, maxWidth: 900)
            .navigationTitle("\(entity.rawValue) Detail")
            
            HStack {
                Text("* - calculated based on an internal factor")
                    .font(.caption2)
                    .padding(15)
                Spacer()
            }
        }
    }
}
