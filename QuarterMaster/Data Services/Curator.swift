//
//  Curator.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/17/26.
//

import Foundation

struct DataCurator {

    static func curateData(taxPeriodInput: TaxPeriodInput) {
        
            // Aggregate other income parts to a single value for other income.
        let otherIncomeFields: [EstimateValues] = [.oilRoyalties, .supplementalIncome]
        
        var calculatedOtherIncome = 00.0
        for field in otherIncomeFields {
            calculatedOtherIncome = calculatedOtherIncome + taxPeriodInput[keyPath: field.keyPath]
        }
        taxPeriodInput.otherIncome = calculatedOtherIncome
        
            // Use factor to estimate Qualified Dividends from sum of Qualified Eligible Dividends & Short-term Capital Gain/Reinvest STCG
        taxPeriodInput.qualifiedDividends = (taxPeriodInput.qualifiedEligibleDividends + taxPeriodInput.shortTermCG +  taxPeriodInput.reinvestSTCG) * SeasonalConstants.qualifiedDividendsFactor
        
            // Add Qualified Eligible Dividends to Ordinary Dividends to use for tax calc.
        taxPeriodInput.ordinaryDividends += taxPeriodInput.qualifiedEligibleDividends
        
            // Add Reinvest Long-term CG to Capital Gain Distribution
        taxPeriodInput.capitalGainDistribution += taxPeriodInput.reinvestLTCG
        
            // Remove leading negative sign from Federal and State witholdings and estimates.
        taxPeriodInput.fedCYEstimates = abs(taxPeriodInput.fedCYEstimates)
        taxPeriodInput.stateCYEstimates = abs(taxPeriodInput.stateCYEstimates)
        taxPeriodInput.fedCYWitholding = abs(taxPeriodInput.fedCYWitholding)
        taxPeriodInput.stateCYWitholding = abs(taxPeriodInput.stateCYWitholding)
    }
}
