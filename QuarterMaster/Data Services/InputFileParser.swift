//
//  InputFileParser.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/15/26.
//

import Foundation
import SwiftData

extension String {
    func toDouble() -> Double? {
        let cleaned = self.replacingOccurrences(of: "[$, ]", with: "", options: .regularExpression)
        return Double(cleaned)
    }
}

struct CSVImportService {
        
    static func processCSV(content: String, context: ModelContext, estimationCycle: EstimationCycle, taxPeriod: TaxPeriod) -> TaxPeriodInput {
        var taxPeriodInput: TaxPeriodInput?
        
            // Parse input file: split into lines, then handoff to parser depending on input file.
        let rows = content.components(separatedBy: .newlines)
        
        if estimationCycle == EstimationCycle.quarterly {
            taxPeriodInput = parseQuarterlyInput (taxPeriod: taxPeriod, inputData: rows, context: context)
        } else {
            taxPeriodInput =  parseAnnualInput (taxPeriod: taxPeriod, inputData: rows, context: context)
        }
        
        try? context.save()
        
        guard let taxPeriodInput else { return TaxPeriodInput()}
        return taxPeriodInput
    }
    
    static func parseQuarterlyInput (taxPeriod: TaxPeriod, inputData: [String], context: ModelContext) -> TaxPeriodInput {
        var taxPeriodInput = TaxPeriodInput.getRecord(for: taxPeriod.rawValue, estimationCycle: .quarterly, in: context)
        
        for row in inputData {
            let parts = row.components(separatedBy: "\",\"")
            guard parts.count >= 2 else { continue }
            
                // Clean up surrounding quotes from label and value
            let labelTrimmingSet = CharacterSet(charactersIn: " ,-").union(.whitespaces)
            let rawLabel = parts[0]
                .replacingOccurrences(of: "\"", with: "")
                .trimmingCharacters(in: labelTrimmingSet)
            
            let rawValue = parts[1].replacingOccurrences(of: "\"", with: "")
            
                // Match label against valid label enum. Sanitize numeric value; remove '$', ',', and whitespace
            if let category = EstimateValues.labelLookup[rawLabel.lowercased()] {
                guard let cleanValue = rawValue.toDouble() else {
                    print("Can't convert rawValue to double")
                    return taxPeriodInput
                }
                taxPeriodInput[keyPath: category.keyPath] = cleanValue
            }
        }
        return taxPeriodInput
    }

        // Annual estimate input is a month x month budget/actuals export: two header rows lay out 12 month blocks starting at column index 2, each spanning 3 columns (Actual, Budgeted, Difference). We only use Budgeted: the annual TaxPeriodInput total for each category is the sum of that category's Budgeted value across all 12 months. Actual and Difference aren't used here. The per-month Budgeted values are also persisted to MonthlyBudgetEntry for later IRMAA projection use.
    
    static func parseAnnualInput (taxPeriod: TaxPeriod, inputData: [String], context: ModelContext) -> TaxPeriodInput {
        var taxPeriodInput = TaxPeriodInput.getRecord(for: taxPeriod.rawValue, estimationCycle: .annual, in: context)
        var monthlyBudget = MonthlyBudgetEntry.resetRecords(in: context)

        for row in inputData {
            let fields = parseCSVRow(row)

            let rawLabel = fields
                .drop(while: { $0.isEmpty || $0.allSatisfy({ $0 == "-" || $0 == " " }) })
                .first?
                .drop(while: { $0 == "-" || $0 == " " })
                .trimmingCharacters(in: .whitespaces) ?? ""

            guard let category = EstimateValues.labelLookup[rawLabel.lowercased()] else { continue }

            for month in 1...12 {
                let budgetedIndex = 3 + (month - 1) * 3
                guard budgetedIndex < fields.count else { continue }

                let rawValue = fields[budgetedIndex].replacingOccurrences(of: ",", with: "")
                guard let cleanValue = rawValue.toDouble() else {
                    print("Can't convert rawValue to double for \(rawLabel), month \(month)")
                    continue
                }
                
                monthlyBudget[month - 1][keyPath: category.monthlyBudgetKeyPath] += cleanValue
                taxPeriodInput[keyPath: category.keyPath] += cleanValue
            }
        }
        return taxPeriodInput
    }
    
    static func parseCSVRow(_ row: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        
        let cleaned = row.replacingOccurrences(of: "\u{FEFF}", with: "")
        
        for char in cleaned {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current.trimmingCharacters(in: .whitespaces)) // last field
        
        return fields
    }
}
