//
//  InputFileParser.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/15/26.
//

import Foundation
import SwiftData

struct CSVImportService {
        
    static func processCSV(content: String, context: ModelContext, taxPeriod: TaxPeriod) -> TaxPeriodInput {
        var taxPeriodInput = TaxPeriodInput.getRecord(for: taxPeriod.rawValue, taxCycle: .quarterly, in: context)
        
            // Parse input file: split into lines, then by quote-comma-quote (ignoring internal value commas).
        let rows = content.components(separatedBy: .newlines)
        
        for row in rows {
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
        try? context.save()
        
        return taxPeriodInput
    }
}
