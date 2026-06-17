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
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
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
                print("Import failed: \(error.localizedDescription)")
        }
            // With an input record for quarter, post process the inputs and calculate tax estimate.
        if let quarterlyRec = quarterlyRecord {
            
            DataCurator.curateData(record: quarterlyRec)
            
            TaxCalculator.calculate(record: quarterlyRec)
        }
        try? context.save()
    }
}
