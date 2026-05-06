# Berroku — Design Reference

A reference for LLMs (and humans) working on Berroku. Captures the game's
rules, brand language, colour system, typography, layout patterns,
component vocabulary, motion, and the architectural patterns the SwiftUI
codebase leans on. The goal is that another agent can pick this up cold
and produce work that fits the existing app.

Berroku is an iOS port of the web game at `circle9puzzle.com/bbtrio`. The
visual direction is "kawaii blueberries on a soft pastel ground" with a
game grid that reads as a clean, restrained logic puzzle. Hero artwork is
warm and illustrated; the puzzle itself is quiet, monochromatic, and
high-contrast so glanceable scanning of clues stays effortless.

---

## 1. Game concept

- **Goal.** Place exactly **3 berries** in every row, every column, and
  every block (an irregular polyomino region) of a 9×9 grid.
- **Number clues.** Some cells contain a number 0–8 that fixes how many
  of the 8 surrounding cells (orthogonal + diagonal) contain berries. A
  clue cell itself is `.empty` and never holds a berry.
- **Cell states.** Each interactive cell cycles
  `undecided → empty → berry → undecided`. `empty` is the player's
  "definitely not a berry" mark — drawn as a small X.
- **Constraint groups.** Four kinds: `row`, `column`, `block`,
  `number(cell)`. The first three each require exactly 3 berries; the
  fourth requires the clue's value among the cell's 8 neighbours.
- **Difficulties.** Standard (easy), Advanced (medium), Expert (hard).
  Indices 1, 2, 3 in the picker. There is one daily set per difficulty
  and an unlimited Pro set per difficulty (one-time IAP).

---

## 2. Brand voice

- **Name.** "Berroku." Always capitalised, displayed in a serif weight
  bold for hero/title moments. Game Center uses lowercase "berroku" in
  achievement IDs (`com.altthree.berroku.{id}`) — this is intentional
  and must be kept lowercase to match App Store Connect registration.
- **Tagline (home).** "Place 3 berries in every row, column & block."
- **Tone.** Friendly, soft, encouraging. Never punishing. Errors fade
  in after a delay rather than snapping on; restart prompts are framed
  as "Fresh start?" not "You're stuck." Solved screen reads "Sweet!"
- **Mascot.** A cluster of three illustrated kawaii blueberries with
  faces (happy / smile / wink), plus leaves, used in the home hero and
  walkthrough. See `IllustratedBerryClusterView` and `BlueberryView`
  for the canonical renderings.

---

## 3. Colour system

All semantic game colours go through `Theme` (`Models/Theme.swift`) and
resolve to named colour assets in `Assets.xcassets`. Every game colour
ships with explicit light **and** dark variants — never use a flat
`Color.black`/`Color.white` for grid content.

### 3.1 Game palette (asset catalogue)

| Token              | Light (sRGB)              | Dark (sRGB)                | Role                                                     |
| ------------------ | ------------------------- | -------------------------- | -------------------------------------------------------- |
| `BerryBlue`        | `0.208, 0.518, 0.894`     | `0.353, 0.624, 0.910`      | Brand accent. Berries, headlines, primary CTAs, badges.  |
| `CellBackground`   | `0.961, 0.961, 0.961`     | `0.173, 0.173, 0.180`      | Grid cell fill (subtle off-white / near-black).          |
| `GridLineThin`     | `0.533, 0.533, 0.533`     | `0.333, 0.333, 0.333`      | Hairline lines between cells (drawn at 50% opacity).     |
| `GridLineThick`    | `0.000, 0.000, 0.000`     | `1.000, 1.000, 1.000`      | Block boundaries and outer border (2–2.5pt).             |
| `ClueText`         | `0.000, 0.000, 0.000`     | `1.000, 1.000, 1.000`      | Number clue glyphs.                                      |
| `EmptyDot`         | `0.533, 0.533, 0.533`     | `0.600, 0.600, 0.600`      | The X-mark indicating "definitely not a berry."          |
| `ErrorCell`        | `0.980, 0.847, 0.914`     | `0.400, 0.150, 0.220`      | Cell tint when a constraint group is broken.             |
| `ErrorText`        | `0.953, 0.133, 0.545`     | `1.000, 0.300, 0.600`      | Number clue colour when its group errors. Pink-magenta.  |
| `HintHighlight`    | `1.000, 0.800, 0.200, .4` | `1.000, 0.750, 0.100, .4`  | Yellow wash over a cell the hint engine is pointing at.  |

Constants on `Theme` you should reuse rather than redefine:

- `Theme.satisfiedClueOpacity = 0.25` — opacity applied to a clue's
  number once its surround is satisfied (it dims to fade out of the
  scan).
- `Theme.errorAnimationDelay = 1.0` — seconds between a cell change and
  errors becoming visible (`PuzzleModel.showErrors`).
- `Theme.backgroundGradient` — the standard page background:
  `LinearGradient` from `BerryBlue.opacity(0.08)` at top to
  `Color(.systemGroupedBackground)` at centre.

### 3.2 Mascot illustration palette

`IllustratedBerryClusterView` defines its own private palette tuned for
the painterly hero illustration. Only use these inside the mascot
renderings:

```
Body dark    #314A83  (0.19, 0.29, 0.51)
Body mid     #4F6AA2  (0.31, 0.42, 0.63)
Body base    #6181B8  (0.38, 0.51, 0.72)
Body light   #99BCE1  (0.60, 0.74, 0.89)
Eye          #38274B  (0.22, 0.15, 0.29)
Cheek        #D18482  (0.82, 0.51, 0.50)
Mouth dark   #602441  (0.37, 0.14, 0.26)
Mouth red    #EF716B  (0.93, 0.44, 0.42)
Leaf light   #ABD167  (0.67, 0.82, 0.40)
Leaf mid     #80A847  (0.50, 0.66, 0.28)
Leaf dark    #547D33  (0.33, 0.49, 0.20)
```

The simpler `BlueberryView` (used in smaller spots) uses a slightly
different, slightly more muted blue-purple palette (`0.45, 0.48, 0.64`
body, etc.). Treat these two illustration sets as cousins, not
identical — pick the one matching the existing usage and don't recolour
across.

### 3.3 Semantic system colours

Outside the grid, the app leans heavily on system materials and
semantic colours so things adapt to Dark Mode for free:

- `.secondary`, `.tertiary` for muted body text.
- `Color(.systemGroupedBackground)`, `.secondarySystemGroupedBackground`
  for sheets and cards on iOS < 26.
- `.orange` for streak motifs (flame, "all daily complete!" sparkle).
- `.green` for completion / success badges.
- `.yellow` for hint achievements; `.pink/.red/.brown` for streak
  achievement tiers; `.teal/.indigo/.purple/.mint/.cyan` for puzzle-count
  and per-difficulty achievement badges. Each achievement's tint is in
  the `AchievementInfo` table at the top of `HomeView.allAchievements`.

### 3.4 Usage rules

- Berries: always `Theme.berryBlue`, with a `.white.opacity(0.25)`
  highlight spot in the upper-left third for dimensional shading.
- Headlines and the brand mark: `Theme.berryBlue`.
- Primary CTA pills: `Theme.berryBlue` background with white label.
- Errors: surface them only after the player has stopped editing —
  `PuzzleGridView` schedules `showErrors = true` after ~1 second of
  inactivity. Don't flash them mid-drag.

---

## 4. Typography

Three families coexist:

| Use                                  | Style                                                            |
| ------------------------------------ | ---------------------------------------------------------------- |
| App title, hero numerals, "Sweet!"   | `.system(.largeTitle, design: .serif).weight(.bold)`             |
| Stat values (solved/streak/fastest)  | `.system(.title2, design: .serif).weight(.bold).monospacedDigit()`|
| Clue glyphs in the grid              | `.system(size: cellSize * 0.5, weight: .semibold, design: .rounded)` |
| Timer                                | `.system(.body, design: .monospaced)` with `.numericText()` content transition |
| Body / labels                        | Default SF (system text styles: `.headline`, `.subheadline`, `.caption`, etc.) |

Conventions:

- Use Dynamic Type. Every text style above is one of SwiftUI's named
  styles, so sizes scale with the user's accessibility settings. Don't
  hardcode point sizes outside the grid (the grid scales off
  `cellSize`).
- `.monospacedDigit()` on any number that updates in place (timer,
  counters) so layout doesn't jitter.
- Stat-card numbers and the brand mark use `.serif` for warmth. Body
  copy stays in SF for legibility.
- Clue glyphs use the rounded design — they read as "puzzle pieces"
  rather than typewritten characters.

---

## 5. Layout, spacing, structure

### 5.1 Page chrome

- Pages typically max out at `frame(maxWidth: 600)` so iPad doesn't
  spread cards into wide unreadable bands.
- Outer horizontal padding is `16pt`; cards' internal padding is
  typically `20pt` (occasionally `24pt` for the Pro promo).
- Vertical rhythm in stacked cards is `20pt` spacing.
- The home, achievements, and game backgrounds all use
  `Theme.backgroundGradient` for a consistent soft-blue wash at the top
  fading into the grouped-background tone.

### 5.2 Cards

The shared card surface is `adaptiveGlass(in: 16)`
(`Models/GlassCompat.swift`):

- iOS 26+: `glassEffect(in: .rect(cornerRadius: 16))` (Liquid Glass).
- Older iOS: `Color(.secondarySystemGroupedBackground)` clipped to a
  16pt rounded rect.

Wrap groups of glass elements in `AdaptiveGlassContainer(spacing: 20)`
so iOS 26 can blend their reflections together; older iOS quietly
unwraps it. **Never** use `.regularMaterial` or hand-rolled blurs —
always go through the adaptive helpers.

Other card corner radii in use: `14` (achievement badges), `16` (most
cards), `24` (Pro promo hero, larger and more tactile).

### 5.3 Buttons

Primary and secondary buttons go through adaptive helpers so iOS 26
gets glass treatments and older iOS stays bordered:

- `.adaptiveProminentButton()` → `.glassProminent` / `.borderedProminent`
- `.adaptiveSecondaryButton()` → `.glass` / `.bordered`

Pill-style CTAs (Daily row "Play"/"Continue", Pro purchase) use
`Capsule()` clip with `Theme.berryBlue` fill and white `.semibold`
labels at `.subheadline`. Vertical padding 10–12, horizontal 18–22.

The toolbar at the bottom of `GameView` is the OS `.bottomBar` — undo,
redo, erase, hint, check. All five disable themselves once the puzzle
is solved.

### 5.4 Iconography

Use SF Symbols throughout. Recurring symbols (so new screens stay
consistent):

| Concept            | Symbol                                       |
| ------------------ | -------------------------------------------- |
| Daily / today      | `calendar`                                   |
| Pro / unlimited    | `infinity`, `checkmark.seal.fill` (unlocked) |
| Stats              | `chart.bar.fill`, `chart.bar.xaxis`          |
| Streak             | `flame.fill`                                 |
| Fastest time       | `bolt.fill`                                  |
| Best streak        | `trophy.fill`                                |
| Hints              | `lightbulb`, `lightbulb.fill`, `lightbulb.max.fill` |
| Puzzles solved     | `puzzlepiece.fill`                           |
| Per-difficulty     | `1.circle.fill` / `2.circle.fill` / `3.circle.fill`, or `square.grid.3x3.fill` |
| Sweep / celebration| `sparkles`                                   |
| Toolbar (game)     | `arrow.uturn.backward`, `arrow.uturn.forward`, `eraser`, `lightbulb`, `checkmark.circle` |
| Settings           | `gearshape`                                  |
| Tab bar            | `house.fill`, `trophy.fill`, `gearshape`     |

---

## 6. The puzzle grid (`PuzzleGridView`)

The grid is rendered by a single SwiftUI `Canvas`. Specifics that any
agent touching it should preserve:

- **Aspect.** Locked square via `.aspectRatio(1, contentMode: .fit)`,
  capped at `maxWidth: 500`.
- **Cell size.** `min(width, height) / numColumns`, propagated up to
  the parent via a `PreferenceKey` for hit testing.
- **Cell rendering order:** background fill → thin grid lines → block
  boundaries → cell contents (clue / berry / X). This order matters so
  block boundaries stay on top of cell fills but under content.
- **Cells inset by 1pt** from their grid square and clipped to a 2pt
  rounded rect — so cell fills don't fight the grid lines.
- **Thin lines.** `GridLineThin` at `opacity(0.5)`, `lineWidth: 0.5`.
- **Block boundaries.** `GridLineThick`, `lineWidth: 2` with round
  caps. Outer border drawn at `lineWidth: 2.5`, corner radius 4.75
  (matching the Canvas's own 6pt rounded clip minus inset).
- **Berry.** Filled circle, radius `cellSize * 0.30`, with a small
  upper-left highlight circle at `0.35 *` berry radius and `25%` white
  opacity. Newly placed berries pulse to `1.15×` scale briefly
  (`recentlyPlacedBerries`).
- **Empty mark.** A small X (two stroked diagonals), `lineWidth: 1.5`,
  round caps, half-extent `cellSize * 0.12`. **Not** a dot — the X is
  intentional; do not "simplify" back to a dot.
- **Clue glyphs.** `cellSize * 0.5`, semibold, rounded. Drop to
  `Theme.satisfiedClueOpacity` (0.25) when their group is satisfied so
  the player's eye skips over solved clues.
- **Error highlighting.** Cell background swaps to `Theme.errorCell`,
  clue text colour swaps to `Theme.errorText`. Gated behind
  `model.showErrors` which only flips on after ~1s of input
  inactivity (so dragging through a transient invalid state doesn't
  feel like nagging).
- **Hint highlight.** A `Theme.hintHighlight` (yellow, 40% alpha) wash
  layered over the cell background.
- **Celebration cascade.** On solve, `celebrationProgress` ramps 0→1
  over ~900ms in 18 steps; each row fills with
  `Theme.berryBlue.opacity(0.2)` as the cascade reaches it (top to
  bottom). Suppressed under Reduce Motion.
- **Outer shadow.** `Color.black.opacity(0.08), radius: 8, y: 2`.

### 6.1 Input

- Single combined `DragGesture(minimumDistance: 0)` handles both tap
  and drag. The first contacted cell decides the transition
  (`.next` from its current state); every subsequent cell touched by
  the same drag receives the **same** target state. This makes "fill a
  row of berries" or "wipe a row to empty" feel direct.
- Each cell change fires a haptic
  (`sensoryFeedback(.impact(flexibility: .solid, intensity: 0.5))`)
  and a tap sound when sound is enabled.
- One drag = one undo entry per touched cell, but `erase` collapses the
  whole bulk-clear into a single undo step (`eraseBatch`).
- Clue cells are non-interactive (`isInteractive(_:)` returns false).

### 6.2 Accessibility

- The Canvas is overlaid with an invisible 9×9 SwiftUI `Grid` of
  buttons, one per cell, providing per-cell `accessibilityLabel`
  ("Row 3, column 5, berry") and `.accessibilityAction` so VoiceOver
  users can tap their way through.
- Reduce Motion is honoured: berry placement pulse, celebration
  cascade, solved-overlay scale transition, and hero animation all
  collapse to identity transitions when set.

---

## 7. Motion vocabulary

- **Hero cluster.** `PhaseAnimator([false, true])` with `easeInOut(1.6)`
  — the three berries gently bob and rotate in opposing phases.
- **Solved overlay.** `.spring(duration: 0.4, bounce: 0.3)` for the
  scale+opacity transition. Confetti via `ConfettiView` underneath.
- **Restart prompt.** Same spring as the solved overlay.
- **Newly placed berry.** Scale to `1.15` for ~150ms then settle.
- **Errors.** Two-stage delay: `recentlyPlacedBerries` clears at 150ms,
  errors become visible at 1000ms.
- **Timer.** `.numericText()` content transition so digits roll instead
  of cross-fade.
- **Cascade on solve.** 18-step manual ramp (50ms per step) of
  `celebrationProgress` 0→1, then the spring-in of the overlay.
- **Reduce Motion override.** Every animated path checks
  `@Environment(\.accessibilityReduceMotion)` and provides a static
  fallback. Add the same check to anything new.

---

## 8. Components and recurring patterns

### 8.1 Daily puzzle row icon

A 56×56 rounded square (radius 14):

- Solved + hint used → orange fill with `lightbulb.fill` glyph in white.
- Solved hint-free → green fill with `checkmark.circle` in white.
- In-progress → `Theme.berryBlue` fill with the difficulty index in
  white bold.
- Untouched → 10% berryBlue tint, 30% berryBlue stroke, difficulty
  index in `Theme.berryBlue` semibold.

### 8.2 Stat tile

`statItem(value:label:icon:)` in `HomeView`. A vertical stack of
`{icon (BerryBlue, .caption)} / {value (.title2 bold monospacedDigit)}
/ {label (.caption secondary)}`, padded 12pt, on a `BerryBlue.opacity(0.06)`
background, clipped to a 10pt rounded rect.

### 8.3 Achievement badge

A 60×60 stack: progress ring (`Circle().trim` stroked at 3pt rounded
with `BerryBlue` over a `BerryBlue.opacity(0.15)` track) only shown for
multi-step achievements; a coloured fill circle inset 6pt with the
achievement's symbol in white. Below: title (`.footnote.weight(.bold)`),
subtitle (`.caption2 secondary`), and percentage if unearned and
multi-step. Unearned badges read at 70% opacity. Min height 165pt so
the grid stays even.

### 8.4 Streak banner

Orange motif: 44×44 circle of `Color.orange.opacity(0.18)` with
`flame.fill` in `.orange`, headline + subhead, then 7 small circles
(stroked, fill orange when that day is completed) for the last 7 days.
Banner background `Color.orange.opacity(0.12)`, stroked 1.5pt at 40%.

### 8.5 In-progress accessory (iOS 26+)

`tabViewBottomAccessory` shows the most recently played, today's,
unfinished daily puzzle. Two layouts driven by
`\.tabViewBottomAccessoryPlacement`:

- `.inline` (collapsed): 22pt berryBlue circle with index, then
  `mm:ss` monospaced.
- Expanded: 32pt circle, "Today's {Difficulty}" + timer, trailing
  `play.fill`. Backed by `Color(.systemBackground)` so scrolling
  content doesn't bleed through the bar.

### 8.6 Solved overlay

Inside the grid frame, glass-card style, with:

- "Sweet!" in serif large title bold.
- Subtitle: "Today's standard puzzle, solved." (varies by source/
  difficulty).
- Stats card: "Your time" + "Streak", divider between.
- Buttons: "Next puzzle" (prominent), "Share my time" (secondary),
  conditional Pro upsell or "Next difficulty," and a final small
  `.caption secondary` "View grid" link to dismiss.

---

## 9. Architecture

SwiftUI + SwiftData + `@Observable`. **No external dependencies.** Swift
6 concurrency: `MainActor` is the default isolation for views and the
puzzle model; state types are explicitly main-actor isolated.

### 9.1 Layering

```
Views/        — Pure SwiftUI, no business logic beyond view state.
Models/       — Game domain (PuzzleModel, CellState, Theme, GameTimer,
                 BerrokuSchema with versioned @Model classes).
Services/     — System integrations (StoreKit, GameKit, notifications,
                 sound, the PuzzleSolver hint engine).
Resources/    — Bundled puzzles.json (3,300 puzzles).
```

### 9.2 State conventions

- `PuzzleModel` is the only big `@Observable` engine. Views observe it
  via `@Bindable`. Don't introduce parallel `@Published` mirrors.
- View state belongs in `@State` on the owning view. Cross-view shared
  state goes through `@Query` (SwiftData) or environment objects, not
  singletons.
- Per-session toggles (autoCheck, showTimer, fillHints,
  hapticsEnabled, soundEnabled) use `@AppStorage`. Booleans default to
  the "polite" choice (auto-check on, timer on, fill-hints off so the
  hint highlights rather than auto-fills).
- Walkthrough/tutorial gating: `hasSeenWalkthrough`,
  `hasCompletedTutorial` `@AppStorage` flags. Existing users who
  already saw the walkthrough silently mark the tutorial as complete
  so they aren't re-onboarded.

### 9.3 Persistence

Every `@Model` change must add a new `VersionedSchema` in
`BerrokuSchema.swift` with explicit defaults on new non-optional
properties, append it to `BerrokuMigrationPlan.schemas`, and add a
migration stage. The container is built with the explicit migration
plan so failure is loud (`fatalError`) — never silently reset the
store. See `CLAUDE.md` for the full checklist.

Saved per-puzzle state (`GameState`) keys on the
`(puzzleJSON, source, dateString | proSetNumber)` tuple, not on
`puzzleJSON` alone, because two daily dates can hash to the same
underlying `PuzzleDefinition`.

### 9.4 Game-engine invariants

- A drag is one undo unit per cell, but `erase` is one undo unit total
  (`eraseBatch`).
- Clue cells are seeded `.empty` and are non-interactive forever.
- `recordCompletion` only updates `fastestCompletionTime` for
  fully hint-free runs.
- `restart()` zeroes the board but **preserves** `hintCount` and the
  game timer's elapsed time — a hint-assisted puzzle stays
  hint-assisted, and the time spent before restart still counts.
- After every 3rd hint (3, 6, 9 …) the game shows a soft "Fresh
  start?" prompt — never blocking, always optional.
- Daily puzzle selection is deterministic via `cyrb53` of
  `"<day> <month> <year> <difficulty> <source> <setNumber>"` seeded
  with 42, ported from the JS version. Don't change the seed or
  hashing — it would shift everyone's daily puzzle.

### 9.5 Cross-platform (web parity)

This is a port of `circle9puzzle.com/bbtrio`. Keep the puzzle
selection hash, JSON schema, and difficulty names matching the web
version. Game Center IDs use lowercase `berroku` even though the bundle
is `Berroku` — that's intentional and registered in App Store Connect.

---

## 10. Things to NOT do

- Don't introduce a third-party dependency. The app is intentionally
  zero-dep.
- Don't replace the X mark with a dot, the rounded clue glyphs with
  default SF, or `Theme.berryBlue` with `.blue`.
- Don't surface errors instantly — keep the ~1s delay so dragging
  isn't punishing.
- Don't animate on the main path without a Reduce Motion fallback.
- Don't bypass `Theme` / asset-catalog colours by hardcoding
  `Color(red:green:blue:)` for game-grid content. Mascot illustrations
  are the only exception, and they have their own dedicated palette.
- Don't ship a SwiftData `@Model` change without bumping the schema
  version and adding a migration stage with defaults on new fields.
- Don't change the daily-selection hash, the puzzle JSON shape, or the
  `com.altthree.berroku.*` Game Center ID casing.
- Don't make the solved/restart copy clinical. Keep it warm
  ("Sweet!", "Fresh start?", "Streak going strong!").
