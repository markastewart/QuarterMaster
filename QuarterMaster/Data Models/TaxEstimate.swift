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
    var taxEntity: String = ""
    var taxableSocialSecurity = 0.0
    var adjustedGrossIncome = 0.0
    var incomeAdditions = 0.0
    var taxableCapitalGains = 0.0
    var netInvestmentIncomeTax = 0.0
    var marginalTaxRate = 0.0
    var additionalDeductions = 0.0
    var totalDeductions = 0.0
    var taxableIncome = 0.0
    var totalTax = 0.0
    var taxesPaid = 0.0
    var taxEstimate = 0.0
    var fedAGI = 0.0
    var stateExemptions = 0.0
    
    var taxPeriodInput: TaxPeriodInput?
    
    init(taxEntity: String, taxPeriodInput: TaxPeriodInput) {
        self.taxEntity = taxEntity
        self.taxPeriodInput = taxPeriodInput
    }
}

enum TaxEntity: String, CaseIterable, Identifiable, Hashable {
    case federal = "Federal"
    case state = "State"
    
        // Required for Identifiable so you can use it in a Picker if desired
    var id: String { self.rawValue }
}

    // Helper extension so in Xcode when at a breakpoint, can type, po <TaxEstimate typed variable name - e.g., po taxEstimate and get a display of all variables and values.
extension TaxEstimate: CustomStringConvertible {
    var description: String {
        """
        TaxEstimate:
          taxEntity:                \(taxEntity)
          taxableSocialSecurity:    \(taxableSocialSecurity)
          adjustedGrossIncome:      \(adjustedGrossIncome)
          incomeAdditions:          \(incomeAdditions)
          taxableCapitalGains:      \(taxableCapitalGains)
          netInvestmentIncomeTax:   \(netInvestmentIncomeTax)
          marginalTaxRate:          \(marginalTaxRate)
          additionalDeductions:     \(additionalDeductions)
          totalDeductions:          \(totalDeductions)
          taxableIncome:            \(taxableIncome)
          totalTax:                 \(totalTax)
          taxesPaid:                \(taxesPaid)
          taxEstimate:              \(taxEstimate)
          fedAGI:                   \(fedAGI)
          stateExemptions:          \(stateExemptions)
        """
    }
}
