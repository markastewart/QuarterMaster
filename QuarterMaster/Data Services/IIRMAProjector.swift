//
//  IIRMAProjector.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 8/14/26.
//

import Foundation

    // Projects MAGI for IRMAA headroom purposes by blending year-to-date actuals with budgeted amounts for whatever's left in year - rather than the run-rate annualization FederalTaxCalculator uses for the general tax estimate (which assumes rest of year continues at same pace as what's happened so far, and so doesn't see one-time events like a planned Roth conversion that hasn't been imported yet). taxPeriodInput's fields are cumulative YTD as of current period, so "actual" is just a direct field read - no summing across prior periods needed. "Remaining" is whatever budget months fall after the current period's months-elapsed cutoff. Alongside final MAGI/headroom, this also breaks the projection down category by category against what  existing run-rate AGI calculation would have produced for that same category - so it's possible to see which specific income items are driving budget-aware projection higher than the simple run-rate extrapolation would suggest.
struct IRMAAProjector {

        // A single income category's run-rate figure vs. its actual+remaining-budget projection.
    struct CategoryDelta: Identifiable {
        let label: String
        let runRateValue: Double
        let projectedValue: Double
        var delta: Double { projectedValue - runRateValue }
        var id: String { label }
    }

    struct Result {
        let runRateAGI: Double
        let projectedMAGI: Double
        let headroom: Double
        let tier1Headroom: Double
        let tier2Headroom: Double
        let categoryDeltas: [CategoryDelta]

        var isOverThreshold: Bool { headroom < 0 }
        var isOverTier1Threshold: Bool { tier1Headroom < 0 }
        var isOverTier2Threshold: Bool { tier2Headroom < 0 }

            // Only worth surfacing "what's driving this" once the budget-aware projection has pulled meaningfully ahead of the simple run-rate AGI - below that, the divergence isn't material enough to matter.
        var isMaterialGap: Bool {
            guard runRateAGI > 0 else { return false }
            return projectedMAGI > runRateAGI * 1.025
        }

            // Only positive deltas count as "driving MAGI up" - a category projecting lower than its run-rate figure is offsetting the total, not contributing to it.
        var topFiveDeltas: [CategoryDelta] {
            categoryDeltas
                .filter { $0.delta > 0 }
                .sorted { $0.delta > $1.delta }
                .prefix(5)
                .map { $0 }
        }
    }

        // fedEstimate should be the TaxEstimate already computed for taxPeriodInput (for its adjustedGrossIncome/taxableCapitalGains/taxableSocialSecurity figures - the run-rate side of every comparison reuses those rather than recomputing them).
    static func projectMAGI(taxPeriodInput: TaxPeriodInput, fedEstimate: TaxEstimate, monthlyBudget: [MonthlyBudgetEntry]) -> Result {

        let factor = TaxPeriod.factor(for: taxPeriodInput.taxPeriodId)
        let monthsElapsed = Int((12.0 / factor).rounded())
        let remainingMonths = monthlyBudget.filter { $0.month > monthsElapsed }

        func remainingBudget(_ keyPath: KeyPath<MonthlyBudgetEntry, Double>) -> Double {
            remainingMonths.reduce(0.0) { $0 + $1[keyPath: keyPath] }
        }

            // taxPeriodInput's fields are already curated (DataCurator has run by time we get here), so ordinaryDividends already includes qualifiedEligibleDividends and capitalGainDistribution already includes reinvestLTCG for actual portion. MonthlyBudgetEntry holds raw, uncurated values, so same adjustments needed by hand when summing remaining months.

        let runRateInterest = taxPeriodInput.interest * factor
        let projectedInterest = taxPeriodInput.interest + remainingBudget(\.interest)

        let runRateOrdinaryDividends = taxPeriodInput.ordinaryDividends * factor
        let projectedOrdinaryDividends = taxPeriodInput.ordinaryDividends
            + remainingBudget(\.ordinaryDividends)
            + remainingBudget(\.qualifiedEligibleDividends)

        let runRateIRADistributions = taxPeriodInput.iraDistributions * factor
        let projectedIRADistributions = taxPeriodInput.iraDistributions + remainingBudget(\.iraDistributions)

        let runRatePensionAnnuities = taxPeriodInput.pensionAnnuities * factor
        let projectedPensionAnnuities = taxPeriodInput.pensionAnnuities + remainingBudget(\.pensionAnnuities)

            // taxableCapitalGains isn't separately annualized by FederalTaxCalculator - it's folded into the aggregate sum before the single *factor multiplication - so its run-rate equivalent has to be derived the same way here.
        let runRateTaxableCapitalGains = fedEstimate.taxableCapitalGains * factor
        let projectedTaxableCapitalGains = fedEstimate.taxableCapitalGains
            + remainingBudget(\.shortTermCG)
            + remainingBudget(\.longTermGain)
            + remainingBudget(\.capitalGainDistribution)
            + remainingBudget(\.reinvestLTCG)

        let runRateOtherIncome = taxPeriodInput.otherIncome * factor
        let projectedOtherIncome = taxPeriodInput.otherIncome
            + remainingBudget(\.oilRoyalties)
            + remainingBudget(\.supplementalIncome)

        let projectedSocialSecurity = taxPeriodInput.socialSecurity + remainingBudget(\.socialSecurity)

            // Same "keep it simple" other-income test FederalTaxCalculator uses, just built from the actual+remaining-budget projection instead of a run-rate annualization.
        let otherIncomeTest = projectedPensionAnnuities + projectedOrdinaryDividends + projectedOtherIncome + projectedInterest

            // Run-rate taxable SS is already fully computed by FederalTaxCalculator (it applies its own annualization internally), so it's used as-is rather than re-derived.
        let runRateTaxableSocialSecurity = fedEstimate.taxableSocialSecurity
        let projectedTaxableSocialSecurity = FederalTaxCalculator.computeTaxableSocialSecurity(
            annualizedAGI: otherIncomeTest,
            annualizedSS: projectedSocialSecurity
        )

        let projectedAGI = projectedInterest
            + projectedOrdinaryDividends
            + projectedIRADistributions
            + projectedPensionAnnuities
            + projectedTaxableCapitalGains
            + projectedOtherIncome
            + projectedTaxableSocialSecurity

        let projectedNonTaxableDividends = taxPeriodInput.dividendsNonTaxable + remainingBudget(\.dividendsNonTaxable)

        let projectedMAGI = projectedAGI + projectedNonTaxableDividends
        let headroom = SeasonalConstants.irmaaTier0CeilingMFJ - projectedMAGI
        let tier1Headroom = SeasonalConstants.irmaaTier1CeilingMFJ - projectedMAGI
        let tier2Headroom = SeasonalConstants.irmaaTier2CeilingMFJ - projectedMAGI

        let categoryDeltas = [
            CategoryDelta(label: "Interest", runRateValue: runRateInterest, projectedValue: projectedInterest),
            CategoryDelta(label: "Ordinary Dividends", runRateValue: runRateOrdinaryDividends, projectedValue: projectedOrdinaryDividends),
            CategoryDelta(label: "IRA Distributions", runRateValue: runRateIRADistributions, projectedValue: projectedIRADistributions),
            CategoryDelta(label: "Pension & Annuities", runRateValue: runRatePensionAnnuities, projectedValue: projectedPensionAnnuities),
            CategoryDelta(label: "Capital Gains", runRateValue: runRateTaxableCapitalGains, projectedValue: projectedTaxableCapitalGains),
            CategoryDelta(label: "Other Income", runRateValue: runRateOtherIncome, projectedValue: projectedOtherIncome),
            CategoryDelta(label: "Taxable Social Security", runRateValue: runRateTaxableSocialSecurity, projectedValue: projectedTaxableSocialSecurity),
            CategoryDelta(label: "Nontaxable Dividends", runRateValue: 0.0, projectedValue: projectedNonTaxableDividends)        ]

        return Result(
            runRateAGI: fedEstimate.adjustedGrossIncome,
            projectedMAGI: projectedMAGI,
            headroom: headroom,
            tier1Headroom: tier1Headroom,
            tier2Headroom: tier2Headroom,
            categoryDeltas: categoryDeltas
        )
    }
}
