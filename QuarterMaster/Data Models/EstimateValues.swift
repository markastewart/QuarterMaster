//
//  EstimateValues.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/15/26.
//

import Foundation

enum EstimateValues: String, CaseIterable {
    case pensionAnnuities = "Pensions & Annuities"
    case socialSecurity = "Social Security Benefits"
    case interest = "Interest"
    case oilRoyalties = "Oil Royalties"
    case drugTrialCompensation = "Drug Trial Compensation"
    case ordinaryDividends = "Ordinary Dividends"
    case qualifiedDividends = "Qualified Dividends"
    case iraDistributions = "IRA Distributions"
    case shortTermCG = "Short Term Capital Gain"
    case longTermCG = "Long Term Capital Gain"
    case shortTermGain = "Short Term Gain"
    case longTermGain = "Long Term Gain"
    case fedCYWitholding = " Federal Income Tax - CY Witholding"
    case fedCYEstimates = " Federal Income Tax - CY Estimates"
    case stateCYWitholding = "State Income Tax - CY Witholding"
    case stateCYEstimates = "State Income Tax - CY Estimates"


        // Maps the Enum case to the actual property in your SwiftData model
    var keyPath: WritableKeyPath<QuarterlyInput, Double> {
        switch self {
        case .pensionAnnuities: return \.pensionAnnuities
        case .socialSecurity: return \.socialSecurity
        case .interest: return \.interest
        case .oilRoyalties: return \.oilRoyalties
        case .drugTrialCompensation: return \.drugTrialCompensation
        case .ordinaryDividends: return \.ordinaryDividends
        case .qualifiedDividends: return \.qualifiedDividends
        case .iraDistributions: return \.iraDistributions
        case .shortTermCG: return \.shortTermCG
        case .longTermCG: return \.longTermCG
        case .shortTermGain: return \.shortTermGain
        case .longTermGain: return \.longTermGain
        case .fedCYWitholding: return \.fedCYWitholding
        case .fedCYEstimates: return \.fedCYEstimates
        case .stateCYWitholding: return \.stateCYWitholding
        case .stateCYEstimates: return \.stateCYEstimates
        }
    }
}
