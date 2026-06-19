//
//  DashboardVM.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/17/26.
//

import Foundation
import SwiftData
import SwiftUI

@Observable
class DashboardVM {
    let modelContext: ModelContext
    var quarterlyData: [QuarterlyInput] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchData()
    }

    func fetchData() {
        let descriptor = FetchDescriptor<QuarterlyInput>(sortBy: [SortDescriptor(\.quarterID)])
        quarterlyData = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    var federalTaxResults: [TaxEstimate] {
        quarterlyData.flatMap { $0.taxEstimates }
                .filter { $0.taxEntity == TaxEntity.federal.rawValue }
    }
    
    var stateTaxResults: [TaxEstimate] {
        quarterlyData.flatMap { $0.taxEstimates }
                .filter { $0.taxEntity == TaxEntity.state.rawValue }
    }
    
    struct TaxSummaryRow: Identifiable {
        let id = UUID()
        let label: String
        let q1: Double
        let q2: Double
        let q3: Double
        let q4: Double
    }
    
    func summaryRows(for configs: [QuarterMasterDashboard.TaxSummaryLabels], taxEntity: TaxEntity) -> [TaxSummaryRow] {
        let taxResults = taxEntity == TaxEntity.federal ? federalTaxResults : stateTaxResults
        return configs.map { config in
            TaxSummaryRow(
                label: config.displayName,
                q1: taxResults.first(where: { $0.quarterlyInput?.quarterID == Quarter.first.rawValue })?[keyPath: config.keyPath] ?? 0,
                q2: taxResults.first(where: { $0.quarterlyInput?.quarterID == Quarter.second.rawValue })?[keyPath: config.keyPath] ?? 0,
                q3: taxResults.first(where: { $0.quarterlyInput?.quarterID == Quarter.third.rawValue })?[keyPath: config.keyPath] ?? 0,
                q4: taxResults.first(where: { $0.quarterlyInput?.quarterID == Quarter.fourth.rawValue })?[keyPath: config.keyPath] ?? 0
            )
        }
    }
    
    func generateQuarterlyEstimate(for quarter: Quarter, result: Result<[URL], Error>, context: ModelContext) {
        var quarterlyRecord: QuarterlyInput?
        
            // Read and store input data
        switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                
                    // Get access since running in sandbox.
                let _ = url.startAccessingSecurityScopedResource()
                
                let content = try? String(contentsOf: url, encoding: .utf8)
                guard let inputRecord = content else { return }
                
                quarterlyRecord = CSVImportService.processCSV(content: inputRecord, context: modelContext, quarter: quarter)
                
            case .failure(let error):
                print("Failed to read and process input data for the quarter: \(error.localizedDescription)")
        }
        
            // Verifying an input record is available, post-process the inputs and calculate Federal and State tax estimates.
        if let quarterlyRec = quarterlyRecord {
            
            DataCurator.curateData(quarterlyRecord: quarterlyRec)
            
            FederalTaxCalculator.calculateFederalEstimate(quarterlyRecord: quarterlyRec)
            
            StateTaxCalculator.calculateStateEstimate(quarterlyRecord: quarterlyRec)
        }
        try? context.save()
    }
}
