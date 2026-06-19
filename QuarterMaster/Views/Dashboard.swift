//
//  ContentView.swift
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
        NavigationStack {
            if let vm = viewModel {
                HStack(alignment: .top, spacing: 0) {
                    controlSidebarPane(vm: vm)
                        .frame(width: 280)
                        .padding(.trailing, 8)
                    
                    Divider()
                    
                    VStack(spacing: 20) {
                        ledgerSection(title: "Federal Tax Estimates", data: quarterlyData, isFederal: true)
                        Divider()
                        ledgerSection(title: "State Tax Estimates", data: quarterlyData, isFederal: false)
                    }
                    .padding()
                }
                .navigationTitle("")
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
                    Text("QuarterMaster").font(.title2).bold()
                    Text("Income Tax Estimator").font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding(.top, 8)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Select Quarter and Import source file").font(.caption.bold()).foregroundStyle(.secondary)
                
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
    
    // MARK: - Reusable Ledger Section
    private func ledgerSection(title: String, data: [QuarterlyInput], isFederal: Bool) -> some View {
        VStack(alignment: .leading) {
            Text(title).font(.headline).padding(.bottom, 4)
            
            Table(data) {
                TableColumn("Quarter") { Text($0.quarterID) }.width(80)
                TableColumn(isFederal ? "Fed Liability" : "State Liability") {
                    let index = isFederal ? 0 : 1
                    Text($0.taxEstimates[index].taxEstimate, format: .currency(code: "USD"))
                }
            }
            .frame(minHeight: 200)
            .navigationDestination(for: QuarterlyInput.self) { estimate in
                EstimateDetailView(/*estimate: estimate*/)
            }
        }
    }
}


struct EstimateDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel: DashboardVM?
    @State private var isImporting = false
    @State private var selectedQuarter: Quarter = .first
    
        // Assuming QuarterlyInput is the model holding your estimate data
    @Query(sort: \QuarterlyInput.quarterID) private var allQuarterlyData: [QuarterlyInput]
    
    var body: some View {
        ContentUnavailableView(
            "Coming Soon",
            systemImage: "hammer.fill",
            description: Text("This feature is currently under development and will be available in a future update.")
        )
    }
}

