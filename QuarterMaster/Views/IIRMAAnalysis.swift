//
//  IIRMAAnalysis.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 8/14/26.
//

import SwiftUI
import SwiftData

    // Presentation only - reads whatever IRMAAAnalysisVM computed at init and renders it.
struct IRMAAAnalysis: View {
    @Environment(\.modelContext) private var modelContext
    let taxPeriodInput: [TaxPeriodInput]
    let estimateCycle: EstimationCycle

    @State private var vm: IRMAAAnalysisVM?
    @State private var conversionAmount: Double?
    @State private var conversionAmountText: String = ""
    @FocusState private var amountFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let vm, !vm.results.isEmpty {
                let rows = irmaaRows(results: vm.results)

                Table(rows) {
                    EstimateColumns.makeColumns(taxEntity: .federal, estimateCycle: estimateCycle, title: "IRMAA Analysis")
                }
                .id(estimateCycle)
                .frame(height: CGFloat(rows.count) * 28 + 30)

                Text("2026 Tier 0 ceiling: \(SeasonalConstants.irmaaTier0CeilingMFJ, format: .currency(code: "USD").precision(.fractionLength(0))) · Tier 1 ceiling: \(SeasonalConstants.irmaaTier1CeilingMFJ, format: .currency(code: "USD").precision(.fractionLength(0))) · Tier 2 ceiling: \(SeasonalConstants.irmaaTier2CeilingMFJ, format: .currency(code: "USD").precision(.fractionLength(0)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Each period blends that period's year-to-date actuals with the remaining months' budgeted income - not a substitute for the true two-year IRMAA lookback.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                topDriversSection
                rothConversionWhatIfSection
            } else {
                Text("No data available yet. Import a quarterly estimate and an annual budget first.")
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .navigationTitle("IRMAA Headroom Analysis")
        .onAppear {
            if vm == nil {
                vm = IRMAAAnalysisVM(modelContext: modelContext, taxPeriodInput: taxPeriodInput)
            }
        }
    }

        // Shows what's driving most recent period's Projected MAGI above its Run-Rate AGI - only when that gap is material (>5%, per IRMAAProjector.Result.isMaterialGap). The table above already shows every period; this section is scoped to the latest one, since showing a top-5 breakdown per period at once would be a lot to take in at once.
    @ViewBuilder
    private var topDriversSection: some View {
        if let latestPeriodId = taxPeriodInput.last?.taxPeriodId,
           let latestResult = vm?.results[latestPeriodId],
           latestResult.isMaterialGap {

            Divider()
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 6) {
                Text("Primary Sources of \(latestPeriodId) Projected MAGI Growth (above Run-Rate)")
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

        // Compare "no conversion" vs. "convert $X" for the latest period. Purely a scratchpad - nothing here reads or writes real TaxPeriodInput/TaxEstimate data; if a conversion is actually made, it'll show up for real once reflected in a future import.
    @ViewBuilder
    private var rothConversionWhatIfSection: some View {
        if let latestInput = taxPeriodInput.last, let vm {
            Divider()
                .padding(.vertical, 4)

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
                    
                    whatIfRow(label: "Special Deduction", current: comparison.current.specialDeduction, withConversion: comparison.withConversion.specialDeduction)
                    whatIfRow(label: "Federal Tax Due", current: comparison.current.federalTaxDue, withConversion: comparison.withConversion.federalTaxDue)
                    whatIfRow(label: "State Tax Due", current: comparison.current.stateTaxDue, withConversion: comparison.withConversion.stateTaxDue)
                    whatIfRow(label: "Tier 0 IRMAA Headroom", current: comparison.current.irmaaHeadroom, withConversion: comparison.withConversion.irmaaHeadroom, flagIfNegative: true)

                    if comparison.withConversion.irmaaHeadroom < 0 {
                        Text("This amount would push you over the Tier 0 IRMAA threshold for this period.")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    whatIfRow(label: "Tier 1 IRMAA Headroom", current: comparison.current.tier1Headroom, withConversion: comparison.withConversion.tier1Headroom, flagIfNegative: true)
                    
                    if comparison.withConversion.tier1Headroom < 0 {
                        Text("This amount would push you over the Tier 1→2 IRMAA threshold for this period.")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    whatIfRow(label: "Tier 2 IRMAA Headroom", current: comparison.current.tier2Headroom, withConversion: comparison.withConversion.tier2Headroom, flagIfNegative: true)
                    
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

    private var whatIfHeaderRow: some View {
        HStack {
            Text("").frame(width: 160, alignment: .leading)
            Text("Current").bold().frame(width: 130, alignment: .trailing)
            Text("With Conversion").bold().frame(width: 130, alignment: .trailing)
            Spacer()
        }
    }

    private func whatIfRow(label: String, current: Double, withConversion: Double, flagIfNegative: Bool = false) -> some View {
        HStack {
            Text(label)
                .frame(width: 160, alignment: .leading)
            Text(current, format: .currency(code: "USD").precision(.fractionLength(0)))
                .frame(width: 130, alignment: .trailing)
            Text(withConversion, format: .currency(code: "USD").precision(.fractionLength(0)))
                .frame(width: 130, alignment: .trailing)
                .foregroundColor(flagIfNegative && withConversion < 0 ? .red : .primary)
            Spacer()
        }
    }
}

    // Support types/functions for the view - same shape as TaxSummaryRow/summaryRows in EstimateSummary.swift, so this table renders through the exact same EstimateColumns builder.
struct IRMAARow: Identifiable {
    let label: String
    let values: [String: Double]
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

    return [
        IRMAARow(label: "Run-Rate YTD AGI", values: runRateAGIValues),
        IRMAARow(label: "Projected MAGI", values: magiValues),
        IRMAARow(label: "Tier 0 IRMAA Headroom", values: headroomValues),
        IRMAARow(label: "Tier 1 IRMAA Headroom", values: results.mapValues { $0.tier1Headroom }),
        IRMAARow(label: "Tier 2 IRMAA Headroom", values: results.mapValues { $0.tier2Headroom })
    ]
}
