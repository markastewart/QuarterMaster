//
//  FederalTaxCalculator.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/17/26.
//

import Foundation

struct FederalTaxCalculator {
    
    static func calculateFederalEstimate(quarterlyRecord: QuarterlyInput) {
        let fedEstimate = TaxEstimate(taxEntity: "Federal", quarterlyInput: quarterlyRecord)
        
        let taxableInterest = quarterlyRecord.interest
        
        let ordinaryDividends = quarterlyRecord.ordinaryDividends
        
        let iraDistributions = quarterlyRecord.iraDistributions
        
        let pensionAnnuities = quarterlyRecord.pensionAnnuities
        
            // Calculate Taxable Social Security
        taxableSocialSecurityCalc(fedEstimate: fedEstimate, quarterlyRecord: quarterlyRecord)
        
            // Calculate Taxable Capital Gains
        taxableCapitalGainsCalc(quarterlyRecord: quarterlyRecord)
        
        let additionalIncome = quarterlyRecord.otherIncome
        
            // Calculate federal AGI
        let quarterlyAdjustedGrossIncome = taxableInterest + ordinaryDividends + iraDistributions + pensionAnnuities + fedEstimate.taxableSocialSecurity + fedEstimate.taxableCapitalGains + additionalIncome
        
        fedEstimate.adjustedGrossIncome = quarterlyAdjustedGrossIncome * Quarter.factor(for: quarterlyRecord.quarterID)
        
        additionalDeductionsCalc(quarterlyRecord: quarterlyRecord)
        
            // Calculate total deductions and taxable income
        fedEstimate.totalDeductions = Double (SeasonalConstants.standardDeduction) + fedEstimate.additionalDeductions
        
        fedEstimate.taxableIncome = fedEstimate.adjustedGrossIncome - fedEstimate.totalDeductions
        
        fedEstimate.totalTax = annualTaxCalc(quarterlyRecord: quarterlyRecord) /*- quarterlyRecord.foreignTaxPaid*/
        
        fedEstimate.taxesPaid = quarterlyRecord.fedCYWitholding + quarterlyRecord.fedCYEstimates
        
        fedEstimate.taxEstimate = fedEstimate.totalTax - fedEstimate.taxesPaid
    }
    
    
    static func taxableSocialSecurityCalc(fedEstimate: TaxEstimate, quarterlyRecord: QuarterlyInput) {

        fedEstimate.taxableSocialSecurity = 123
    }
    
    
    static func taxableCapitalGainsCalc(quarterlyRecord: QuarterlyInput) {
        
    }
    
    static func additionalDeductionsCalc(quarterlyRecord: QuarterlyInput) {
        
    }
    
    
    static func annualTaxCalc(quarterlyRecord: QuarterlyInput) -> Double {
        
        return 0.0
    }
}
