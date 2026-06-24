//
//  StateTaxCalculator.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/17/26.
//

import Foundation

struct StateTaxCalculator {
    
    static func calculateStateEstimate(taxPeriodInput: TaxPeriodInput, fedEstimate: TaxEstimate) {
        let stateEstimate = TaxEstimate(taxEntity: TaxEntity.state.rawValue, taxPeriodInput: taxPeriodInput)
        
        stateEstimate.fedAGI = fedEstimate.adjustedGrossIncome
        stateEstimate.incomeAdditions = calculateAdditions(taxPeriodInput: taxPeriodInput)
        stateEstimate.totalDeductions = calculateDeductions (taxPeriodInput: taxPeriodInput, fedResults: fedEstimate)
        stateEstimate.adjustedGrossIncome = stateEstimate.fedAGI + stateEstimate.incomeAdditions - stateEstimate.totalDeductions
        
        stateEstimate.stateExemptions = SeasonalConstants.stateExemption * 2
        stateEstimate.taxableIncome = stateEstimate.adjustedGrossIncome - stateEstimate.stateExemptions
        
        stateEstimate.totalTax = calculateTaxFromTables(taxableIncome: stateEstimate.taxableIncome)
        let credits = calculateCredits(taxLiability: stateEstimate.totalTax, taxableIncome: stateEstimate.taxableIncome)
        stateEstimate.totalTax -= credits
        
        stateEstimate.taxesPaid = taxPeriodInput.stateCYEstimates + taxPeriodInput.stateCYWitholding
        
            // Proprate tax due pay YTD
        let prorateTaxDue = (stateEstimate.totalTax * (1 / TaxPeriod.factor(for: taxPeriodInput.taxPeriodId))) - stateEstimate.taxesPaid
        stateEstimate.taxEstimate = prorateTaxDue
    }
    
    static func calculateAdditions(taxPeriodInput: TaxPeriodInput) -> Double {
        let additions = taxPeriodInput.dividendsNonTaxable * SeasonalConstants.nonTaxDividendsFactor
        return additions
    }
    
    static func calculateDeductions(taxPeriodInput: TaxPeriodInput, fedResults: TaxEstimate) -> Double {
        let deductions = fedResults.taxableSocialSecurity + taxPeriodInput.deposit529
        return deductions
    }
    
    static func calculateTaxFromTables(taxableIncome: Double) -> Double {
        let income = max(0, taxableIncome)
        let minTax = SeasonalConstants.OhioTaxTable2025.getMinTax(for: income)
        let minRate = SeasonalConstants.OhioTaxTable2025.getMarginalRate(for: income)
        let bracketStart = SeasonalConstants.OhioTaxTable2025.getBracketStart(for: income)
        
        return minTax + (max(0, income - bracketStart) * minRate)
    }
    
    static func calculateCredits(taxLiability: Double, taxableIncome: Double) -> Double {
        
        let jfcRate = SeasonalConstants.OhioJFC2025.getMarginalRate(for: taxableIncome)
        return taxLiability * jfcRate
    }
}
