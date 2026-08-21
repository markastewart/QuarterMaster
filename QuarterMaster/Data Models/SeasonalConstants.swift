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
    
    static let standardDeduction = 35500
    static let ssMaxThreshold = 44000
    static let ssMinThreshold = 32000
    static let maxEnhancedDeduction = 6000.0
    static let enhancedDeductionThreshold = 150000.0
    static let stateExemption = 1900.0
    static let nonTaxDividendsFactor = 0.96         // Used for state calculation of additional taxable income.
    static let programYear = "2026"
    static let maxCashDonations = 2000.0
    static let irmaaTier0CeilingMFJ = 226000.0      // Estimated 2028-effective Tier 0→1 MAGI threshold (MFJ)
    static let irmaaTier1CeilingMFJ = 284000.0      // Estimated 2028-effective Tier 1→2 MAGI threshold (MFJ)
    static let irmaaTier2CeilingMFJ = 355000.0      // Estimated 2028-effective Tier 2→3 MAGI threshold (MFJ)
    
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
    
    struct IRSTaxTable {
        static let mfjBrackets: [TaxBracket] = [
            TaxBracket(rate: 0.10, minIncome: 0, maxIncome: 24899),
            TaxBracket(rate: 0.12, minIncome: 24801, maxIncome: 100800),
            TaxBracket(rate: 0.22, minIncome: 100801, maxIncome: 211400),
            TaxBracket(rate: 0.24, minIncome: 211401, maxIncome: 403550),
            TaxBracket(rate: 0.32, minIncome: 403551, maxIncome: 512450),
            TaxBracket(rate: 0.35, minIncome: 512451, maxIncome: 768700),
            TaxBracket(rate: 0.37, minIncome: 768701, maxIncome: nil)
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
    
    struct OhioTaxTable {
        static let mfjBrackets: [StateTaxBracket] = [
            StateTaxBracket(rate: 0.00, minTax: 0.00, minIncome: 0, maxIncome: 26050),
            StateTaxBracket(rate: 0.0275, minTax: 0.00, minIncome: 26051, maxIncome: nil)
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
    
    struct OhioJFC {
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
