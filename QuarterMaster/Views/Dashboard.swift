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
    
    var body: some View {
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
            switch result {
                case .success(let urls):
                    guard let url = urls.first, url.startAccessingSecurityScopedResource() else { return }
                    defer { url.stopAccessingSecurityScopedResource() }
                    
                    if let content = try? String(contentsOf: url, encoding: .utf8) {
                        CSVImportService.processCSV(content: content, context: modelContext, selectedQuarter: selectedQuarter)
                    }
                case .failure(let error):
                    print("Import failed: \(error.localizedDescription)")
            }
        }
    }
}

