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
    var pensionAnnuities = 0.0
    var socialSecurity = 0.0
    var interest = 0.0
    var oilRoyalties = 0.0
    var drugTrialCompensation = 0.0
    var pollWorker = 0.0
    var otherIncome = 0.0
    var ordinaryDividends = 0.0
    var qualifiedDividends = 0.0
    var qualifiedEligibleDividends = 0.0
    var iraDistributions = 0.0
    var shortTermCG = 0.0
    var shortTermGain = 0.0
    var longTermGain = 0.0
    var reinvestSTCG = 0.0
    var reinvestLTCG = 0.0
    var capitalGainDistribution = 0.0
    var fedCYWitholding: Double = 0.0
    var fedCYEstimates: Double = 0.0
    var stateCYWitholding: Double = 0.0
    var stateCYEstimates: Double = 0.0
    
    @Relationship(deleteRule: .cascade, inverse: \TaxEstimate.quarterlyInput)
    var taxEstimates: [TaxEstimate] = []
    
    
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
                context.delete(existing)
                try? context.save()
            }
        } catch {
            print("Fetch failed: \(error)")
        }
        
        let newRecord = QuarterlyInput()
        newRecord.quarterID = quarterID
        context.insert(newRecord)
        
        return newRecord
    }
}
