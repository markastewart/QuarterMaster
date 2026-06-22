//
//  DashboardVM.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/17/26.
//

import Foundation
import SwiftData

@Observable
class DashboardVM {
    let modelContext: ModelContext
    var taxPeriodInput: [TaxPeriodInput] = []
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        fetchData()
    }

    func fetchData() {
        let descriptor = FetchDescriptor<TaxPeriodInput>(sortBy: [SortDescriptor(\.periodType)])
        taxPeriodInput = (try? modelContext.fetch(descriptor)) ?? []
    }
    
    var federalTaxResults: [TaxEstimate] {
        taxPeriodInput.flatMap { $0.taxEstimates }
                .filter { $0.taxEntity == TaxEntity.federal.rawValue }
    }
    
    var stateTaxResults: [TaxEstimate] {
        taxPeriodInput.flatMap { $0.taxEstimates }
                .filter { $0.taxEntity == TaxEntity.state.rawValue }
    }
    
    struct TaxSummaryRow: Identifiable, Hashable {
        let label: String
        let q1: Double
        let q2: Double
        let q3: Double
        let q4: Double
        
        var id: String { label }
    }
    
    func generateQuarterlyEstimate(for taxPeriod: TaxPeriod, result: Result<[URL], Error>, context: ModelContext) {
        var taxPeriodInput: TaxPeriodInput?
        
            // Read and store input data
        switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                
                    // Get access since running in sandbox.
                let _ = url.startAccessingSecurityScopedResource()
                
                let content = try? String(contentsOf: url, encoding: .utf8)
                guard let inputRecord = content else { return }
                
                taxPeriodInput = CSVImportService.processCSV(content: inputRecord, context: modelContext, taxPeriod: taxPeriod)
                
            case .failure(let error):
                print("Failed to read and process input data for the tax period: \(error.localizedDescription)")
        }
        
            // Verifying an input record is available, post-process the inputs and calculate Federal and State tax estimates.
        if let taxPeriodRec = taxPeriodInput {
            
            DataCurator.curateData(taxPeriodInput: taxPeriodRec)
            
            FederalTaxCalculator.calculateFederalEstimate(taxPeriodInput: taxPeriodRec)
            
            if let fedTaxEstimate = taxPeriodRec.taxEstimates.first(where: { $0.taxEntity == TaxEntity.federal.rawValue}) {
                StateTaxCalculator.calculateStateEstimate(taxPeriodInput: taxPeriodRec, fedEstimate: fedTaxEstimate)
            }
        }
        try? context.save()
    }
}
