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
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: [GameState.self, PlayerStats.self])
    }
}
