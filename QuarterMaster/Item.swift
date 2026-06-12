//
//  Item.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/12/26.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
