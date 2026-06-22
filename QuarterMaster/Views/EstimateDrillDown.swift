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
    let isFederal: Bool
    let taxPeriodInput: [TaxPeriodInput]
    
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
            
        let rows = drilldownRows(configs: drilldownConfigs, taxEntity: entity, taxPeriodInput: taxPeriodInput)
            
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

    // Support functions, structures for the view.

struct DrilldownRowConfig {
    let displayName: String
    let extract: (TaxPeriodInput?, TaxEstimate?) -> Double
}

struct DrilldownRow: Identifiable {
    let label: String
    let q1: Double
    let q2: Double
    let q3: Double
    let q4: Double
    
    var id: String { label }
}

func drilldownRows(configs: [DrilldownRowConfig], taxEntity: TaxEntity, taxPeriodInput: [TaxPeriodInput]) -> [DrilldownRow] {
    func data(for taxPeriod: String) -> (TaxPeriodInput?, TaxEstimate?) {
        let input = taxPeriodInput.first { $0.periodType == taxPeriod }
        let estimate = input?.taxEstimates.first { $0.taxEntity == taxEntity.rawValue }
        return (input, estimate)
    }
    
    let q1Data = data(for: TaxPeriod.first.rawValue)
    let q2Data = data(for: TaxPeriod.second.rawValue)
    let q3Data = data(for: TaxPeriod.third.rawValue)
    let q4Data = data(for: TaxPeriod.fourth.rawValue)
    
    return configs.map { config in
        DrilldownRow(
            label: config.displayName,
            q1: config.extract(q1Data.0, q1Data.1),
            q2: config.extract(q2Data.0, q2Data.1),
            q3: config.extract(q3Data.0, q3Data.1),
            q4: config.extract(q4Data.0, q4Data.1)
        )
    }
}

