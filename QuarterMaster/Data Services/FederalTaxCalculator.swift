//
//  FederalTaxCalculator.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/17/26.
//

import Foundation

struct FederalTaxCalculator {
    
    static func calculateFederalEstimate(taxPeriodInput: TaxPeriodInput) {
        let fedEstimate = TaxEstimate(taxEntity: TaxEntity.federal.rawValue, taxPeriodInput: taxPeriodInput)
        
        let taxableInterest = taxPeriodInput.interest
        
        let ordinaryDividends = taxPeriodInput.ordinaryDividends
        
        let iraDistributions = taxPeriodInput.iraDistributions
        
        let pensionAnnuities = taxPeriodInput.pensionAnnuities
        
            // Calculate Taxable Social Security
        taxableSocialSecurityCalc(fedEstimate: fedEstimate, taxPeriodInput: taxPeriodInput)
        
            // Calculate Taxable Capital Gains
        taxableCapitalGainsCalc(taxPeriodInput: taxPeriodInput, fedEstimate: fedEstimate)
        
        let additionalIncome = taxPeriodInput.otherIncome
        
            // Calculate federal AGI
        let quarterlyAdjustedGrossIncome = taxableInterest + ordinaryDividends + iraDistributions + pensionAnnuities + fedEstimate.taxableCapitalGains + additionalIncome
        
            // Social security is already annualized so add it to remainder of annualized AGI.
        fedEstimate.adjustedGrossIncome = (quarterlyAdjustedGrossIncome * TaxPeriod.factor(for: taxPeriodInput.taxPeriodId)) + fedEstimate.taxableSocialSecurity
        
        additionalDeductionsCalc(fedEstimate: fedEstimate)
        
            // Calculate total deductions and taxable income
        fedEstimate.totalDeductions = Double (SeasonalConstants.standardDeduction) + fedEstimate.additionalDeductions + min(taxPeriodInput.cashDonations, 2000.0)
        
        fedEstimate.taxableIncome = fedEstimate.adjustedGrossIncome - fedEstimate.totalDeductions
        
        fedEstimate.totalTax = annualTaxCalc(taxPeriodInput: taxPeriodInput, fedEstimate: fedEstimate) - SeasonalConstants.foreignTaxPaid
        
        fedEstimate.taxesPaid = taxPeriodInput.fedCYWitholding + taxPeriodInput.fedCYEstimates
        
            // Proprate tax due pay YTD
        let prorateTaxDue = (fedEstimate.totalTax * (1 / TaxPeriod.factor(for: taxPeriodInput.taxPeriodId))) - fedEstimate.taxesPaid
        
        fedEstimate.taxEstimate = prorateTaxDue
    }
    
    
        // taxableSocialSecurityCalc - Calculate taxable social security for estimate.
    static func taxableSocialSecurityCalc(fedEstimate: TaxEstimate, taxPeriodInput: TaxPeriodInput) {

        // Keep it simple - if annualized pensions, interest, other income, ordinary dividends > MaxThreshold, taxable social security is 85%; if less that MinThreshold its 0, otherwise 0.50.
        
        guard let periodType = fedEstimate.taxPeriodInput?.taxPeriodId else { return }
        let annualizedAGI = (taxPeriodInput.pensionAnnuities + taxPeriodInput.ordinaryDividends + taxPeriodInput.otherIncome + taxPeriodInput.interest) * TaxPeriod.factor(for: periodType)
        
        let annualizedSocSec = taxPeriodInput.socialSecurity * TaxPeriod.factor(for: periodType)
        
        fedEstimate.taxableSocialSecurity = computeTaxableSocialSecurity(annualizedAGI: annualizedAGI, annualizedSS: annualizedSocSec)
        
        func computeTaxableSocialSecurity(annualizedAGI: Double, annualizedSS: Double) -> Double {
            if annualizedAGI > Double(SeasonalConstants.ssMaxThreshold) { return annualizedSS * 0.85 }
            if annualizedAGI < Double(SeasonalConstants.ssMinThreshold) { return 0 }
            return annualizedSS * 0.50
        }
    }
    
    
    static func taxableCapitalGainsCalc(taxPeriodInput: TaxPeriodInput, fedEstimate: TaxEstimate) {
        
        fedEstimate.taxableCapitalGains = taxPeriodInput.shortTermCG + taxPeriodInput.longTermGain + taxPeriodInput.capitalGainDistribution
    }
    
    static func additionalDeductionsCalc(fedEstimate: TaxEstimate) {
        
        let excess = fedEstimate.adjustedGrossIncome - SeasonalConstants.enhancedDeductionThreshold
        let reduction = excess * 0.06
        let additionalDeduction = SeasonalConstants.maxEnhancedDeduction - reduction
            // If additional deduction available, multiple by 2 for MFJ
        fedEstimate.additionalDeductions = additionalDeduction < 0 ? 0 : additionalDeduction * 2
    }
    
    
    static func annualTaxCalc(taxPeriodInput: TaxPeriodInput, fedEstimate: TaxEstimate) -> Double {
        
        let taxableGains = taxPeriodInput.qualifiedDividends + taxPeriodInput.capitalGainDistribution + taxPeriodInput.longTermGain
        
        let ordinaryIncome = fedEstimate.taxableIncome - taxableGains
        
        let taxOnGains = taxableGains * 0.15
        
        let taxOnOrdinary = calculateTaxFromTables(taxableIncome: ordinaryIncome)
        
        return taxOnGains + taxOnOrdinary
    }
    
    
    static func calculateTaxFromTables(taxableIncome: Double) -> Double {
        var totalTax = 0.0
        var remainingIncome = taxableIncome
        
        for bracket in SeasonalConstants.IRSTaxTable.mfjBrackets {
            let bracketMax = bracket.maxIncome ?? Double.infinity
            let taxableInThisBracket = min(remainingIncome, bracketMax - bracket.minIncome)
            
            if taxableInThisBracket > 0 {
                totalTax += taxableInThisBracket * bracket.rate
                remainingIncome -= taxableInThisBracket
            } else {
                break
            }
        }
        return max(0, totalTax)
    }
}
