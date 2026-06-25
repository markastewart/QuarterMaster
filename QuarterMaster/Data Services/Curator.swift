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
        taxPeriodInput.otherIncome = otherIncomeFields.reduce(0.0) { sum, field in
            sum + taxPeriodInput[keyPath: field.keyPath]
        }
            // Use factor to estimate Qualified Dividends from sum of Qualified Eligible Dividends & Short-term Capital Gain/Reinvest STCG
        taxPeriodInput.qualifiedDividends = (taxPeriodInput.qualifiedEligibleDividends + taxPeriodInput.shortTermCG +  taxPeriodInput.reinvestSTCG) * SeasonalConstants.qualifiedDividendsFactor
        
            // Add Qualified Eligible Dividends to Ordinary Dividends to use for tax calc.
        taxPeriodInput.ordinaryDividends += taxPeriodInput.qualifiedEligibleDividends
        
            // Add Reinvest Long-term CG to Capital Gain Distribution
        taxPeriodInput.capitalGainDistribution += taxPeriodInput.reinvestLTCG
        
            // Remove leading negative sign from Federal and State witholdings, estimates and cash donations.
        taxPeriodInput.fedCYEstimates = abs(taxPeriodInput.fedCYEstimates)
        taxPeriodInput.stateCYEstimates = abs(taxPeriodInput.stateCYEstimates)
        taxPeriodInput.fedCYWitholding = abs(taxPeriodInput.fedCYWitholding)
        taxPeriodInput.stateCYWitholding = abs(taxPeriodInput.stateCYWitholding)
        taxPeriodInput.cashDonations = abs(taxPeriodInput.cashDonations)
    }
}
