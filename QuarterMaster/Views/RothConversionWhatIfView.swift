//
//  RothConversionWhatIfView.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 9/2/26.
//

import SwiftUI
import SwiftData

    // Presentation only - moved out of IRMAAAnalysis into its own screen, reached from a dedicated Dashboard button rather than as a section underneath the IRMAA table. Still reuses IRMAAAnalysisVM (rather than a dedicated VM) since whatIfComparison already lives there and needs the same per-period IRMAAProjector.Result set (for the "current" side of the comparison) and monthlyBudget that VM already computes - created fresh each time this view appears, same lifecycle IRMAAAnalysis uses.
struct RothConversionWhatIfView: View {
    @Environment(\.modelContext) private var modelContext
    let taxPeriodInput: [TaxPeriodInput]
    let estimateCycle: EstimationCycle
    
    @State private var vm: IRMAAAnalysisVM?
    @State private var conversionAmountText: String = ""
    @FocusState private var amountFieldFocused: Bool
    @State private var conversionAmount: Double?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let vm, !vm.results.isEmpty, let latestInput = taxPeriodInput.last {
                whatIfSection(latestInput: latestInput, vm: vm)
            } else {
                Text("No data available yet. Import a quarterly estimate and an annual budget first.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Roth Conversion What-If")
        .onAppear {
            if vm == nil {
                vm = IRMAAAnalysisVM(modelContext: modelContext, taxPeriodInput: taxPeriodInput)
            }
        }
    }
    
        // Compare "no conversion" vs. "convert $X" for the latest period. Purely a scratchpad - nothing here reads or writes real TaxPeriodInput/TaxEstimate data; if a conversion is actually made, it'll show up for real once reflected in a future import.
    @ViewBuilder
    private func whatIfSection(latestInput: TaxPeriodInput, vm: IRMAAAnalysisVM) -> some View {
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
            
            if let amount = conversionAmount, amount > 0,
               let comparison = vm.whatIfComparison(for: latestInput, conversionAmount: amount) {
                
                whatIfHeaderRow
                
                whatIfRow(label: "Fed AGI", current: comparison.current.fedAGI, withConversion: comparison.withConversion.fedAGI, delta: comparison.fedAGIDelta)
                whatIfRow(label: "Fed Total Tax", current: comparison.current.fedTotalTax, withConversion: comparison.withConversion.fedTotalTax, delta: comparison.fedTotalTaxDelta)
                whatIfRow(label: "Fed Tax Marginal Rate", current: comparison.current.fedMarginalRate, withConversion: comparison.withConversion.fedMarginalRate, delta: nil, formatStyle: .percent)
                whatIfRow(label: "State AGI", current: comparison.current.stateAGI, withConversion: comparison.withConversion.stateAGI, delta: comparison.stateAGIDelta)
                whatIfRow(label: "State Total Tax", current: comparison.current.stateTotalTax, withConversion: comparison.withConversion.stateTotalTax, delta: comparison.stateTotalTaxDelta)
                whatIfRow(label: "Special Deduction", current: comparison.current.specialDeduction, withConversion: comparison.withConversion.specialDeduction, delta: comparison.specialDeductionDelta)
                whatIfRow(label: "Projected MAGI", current: comparison.current.projectedMAGI, withConversion: comparison.withConversion.projectedMAGI, delta: comparison.projectedMAGIDelta)
                whatIfRow(label: "Tier 0 Headroom", current: comparison.current.irmaaHeadroom, withConversion: comparison.withConversion.irmaaHeadroom, delta: comparison.irmaaHeadroomDelta, flagIfNegative: true)
                whatIfRow(label: "Tier 1 Headroom", current: comparison.current.tier1Headroom, withConversion: comparison.withConversion.tier1Headroom, delta: comparison.tier1HeadroomDelta, flagIfNegative: true)
                whatIfRow(label: "Tier 2 Headroom", current: comparison.current.tier2Headroom, withConversion: comparison.withConversion.tier2Headroom, delta: comparison.tier2HeadroomDelta, flagIfNegative: true)
                
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
    
    private func commitConversionAmount() {
        let cleaned = conversionAmountText.filter { $0.isNumber || $0 == "." }
        conversionAmount = Double(cleaned)
    }
    
    private var whatIfHeaderRow: some View {
        HStack {
            Text("").frame(width: 160, alignment: .leading)
            Text("Current").bold().frame(width: 130, alignment: .trailing)
            Text("With Conversion").bold().frame(width: 130, alignment: .trailing)
            Text("Delta").bold().frame(width: 130, alignment: .trailing)
            Spacer()
        }
    }
    
        // delta is dollar-denominated (withConversion - current) and shown in its own column; pass nil to leave that column blank, which we do for the Marginal Rate row since a rate difference isn't a dollar delta.
    private func whatIfRow(label: String, current: Double, withConversion: Double, delta: Double?, formatStyle: RowFormatStyle = .currency, flagIfNegative: Bool = false) -> some View {
        HStack {
            Text(label)
                .frame(width: 160, alignment: .leading)
            whatIfValueText(current, formatStyle: formatStyle)
                .frame(width: 130, alignment: .trailing)
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
                Text(value, format: .percent.precision(.fractionLength(1)))
        }
    }
}

