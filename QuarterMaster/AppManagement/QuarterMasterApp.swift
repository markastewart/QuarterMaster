//
//  QuarterMasterApp.swift
//  QuarterMaster
//
//  Created by Mark A Stewart on 6/12/26.
//

import SwiftUI
import SwiftData

@main
struct QuarterMasterApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TaxPeriodInput.self,
            TaxEstimate.self
        ])

        // Build the sandboxed Documents/QuarterMaster/ path
        guard let documentsURL = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first else {
            fatalError("Could not locate Documents directory")
        }

        let folderURL = documentsURL.appendingPathComponent("QuarterMaster/\(SeasonalConstants.programYear)")

        if !FileManager.default.fileExists(atPath: folderURL.path) {
            do {
                try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
            } catch {
                fatalError("Could not create database directory: \(error)")
            }
        }

        let storeURL = folderURL.appendingPathComponent("QuarterMaster.sqlite")
        print("SwiftData Database Location: \(storeURL.path)")

        let modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            QuarterMasterDashboard()
                .frame(maxWidth: .infinity)
        }
        .modelContainer(sharedModelContainer)
    }
}
