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
    
        // Required for Identifiable so you can use it in a Picker if desired
    var id: String { self.rawValue }
}
