//
//  IIRMAProjector.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 8/14/26.
//

import Foundation

    // Projects MAGI for IRMAA headroom purposes by blending year-to-date actuals with budgeted amounts for whatever's left in year - rather than the run-rate annualization FederalTaxCalculator uses for the general tax estimate (assumes rest of year continues at same pace as what's happened so far, and so doesn't see one-time events like a planned Roth conversion that hasn't been imported yet) needs to see. taxPeriodInput's fields are cumulative YTD as of the current period, so "actual" is just a direct field read - no summing across prior periods needed. "Remaining" is whatever budget months fall after the current period's months-elapsed cutoff.
struct IRMAAProjector {

    struct Result {
        let projectedMAGI: Double
        let headroom: Double
        var isOverThreshold: Bool { headroom < 0 }
    }

        // fedEstimate should be the TaxEstimate already computed for taxPeriodInput (for its taxableCapitalGains figure - actual capital gains use the same curated fields as the main tax calc, so no need to recompute that part).
    static func projectMAGI(taxPeriodInput: TaxPeriodInput, fedEstimate: TaxEstimate, monthlyBudget: [MonthlyBudgetEntry]) -> Result {

        let monthsElapsed = Int((12.0 / TaxPeriod.factor(for: taxPeriodInput.taxPeriodId)).rounded())
        let remainingMonths = monthlyBudget.filter { $0.month > monthsElapsed }

        func remainingBudget(_ keyPath: KeyPath<MonthlyBudgetEntry, Double>) -> Double {
            remainingMonths.reduce(0.0) { $0 + $1[keyPath: keyPath] }
        }

            // taxPeriodInput's fields are already curated (DataCurator has run by the time we get here), so ordinaryDividends already includes qualifiedEligibleDividends and capitalGainDistribution already includes reinvestLTCG for the actual portion. MonthlyBudgetEntry holds raw, uncurated values, so the same adjustments need to be applied by hand when summing the remaining months.
        let projectedInterest = taxPeriodInput.interest + remainingBudget(\.interest)

        let projectedOrdinaryDividends = taxPeriodInput.ordinaryDividends
            + remainingBudget(\.ordinaryDividends)
            + remainingBudget(\.qualifiedEligibleDividends)

        let projectedIRADistributions = taxPeriodInput.iraDistributions + remainingBudget(\.iraDistributions)

        let projectedPensionAnnuities = taxPeriodInput.pensionAnnuities + remainingBudget(\.pensionAnnuities)

        let projectedOtherIncome = taxPeriodInput.otherIncome
            + remainingBudget(\.oilRoyalties)
            + remainingBudget(\.supplementalIncome)

        let projectedTaxableCapitalGains = fedEstimate.taxableCapitalGains
            + remainingBudget(\.shortTermCG)
            + remainingBudget(\.longTermGain)
            + remainingBudget(\.capitalGainDistribution)
            + remainingBudget(\.reinvestLTCG)

        let projectedSocialSecurity = taxPeriodInput.socialSecurity + remainingBudget(\.socialSecurity)

            // Same "keep it simple" other-income test FederalTaxCalculator uses, just built from the actual+remaining-budget projection instead of a run-rate annualization.
        let otherIncomeTest = projectedPensionAnnuities + projectedOrdinaryDividends + projectedOtherIncome + projectedInterest

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

        let headroom = SeasonalConstants.irmaaThresholdMFJ - projectedMAGI

        return Result(projectedMAGI: projectedMAGI, headroom: headroom)
    }
}
