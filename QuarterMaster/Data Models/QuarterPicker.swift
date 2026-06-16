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
}
