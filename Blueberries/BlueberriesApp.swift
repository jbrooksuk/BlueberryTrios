//
//  BlueberriesApp.swift
//  Blueberries
//
//  Created by James Brooks on 25/03/2026.
//

import SwiftUI
import SwiftData

@main
struct BlueberriesApp: App {
    let modelContainer: ModelContainer = BlueberriesApp.makeContainer()

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(modelContainer)
    }

    // MARK: - Container setup

    /// Builds the SwiftData container using the explicit versioned schema and
    /// migration plan, so we never fall back to SwiftData's unversioned
    /// automatic migration (which silently resets the store if it fails).
    ///
    /// Debug builds use a separate store file so experiments don't pollute
    /// the release store. Release builds continue to use the default store
    /// name to preserve data from previously shipped versions.
    private static func makeContainer() -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)

        #if DEBUG
        // Separate on-disk file for debug builds. "Berroku-Debug.store" lives
        // alongside the release "default.store" in the same container, so
        // installing the debug scheme does not touch real user data.
        let configuration = ModelConfiguration("Berroku-Debug", schema: schema)
        #else
        // Default configuration — matches the implicit name SwiftData used
        // prior to introducing this migration plan, so shipped users'
        // existing "default.store" continues to be found and migrated.
        let configuration = ModelConfiguration(schema: schema)
        #endif

        do {
            return try ModelContainer(
                for: schema,
                migrationPlan: BerrokuMigrationPlan.self,
                configurations: configuration
            )
        } catch {
            // Surface the *real* error instead of letting SwiftData silently
            // fall back to a fresh store (which is what was happening before
            // and caused the "lost statistics" reports).
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
