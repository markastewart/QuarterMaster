//
//  IIRMAAnalysis.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 8/14/26.
//

import SwiftUI
import SwiftData

    // Presentation only - reads whatever IRMAAAnalysisVM computed at init and renders it.
struct IRMAAAnalysisView: View {
    @Environment(\.modelContext) private var modelContext
    let taxPeriodInput: [TaxPeriodInput]

    @State private var vm: IRMAAAnalysisVM?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if let result = vm?.result {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Projected MAGI").font(.headline)
                    Text(result.projectedMAGI, format: .currency(code: "USD").precision(.fractionLength(0)))
                        .font(.title2)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(result.isOverThreshold ? "Over IRMAA Threshold By" : "IRMAA Headroom")
                        .font(.headline)
                    Text(abs(result.headroom), format: .currency(code: "USD").precision(.fractionLength(0)))
                        .font(.title2)
                        .foregroundColor(result.isOverThreshold ? .red : .primary)
                }

                Text("2026 MFJ threshold: \(SeasonalConstants.irmaaThresholdMFJ, format: .currency(code: "USD").precision(.fractionLength(0)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Projection blends year-to-date actuals with the remaining months' budgeted income - it is not a substitute for the true two-year IRMAA lookback.")
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
