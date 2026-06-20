//
//  EstimateDrillDown.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/19/26.
//

import SwiftUI
import SwiftData

struct EstimateDrillDown: View {
    let taxEntity: TaxEntity
    let viewModel: DashboardVM
    
    
    var body: some View {
        ContentUnavailableView(
            "Coming Soon",
            systemImage: "hammer.fill",
            description: Text("Entity: \(taxEntity.rawValue) tax estimate details")
        )
    }
}
