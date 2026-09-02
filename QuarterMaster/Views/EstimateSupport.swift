//
//  EstimateSupport.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/24/26.
//

import SwiftUI

    // RowFormatStyle - controls how a row's values are rendered in the shared Table columns. Currency rows (the default) show dollar amounts; percent rows (e.g. Marginal Tax Rate) show a percentage.
enum RowFormatStyle {
    case currency
    case percent
}

protocol TaxRowProvider : Identifiable {
    var label: String { get }
    var formatStyle: RowFormatStyle { get }
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
                cellText(for: row, key: TaxPeriod.first.rawValue)
            }
            .alignment(.center)
            
            TableColumn("\(TaxPeriod.second.rawValue)") { row in
                cellText(for: row, key: TaxPeriod.second.rawValue)
            }
            .alignment(.center)
            
            TableColumn("\(TaxPeriod.third.rawValue)") { row in
                cellText(for: row, key: TaxPeriod.third.rawValue)
            }
            .alignment(.center)
            
            TableColumn("\(TaxPeriod.fourth.rawValue)") { row in
                cellText(for: row, key: TaxPeriod.fourth.rawValue)
            }
            .alignment(.center)
        } else {
            TableColumn("\(TaxPeriod.annual.rawValue)") { row in
                cellText(for: row, key: TaxPeriod.annual.rawValue)
            }.alignment(.center)
            
                // Invisible spacers needed so table pushes single column to left boundary
            TableColumn("") { _ in Text("") }
            TableColumn("") { _ in Text("") }
            TableColumn("") { _ in Text("") }
        }
    }
    
        // cellText - renders a single cell using the row's own format style (currency vs percent), so a row like Marginal Tax Rate can live in the same Table as the dollar-figure rows around it.
    @ViewBuilder
    private static func cellText<T: TaxRowProvider>(for row: T, key: String) -> some View {
        switch row.formatStyle {
            case .currency:
                Text(row[key], format: .currency(code: "USD").precision(.fractionLength(0)))
            case .percent:
                Text(row[key], format: .percent.precision(.fractionLength(0)))
        }
    }
}
