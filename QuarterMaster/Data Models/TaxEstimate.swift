//
//  TaxEstimate.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/17/26.
//

import Foundation
import SwiftData

@Model
final class TaxEstimate {
    var quarterID: String = ""
    var taxEntity: String = ""
    var taxableSocialSecurity = 0.0
    var adjustedGrossIncome = 0.0
    var taxableCapitalGains = 0.0
    var additionalDeductions = 0.0
    var totalDeductions = 0.0
    var taxableIncome = 0.0
    var totalTax : Double = 0.0
    var taxesPaid: Double = 0.0
    var taxEstimate: Double = 0.0
    
    var quarterlyInput: QuarterlyInput?
        
    init(taxEntity: String, quarterlyInput: QuarterlyInput) {
        self.taxEntity = taxEntity
        self.quarterlyInput = quarterlyInput
        self.quarterID = quarterlyInput.quarterID
    }
}

enum TaxEntity: String, CaseIterable, Identifiable {
    case federal = "Federal"
    case state = "State"
    
        // Required for Identifiable so you can use it in a Picker
    var id: String { self.rawValue }
    
//    var annualizationFactor: Double {
//            switch self {
//            case .first:  return 4.0   // 12 months / 3
//            case .second: return 2.4   // 12 months / 5
//            case .third:  return 1.5   // 12 months / 8
//            case .fourth: return 1.0   // 12 months / 12
//            }
//        }
//    
//    static func factor(for rawValue: String) -> Double {
//            // Returns the factor if found, or 1.0 (or 0.0) as a safe default
//        return Quarter(rawValue: rawValue)?.annualizationFactor ?? 1.0
//    }
}
