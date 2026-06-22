//
//  FederalTaxCalculator.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/17/26.
//

import Foundation

struct FederalTaxCalculator {
    
    static func calculateFederalEstimate(quarterlyRecord: QuarterlyInput) {
        let fedEstimate = TaxEstimate(taxEntity: TaxEntity.federal.rawValue, quarterlyInput: quarterlyRecord)
        
        let taxableInterest = quarterlyRecord.interest
        
        let ordinaryDividends = quarterlyRecord.ordinaryDividends
        
        let iraDistributions = quarterlyRecord.iraDistributions
        
        let pensionAnnuities = quarterlyRecord.pensionAnnuities
        
            // Calculate Taxable Social Security
        taxableSocialSecurityCalc(fedEstimate: fedEstimate, quarterlyRecord: quarterlyRecord)
        
            // Calculate Taxable Capital Gains
        taxableCapitalGainsCalc(quarterlyRecord: quarterlyRecord, fedEstimate: fedEstimate)
        
        let additionalIncome = quarterlyRecord.otherIncome
        
            // Calculate federal AGI
        let quarterlyAdjustedGrossIncome = taxableInterest + ordinaryDividends + iraDistributions + pensionAnnuities + fedEstimate.taxableCapitalGains + additionalIncome
        
            // Social security is already annualized so add it to remainder of annualized AGI.
        fedEstimate.adjustedGrossIncome = (quarterlyAdjustedGrossIncome * Quarter.factor(for: quarterlyRecord.quarterID)) + fedEstimate.taxableSocialSecurity
        
        additionalDeductionsCalc(fedEstimate: fedEstimate)
        
            // Calculate total deductions and taxable income
        fedEstimate.totalDeductions = Double (SeasonalConstants.standardDeduction) + fedEstimate.additionalDeductions
        
        fedEstimate.taxableIncome = fedEstimate.adjustedGrossIncome - fedEstimate.totalDeductions
        
        fedEstimate.totalTax = annualTaxCalc(quarterlyRec: quarterlyRecord, fedEstimate: fedEstimate) - SeasonalConstants.foreignTaxPaid
        
        fedEstimate.taxesPaid = quarterlyRecord.fedCYWitholding + quarterlyRecord.fedCYEstimates
        
            // Proprate tax due pay YTD
        let prorateTaxDue = (fedEstimate.totalTax * (1 / Quarter.factor(for: quarterlyRecord.quarterID))) - fedEstimate.taxesPaid
        
        fedEstimate.taxEstimate = prorateTaxDue
    }
    
    
        // taxableSocialSecurityCalc - Calculate taxable social security for estimate.
    static func taxableSocialSecurityCalc(fedEstimate: TaxEstimate, quarterlyRecord: QuarterlyInput) {

        // Keep it simple - if annualized pensions, interest, other income, ordinary dividends > MaxThreshold, taxable social security is 85%; if less that MinThreshold its 0, otherwise 0.50.
        
        let annualizedAGI = (quarterlyRecord.pensionAnnuities + quarterlyRecord.ordinaryDividends + quarterlyRecord.otherIncome + quarterlyRecord.interest) * Quarter.factor(for: fedEstimate.quarterID)
        
        let annualizedSocialSecurity = quarterlyRecord.socialSecurity * Quarter.factor(for: fedEstimate.quarterID)
        
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
    
    
    static func taxableCapitalGainsCalc(quarterlyRecord: QuarterlyInput, fedEstimate: TaxEstimate) {
        
        fedEstimate.taxableCapitalGains = quarterlyRecord.shortTermCG + quarterlyRecord.longTermGain + quarterlyRecord.capitalGainDistribution
    }
    
    static func additionalDeductionsCalc(fedEstimate: TaxEstimate) {
        
        let excess = fedEstimate.adjustedGrossIncome - SeasonalConstants.enhancedDeductionThreshold
        let reduction = excess * 0.06
        let additionalDeduction = SeasonalConstants.maxEnhancedDeduction - reduction
            // If additional deduction available, multiple by 2 for MFJ
        fedEstimate.additionalDeductions = additionalDeduction < 0 ? 0 : additionalDeduction * 2
    }
    
    
    static func annualTaxCalc(quarterlyRec: QuarterlyInput, fedEstimate: TaxEstimate) -> Double {
        
        let taxableGains = quarterlyRec.qualifiedDividends + quarterlyRec.capitalGainDistribution + quarterlyRec.longTermGain
        
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
