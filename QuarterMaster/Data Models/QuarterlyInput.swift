//
//  QuarterlyInput.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/15/26.
//

import Foundation
import SwiftData

@Model
final class QuarterlyInput {
    var timestamp: Date
    var quarterID: String = ""
    var pensionAnnuities : Double = 0.0
    var socialSecurity : Double = 0.0
    var interest: Double = 0.0
    var oilRoyalties: Double = 0.0
    var drugTrialCompensation: Double = 0.0
    var ordinaryDividends: Double = 0.0
    var qualifiedDividends: Double = 0.0
    var iraDistributions: Double = 0.0
    var shortTermCG: Double = 0.0
    var longTermCG: Double = 0.0
    var shortTermGain: Double = 0.0
    var longTermGain: Double = 0.0
    var cashDonations: Double = 0.0
    var IRSCYWitholding: Double = 0.0
    var IRSCYEstimates: Double = 0.0
    var StateCYWitholding: Double = 0.0
    var StateCYEstimates: Double = 0.0
    
    
    init(timestamp: Date = .now) {
        self.timestamp = timestamp
    }
}
