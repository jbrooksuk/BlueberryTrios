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
- `StoreKitService` — StoreKit 2 IAP for a single non-consumable "Pro Puzzles" product (`com.altthree.Berroku.pro`). Handles purchase, restore, verification, and entitlement tracking
- `GameCenterService` — Seven achievements (1/10/100/500 puzzles, 3/7/30-day streaks) and a fastest-time leaderboard. Authenticates on launch
- `PuzzleSolver` — Four solving techniques for hint generation: fill/full (basic), min/max (intersection reasoning), and shallow lookahead (contradiction detection)

### Resources & Configuration
- `puzzles.json` — 3,300 puzzles (1000 Standard, 1000 Advanced, 1300 Expert) with embedded solutions
- `Products.storekit` — StoreKit config with Pro product at $1.99 / £1.99
- `Blueberries.entitlements` — Game Center capability only
- Asset catalog has 9 custom color sets (all with light/dark variants) for the game theme

## Key Details

- Bundle ID: `com.altthree.Berroku` (release), `com.altthree.Berroku.debug` (debug). Debug builds use a separate SwiftData store (`Berroku-Debug.store`) so experimentation never touches release user data. Debug builds skip Game Center entirely (the debug bundle ID is not registered in App Store Connect).
- iOS 17.0+ deployment target, built with Xcode 26.2, Swift 6 concurrency (`MainActor` default isolation)
- Cell states cycle: undecided -> empty -> berry -> undecided; drag paints all touched cells with the same transition
- Daily puzzles use `cyrb53(dateString + difficulty + source + setNumber)` for deterministic selection
- Pro puzzles increment set number; `newProPuzzle()` skips already-solved sets
- Settings are per-session state in GameView: auto-check, show timer, fill hints (vs highlight-only), haptics
- Game Center achievement IDs follow pattern: `com.altthree.berroku.{identifier}` (lowercase `berroku` — does not match the bundle ID's `Berroku` capitalisation; keep it lowercase to match what's registered in App Store Connect)

## Changing SwiftData `@Model` classes

**Every `@Model` change must go through `Blueberries/Models/BerrokuSchema.swift`.** The app builds its `ModelContainer` with an explicit `VersionedSchema` + `SchemaMigrationPlan` and will `fatalError` loudly on launch if a migration fails — it will NOT silently reset the store. That is deliberate; do not "fix" the fatalError by catching it.

When adding, removing, or renaming a property on `GameState`, `PlayerStats`, or any future `@Model`:

1. **Give every new non-optional property a default value** (`var hintUsed: Bool = false`, `var newField: String = ""`). SwiftData's lightweight migration can only add a new mandatory attribute if it has a default to fill into existing rows. A missing default produces `NSCocoaErrorDomain 134110 "Validation error missing attribute values on mandatory destination attribute"` and bricks every shipped user's install. This has already happened once — do not let it happen again.
2. **Bump the schema version.** In `BerrokuSchema.swift`, copy the current model shape into a new `SchemaV{N}: VersionedSchema`, apply the changes there, append it to `BerrokuMigrationPlan.schemas`, and add a migration stage:
   - Use `.lightweight(fromVersion:toVersion:)` if every change is additive and every new field has a default.
   - Use `.custom(...)` for renames, splits, backfills from another model, or anything that needs code to run during the transition.
3. **Test on a device (or simulator) with the previous schema installed** before shipping. Install the prior build first, launch it to create a store, then install the new build over the top. If migration fails, the app will crash on launch — fix it before merging.
4. **Never skip a version.** If V2 is shipped, V3 must migrate from V2, not from V1. Keep every shipped schema version in `schemas` and stages for every hop.

Optional properties (`Date?`, `String?`, `Int?`) don't need defaults — the optional is itself the default. Prefer optional over default-value when the absence of a value is semantically meaningful.
