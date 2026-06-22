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
        fedEstimate.adjustedGrossIncome = (quarterlyAdjustedGrossIncome * TaxPeriod.factor(for: taxPeriodInput.periodType)) + fedEstimate.taxableSocialSecurity
        
        additionalDeductionsCalc(fedEstimate: fedEstimate)
        
            // Calculate total deductions and taxable income
        fedEstimate.totalDeductions = Double (SeasonalConstants.standardDeduction) + fedEstimate.additionalDeductions
        
        fedEstimate.taxableIncome = fedEstimate.adjustedGrossIncome - fedEstimate.totalDeductions
        
        fedEstimate.totalTax = annualTaxCalc(taxPeriodInput: taxPeriodInput, fedEstimate: fedEstimate) - SeasonalConstants.foreignTaxPaid
        
        fedEstimate.taxesPaid = taxPeriodInput.fedCYWitholding + taxPeriodInput.fedCYEstimates
        
            // Proprate tax due pay YTD
        let prorateTaxDue = (fedEstimate.totalTax * (1 / TaxPeriod.factor(for: taxPeriodInput.periodType))) - fedEstimate.taxesPaid
        
        fedEstimate.taxEstimate = prorateTaxDue
    }
    
    
        // taxableSocialSecurityCalc - Calculate taxable social security for estimate.
    static func taxableSocialSecurityCalc(fedEstimate: TaxEstimate, taxPeriodInput: TaxPeriodInput) {

        // Keep it simple - if annualized pensions, interest, other income, ordinary dividends > MaxThreshold, taxable social security is 85%; if less that MinThreshold its 0, otherwise 0.50.
        
        guard let periodType = fedEstimate.taxPeriodInput?.periodType else { return }
        let annualizedAGI = (taxPeriodInput.pensionAnnuities + taxPeriodInput.ordinaryDividends + taxPeriodInput.otherIncome + taxPeriodInput.interest) * TaxPeriod.factor(for: periodType)
        
        let annualizedSocialSecurity = taxPeriodInput.socialSecurity * TaxPeriod.factor(for: periodType)
        
        if Int (annualizedAGI) > SeasonalConstants.ssMaxThreshold {
            fedEstimate.taxableSocialSecurity = (annualizedSocialSecurity * 0.85)
            
        }
        else if Int (annualizedAGI) < SeasonalConstants.ssMinThreshold {
            fedEstimate.taxableSocialSecurity = 0
        }
        else {
            fedEstimate.taxableSocialSecurity = annualizedSocialSecurity * 0.50
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
    
    
    static func calculateTaxFromTables (taxableIncome: Double) -> Double {
        var totalTax = 0.0
        
        for taxTableRecord in SeasonalConstants.IRSTaxTable2025.mfjBrackets {
            
                // Loop through brackets preceding the bracket for the taxableIncome
            if let max = taxTableRecord.maxIncome, taxableIncome > max {
                totalTax += (taxTableRecord.maxIncome! - taxTableRecord.minIncome) * taxTableRecord.rate
            }
                // This is the bracket for the  taxable income
            else {
                totalTax += (taxableIncome - taxTableRecord.minIncome) * taxTableRecord.rate
                break
            }
        }
        return totalTax
    }
}
