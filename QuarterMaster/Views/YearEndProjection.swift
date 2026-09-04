//
//  YearEndProjection.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 9/3/26.
//

import SwiftUI
import SwiftData

    // Year-End Projection flow: the budget-aware projection (YTD actuals + remaining budgeted months) up top, IRMAA tier headroom immediately below it (same table - headroom rows sit below the AGI/MAGI rows), and an optional Roth conversion entry at the bottom that turns the projection into a side-by-side Current vs. With-Conversion comparison with a Delta column. Uses IRMAAAnalysisVM since whatIfComparison and the per-period IRMAAProjector.Result set monthlyBudget it needs already live there - created fresh each time this view appears, same lifecycle the two screens it replaces used.

struct YearEndProjectionView: View {
    @Environment(\.modelContext) private var modelContext
    let taxPeriodInput: [TaxPeriodInput]
    let estimateCycle: EstimationCycle
    
    @State private var vm: IRMAAAnalysisVM?
    @State private var conversionAmountText: String = ""
    @FocusState private var amountFieldFocused: Bool
    @State private var conversionAmount: Double?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let vm, !vm.results.isEmpty {
                    projectionSection(vm: vm)
                    
                    if let latestInput = taxPeriodInput.last {
                        Divider()
                        rothConversionSection(latestInput: latestInput, vm: vm)
                    }
                } else {
                    Text("No data available yet. Import a quarterly estimate and an annual budget first.")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("YE Projection & Roth Conversion")
        .onAppear {
            if vm == nil {
                vm = IRMAAAnalysisVM(modelContext: modelContext, taxPeriodInput: taxPeriodInput)
            }
        }
    }
    
        // MARK: - Best Year-End Projection + IRMAA Headroom
        // One combined table: Run-Rate YTD AGI and Projected MAGI up top, Tier 0/1/2 Headroom rows immediately below - same budget-aware projection that used to live on the standalone IRMAA screen.
    @ViewBuilder
    private func projectionSection(vm: IRMAAAnalysisVM) -> some View {
        let rows = irmaaRows(results: vm.results)
        
        VStack(alignment: .leading, spacing: 8) {
            Text("IIRMA Analysis").font(.headline)
            
            Table(rows) {
                EstimateColumns.makeColumns(taxEntity: .federal, estimateCycle: estimateCycle, title: "")
            }
            .id(estimateCycle)
            .frame(height: CGFloat(rows.count) * 28 + 30)
            
            Text("2026 Tier 0 ceiling: \(SeasonalConstants.irmaaTier0CeilingMFJ, format: .currency(code: "USD").precision(.fractionLength(0))) · Tier 1 ceiling: \(SeasonalConstants.irmaaTier1CeilingMFJ, format: .currency(code: "USD").precision(.fractionLength(0))) · Tier 2 ceiling: \(SeasonalConstants.irmaaTier2CeilingMFJ, format: .currency(code: "USD").precision(.fractionLength(0)))")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text("Each period blends that period's year-to-date actuals with the remaining months' budgeted income - not a substitute for the true two-year IRMAA lookback.")
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            estimateCycle == .quarterly ? topDriversSection(vm: vm) : nil
        }
    }
    
        // Shows what's driving most recent period's Projected MAGI above its Run-Rate AGI - only when gap is material (>5%, per IRMAAProjector.Result.isMaterialGap). The summary table shows every period; this section scoped to the latest one.
    @ViewBuilder
    private func topDriversSection(vm: IRMAAAnalysisVM) -> some View {
        if let latestPeriodId = taxPeriodInput.last?.taxPeriodId,
           let latestResult = vm.results[latestPeriodId],
           latestResult.isMaterialGap {
            
            Divider()
                .padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Primary Sources of \(latestPeriodId) Projected MAGI Growth (above the Run-Rate YTD AGI value)")
                    .font(.headline)
                
                ForEach(latestResult.topFiveDeltas) { item in
                    HStack {
                        Text(item.label)
                            .frame(width: 200, alignment: .leading)
                        Text(item.delta, format: .currency(code: "USD").precision(.fractionLength(0)))
                            .frame(width: 110, alignment: .trailing)
                        Spacer()
                    }
                }
            }
        }
    }
    
        // MARK: - Roth Conversion Entry
        // Compare "no conversion" vs. "convert $X" for the latest period. Purely a scratchpad - nothing here reads or writes real TaxPeriodInput/TaxEstimate data; if a conversion is actually made, it'll show up for real once reflected in a future import.

        // Opens showing just Current column - pulled from a conversionAmount: 0 comparison, whose withConversion/delta simply mirror current in that case (RothConversionWhatIf.compare's early-return for a non-positive amount) - so there's nothing to compute twice. Once positive amount entered, same comparison call (with real amount) drives With Conversion and Delta columns, which whatIfHeaderRow/whatIfRow reveal via showComparison.
    @ViewBuilder
    private func rothConversionSection(latestInput: TaxPeriodInput, vm: IRMAAAnalysisVM) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Roth Conversion What-If (\(latestInput.taxPeriodId))")
                .font(.headline)
            
            HStack {
                Text("Conversion Amount:")
                TextField("Amount", text: $conversionAmountText)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 140)
                    .focused($amountFieldFocused)
                    .onSubmit {
                        commitConversionAmount()
                    }
                    .onChange(of: amountFieldFocused) { _, isFocused in
                        if !isFocused {
                            commitConversionAmount()
                        }
                    }
            }
            
            if let comparison = vm.whatIfComparison(for: latestInput, conversionAmount: conversionAmount ?? 0) {
                let showComparison = (conversionAmount ?? 0) > 0
                
                whatIfHeaderRow(showComparison: showComparison)
                
                whatIfRow(label: "YE Fed AGI", current: comparison.current.fedAGI, withConversion: comparison.withConversion.fedAGI, delta: comparison.fedAGIDelta, showComparison: showComparison)
                whatIfRow(label: "Net Taxable Income", current: comparison.current.netTaxableIncome, withConversion: comparison.withConversion.netTaxableIncome, delta: comparison.netTaxableIncomeDelta, showComparison: showComparison)
                whatIfRow(label: "Fed Total Tax", current: comparison.current.fedTotalTax, withConversion: comparison.withConversion.fedTotalTax, delta: comparison.fedTotalTaxDelta, showComparison: showComparison)
                whatIfRow(label: "Fed Tax Marginal Rate", current: comparison.current.fedMarginalRate, withConversion: comparison.withConversion.fedMarginalRate, delta: nil, formatStyle: .percent, showComparison: showComparison)
                whatIfRow(label: "Net Investment Tax", current: comparison.current.netInvestmentIncomeTax, withConversion: comparison.withConversion.netInvestmentIncomeTax, delta: comparison.netInvestmentIncomeTaxDelta, showComparison: showComparison)
                whatIfRow(label: "State AGI", current: comparison.current.stateAGI, withConversion: comparison.withConversion.stateAGI, delta: comparison.stateAGIDelta, showComparison: showComparison)
                whatIfRow(label: "State Total Tax", current: comparison.current.stateTotalTax, withConversion: comparison.withConversion.stateTotalTax, delta: comparison.stateTotalTaxDelta, showComparison: showComparison)
                whatIfRow(label: "Special Deduction", current: comparison.current.specialDeduction, withConversion: comparison.withConversion.specialDeduction, delta: comparison.specialDeductionDelta, showComparison: showComparison)
                whatIfRow(label: "Projected MAGI", current: comparison.current.projectedMAGI, withConversion: comparison.withConversion.projectedMAGI, delta: comparison.projectedMAGIDelta, showComparison: showComparison)
                whatIfRow(label: "Tier 0 Headroom", current: comparison.current.irmaaHeadroom, withConversion: comparison.withConversion.irmaaHeadroom, delta: comparison.irmaaHeadroomDelta, flagIfNegative: true, showComparison: showComparison)
                whatIfRow(label: "Tier 1 Headroom", current: comparison.current.tier1Headroom, withConversion: comparison.withConversion.tier1Headroom, delta: comparison.tier1HeadroomDelta, flagIfNegative: true, showComparison: showComparison)
                whatIfRow(label: "Tier 2 Headroom", current: comparison.current.tier2Headroom, withConversion: comparison.withConversion.tier2Headroom, delta: comparison.tier2HeadroomDelta, flagIfNegative: true, showComparison: showComparison)
                
                if showComparison {
                    if comparison.withConversion.irmaaHeadroom < 0 {
                        Text("This amount would push you over the Tier 0→1 IRMAA threshold for this period.")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    if comparison.withConversion.tier1Headroom < 0 {
                        Text("This amount would push you over the Tier 1→2 IRMAA threshold for this period.")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    if comparison.withConversion.tier2Headroom < 0 {
                        Text("This amount would push you over the Tier 2→3 IRMAA threshold for this period.")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
        }
    }
    
    private func commitConversionAmount() {
        let cleaned = conversionAmountText.filter { $0.isNumber || $0 == "." }
        conversionAmount = Double(cleaned)
    }
    
        // Current is always shown; With Conversion and Delta only render once showComparison is true (i.e. a positive conversion amount has been entered).
    private func whatIfHeaderRow(showComparison: Bool) -> some View {
        HStack {
            Text("").frame(width: 160, alignment: .leading)
            Text("Current").bold().frame(width: 130, alignment: .trailing)
            if showComparison {
                Text("With Conversion").bold().frame(width: 130, alignment: .trailing)
                Text("Delta").bold().frame(width: 130, alignment: .trailing)
            }
            Spacer()
        }
    }
    
        // delta is dollar-denominated (withConversion - current) and shown in its own column; pass nil to leave that column blank, which we do for the Marginal Rate row since a rate difference isn't a dollar delta. With Conversion/Delta only render when showComparison is true - flagIfNegative colors both Current and (when shown) With Conversion red, since Current alone can already be past a headroom threshold before any conversion is considered.
    private func whatIfRow(label: String, current: Double, withConversion: Double, delta: Double?, formatStyle: RowFormatStyle = .currency, flagIfNegative: Bool = false, showComparison: Bool) -> some View {
        HStack {
            Text(label)
                .frame(width: 160, alignment: .leading)
            whatIfValueText(current, formatStyle: formatStyle)
                .frame(width: 130, alignment: .trailing)
                .foregroundColor(flagIfNegative && current < 0 ? .red : .primary)
            if showComparison {
                whatIfValueText(withConversion, formatStyle: formatStyle)
                    .frame(width: 130, alignment: .trailing)
                    .foregroundColor(flagIfNegative && withConversion < 0 ? .red : .primary)
                Group {
                    if let delta {
                        whatIfValueText(delta, formatStyle: .currency)
                    } else {
                        Text("—")
                    }
                }
                .frame(width: 130, alignment: .trailing)
                .foregroundStyle(.secondary)
            }
            Spacer()
        }
    }
    
        // whatIfValueText - same currency/percent split as EstimateColumns.cellText, just for this view's hand-built HStack rows rather than a Table (this view doesn't route through TaxRowProvider).
    @ViewBuilder
    private func whatIfValueText(_ value: Double, formatStyle: RowFormatStyle) -> some View {
        switch formatStyle {
            case .currency:
                Text(value, format: .currency(code: "USD").precision(.fractionLength(0)))
            case .percent:
                Text(value, format: .percent.precision(.fractionLength(0)))
        }
    }
}

    // Support types/functions for the projection table - same shape as TaxSummaryRow/summaryRows in EstimateSummary.swift, so this table renders through the exact same EstimateColumns builder. Moved here from the retired IIRMAAnalysis.swift.
struct IRMAARow: Identifiable {
    let label: String
    let values: [String: Double]
    let formatStyle: RowFormatStyle = .currency
    var id: String { label }
    
    subscript(key: String) -> Double {
        values[key] ?? 0.0
    }
}
extension IRMAARow: TaxRowProvider {}

func irmaaRows(results: [String: IRMAAProjector.Result]) -> [IRMAARow] {
    let runRateAGIValues = results.mapValues { $0.runRateAGI }
    let magiValues = results.mapValues { $0.projectedMAGI }
    let headroomValues = results.mapValues { $0.headroom }
    let tier1HeadroomValues = results.mapValues { $0.tier1Headroom }
    let tier2HeadroomValues = results.mapValues { $0.tier2Headroom }
    
    return [
        IRMAARow(label: "Run-Rate YTD AGI", values: runRateAGIValues),
        IRMAARow(label: "Projected MAGI", values: magiValues),
        IRMAARow(label: "Tier 0 Headroom", values: headroomValues),
        IRMAARow(label: "Tier 1 Headroom", values: tier1HeadroomValues),
        IRMAARow(label: "Tier 2 Headroom", values: tier2HeadroomValues)
    ]
}
