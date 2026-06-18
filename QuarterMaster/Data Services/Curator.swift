//
//  Curator.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/17/26.
//

import Foundation

struct DataCurator {

    static func curateData(quarterlyRecord: QuarterlyInput) {
        
            // Aggregate other income parts to a single value for other income.
        let otherIncomeFields: [EstimateValues] = [.oilRoyalties, .drugTrialCompensation, .pollWorker]
        
        var calculatedOtherIncome = 00.0
        for field in otherIncomeFields {
            calculatedOtherIncome = calculatedOtherIncome + quarterlyRecord[keyPath: field.keyPath]
        }
        quarterlyRecord.otherIncome = calculatedOtherIncome
        
            // Apply factor to estimate Qualified Dividends from Qualified Eligible Dividends. Add 
        quarterlyRecord.qualifiedDividends = quarterlyRecord.qualifiedEligibleDividends * SeasonalConstants.qualifiedDividendsFactor
        
            // Add Qualified Eligible Dividends and Short Term Capital Gain to Ordinary Dividends as that will be what's used for tax calc.
        let additionalOrdinaryDividends = quarterlyRecord.qualifiedEligibleDividends + quarterlyRecord.shortTermCG
        quarterlyRecord.ordinaryDividends += additionalOrdinaryDividends
    }
}
