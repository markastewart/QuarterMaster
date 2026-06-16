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
            QuarterlyInput.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        print("SwiftData Database Location: \(modelConfiguration.url.path)")

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Dashboard()
        }
        .modelContainer(sharedModelContainer)
    }
}
