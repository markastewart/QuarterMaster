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
    @State private var selectedQuarter: Quarter = .first
    @Query(sort: \QuarterlyInput.quarterID) private var quarterlyData: [QuarterlyInput]
    
    var body: some View {
        NavigationStack() {
            if let vm = viewModel {
                HStack(alignment: .top, spacing: 0) {
                    controlSidebarPane(vm: vm)
                        .frame(width: 280)
                        .padding(.trailing, 8)
                    
                    Divider()
                    
                    VStack(spacing: 20) {
                        EstimateSummary(title: "Federal Tax Estimates", viewModel: vm, isFederal: true)
                        Divider()
                        EstimateSummary(title: "State Tax Estimates", viewModel: vm, isFederal: false)
                    }
                    .padding()
                }
                .navigationTitle("")
                .onChange(of: quarterlyData) { _, newValue in
                    vm.quarterlyData = newValue
                }
                .onAppear {
                    vm.quarterlyData = quarterlyData
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
                Text("Select Quarter to estimate and Import source file").font(.caption.bold()).foregroundStyle(.secondary)
                
                Picker("Quarter", selection: $selectedQuarter) {
                    ForEach(Quarter.allCases) { q in Text(q.rawValue).tag(q) }
                }
                .pickerStyle(.segmented)
                
                Button { isImporting = true } label: {
                    Label("Import \(selectedQuarter.rawValue) CSV", systemImage: "doc.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            Spacer()
        }
        .padding()
        .fileImporter(isPresented: $isImporting, allowedContentTypes: [.commaSeparatedText], allowsMultipleSelection: false) { result in vm.generateQuarterlyEstimate(for: selectedQuarter, result: result, context: modelContext)
        }
    }
}
