//
//  IIRMAAnalysisVM.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 8/14/26.
//

import Foundation
import SwiftData

    // Created fresh each time IRMAAAnalysisView appears (matches DashboardVM's lifecycle), and computes its result once at init - no live recompute hook, since a new tax estimate can only be generated back on the Dashboard, which would spin up a fresh instance here anyway next time the view is opened.

@Observable
class IRMAAAnalysisVM {
    var result: IRMAAProjector.Result?

        // taxPeriodInput should be the same filtered array the Dashboard already has in hand (scoped to the currently selected estimation cycle); the current period is taken as the last one, matching the array's ascending sort by taxPeriodId.
    init(modelContext: ModelContext, taxPeriodInput: [TaxPeriodInput]) {
        guard let currentInput = taxPeriodInput.last,
              let fedEstimate = currentInput.taxEstimates.first(where: { $0.taxEntity == TaxEntity.federal.rawValue }) else {
            return
        }

        let monthlyBudget = MonthlyBudgetEntry.fetchAll(in: modelContext)
        result = IRMAAProjector.projectMAGI(taxPeriodInput: currentInput, fedEstimate: fedEstimate, monthlyBudget: monthlyBudget)
    }
}
