# Berroku for Android

## Product goal

Build a native Android edition of Berroku that shares the iOS game's rules,
puzzle catalogue, daily-puzzle selection, progression, tone, and visual identity,
while using Android-native navigation, accessibility, billing, notifications,
widgets, and game services.

The Android edition should feel like the same game, not a pixel-for-pixel iOS
copy. Material components should provide the surrounding application chrome;
the puzzle grid and blueberry brand remain custom and platform-independent.

## Implementation status

Phase 1 is now underway in `android/`. The repository contains a native Compose
application, a platform-independent `game-core`, direct packaging of the iOS
`puzzles.json`, process-death game restoration, the first playable daily screen,
and an Android GitHub Actions build. Kotlin parity tests lock the exact Swift seed
string, cyrb53 output, catalogue index, constraints, command history, restart,
restore, and deterministic hint behavior.

## Game contract to preserve

- A 9 x 9 grid with exactly three berries in every row, column, and irregular
  block.
- A numbered cell is permanently empty and constrains its eight surrounding
  cells to the displayed berry count.
- Interactive cells cycle `undecided -> empty -> berry -> undecided`.
- A drag paints every newly entered cell with the transition selected by the
  first cell. A single drag is one undoable command batch.
- Errors appear only after one second of inactivity when auto-check is enabled.
- A satisfied number clue fades, but remains readable.
- Hints try fill/full, intersection min/max, and contradiction lookahead before
  falling back to the embedded solution.
- Daily puzzles are selected deterministically from local date, difficulty,
  source, and set number using the existing cyrb53 algorithm and UTF-16 input.
- Three daily difficulties are free. Unlimited Pro puzzles are unlocked by a
  one-time purchase. Berry Revival remains a consumable purchase.
- A solve records elapsed time, hints, mistakes, streaks, flawless streaks,
  daily sweeps, per-difficulty totals, and Pro totals.

## Recommended Android stack

- Kotlin, coroutines, and immutable domain models.
- Jetpack Compose with Material 3 for screens and controls.
- A single-activity app using Navigation Compose.
- Screen-level `ViewModel`s exposing immutable `StateFlow` UI state and accepting
  explicit user events.
- A pure Kotlin `game-core` module for puzzle parsing, selection, validation,
  commands, solving, and statistics. It must not depend on Android APIs.
- Room for saved games and player statistics, with explicit migrations.
- Preferences DataStore for gameplay settings and walkthrough/tutorial flags.
- Google Play Billing for the permanent Pro entitlement and consumable revival.
- Google Play Games Services for achievements and fastest-time leaderboards.
- AlarmManager for the user-selected daily reminder time; reschedule after boot,
  time-zone changes, and app updates. Use WorkManager only for deferrable work.
- Glance for the daily-progress home-screen widget.
- Gradle version catalog and convention plugins; no dependency-injection
  framework is needed for the first release.

## Proposed modules

```text
android/
  settings.gradle.kts
  build.gradle.kts
  gradle.properties
  gradlew / gradlew.bat
  gradle/              Wrapper and version catalogue
  app/                 Application, navigation, theme, service wiring
  game-core/           Rules, solver, commands, deterministic selection, stats
  data/                Room, DataStore, repositories, migrations
  feature-home/        Daily cards, Pro entry, stats, achievements
  feature-game/        Game screen, canvas grid, timer, solved flow
  feature-help/        Walkthrough and interactive tutorial
  feature-settings/    Preferences, reminders, purchases, links
  platform-services/   Billing, Play Games, notifications, sharing, review
  widget/              Glance daily-progress widget
```

For a small initial team, `feature-*` may start as packages inside `app`; keep
`game-core` separate from day one because it provides the most valuable test and
portability boundary.

## Repository and CI layout

Keep Android in this repository under `android/`; do not create a separate
repository. The existing iOS project remains at the repository root and the web
site remains under `web/`. This lets both native apps consume the same versioned
puzzle catalogue and parity fixtures while retaining independent build systems.

The scaffold includes `.github/workflows/android.yml`. It runs only for changes
to `android/**`, the shared puzzle catalogue, or the workflow itself, and:

1. Check out the repository and install the JDK version pinned by the project.
2. Validate and cache the Gradle wrapper using `gradle/actions/setup-gradle`.
3. Run `./gradlew :game-core:test :app:lintDebug :app:assembleDebug` from
   `android/`.
4. Upload lint/test reports even after failures.
5. Upload `android/app/build/outputs/apk/debug/app-debug.apk` as an artifact on
   successful builds, with a short retention period such as 14 days.

The debug APK is sufficient for manual testing and is signed automatically with
the standard debug key; no repository secret is required. Download the artifact
from the GitHub Actions run, unzip it, start an Android Studio virtual device,
and either drag the APK onto the emulator or run:

```bash
adb install -r app-debug.apk
```

For pull requests, unit tests and debug assembly are the fast required checks.
Add an emulator instrumentation job later for Compose UI tests. Keep it separate
because emulator startup is slower and more failure-prone; initially run it on
`main`, nightly, or on demand. A release AAB is a distinct publishing workflow
that requires Play signing credentials and must never reuse the debug artifact.

Suggested workflow shape once `android/gradlew` exists:

```yaml
name: Android

on:
  push:
    branches: [main]
    paths: ['android/**', '.github/workflows/android.yml']
  pull_request:
    branches: [main]
    paths: ['android/**', '.github/workflows/android.yml']
  workflow_dispatch:

permissions:
  contents: read

jobs:
  build:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: android
    steps:
      - uses: actions/checkout@v7
      - uses: actions/setup-java@v5
        with:
          distribution: temurin
          java-version: '17'
      - uses: gradle/actions/setup-gradle@v6
        with:
          cache-provider: basic
      - run: chmod +x gradlew
      - run: ./gradlew :game-core:test :app:lintDebug :app:assembleDebug
      - uses: actions/upload-artifact@v7
        if: always()
        with:
          name: android-reports
          path: |
            android/**/build/reports/
            android/**/build/test-results/
          retention-days: 14
      - uses: actions/upload-artifact@v7
        with:
          name: berroku-debug-apk
          path: android/app/build/outputs/apk/debug/app-debug.apk
          retention-days: 14
```

Pin Java and action major versions to those supported by the Gradle/Android
Gradle Plugin versions selected during scaffolding; the example is a starting
shape, not a substitute for testing the generated project.

## Domain design

Use value types for `CellId`, `CellState`, `GroupId`, `PuzzleDefinition`, and
`CheckResult`. Construct an immutable `PuzzleTopology` once per puzzle containing
the row, column, block, number-clue, neighbour, and reverse cell-to-group maps.

`PuzzleSession` owns the mutable play state. Expose changes through commands:

```kotlin
sealed interface GameCommand {
    data class Paint(val changes: List<CellChange>) : GameCommand
    data class Erase(val changes: List<CellChange>) : GameCommand
}
```

Both undo and redo operate on whole commands, which makes a tap a one-change
command, a drag a multi-change command, and erase a multi-change command. Keep
mistake history sticky for the session and keep hint count through restart, as
on iOS.

Use stable identifiers rather than serialized puzzle JSON as primary keys:

```text
daily:<local-date>:<difficulty>:<catalog-version>
pro:<difficulty>:<set-number>:<catalog-version>
```

Store the selected puzzle index and a SHA-256 content fingerprint as integrity
metadata. This avoids using a large JSON blob as an identity while preserving
the ability to detect a changed catalogue.

## Persistence schema

`saved_game`

- `gameId` primary key
- `puzzleIndex`, `puzzleFingerprint`, `catalogVersion`
- `source`, `difficulty`, `localDate`, `proSetNumber`
- compact cell-state string
- JSON-encoded undo and redo command lists
- `elapsedMillis`, `hintedCell`, `hintCount`, `madeMistake`
- `solved`, `completionInstant`, `lastPlayedInstant`

`player_stats` is a one-row table containing all counters and dates currently in
the iOS V5 schema. Preferences such as auto-check, timer, fill hints, sound,
haptics, and onboarding flags belong in DataStore rather than Room.

Every Room schema change must export its schema, include a migration, and be
tested from every released version. Never use destructive migration fallback for
production player data.

## UI plan

### Visual parity strategy

Target high identity parity, not pixel parity: roughly 85–90% similarity in the
game and brand, and 60–70% similarity in surrounding platform chrome.

Preserve exactly or very closely:

- The puzzle grid's geometry, semantic colors, line hierarchy, clue treatment,
  berry proportions, X mark, hint wash, error delay, and solved cascade.
- The restrained blueberry palette in light and dark themes.
- The warm editorial title treatment, readable neutral body type, and
  monospaced timer/numerals. Use Android-licensed font counterparts rather than
  attempting to reproduce Apple system fonts.
- The blueberry illustration style, brand name, friendly puzzle-editor voice,
  screen information hierarchy, and quiet celebration character.
- Core spacing relationships and the constrained reading/game width on tablets.

Adapt deliberately for Android:

- Use Material 3 navigation, app bars, dialogs, sheets, switches, segmented
  choices, touch targets, back behavior, and system insets.
- Replace Liquid Glass with opaque, blue-tinted surfaces separated by tonal
  contrast and fine keylines. Reserve a soft shadow for genuinely raised or
  temporary elements. Do not imitate glass with blur-heavy glassmorphism.
- Use shape sparingly: approximately 16 dp for major grouped surfaces, 12 dp for
  compact controls, and pills only for actions/statuses that semantically merit
  them. Avoid placing every section inside a floating rounded card.
- Let Material ripple/pressed states and Android haptics replace iOS glass
  morphing. Keep custom motion for puzzle feedback and the solved moment.
- On large screens, adapt composition rather than merely enlarging the phone UI.
  Keep the grid square and bounded; allow supporting information to move beside
  it where useful.

The visual north star is “the same carefully printed puzzle edition, bound for a
different platform.” A screenshot should be recognizably Berroku before the
viewer notices which operating system is running it.

### Home

- Bottom navigation: Home, Achievements, Settings.
- Illustrated blueberry hero, brand title, and concise rule reminder.
- Three daily rows showing complete, in-progress, and hint-assisted state.
- Resume-current-game accessory when appropriate.
- Pro unlock or continue card, statistics cards, calendar, streak revival, and
  achievement progress.
- Use adaptive layouts: one readable column on phones and constrained/two-pane
  arrangements on large screens and foldables.

### Game

- Header with Daily/Pro selector, difficulty buttons, optional timer, new-Pro
  action, and settings.
- Draw the grid in a Compose `Canvas`: backgrounds, thin lines, block borders,
  contents, then highlights. Preserve the iOS colors, line weights, berry
  proportions, X mark, and delayed error treatment.
- Use pointer input to distinguish tap from drag and collect one command batch
  per gesture. Clamp hit testing at grid edges and ignore clue cells.
- Bottom app bar actions: undo, redo, erase, hint, and manual check. Hide manual
  check entirely when auto-check is enabled rather than leaving an invisible
  layout slot.
- Provide a semantics node for every cell with row, column, clue/state, click
  action, and selected-state description. Minimum interactive targets are 48 dp.
- Respect font scale, high contrast, touch-and-hold delay, vibration settings,
  and Remove Animations. Never rely on color alone for error or completion state.
- Celebration is a row cascade plus confetti; use a static/opacity-only result
  when motion is reduced.

### Tutorial and walkthrough

Port the instructional content, but make the tutorial run against the real core
engine. Add TalkBack instructions for cycling a cell and explain drag painting
only as an optional shortcut.

## Platform service mapping

| iOS | Android |
| --- | --- |
| SwiftData | Room |
| `@AppStorage` | Preferences DataStore |
| StoreKit 2 | Google Play Billing |
| Game Center | Play Games Services |
| UserNotifications | AlarmManager + notification channels |
| WidgetKit | Glance App Widget |
| Share sheet | Android Sharesheet (`ACTION_SEND`) |
| App review request | Play In-App Review |
| SwiftUI Canvas | Compose Canvas |
| sensory feedback | Compose haptic feedback / vibrator APIs |

Billing processing must be idempotent. Acknowledge the non-consumable Pro
purchase after granting the entitlement; consume Berry Revival only after its
streak grant is committed. Re-query purchases when billing reconnects and when
the app resumes. A backend is optional for the first release, but recommended if
revocation handling or stronger fraud resistance is required.

## Delivery phases

### Phase 0: parity fixtures

- Freeze a versioned copy of `puzzles.json` and record its checksum.
- Export cross-platform golden fixtures for daily selections across dates,
  time zones, all difficulties, and several Pro set numbers.
- Export solver fixtures, validation states, and stats timelines from iOS tests.
- Decide package name, Play product IDs, achievement IDs, leaderboard IDs, and
  whether iOS and Android progress remain intentionally separate.

Exit: Kotlin tests reproduce the same puzzle indexes and rule results as Swift.

### Phase 1: playable offline vertical slice

- Create modules, theme, navigation shell, and `game-core`.
- Port puzzle definitions, topology, session commands, validation, and solver.
- Implement the Compose grid, tap/drag input, undo/redo, erase, hints, manual and
  automatic checking, timer, restart, and solved overlay.
- Bundle the full puzzle catalogue.

Exit: all three daily difficulties can be completed offline with process-death
recovery and full accessibility semantics.

### Phase 2: persistence and product shell

- Add Room saves/stats and DataStore settings.
- Build Home, Achievements, Settings, calendar, walkthrough, and tutorial.
- Add sharing, sounds, haptics, review prompts, reminders, and the widget.

Exit: the core free experience matches iOS behavior and survives upgrades.

### Phase 3: Play integrations

- Configure and test Pro and Berry Revival products with licensed testers.
- Add Play Games sign-in, achievements, and fastest-time leaderboard.
- Add reconciliation on startup/resume and offline queues for score/achievement
  submissions.

Exit: purchases restore correctly; grants cannot double-apply; game-service
progress catches up after reconnecting.

### Phase 4: release hardening

- Baseline profiles and Macrobenchmark for cold start, home scrolling, and grid
  interaction; verify stable frame timing on a mid-range device.
- Screenshot tests for phone/tablet, light/dark mode, large fonts, and locales.
- TalkBack, Switch Access, keyboard/D-pad, foldable, rotation, background/restore,
  DST, time-zone-change, and notification-permission testing.
- Internal testing, closed testing, staged production rollout, crash/ANR
  monitoring, privacy disclosures, store listing, and support documentation.

Exit: release candidate meets parity criteria and has rollback/monitoring plans.

## Required parity tests

- cyrb53 matches JavaScript/Swift unsigned 32-bit overflow and UTF-16 behavior.
- The same civil date and time zone select the same daily puzzle on both apps.
- A clue cell can never become a berry, including through hints and restore.
- A drag never changes the same cell twice and one undo reverses the whole drag.
- Redo restores the whole command; a new command clears redo history.
- Manual Check refreshes visible errors when auto-check is disabled.
- A solved board records completion exactly once across repeated saves and app
  restarts.
- Restart clears the board and mistake flag but preserves hint count and elapsed
  time.
- Pro generation skips existing game IDs and is deterministic for a set number.
- Purchase grants are idempotent across callbacks, resume, reconnect, and crash.
- Notification scheduling behaves correctly across DST and time-zone changes.
- Room migrations preserve saves, statistics, and entitlement-derived UI.

## iOS review findings that affect the port

### High: manual Check currently has no visible effect

`GameView` calls `model.checkSolved()` and discards the returned `CheckResult`.
It neither assigns `lastCheck` nor enables `showErrors`, so with auto-check off
the button cannot display errors. Fix iOS with a dedicated model action that
updates `lastCheck` and explicitly reveals errors; implement and test that action
in Android from the outset.

### Medium: drag painting is not one undoable action

`PuzzleGridView` calls `applyCell` for each entered cell, and `applyCell` appends
each change separately. This conflicts with the documented interaction contract.
Use command batches on both platforms so a drag and erase each have symmetric
single-step undo/redo.

### Medium: purchase and save failures are mostly invisible

Product loading logs only in debug; purchase buttons use `try?`; restore uses
`try?`; and save failures become assertions. Players can receive no useful state
when the store, verification, or persistence fails. Both apps should expose
loading, pending, cancelled, retryable failure, and successful entitlement states,
and persistence failures should produce a recoverable alert/logging signal.

### Medium: large views own too many responsibilities

`GameView` and `HomeView` combine rendering, navigation, persistence, timer,
billing, game-service reporting, widget updates, review prompting, and date
rollover. This raises regression risk and makes behavior difficult to test. The
Android UDF boundary should keep composables stateless and move orchestration to
ViewModels/use cases. A similar extraction would improve the iOS app.

### Low: documentation has drifted

The repository overview says there are no external dependencies and describes
3,300 puzzles, while the project contains SiriusRating and tests expect 2,000
puzzles per difficulty. Refresh the overview before treating it as a parity
specification; use the JSON and executable tests as the authority.

## Definition of parity

Android parity means identical puzzle/rule outcomes and equivalent player-facing
capabilities. It does not require shared purchases, shared saves, identical system
chrome, or identical animation primitives. Cross-platform account sync should be
a separate product decision because it introduces authentication, backend storage,
conflict resolution, privacy, and entitlement reconciliation.
