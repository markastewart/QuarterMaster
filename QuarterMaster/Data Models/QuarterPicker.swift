//
//  QuarterPicker.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/16/26.
//

import Foundation

enum Quarter: String, CaseIterable, Identifiable {
    case first = "1Q"
    case second = "2Q"
    case third = "3Q"
    case fourth = "4Q"
    
        // Required for Identifiable so you can use it in a Picker
    var id: String { self.rawValue }
    
    var annualizationFactor: Double {
            switch self {
            case .first:  return 4.0   // 12 months / 3
            case .second: return 2.4   // 12 months / 5
            case .third:  return 1.5   // 12 months / 8
            case .fourth: return 1.0   // 12 months / 12
            }
        }
}

extension Quarter {
    static func factor(for rawValue: String) -> Double {
            // Returns the factor if found, or 1.0 (or 0.0) as a safe default
        return Quarter(rawValue: rawValue)?.annualizationFactor ?? 1.0
    }
}
