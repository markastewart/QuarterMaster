//
//  ContentView.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/12/26.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct Dashboard: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isImporting = false
    @State private var selectedQuarter: Quarter = .first
    @State private var viewModel: DashboardVM?
    
    var body: some View {
        VStack {
            if let vm = viewModel {
                Picker("Select Quarter", selection: $selectedQuarter) {
                    ForEach(Quarter.allCases) { quarter in
                        Text(quarter.rawValue).tag(quarter)
                    }
                }
                .pickerStyle(.segmented) // Looks great for quarters
                .padding()
                
                Button("Import CSV") {
                    isImporting = true
                }
                .fileImporter(
                    isPresented: $isImporting,
                    allowedContentTypes: [.commaSeparatedText],
                    allowsMultipleSelection: false
                ) { result in
                    vm.generateQuarterlyEstimate(for: selectedQuarter, result: result, context: modelContext)
                }
            }
        }
        .onAppear {
            if viewModel == nil {
                viewModel = DashboardVM(modelContext: modelContext)
            }
        }
    }
}

