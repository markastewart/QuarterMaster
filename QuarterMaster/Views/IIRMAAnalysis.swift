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
    let magiValues = results.mapValues { $0.projectedMAGI }
    let headroomValues = results.mapValues { $0.headroom }

    return [
        IRMAARow(label: "Projected MAGI", values: magiValues),
        IRMAARow(label: "IRMAA Headroom", values: headroomValues)
    ]
}
