//
//  TaxPeriodInput.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/15/26.
//

import Foundation
import SwiftData

@Model
final class TaxPeriodInput {
    var taxPeriodId: String = ""
    var estimationCycle: EstimationCycle = EstimationCycle.quarterly
    var pensionAnnuities = 0.0
    var socialSecurity = 0.0
    var interest = 0.0
    var oilRoyalties = 0.0
    var supplementalIncome = 0.0
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
    var fedCYWitholding = 0.0
    var fedCYEstimates = 0.0
    var stateCYWitholding = 0.0
    var stateCYEstimates = 0.0
    var deposit529 = 0.0
    var dividendsNonTaxable = 0.0
    
    @Relationship(deleteRule: .cascade, inverse: \TaxEstimate.taxPeriodInput)
    var taxEstimates: [TaxEstimate] = []
    
    
    init() {
    }
}

extension TaxPeriodInput {
        /// Returns an existing record or creates a new one, ready for population.
    static func getRecord(for taxPeriod: String, estimationCycle: EstimationCycle, in context: ModelContext) -> TaxPeriodInput {
        
            // Fetch all records, filter in memory — avoids the predicate enum bug. If record found, delete it and create a new one. If no record, then just create a new one.
        let descriptor = FetchDescriptor<TaxPeriodInput>()
        do {
            let all = try context.fetch(descriptor)
            if let existing = all.first(where: { $0.estimationCycle == estimationCycle && $0.taxPeriodId == taxPeriod }) {
                context.delete(existing)
                try? context.save()
            }
        } catch {
            print("Fetch failed: \(error)")
        }
        
        let newRecord = TaxPeriodInput()
        newRecord.taxPeriodId = taxPeriod
        newRecord.estimationCycle = estimationCycle
        context.insert(newRecord)
        return newRecord
    }
}

enum TaxPeriod: String, CaseIterable, Identifiable, Hashable {
    case first = "1Q"
    case second = "2Q"
    case third = "3Q"
    case fourth = "4Q"
    case annual = "Annual"
    
        // Required for Identifiable so you can use it in a Picker
    var id: String { self.rawValue }
    
    var annualizationFactor: Double {
            switch self {
            case .first:  return 4.0   // 12 months / 3
            case .second: return 2.4   // 12 months / 5
            case .third:  return 1.5   // 12 months / 8
            case .fourth: return 1.0   // 12 months / 12
            case .annual: return 1.0   // 12 months / 12
            }
        }
    
    static func factor(for rawValue: String) -> Double {
            // Returns the factor if found, or 1.0 (or 0.0) as a safe default
        return TaxPeriod(rawValue: rawValue)?.annualizationFactor ?? 1.0
    }
}

enum EstimationCycle: String, Codable, CaseIterable, Identifiable, Hashable {
    case quarterly = "Quarterly"
    case annual = "Annual"
    
    var id: String {self.rawValue}
}

    // Helper extension so in Xcode when at a breakpoint, can type, po <TaxPeriodInput typed variable name - e.g., po taxPeriodInput and get a display of all variables and values.
extension TaxPeriodInput: CustomStringConvertible {
    var description: String {
        """
        TaxPeriodInput:
          taxPeriodId:               \(taxPeriodId)
          estimationCycle:                  \(estimationCycle)
          pensionAnnuities:          \(pensionAnnuities)
          socialSecurity:            \(socialSecurity)
          interest:                  \(interest)
          oilRoyalties:              \(oilRoyalties)
          supplementalIncome:        \(supplementalIncome)
          otherIncome:               \(otherIncome)
          ordinaryDividends:         \(ordinaryDividends)
          qualifiedDividends:        \(qualifiedDividends)
          qualifiedEligibleDividends:\(qualifiedEligibleDividends)
          iraDistributions:          \(iraDistributions)
          shortTermCG:               \(shortTermCG)
          shortTermGain:             \(shortTermGain)
          longTermGain:              \(longTermGain)
          reinvestSTCG:              \(reinvestSTCG)
          reinvestLTCG:              \(reinvestLTCG)
          capitalGainDistribution:   \(capitalGainDistribution)
          fedCYWitholding:           \(fedCYWitholding)
          fedCYEstimates:            \(fedCYEstimates)
          stateCYWitholding:         \(stateCYWitholding)
          stateCYEstimates:          \(stateCYEstimates)
          deposit529:                \(deposit529)
          dividendsNonTaxable:       \(dividendsNonTaxable)
          taxEstimates count:        \(taxEstimates.count)
        """
    }
}
