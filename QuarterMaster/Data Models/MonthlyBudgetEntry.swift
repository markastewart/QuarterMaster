//
//  MonthlyBudgetEntry.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 8/14/26.
//

import Foundation
import SwiftData

    // One record per calendar month (1 = January ... 12 = December), holding the Budgeted column values from the Annual Estimate's month x month CSV. Mirrors same raw fields TaxPeriodInput accepts from EstimateValues.labelLookup, since each program year gets its own SwiftData store (see QuarterMasterApp's per-year folder), there's no need to key by program year - a store only ever holds one year's worth of budget. Used by IRMAAProjector to fill in "months not yet covered by actuals" when projecting MAGI for IRMAA headroom purposes.

@Model
final class MonthlyBudgetEntry {
    var month: Int = 1

    var pensionAnnuities = 0.0
    var socialSecurity = 0.0
    var interest = 0.0
    var oilRoyalties = 0.0
    var supplementalIncome = 0.0
    var ordinaryDividends = 0.0
    var qualifiedDividends = 0.0
    var qualifiedEligibleDividends = 0.0
    var iraDistributions = 0.0
    var shortTermCG = 0.0
    var shortTermGain = 0.0
    var longTermGain = 0.0
    var reinvestSTCG = 0.0
    var reinvestLTCG = 0.0
    var capitalGainDistribution = 0.0
    var fedCYWitholding = 0.0
    var fedCYEstimates = 0.0
    var stateCYWitholding = 0.0
    var stateCYEstimates = 0.0
    var deposit529 = 0.0
    var dividendsNonTaxable = 0.0
    var cashDonations = 0.0

    init(month: Int) {
        self.month = month
    }
}

extension MonthlyBudgetEntry {
        /// Wipes any existing monthly budget and creates 12 fresh records (Jan=1 ... Dec=12), ready for population. Annual imports replace the whole year's budget atomically, same spirit as TaxPeriodInput.getRecord replacing a single period.
    static func resetRecords(in context: ModelContext) -> [MonthlyBudgetEntry] {
        let descriptor = FetchDescriptor<MonthlyBudgetEntry>()
        if let existing = try? context.fetch(descriptor) {
            existing.forEach { context.delete($0) }
            try? context.save()
        }

        let months = (1...12).map { MonthlyBudgetEntry(month: $0) }
        months.forEach { context.insert($0) }
        return months
    }

        /// Convenience fetch for consumers (e.g. IRMAAProjector) that just need the current budget.
    static func fetchAll(in context: ModelContext) -> [MonthlyBudgetEntry] {
        let descriptor = FetchDescriptor<MonthlyBudgetEntry>(sortBy: [SortDescriptor(\.month)])
        return (try? context.fetch(descriptor)) ?? []
    }
}
