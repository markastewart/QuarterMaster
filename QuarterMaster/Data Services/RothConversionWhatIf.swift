//
//  RothConversionWhatIf.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 8/18/26.
//

import Foundation

    // Computes a side-by-side comparison of "no conversion" vs. "convert $X" for a given tax period, without touching any persisted TaxPeriodInput/TaxEstimate records - if the user decides to actually do a conversion, that shows up for real once it's reflected in an imported input file, same as any other income item; this is a scratchpad calculation only.

    // The federal "with conversion" figure is NOT computed by mutating iraDistributions and re-running FederalTaxCalculator.calculateFederalEstimate top-to-bottom: that function derives AGI by summing raw per-category fields and then multiplying the whole aggregate by TaxPeriod.factor, which assumes whatever's in each category recurs at the same pace for the rest of the year. A Roth conversion is a one-time amount, not a recurring run-rate item, so adding it to iraDistributions before that multiplication would inflate its effect by the annualization factor (e.g. ~4x too much for a Q1 estimate). Instead, the conversion amount is added directly to the already-correct, already-annualized real AGI, and the downstream deduction/tax-table/NIIT math is reproduced using FederalTaxCalculator's own shared helper functions (additionalDeductionsCalc, annualTaxCalc, netInvestmentIncomeTaxCalc) - so the bracket/deduction/NIIT logic itself is never duplicated, only the AGI-derivation step is bypassed.

    // IRMAAProjector, by contrast, already treats taxPeriodInput.iraDistributions as a direct actual-to-date figure with no further annualization, so for that calculation the conversion amount is added straight to a detached copy's field.

    // StateTaxCalculator takes federal AGI as an input rather than re-deriving it from raw fields, so it has none of the run-rate issue and is called unmodified.

struct RothConversionWhatIf {
    
    struct Scenario {
        let federalTaxDue: Double
        let stateTaxDue: Double
        let irmaaHeadroom: Double
        let tier1Headroom: Double
        let tier2Headroom: Double
        let specialDeduction: Double
    }
    
    struct Comparison {
        let conversionAmount: Double
        let current: Scenario
        let withConversion: Scenario
        
        var federalTaxDueDelta: Double { withConversion.federalTaxDue - current.federalTaxDue }
        var stateTaxDueDelta: Double { withConversion.stateTaxDue - current.stateTaxDue }
        var irmaaHeadroomDelta: Double { withConversion.irmaaHeadroom - current.irmaaHeadroom }
        var tier1HeadroomDelta: Double { withConversion.tier1Headroom - current.tier1Headroom }
        var tier2HeadroomDelta: Double { withConversion.tier2Headroom - current.tier2Headroom }
        var specialDeductionDelta: Double { withConversion.specialDeduction - current.specialDeduction }
    }
    
        // fedEstimate/stateEstimate/currentIRMAAResult should be the real, already-computed values for taxPeriodInput - reused directly for the "current" side rather than recomputed.
    static func compare(
        taxPeriodInput: TaxPeriodInput,
        fedEstimate: TaxEstimate,
        stateEstimate: TaxEstimate,
        currentIRMAAResult: IRMAAProjector.Result,
        monthlyBudget: [MonthlyBudgetEntry],
        conversionAmount: Double
    ) -> Comparison {
        
        let current = Scenario(
            federalTaxDue: fedEstimate.taxEstimate,
            stateTaxDue: stateEstimate.taxEstimate,
            irmaaHeadroom: currentIRMAAResult.headroom,
            tier1Headroom: currentIRMAAResult.tier1Headroom,
            tier2Headroom: currentIRMAAResult.tier2Headroom,
            specialDeduction: fedEstimate.additionalDeductions
        )
        
        guard conversionAmount > 0 else {
            return Comparison(conversionAmount: conversionAmount, current: current, withConversion: current)
        }
        
            // Detached copy - never inserted into any ModelContext, so nothing built against it can persist or attach itself to the real taxEstimates relationship.
        let whatIfInput = taxPeriodInput.detachedCopy()
        
            // --- Federal ---
        let whatIfFedEstimate = TaxEstimate(taxEntity: TaxEntity.federal.rawValue, taxPeriodInput: whatIfInput)
        whatIfFedEstimate.taxableSocialSecurity = fedEstimate.taxableSocialSecurity
        whatIfFedEstimate.taxableCapitalGains = fedEstimate.taxableCapitalGains
        whatIfFedEstimate.adjustedGrossIncome = fedEstimate.adjustedGrossIncome + conversionAmount
        
        FederalTaxCalculator.additionalDeductionsCalc(fedEstimate: whatIfFedEstimate)
        whatIfFedEstimate.totalDeductions = Double(SeasonalConstants.standardDeduction) + whatIfFedEstimate.additionalDeductions + min(whatIfInput.cashDonations, 2000.0)
        whatIfFedEstimate.taxableIncome = whatIfFedEstimate.adjustedGrossIncome - whatIfFedEstimate.totalDeductions
        FederalTaxCalculator.netInvestmentIncomeTaxCalc(taxPeriodInput: whatIfInput, fedEstimate: whatIfFedEstimate)
        whatIfFedEstimate.totalTax = FederalTaxCalculator.annualTaxCalc(taxPeriodInput: whatIfInput, fedEstimate: whatIfFedEstimate) - SeasonalConstants.foreignTaxPaid + whatIfFedEstimate.netInvestmentIncomeTax
        whatIfFedEstimate.taxesPaid = whatIfInput.fedCYWitholding + whatIfInput.fedCYEstimates
        
        let factor = TaxPeriod.factor(for: whatIfInput.taxPeriodId)
        whatIfFedEstimate.taxEstimate = (whatIfFedEstimate.totalTax * (1 / factor)) - whatIfFedEstimate.taxesPaid
        
            // State: no run-rate issue here, safe to call unmodified.
        StateTaxCalculator.calculateStateEstimate(taxPeriodInput: whatIfInput, fedEstimate: whatIfFedEstimate)
        guard let whatIfStateEstimate = whatIfInput.taxEstimates.first(where: { $0.taxEntity == TaxEntity.state.rawValue }) else {
            return Comparison(conversionAmount: conversionAmount, current: current, withConversion: current)
        }
        
            // IRMAA: iraDistributions is treated as a direct actual-to-date figure already, so the full conversion amount is added straight to the detached copy's field.
        whatIfInput.iraDistributions += conversionAmount
        let whatIfIRMAAResult = IRMAAProjector.projectMAGI(taxPeriodInput: whatIfInput, fedEstimate: whatIfFedEstimate, monthlyBudget: monthlyBudget)
        
        let withConversion = Scenario(
            federalTaxDue: whatIfFedEstimate.taxEstimate,
            stateTaxDue: whatIfStateEstimate.taxEstimate,
            irmaaHeadroom: whatIfIRMAAResult.headroom,
            tier1Headroom: whatIfIRMAAResult.tier1Headroom,
            tier2Headroom: whatIfIRMAAResult.tier2Headroom,
            specialDeduction: whatIfFedEstimate.additionalDeductions
        )
        
        return Comparison(conversionAmount: conversionAmount, current: current, withConversion: withConversion)
    }
}
