//
//  StateTaxCalculator.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/17/26.
//

import Foundation

struct StateTaxCalculator {
    
    static func calculateStateEstimate(quarterlyRecord: QuarterlyInput, fedTaxResults: [TaxEstimate]) {
        let stateEstimate = TaxEstimate(taxEntity: TaxEntity.state.rawValue, quarterlyInput: quarterlyRecord)
        
        guard let fedEstimate = quarterlyRecord.taxEstimates.first(where: {
            $0.quarterID == quarterlyRecord.quarterID
        }) else {
            print("No federal estimate found for \(quarterlyRecord.quarterID)")
            return
        }
        
        stateEstimate.fedAGI = fedEstimate.adjustedGrossIncome
        stateEstimate.incomeAdditions = calculateAdditions(quarterlyResults: quarterlyRecord)
        stateEstimate.totalDeductions = calculateDeductions (quarterlyResults: quarterlyRecord, fedResults: fedEstimate)
        stateEstimate.adjustedGrossIncome = stateEstimate.fedAGI + stateEstimate.incomeAdditions - stateEstimate.totalDeductions
        
        let exemptions = SeasonalConstants.stateExemption * 2
        stateEstimate.taxableIncome = stateEstimate.adjustedGrossIncome - exemptions
        
        stateEstimate.totalTax = calculateTaxFromTables(taxableIncome: stateEstimate.taxableIncome)
        let credits = calculateCredits(taxLiability: stateEstimate.totalTax, taxableIncome: stateEstimate.taxableIncome)
        stateEstimate.totalTax -= credits
        
        stateEstimate.taxesPaid = quarterlyRecord.stateCYEstimates + quarterlyRecord.stateCYWitholding
        
            // Proprate tax due pay YTD
        let prorateTaxDue = (stateEstimate.totalTax * (1 / Quarter.factor(for: quarterlyRecord.quarterID))) - stateEstimate.taxesPaid
        stateEstimate.taxEstimate = prorateTaxDue
    }
    
    static func calculateAdditions(quarterlyResults: QuarterlyInput) -> Double {
        let additions = quarterlyResults.dividendsNonTaxable * SeasonalConstants.nonTaxDividendsFactor
        return additions
    }
    
    static func calculateDeductions(quarterlyResults: QuarterlyInput, fedResults: TaxEstimate) -> Double {
        let deductions = fedResults.taxableSocialSecurity + quarterlyResults.deposit529
        return deductions
    }
    
    static func calculateTaxFromTables(taxableIncome: Double) -> Double {
        
        let minTax = SeasonalConstants.OhioTaxTable2025.getMinTax(for: taxableIncome)
        let minRate = SeasonalConstants.OhioTaxTable2025.getMarginalRate(for: taxableIncome)
        let totalTax = minTax + ((taxableIncome - SeasonalConstants.OhioTaxTable2025.getBracketStart(for: taxableIncome)) * minRate)
        return totalTax
    }
    
    static func calculateCredits(taxLiability: Double, taxableIncome: Double) -> Double {
        
        let jfcRate = SeasonalConstants.OhioJFC2025.getMarginalRate(for: taxableIncome)
        return taxLiability * jfcRate
    }
}
