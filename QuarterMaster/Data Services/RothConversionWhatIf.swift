//
//  RothConversionWhatIf.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 8/18/26.
//

import Foundation

    // Computes a side-by-side comparison of "no conversion" vs. "convert $X" for a given tax period, without touching any persisted TaxPeriodInput/TaxEstimate records - if the user decides to actually do a conversion, that shows up for real once it's reflected in an imported input file, same as any other income item; this is a scratchpad calculation only.

    // Both sides of the comparison ("current" and "withConversion") are built on IRMAAProjector's budget-aware  AGI - YTD actuals blended with whatever's budgeted for the remaining months - rather than FederalTaxCalculator's straight-line run-rate factor, which has no way to see one-time/uneven income or tax events planned for later in the year. Building both sides the same way keeps the Delta column reflecting only the conversion's effect, not a mismatch between two different ways of projecting the rest of the year. One consequence: for a quarterly period with a material run-rate-vs-budget gap, this what-if's "Current" Fed AGI/Total Tax will differ from the "official" quarterly Federal Tax Estimate shown elsewhere in the app, which still uses the plain run-rate factor.

    // The conversion amount itself is never re-annualized: it's added directly to iraDistributions on a detached input copy before the budget-aware projection runs, since IRMAAProjector already treats iraDistributions as a direct actual-to-date figure with no further annualization - so a one-time conversion lands as a one-time amount, not inflated by however many months remain in the period.

    // StateTaxCalculator takes federal AGI as an input rather than re-deriving it from raw fields, so feeding it the budget-aware scenarioFedEstimate automatically makes the state side budget-aware too - no changes needed there.

struct RothConversionWhatIf {
    
    struct Scenario {
        let federalTaxDue: Double
        let stateTaxDue: Double
        let projectedMAGI: Double
        let irmaaHeadroom: Double
        let tier1Headroom: Double
        let tier2Headroom: Double
        let specialDeduction: Double
        let fedAGI: Double
        let fedTotalTax: Double
        let fedMarginalRate: Double
        let stateAGI: Double
        let stateTotalTax: Double
    }
    
    struct Comparison {
        let conversionAmount: Double
        let current: Scenario
        let withConversion: Scenario
        
        var federalTaxDueDelta: Double { withConversion.federalTaxDue - current.federalTaxDue }
        var stateTaxDueDelta: Double { withConversion.stateTaxDue - current.stateTaxDue }
        var projectedMAGIDelta: Double { withConversion.projectedMAGI - current.projectedMAGI }
        var irmaaHeadroomDelta: Double { withConversion.irmaaHeadroom - current.irmaaHeadroom }
        var tier1HeadroomDelta: Double { withConversion.tier1Headroom - current.tier1Headroom }
        var tier2HeadroomDelta: Double { withConversion.tier2Headroom - current.tier2Headroom }
        var specialDeductionDelta: Double { withConversion.specialDeduction - current.specialDeduction }
        var fedAGIDelta: Double { withConversion.fedAGI - current.fedAGI }
        var fedTotalTaxDelta: Double { withConversion.fedTotalTax - current.fedTotalTax }
        var fedMarginalRateDelta: Double { withConversion.fedMarginalRate - current.fedMarginalRate }
        var stateAGIDelta: Double { withConversion.stateAGI - current.stateAGI }
        var stateTotalTaxDelta: Double { withConversion.stateTotalTax - current.stateTotalTax }
    }
    
        // fedEstimate should be the real, already-computed federal estimate for taxPeriodInput - used only as a source for taxableSocialSecurity/taxableCapitalGains (categories IRMAAProjector treats as already-derived inputs rather than raw fields it re-projects itself); never mutated. stateEstimate is kept as a parameter so callers don't need to change, but its fields are no longer read directly - the budget-aware state figures are recomputed from scratch below instead. currentIRMAAResult is reused as-is for the "current" side rather than recomputed, since it's already the budget-aware projection for the real, unmodified taxPeriodInput/fedEstimate.
    static func compare(
        taxPeriodInput: TaxPeriodInput,
        fedEstimate: TaxEstimate,
        stateEstimate: TaxEstimate,
        currentIRMAAResult: IRMAAProjector.Result,
        monthlyBudget: [MonthlyBudgetEntry],
        conversionAmount: Double
    ) -> Comparison {
        
        let current = buildScenario(
            taxPeriodInput: taxPeriodInput,
            fedEstimate: fedEstimate,
            monthlyBudget: monthlyBudget,
            conversionAmount: 0,
            precomputedIRMAAResult: currentIRMAAResult
        )
        
        guard conversionAmount > 0 else {
            return Comparison(conversionAmount: conversionAmount, current: current, withConversion: current)
        }
        
        let withConversion = buildScenario(
            taxPeriodInput: taxPeriodInput,
            fedEstimate: fedEstimate,
            monthlyBudget: monthlyBudget,
            conversionAmount: conversionAmount,
            precomputedIRMAAResult: nil
        )
        
        return Comparison(conversionAmount: conversionAmount, current: current, withConversion: withConversion)
    }
    
        // Builds one side of the comparison (current when conversionAmount is 0, with-conversion otherwise) on a detached, never-persisted copy of the tax period.
    private static func buildScenario(
        taxPeriodInput: TaxPeriodInput,
        fedEstimate: TaxEstimate,
        monthlyBudget: [MonthlyBudgetEntry],
        conversionAmount: Double,
        precomputedIRMAAResult: IRMAAProjector.Result?
    ) -> Scenario {
        
            // Detached copy - never inserted into any ModelContext, so nothing built against it can persist or attach itself to the real taxEstimates relationship.
        let scenarioInput = taxPeriodInput.detachedCopy()
        scenarioInput.iraDistributions += conversionAmount
        
        let scenarioFedEstimate = TaxEstimate(taxEntity: TaxEntity.federal.rawValue, taxPeriodInput: scenarioInput)
        scenarioFedEstimate.taxableSocialSecurity = fedEstimate.taxableSocialSecurity
        scenarioFedEstimate.taxableCapitalGains = fedEstimate.taxableCapitalGains
        
            // precomputedIRMAAResult is passed in for the no-conversion side, since it's value-identical to recomputing against scenarioInput/scenarioFedEstimate here (conversionAmount 0 leaves iraDistributions unchanged, and taxableSocialSecurity/taxableCapitalGains were just copied from the same fedEstimate) - so it's reused rather than redone.
        let irmaaResult = precomputedIRMAAResult ?? IRMAAProjector.projectMAGI(
            taxPeriodInput: scenarioInput,
            fedEstimate: scenarioFedEstimate,
            monthlyBudget: monthlyBudget
        )
        
            // Budget-aware AGI (YTD actuals + remaining budgeted months) in place of FederalTaxCalculator's run-rate factor - see the file-level comment for why.
        scenarioFedEstimate.adjustedGrossIncome = irmaaResult.projectedAGI
        
        FederalTaxCalculator.additionalDeductionsCalc(fedEstimate: scenarioFedEstimate)
        scenarioFedEstimate.totalDeductions = Double(SeasonalConstants.standardDeduction) + scenarioFedEstimate.additionalDeductions + min(scenarioInput.cashDonations, 2000.0)
        scenarioFedEstimate.taxableIncome = scenarioFedEstimate.adjustedGrossIncome - scenarioFedEstimate.totalDeductions
        FederalTaxCalculator.netInvestmentIncomeTaxCalc(taxPeriodInput: scenarioInput, fedEstimate: scenarioFedEstimate)
        scenarioFedEstimate.totalTax = FederalTaxCalculator.annualTaxCalc(taxPeriodInput: scenarioInput, fedEstimate: scenarioFedEstimate) - SeasonalConstants.foreignTaxPaid + scenarioFedEstimate.netInvestmentIncomeTax
        scenarioFedEstimate.taxesPaid = scenarioInput.fedCYWitholding + scenarioInput.fedCYEstimates
        
        let factor = TaxPeriod.factor(for: scenarioInput.taxPeriodId)
        scenarioFedEstimate.taxEstimate = (scenarioFedEstimate.totalTax * (1 / factor)) - scenarioFedEstimate.taxesPaid
        
            // State: takes federal AGI as an input rather than re-deriving it, so it's automatically budget-aware once fed scenarioFedEstimate above - called unmodified.
        StateTaxCalculator.calculateStateEstimate(taxPeriodInput: scenarioInput, fedEstimate: scenarioFedEstimate)
            // Not expected to be nil in practice (calculateStateEstimate always attaches one) - falls back to 0 rather than propagating an Optional through Scenario if it ever is.
        let scenarioStateEstimate = scenarioInput.taxEstimates.first(where: { $0.taxEntity == TaxEntity.state.rawValue })
        
        return Scenario(
            federalTaxDue: scenarioFedEstimate.taxEstimate,
            stateTaxDue: scenarioStateEstimate?.taxEstimate ?? 0,
            projectedMAGI: irmaaResult.projectedMAGI,
            irmaaHeadroom: irmaaResult.headroom,
            tier1Headroom: irmaaResult.tier1Headroom,
            tier2Headroom: irmaaResult.tier2Headroom,
            specialDeduction: scenarioFedEstimate.additionalDeductions,
            fedAGI: scenarioFedEstimate.adjustedGrossIncome,
            fedTotalTax: scenarioFedEstimate.totalTax,
            fedMarginalRate: scenarioFedEstimate.marginalTaxRate,
            stateAGI: scenarioStateEstimate?.adjustedGrossIncome ?? 0,
            stateTotalTax: scenarioStateEstimate?.totalTax ?? 0
        )
    }
}

