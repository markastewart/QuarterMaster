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
    var quarterID: String = ""
    var pensionAnnuities : Double = 0.0
    var socialSecurity : Double = 0.0
    var interest: Double = 0.0
    var oilRoyalties: Double = 0.0
    var drugTrialCompensation: Double = 0.0
    var pollWorker: Double = 0.0
    var otherIncome: Double = 0.0
    var ordinaryDividends: Double = 0.0
    var qualifiedDividends: Double = 0.0
    var qualifiedEligibleDividends: Double = 0.0
    var iraDistributions: Double = 0.0
    var shortTermCG: Double = 0.0
    var shortTermGain: Double = 0.0
    var longTermGain: Double = 0.0
    var fedCYWitholding: Double = 0.0
    var fedCYEstimates: Double = 0.0
    var stateCYWitholding: Double = 0.0
    var stateCYEstimates: Double = 0.0
    
    
    init() {
        
    }
}

extension QuarterlyInput {
    /// Returns an existing record or creates a new one, ready for population.
    static func getRecord(for quarterID: String, in context: ModelContext) -> QuarterlyInput {
        let predicate = #Predicate<QuarterlyInput> { $0.quarterID == quarterID }
        let descriptor = FetchDescriptor<QuarterlyInput>(predicate: predicate)
        
        do {
            if let existing = try context.fetch(descriptor).first {
                return existing
            }
        } catch {
            print("Fetch failed, creating new record.")
        }
            // Create new if none found
        let newRecord = QuarterlyInput()
        newRecord.quarterID = quarterID
        context.insert(newRecord)
        return newRecord
    }
}
