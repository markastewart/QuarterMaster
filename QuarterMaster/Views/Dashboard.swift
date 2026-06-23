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
    @Query(sort: \TaxPeriodInput.taxPeriodId) private var taxPeriodInput: [TaxPeriodInput]
    @State var taxCycle: TaxCycle = .quarterly
    
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
                Text("Select Quarter to estimate and identify source file").font(.caption.bold()).foregroundStyle(.secondary)
                
                Picker("Quarter", selection: $selectedQuarter) {
                    ForEach(TaxPeriod.allCases) { q in Text(q.rawValue).tag(q) }
                }
                .pickerStyle(.segmented)
                
                Button { isImporting = true; taxCycle = .quarterly } label: {
                    Label("Select Input File for \(selectedQuarter.rawValue)", systemImage: "doc.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            Spacer()
        }
        .padding()
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.commaSeparatedText], allowsMultipleSelection: false) { result in vm.generateTaxEstimate(for: selectedQuarter, result: result, taxCycle: taxCycle, context: modelContext)
        }
    }
}
