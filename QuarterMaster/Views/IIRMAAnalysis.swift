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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let vm, !vm.results.isEmpty {
                let rows = irmaaRows(results: vm.results)

                Table(rows) {
                    EstimateColumns.makeColumns(taxEntity: .federal, estimateCycle: estimateCycle, title: "IRMAA Analysis")
                }
                .id(estimateCycle)
                .frame(height: CGFloat(rows.count) * 28 + 30)

                Text("2026 MFJ threshold: \(SeasonalConstants.irmaaThresholdMFJ, format: .currency(code: "USD").precision(.fractionLength(0)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Each period blends that period's year-to-date actuals with the remaining months' budgeted income - not a substitute for the true two-year IRMAA lookback.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                topDriversSection
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
                Text("Primary Sources of \(latestPeriodId) Projected MAGI Growth")
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
}

    // Support types/functions for the view - same shape as TaxSummaryRow/summaryRows in
    // EstimateSummary.swift, so this table renders through the exact same EstimateColumns builder.
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
        IRMAARow(label: "IRMAA Headroom", values: headroomValues)
    ]
}
