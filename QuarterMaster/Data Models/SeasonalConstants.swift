//
//  SeasonalConstants.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/17/26.
//

import Foundation

struct SeasonalConstants {
    
        // Historical Thrivent Select Account data (source year-end Tax Summary Report) relating ordinary dividends to qualified dividends and foreign taxes paid (both rolling 5-year averages). See Financial Spreadsheet.
    static let qualifiedDividendsFactor = 0.56
    static let foreignTaxPaid = 205.0
    
    static let standardDeduction = 34700
    static let ssMaxThreshold = 44000
    static let ssMinThreshold = 32000
    static let maxEnhancedDeduction = 6000.0
    static let enhancedDeductionThreshold = 150000.0
    static let stateExemption = 1900.0
    static let nonTaxDividendsFactor = 0.96         // Used for state calculation of additional taxable income.
    static let programYear = "2025"
    
    struct TaxBracket {
        let rate: Double
        let minIncome: Double
        let maxIncome: Double?
        
        func contains(_ income: Double) -> Bool {
            if let max = maxIncome {
                return income >= minIncome && income <= max
            }
            return income >= minIncome
        }
    }
    
    struct IRSTaxTable2025 {
        static let mfjBrackets: [TaxBracket] = [
            TaxBracket(rate: 0.10, minIncome: 0, maxIncome: 23850),
            TaxBracket(rate: 0.12, minIncome: 23851, maxIncome: 96950),
            TaxBracket(rate: 0.22, minIncome: 96951, maxIncome: 206700),
            TaxBracket(rate: 0.24, minIncome: 206701, maxIncome: 394600),
            TaxBracket(rate: 0.32, minIncome: 394601, maxIncome: 501050),
            TaxBracket(rate: 0.35, minIncome: 501051, maxIncome: 751600),
            TaxBracket(rate: 0.37, minIncome: 751601, maxIncome: nil)
        ]
            // Helper to retrieve marginal tax rate. If income above maxIncomes, defaults to final (highest) bracket.
        static func getMarginalRate(for income: Double) -> Double {
            let bracket = mfjBrackets.first { $0.contains(income) } ?? mfjBrackets.last!
            return bracket.rate
        }
    }
    
    struct StateTaxBracket {
        let rate: Double
        let minTax: Double
        let minIncome: Double
        let maxIncome: Double?
        
        func contains(_ income: Double) -> Bool {
            if let max = maxIncome {
                return income >= minIncome && income <= max
            }
            return income >= minIncome
        }
    }
    
    struct OhioTaxTable2025 {
        static let mfjBrackets: [StateTaxBracket] = [
            StateTaxBracket(rate: 0.00, minTax: 0.00, minIncome: 0, maxIncome: 26050),
            StateTaxBracket(rate: 0.0275, minTax: 342.00, minIncome: 26051, maxIncome: 100000),
            StateTaxBracket(rate: 0.03125, minTax: 2394.32, minIncome: 100001, maxIncome: nil)
        ]
            // Helper to retrieve marginal tax rate. If income above maxIncomes, defaults to final (highest) bracket.
        static func getMarginalRate(for income: Double) -> Double {
            let bracket = mfjBrackets.first { $0.contains(income) } ?? mfjBrackets.last!
            return bracket.rate
        }
            
        static func getMinTax(for income: Double) -> Double {
            let bracket = mfjBrackets.first { $0.contains(income) } ?? mfjBrackets.last!
            return bracket.minTax
        }
        
        static func getBracketStart(for income: Double) -> Double {
            let bracket = mfjBrackets.first { $0.contains(income) } ?? mfjBrackets.last!
            return bracket.minIncome
        }
    }
    
    struct OhioJFC2025 {
        static let mfjBrackets: [TaxBracket] = [
            TaxBracket(rate: 0.20, minIncome: 0, maxIncome: 25000),
            TaxBracket(rate: 0.15, minIncome: 25001, maxIncome: 50000),
            TaxBracket(rate: 0.10, minIncome: 50001, maxIncome: 75000),
            TaxBracket(rate: 0.05, minIncome: 75001, maxIncome: 749999),
            TaxBracket(rate: 0.00, minIncome: 750000, maxIncome: nil),
        ]
            // Helper to retrieve marginal tax rate. If income above maxIncomes, defaults to final (highest) bracket.
        static func getMarginalRate(for income: Double) -> Double {
            let bracket = mfjBrackets.first { $0.contains(income) } ?? mfjBrackets.last!
            return bracket.rate
        }
    }
}
