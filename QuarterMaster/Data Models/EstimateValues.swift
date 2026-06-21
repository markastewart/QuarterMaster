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
    case supplementalIncome = "Supplemental Income"
    case ordinaryDividends = "Ordinary Dividends"
    case qualifiedDividends = "Qualified Dividends"
    case qualifiedEligibleDividends = "Qualified Eligible Dividends"
    case iraDistributions = "IRA Distributions"
    case shortTermCG = "Short Term Capital Gain"
    case shortTermGain = "Short Term Gain"
    case longTermGain = "Long Term Gain"
    case reinvestSTCG = "Reinvest Short-term Capital Gain"
    case reinvestLTCG = "Reinvest Long-term Capital Gain"
    case capitalGainDistribution = "Capital Gain Distribution"
    case fedCYWitholding = "Federal Income Tax - CY Witholding"
    case fedCYEstimates = "Federal Income Tax - CY Estimated"
    case stateCYWitholding = "State Income Tax - CY Witholding"
    case stateCYEstimates = "State Income Tax - CY Estimated"
    case deposit529 = "529 Deposit"
    case dividendsNonTaxable = "Dividends NonTaxable"


        // Maps the Enum case to the actual property in your SwiftData model
    var keyPath: WritableKeyPath<QuarterlyInput, Double> {
        switch self {
        case .pensionAnnuities: return \.pensionAnnuities
        case .socialSecurity: return \.socialSecurity
        case .interest: return \.interest
        case .oilRoyalties: return \.oilRoyalties
        case .supplementalIncome: return \.supplementalIncome
        case .ordinaryDividends: return \.ordinaryDividends
        case .qualifiedDividends: return \.qualifiedDividends
        case .qualifiedEligibleDividends: return \.qualifiedEligibleDividends
        case .iraDistributions: return \.iraDistributions
        case .shortTermCG: return \.shortTermCG
        case .shortTermGain: return \.shortTermGain
        case .longTermGain: return \.longTermGain
        case .reinvestSTCG: return \.reinvestSTCG
        case .reinvestLTCG: return \.reinvestLTCG
        case .capitalGainDistribution: return \.capitalGainDistribution
        case .fedCYWitholding: return \.fedCYWitholding
        case .fedCYEstimates: return \.fedCYEstimates
        case .stateCYWitholding: return \.stateCYWitholding
        case .stateCYEstimates: return \.stateCYEstimates
        case .deposit529: return \.deposit529
        case .dividendsNonTaxable: return \.dividendsNonTaxable
        }
    }
}
