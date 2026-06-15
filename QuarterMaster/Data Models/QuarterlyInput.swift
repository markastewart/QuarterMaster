//
//  QuarterlyInput.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/15/26.
//

import Foundation
import SwiftData

@Model
final class QuarterlyInput {
    var timestamp: Date
    var quarterID: String
    
    @Relationship(deleteRule: .cascade) var fields: [InputDataFields] = []
    
    init(timestamp: Date = .now) {
        self.timestamp = timestamp
    }
}
