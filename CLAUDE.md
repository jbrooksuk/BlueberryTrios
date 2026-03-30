# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Berroku is a logic puzzle game for iOS, ported from the web version at circle9puzzle.com/bbtrio. Players place 3 berries into each row, column, and block of a 9x9 grid, guided by number clues indicating how many of the 8 surrounding cells contain berries.

## Build & Run

```bash
# Build (use any available iOS 26.2 simulator)
xcodebuild -project Blueberries.xcodeproj -scheme Blueberries -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build
```

Open `Blueberries.xcodeproj` in Xcode for running on simulator/device and previews. The shared scheme has StoreKit configuration (`Products.storekit`) and Game Center debug mode pre-configured.

## Architecture

**SwiftUI + SwiftData + @Observable** app with no external dependencies.

### Models (`Blueberries/Models/`)
- `CellState` — Three-state enum (`.undecided`, `.empty`, `.berry`) with `.next` cycling
- `PuzzleDefinition` — Codable struct for the bundled JSON puzzle format (size, blocks, cellClues, solution)
- `PuzzleModel` — Core game engine (`@Observable`): manages grid structure with four constraint group types (rows, columns, blocks, number-clues), cell state, undo/redo command batching (one drag = one undo), solved detection via `checkSolved()`, and hint cell highlighting
- `PuzzleStore` — Loads bundled puzzles, deterministic daily selection via `cyrb53` hash (ported from JS for cross-platform consistency)
- `GameState` / `PlayerStats` — SwiftData `@Model` classes. `PlayerStats.recordCompletion()` handles streak logic (same-day, consecutive, broken)
- `Theme` — Named color constants referencing asset catalog entries with light/dark variants

### Views (`Blueberries/Views/`)
- `HomeView` — Landing screen with animated hero header, daily puzzle cards with completion badges, Pro purchase card, stats grid, and achievement progress rings. Navigates to GameView
- `GameView` — Puzzle screen composing header (Daily/Pro picker with + button for new Pro puzzles, difficulty selector, timer), the grid, and a `.bottomBar` toolbar (undo/redo/erase/hint/check — all disabled when solved). Manages puzzle loading, state persistence, timer, hint integration, and idle timer suppression
- `PuzzleGridView` — SwiftUI `Canvas` rendering of the 9x9 grid. Handles tap-and-drag via `DragGesture` (first cell sets the transition, subsequent cells get the same state). Draws cell backgrounds, block boundaries (thick) vs grid lines (thin), berry circles, empty dots, number clues with satisfaction opacity, error highlighting, and hint highlighting. Supports haptic feedback

### Services (`Blueberries/Services/`)
- `StoreKitService` — StoreKit 2 IAP for a single non-consumable "Pro Puzzles" product (`com.alt-three.Berroku.pro`). Handles purchase, restore, verification, and entitlement tracking
- `GameCenterService` — Seven achievements (1/10/100/500 puzzles, 3/7/30-day streaks) and a fastest-time leaderboard. Authenticates on launch
- `PuzzleSolver` — Four solving techniques for hint generation: fill/full (basic), min/max (intersection reasoning), and shallow lookahead (contradiction detection)

### Resources & Configuration
- `puzzles.json` — 3,300 puzzles (1000 Standard, 1000 Advanced, 1300 Expert) with embedded solutions
- `Products.storekit` — StoreKit config with Pro product at $1.99 / £1.99
- `Blueberries.entitlements` — Game Center capability only
- Asset catalog has 9 custom color sets (all with light/dark variants) for the game theme

## Key Details

- Bundle ID: `com.alt-three.Berroku`
- iOS 26.2+, Xcode 26.2, Swift 6 concurrency (`MainActor` default isolation)
- Cell states cycle: undecided -> empty -> berry -> undecided; drag paints all touched cells with the same transition
- Daily puzzles use `cyrb53(dateString + difficulty + source + setNumber)` for deterministic selection
- Pro puzzles increment set number; `newProPuzzle()` skips already-solved sets
- Settings are per-session state in GameView: auto-check, show timer, fill hints (vs highlight-only), haptics
- Game Center achievement IDs follow pattern: `com.alt-three.Berroku.{identifier}`
