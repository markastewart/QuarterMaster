//
//  IIRMAAnalysisVM.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 8/14/26.
//

import Foundation
import SwiftData

    // Created fresh each time IRMAAAnalysis appears (matches DashboardVM's lifecycle), and computes its results once at init - no live recompute hook, since a new tax estimate can only be generated back on the Dashboard, which would spin up a fresh instance here anyway next time the view is opened.

@Observable
class IRMAAAnalysisVM {
        // One projection per period, keyed by taxPeriodId, so the view can present headroom for every period with data - same "column per period" strategy EstimateSummary already uses.
    var results: [String: IRMAAProjector.Result] = [:]

        // Kept around (rather than only used locally in init) so whatIfComparison can reuse it without re-fetching from the store on every keystroke as the user adjusts a what-if conversion amount.
    private let monthlyBudget: [MonthlyBudgetEntry]

    init(modelContext: ModelContext, taxPeriodInput: [TaxPeriodInput]) {
        monthlyBudget = MonthlyBudgetEntry.fetchAll(in: modelContext)

        for input in taxPeriodInput {
            guard let fedEstimate = input.taxEstimates.first(where: { $0.taxEntity == TaxEntity.federal.rawValue }) else { continue }
            results[input.taxPeriodId] = IRMAAProjector.projectMAGI(taxPeriodInput: input, fedEstimate: fedEstimate, monthlyBudget: monthlyBudget)
        }
    }

        // Pure calculation, safe to call on every render - taxPeriodInput here should be the real, persisted record for the period being analyzed; RothConversionWhatIf takes care of never mutating or persisting anything against it.
    func whatIfComparison(for taxPeriodInput: TaxPeriodInput, conversionAmount: Double) -> RothConversionWhatIf.Comparison? {
        guard let fedEstimate = taxPeriodInput.taxEstimates.first(where: { $0.taxEntity == TaxEntity.federal.rawValue }),
              let stateEstimate = taxPeriodInput.taxEstimates.first(where: { $0.taxEntity == TaxEntity.state.rawValue }),
              let currentResult = results[taxPeriodInput.taxPeriodId] else {
            return nil
        }

        return RothConversionWhatIf.compare(
            taxPeriodInput: taxPeriodInput,
            fedEstimate: fedEstimate,
            stateEstimate: stateEstimate,
            currentIRMAAResult: currentResult,
            monthlyBudget: monthlyBudget,
            conversionAmount: conversionAmount
        )
    }
}
