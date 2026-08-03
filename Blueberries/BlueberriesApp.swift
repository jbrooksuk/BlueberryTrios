//
//  BlueberriesApp.swift
//  Blueberries
//
//  Created by James Brooks on 25/03/2026.
//

import SwiftUI
import SwiftData
import SiriusRating

@main
struct BlueberriesApp: App {
    let modelContainer: ModelContainer = BlueberriesApp.makeContainer()
    @Environment(\.scenePhase) private var scenePhase
    @State private var notificationService = NotificationService()

    init() {
        SiriusRating.setup { config in
            // A "significant event" is one solved puzzle. Wait until the
            // player has solved enough to know they're sticking around,
            // and lean on event count over session count so we don't
            // pester someone who opens the app and bounces.
            config.daysUntilPrompt = 3
            config.appSessionsUntilPrompt = 3
            config.significantEventsUntilPrompt = 5

            // If they decline or pick "remind me later", back off hard.
            config.daysBeforeReminding = 14
            config.daysAfterDecliningToPromptAgain = 60
            config.declineBackOffFactor = 2.0
            config.maxPromptsAfterDeclining = 2

            // Only ask after a positive moment (i.e. solving), never
            // unsolicited on launch.
            config.canPromptUserToRateOnLaunch = false
        }
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(modelContainer)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                notificationService.refreshIfScheduled(currentStreak: currentEffectiveStreak())
            }
        }
    }

    @MainActor
    private func currentEffectiveStreak() -> Int {
        let context = ModelContext(modelContainer)
        var descriptor = FetchDescriptor<PlayerStats>()
        descriptor.fetchLimit = 1
        let stats = (try? context.fetch(descriptor))?.first
        return stats?.effectiveCurrentStreak ?? 0
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
        let schema = Schema(versionedSchema: SchemaV4.self)

        #if DEBUG
        // Pin the debug store to the debug app's private Application Support
        // directory. ModelConfiguration's `groupContainer` defaults to
        // `.automatic`, which would place the store in the shared
        // `group.com.altthree.berroku` container — where it would survive
        // a debug-app uninstall, because the release app keeps that group
        // container alive. An explicit `url:` keeps debug experiments
        // genuinely isolated and reliably wipeable by deleting the app.
        let appSupport = URL.applicationSupportDirectory
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        let storeURL = appSupport.appendingPathComponent("Berroku-Debug.store")
        let configuration = ModelConfiguration("Berroku-Debug", schema: schema, url: storeURL)
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
