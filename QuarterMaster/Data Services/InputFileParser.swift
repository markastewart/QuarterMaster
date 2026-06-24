//
//  InputFileParser.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/15/26.
//

import Foundation
import SwiftData

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
            
                // Match label against valid label enum
            if let category = EstimateValues.allCases.first(where: {
                $0.rawValue.caseInsensitiveCompare(rawLabel) == .orderedSame
            }) {
                    // Sanitize numeric value; remove '$', ',', and whitespace
                let cleanedValue = rawValue.replacingOccurrences(of: "[$, ]", with: "", options: .regularExpression)
                
                    // Convert to Double and Save via KeyPath
                if let doubleValue = Double(cleanedValue) {
                    taxPeriodInput[keyPath: category.keyPath] = doubleValue
                } else {
                    print("Could not convert value '\(rawValue)' to Double for \(rawLabel)")
                }
            }
        }
        return taxPeriodInput
    }
    
    static func parseAnnualInput (taxPeriod: TaxPeriod, inputData: [String], context: ModelContext) -> TaxPeriodInput {
        var taxPeriodInput = TaxPeriodInput.getRecord(for: taxPeriod.rawValue, estimationCycle: .annual, in: context)
        
        for row in inputData {
            let fields = parseCSVRow(row)

            let rawLabel = fields
                .drop(while: { $0.isEmpty || $0.allSatisfy({ $0 == "-" || $0 == " " }) })
                .first?
                .drop(while: { $0 == "-" || $0 == " " })
                .trimmingCharacters(in: .whitespaces) ?? ""

            let budget = fields.count > 3 ? fields[3] : ""
            let rawValue = budget.replacingOccurrences(of: ",", with: "")
            
                // Match label against valid label enum
            if let category = EstimateValues.allCases.first(where: {
                $0.rawValue.caseInsensitiveCompare(rawLabel) == .orderedSame
            }) {
                    // Sanitize numeric value; remove '$', ',', and whitespace
                let cleanedValue = rawValue.replacingOccurrences(of: "[$, ]", with: "", options: .regularExpression)
                
                    // Convert to Double and Save via KeyPath
                if let doubleValue = Double(cleanedValue) {
                    taxPeriodInput[keyPath: category.keyPath] = doubleValue
                } else {
                    print("Could not convert value '\(rawValue)' to Double for \(rawLabel)")
                }
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
