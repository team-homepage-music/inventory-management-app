//
//  inventory_management_appApp.swift
//  inventory_management_app
//
//  Created by 吉田響 on 2025/11/29.
//

import SwiftUI
import SwiftData

@main
struct inventory_management_appApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Category.self,
            Location.self,
            Tag.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
