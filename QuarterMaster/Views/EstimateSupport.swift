//
//  EstimateSupport.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/24/26.
//

import SwiftUI

protocol TaxRowProvider : Identifiable {
    var label: String { get }
    subscript(key: String) -> Double { get }
}

struct EstimateColumns {
    @TableColumnBuilder<T, Never>
        static func makeColumns<T: TaxRowProvider>(taxEntity: TaxEntity, estimateCycle: EstimationCycle, title: String? = nil) -> some TableColumnContent<T, Never> {

        TableColumn(title ?? "\(taxEntity.rawValue) Tax Estimate") { row in
            Text(row.label).bold()
        }
        .width(min: 200)
        
        if estimateCycle == .quarterly {
            TableColumn("\(TaxPeriod.first.rawValue)") { row in
                Text(row[TaxPeriod.first.rawValue], format: .currency(code: "USD").precision(.fractionLength(0)))
            }
            .alignment(.center)
            
            TableColumn("\(TaxPeriod.second.rawValue)") { row in
                Text(row[TaxPeriod.second.rawValue], format: .currency(code: "USD").precision(.fractionLength(0)))
            }
            .alignment(.center)
            
            TableColumn("\(TaxPeriod.third.rawValue)") { row in
                Text(row[TaxPeriod.third.rawValue], format: .currency(code: "USD").precision(.fractionLength(0)))
            }
            .alignment(.center)
            
            TableColumn("\(TaxPeriod.fourth.rawValue)") { row in
                Text(row[TaxPeriod.fourth.rawValue], format: .currency(code: "USD").precision(.fractionLength(0)))
            }
            .alignment(.center)
        } else {
            TableColumn("\(TaxPeriod.annual.rawValue)") { row in
                Text(row[TaxPeriod.annual.rawValue], format: .currency(code: "USD").precision(.fractionLength(0)))
            }.alignment(.center)
            
                // Invisible spacers needed so table pushes single column to left boundary
            TableColumn("") { _ in Text("") }
            TableColumn("") { _ in Text("") }
            TableColumn("") { _ in Text("") }
        }
    }
}
