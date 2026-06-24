//
//  Dashboard.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/12/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct QuarterMasterDashboard: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DashboardVM?
    @State private var isImporting = false
    @State private var selectedQuarter: TaxPeriod = .first
    @State private var estimationCycle: EstimationCycle = .quarterly
    @Query(sort: \TaxPeriodInput.taxPeriodId) private var taxPeriodInput: [TaxPeriodInput]
    
    var body: some View {
        NavigationStack() {
            if let vm = viewModel {
                HStack(alignment: .top, spacing: 0) {
                    controlSidebarPane(vm: vm)
                        .frame(width: 280)
                        .padding(.trailing, 8)
                    
                    Divider()
                    
                    VStack(spacing: 20) {
                        EstimateSummary(title: "Federal Tax Estimates", isFederal: true, taxPeriodInput: taxPeriodInput)
                        Divider()
                        EstimateSummary(title: "State Tax Estimates", isFederal: false, taxPeriodInput: taxPeriodInput)
                    }
                    .padding()
                }
                .navigationTitle("")
                .onChange(of: taxPeriodInput) { _, newValue in
                    vm.taxPeriodInput = newValue
                }
                .onAppear {
                    vm.taxPeriodInput = taxPeriodInput
                }
            }
        }
        .onAppear { if viewModel == nil { viewModel = DashboardVM(modelContext: modelContext) } }
    }
    
        // MARK: - Sidebar
    private func controlSidebarPane(vm: DashboardVM) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 12) {
                Image("AppLogo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 44, height: 44)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                
                VStack(alignment: .leading) {
                    Text("QuarterMaster " + "\(SeasonalConstants.programYear)" ).font(.title2).bold()
                    Text("Income Tax Estimator").font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(.top, 8)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text ("Generate Tax Estimates")
                    .font(.headline)
                    .padding(.bottom,15)
                
                Text("Select Quarter to estimate and identify input file").font(.caption.bold()).foregroundStyle(.secondary)
                
                Picker("Quarter", selection: $selectedQuarter) {
                    ForEach(TaxPeriod.allCases) { q in Text(q.rawValue).tag(q) }
                }
                .pickerStyle(.segmented)
                
                Button { isImporting = true; estimationCycle = .quarterly } label: {
                    Label("Select Quarterly File for \(selectedQuarter.rawValue)", systemImage: "doc.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom,25)
            }
            VStack(alignment: .leading, spacing: 12) {
                Text("Click to identify input file for annual estimate").font(.caption.bold()).foregroundStyle(.secondary)
                
                Button {
                    isImporting = true
                    estimationCycle = .annual
                    selectedQuarter = .fourth   // An annual record maps to all 4 quarters.
                } label: {
                    Label("Select Annual Estimate File", systemImage: "doc.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            Spacer()
        }
        .padding()
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.commaSeparatedText], allowsMultipleSelection: false) { result in vm.generateTaxEstimate(for: selectedQuarter, result: result, estimationCycle: estimationCycle, context: modelContext)
        }
    }
}
