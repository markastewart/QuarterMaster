//
//  InputDataFields.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/15/26.
//

import Foundation
import SwiftData

@Model
final class InputDataFields {
    var label: String
    var value: Double
    
    init(label: String, value: Double) {
        self.label = label
        self.value = value
    }
}
