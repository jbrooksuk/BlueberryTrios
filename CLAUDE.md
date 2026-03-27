# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Blueberry Trio is a logic puzzle game for iOS, ported from the web version at circle9puzzle.com/bbtrio. Players place 3 berries into each row, column, and block of a 9×9 grid, guided by number clues indicating how many neighboring cells contain berries.

## Build & Run

```bash
# Build (use iPhone 17 Pro simulator or any available iOS 26.2 simulator)
xcodebuild -project Blueberries.xcodeproj -scheme Blueberries -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Open `Blueberries.xcodeproj` in Xcode for running on simulator/device and previews.

## Architecture

- **SwiftUI + SwiftData + @Observable** — uses `@Observable` for game model, SwiftData for persistence
- `BlueberriesApp.swift` — App entry point; sets up `ModelContainer` for `GameState` and `PlayerStats`

### Models (`Blueberries/Models/`)
- `CellState` — enum: `.undecided`, `.empty`, `.berry` with cycling via `.next`
- `PuzzleDefinition` — Codable struct parsing the bundled JSON puzzle format (size, blocks, cellClues, solution)
- `PuzzleModel` — Core game engine (`@Observable`): grid structure, cell state management, group-based validation (rows/columns/blocks/number-clues), undo/redo command history, solved detection
- `PuzzleStore` — Loads bundled puzzles, deterministic daily puzzle selection via `cyrb53` hash
- `GameState` / `PlayerStats` — SwiftData `@Model` classes for persistence
- `Theme` — Color constants referencing asset catalog colors with light/dark variants

### Views (`Blueberries/Views/`)
- `GameView` — Main screen composing header (source/difficulty pickers, timer), grid, and toolbar (undo/redo/erase/hint/check)
- `PuzzleGridView` — SwiftUI `Canvas` rendering of the 9×9 grid with tap & drag gesture handling

### Services (`Blueberries/Services/`)
- `StoreKitService` — StoreKit 2 IAP for "Pro" (unlimited puzzle sets) unlock
- `GameCenterService` — Achievements (1/10/100/500 puzzles, 3/7/30 day streaks) and fastest-time leaderboard
- `PuzzleSolver` — Solving techniques (fill/full, min/max, shallow lookahead) for hint generation

### Resources
- `puzzles.json` — 3300 puzzles (1000 Standard, 1000 Advanced, 1300 Expert) with embedded solutions

## Key Details

- Bundle ID: `com.alt-three.Blueberries`
- iOS 26.2+, Xcode 26.2, Swift 6 concurrency (`MainActor` default isolation)
- No external dependencies or SPM packages
- Game rules: place 3 berries per row/column/block; cell numbers indicate how many of 8 surrounding cells have berries
- Cell states cycle: undecided → empty → berry → undecided (on tap); drag paints all touched cells with the same transition
- "Pro" puzzles gated behind IAP; "Daily" puzzles are free, one per difficulty per day
