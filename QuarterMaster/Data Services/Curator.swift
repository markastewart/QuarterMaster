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
        
            // Apply factor to estimate Qualified Dividends from Qualified Eligible Dividends.
        quarterlyRecord.qualifiedDividends = quarterlyRecord.qualifiedEligibleDividends * SeasonalConstants.qualifiedDividendsFactor
    }
}
