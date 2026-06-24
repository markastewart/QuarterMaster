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
    @State private var selectedCycle: EstimationCycle = .quarterly
    @Query(sort: \TaxPeriodInput.taxPeriodId) private var taxPeriodInput: [TaxPeriodInput]
    
        // Filter depending on selected estimate cycle
    var filteredInput: [TaxPeriodInput] {
        taxPeriodInput.filter { $0.estimationCycle.rawValue == selectedCycle.rawValue }
    }
    
    var body: some View {
        NavigationStack() {
            if let vm = viewModel {
                HStack(alignment: .top, spacing: 0) {
                    controlSidebarPane(vm: vm)
                        .frame(width: 320)
                        .padding(.trailing, 8)
                    
                    Divider()
                    
                    VStack(spacing: 20) {
                        EstimateSummary(title: "Federal Tax Estimates", isFederal: true, taxPeriodInput: filteredInput)
                        Divider()
                        EstimateSummary(title: "State Tax Estimates", isFederal: false, taxPeriodInput: filteredInput)
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
            
            Form {
                EstimationCyclePicker(selectedCycle: $selectedCycle)
            }
            
            Text ("Generate \(selectedCycle.rawValue) Tax Estimate")
                .font(.headline)
                .padding([.top, .bottom], 5)
            
            if selectedCycle == .quarterly {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Quarter to estimate and identify input file").font(.caption.bold()).foregroundStyle(.secondary)
                    
                    Picker("Quarter", selection: $selectedQuarter) {
                        ForEach(TaxPeriod.allCases) { q in Text(q.rawValue).tag(q) }
                    }
                    .pickerStyle(.segmented)
                    
                    Button { isImporting = true } label: {
                        Label("Create quarterly estimate for \(selectedQuarter.rawValue)", systemImage: "doc.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.bottom,25)
                }
            }
            else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Identify input file for annual estimate").font(.caption.bold()).foregroundStyle(.secondary)
                    
                    Button {
                        isImporting = true
                        selectedQuarter = .fourth   // An annual record maps to all 4 quarters.
                    } label: {
                        Label("Click to create annual estimate", systemImage: "doc.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            Spacer()
        }
        .padding()
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.commaSeparatedText], allowsMultipleSelection: false) { result in vm.generateTaxEstimate(for: selectedQuarter, result: result, estimationCycle: selectedCycle, context: modelContext)
        }
    }
}

struct EstimationCyclePicker: View {
    @Binding var selectedCycle: EstimationCycle
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Select Estimation Cycle")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Picker("", selection: $selectedCycle) {
                ForEach(EstimationCycle.allCases) { cycle in
                    Text(cycle.rawValue).tag(cycle)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}
