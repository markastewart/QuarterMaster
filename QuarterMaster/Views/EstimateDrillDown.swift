//
//  EstimateDrillDown.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/19/26.
//

import SwiftUI
import SwiftData

struct EstimateDrillDown: View {
    let isFederal: Bool
    let taxPeriodInput: [TaxPeriodInput]
    let estimateCycle: EstimationCycle
    
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
        DrilldownRowConfig(displayName: "Exemptions *") { _, estimate in estimate?.stateExemptions ?? 0 },
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
                EstimateColumns.makeColumns(taxEntity: entity, estimateCycle: estimateCycle)
            }
            .id(estimateCycle)
            
            HStack {
                Text("* - calculated based on an internal factor")
                    .font(.caption2)
                    .padding(15)
                Spacer()
            }
        }
        .navigationTitle("\(entity.rawValue) Summary")
    }
}


    // Support functions, structures for the view.
struct DrilldownRowConfig {
    let displayName: String
    let extract: (TaxPeriodInput?, TaxEstimate?) -> Double
}

struct DrilldownRow: Identifiable {
    let label: String
    let values: [String: Double]
    var id: String { label }
    
    subscript(key: String) -> Double {
        return values[key] ?? 0.0
    }
}
extension DrilldownRow: TaxRowProvider {}

func drilldownRows(configs: [DrilldownRowConfig], taxEntity: TaxEntity, taxPeriodInput: [TaxPeriodInput]) -> [DrilldownRow] {
    
        // Looking in input data and estimate record, extract data for specified period and return both records
    func data(for taxPeriod: String) -> (TaxPeriodInput?, TaxEstimate?) {
        let input = taxPeriodInput.first { $0.taxPeriodId == taxPeriod }
        let estimate = input?.taxEstimates.first { $0.taxEntity == taxEntity.rawValue }
        return (input, estimate)
    }
    
        // Iterating through the configs, get period ID, extract input and estimate data records for the period, then extract the value associated with the specific config name from the record where that config exists.
    return configs.map { config in
        var rowValues: [String: Double] = [:]
        
        for inputRecord in taxPeriodInput {
            let period = inputRecord.taxPeriodId
            let dataRec = data(for: period)
            let value=config.extract(dataRec.0, dataRec.1)
            rowValues[period]=value
        }
        return DrilldownRow(label: config.displayName, values: rowValues)
    }
}
