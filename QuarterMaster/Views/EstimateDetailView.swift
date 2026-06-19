//
//  EstimateDetailView.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/19/26.
//

import SwiftUI
import SwiftData

struct EstimateDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let quarter: Quarter
    let taxEntity: TaxEntity
    
    @Query(sort: \QuarterlyInput.quarterID) private var allQuarterlyData: [QuarterlyInput]
    
    var body: some View {
        ContentUnavailableView(
            "Coming Soon",
            systemImage: "hammer.fill",
            description: Text("\(taxEntity == .federal ? "Federal" : "State") detail for \(quarter.rawValue) is under development.")
        )
    }
}
