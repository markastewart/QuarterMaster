//
//  Curator.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/17/26.
//

import Foundation

struct DataCurator {

    static func curateData(quarterlyRecord: TaxPeriodInput) {
        
            // Aggregate other income parts to a single value for other income.
        let otherIncomeFields: [EstimateValues] = [.oilRoyalties, .supplementalIncome]
        
        var calculatedOtherIncome = 00.0
        for field in otherIncomeFields {
            calculatedOtherIncome = calculatedOtherIncome + quarterlyRecord[keyPath: field.keyPath]
        }
        quarterlyRecord.otherIncome = calculatedOtherIncome
        
            // Use factor to estimate Qualified Dividends from sum of Qualified Eligible Dividends & Short-term Capital Gain/Reinvest STCG
        quarterlyRecord.qualifiedDividends = (quarterlyRecord.qualifiedEligibleDividends + quarterlyRecord.shortTermCG +  quarterlyRecord.reinvestSTCG) * SeasonalConstants.qualifiedDividendsFactor
        
            // Add Qualified Eligible Dividends to Ordinary Dividends to use for tax calc.
        quarterlyRecord.ordinaryDividends += quarterlyRecord.qualifiedEligibleDividends
        
            // Add Reinvest Long-term CG to Capital Gain Distribution
        quarterlyRecord.capitalGainDistribution += quarterlyRecord.reinvestLTCG
        
            // Remove leading negative sign from Federal and State witholdings and estimates.
        quarterlyRecord.fedCYEstimates = quarterlyRecord.fedCYEstimates * -1
        quarterlyRecord.stateCYEstimates = quarterlyRecord.stateCYEstimates * -1
        quarterlyRecord.fedCYWitholding = quarterlyRecord.fedCYWitholding * -1
        quarterlyRecord.stateCYWitholding = quarterlyRecord.stateCYWitholding * -1
    }
}
