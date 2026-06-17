//
//  TaxEstimate.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/17/26.
//

import Foundation
import SwiftData

@Model
final class TaxEstimate {
    var quarterID: String = ""
    var taxEntity: String = ""
    var adjustedGrossIncome : Double = 0.0
    var totalTax : Double = 0.0
    var taxesPaid: Double = 0.0
    var taxEstimate: Double = 0.0
    
    var quarterlyInput: QuarterlyInput?
        
    init(taxEntity: String, quarterlyInput: QuarterlyInput) {
        self.taxEntity = taxEntity
        self.quarterlyInput = quarterlyInput
        self.quarterID = quarterlyInput.quarterID
    }
}
