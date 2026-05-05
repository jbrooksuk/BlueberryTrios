import Foundation
import SwiftData

// MARK: - Versioned schema

/// Version 1 of the Berroku persistent schema.
///
/// Frozen snapshot of the model shape that shipped before the
/// `hintUsed` -> `hintCount` migration. The nested classes exist solely so
/// SwiftData has a V1 `Schema` to compare against when deciding whether to
/// migrate an on-disk store to V2. Do not reference these nested types from
/// app code — use the top-level `GameState` / `PlayerStats` typealiases
/// which point at the current `SchemaV2` shapes.
enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [SchemaV1.GameState.self, SchemaV1.PlayerStats.self]
    }

    @Model final class GameState {
        var puzzleJSON: String = ""
        var cellStates: String = ""
        var undoHistory: String = ""
        var redoHistory: String = ""
        var elapsedTime: TimeInterval = 0
        var hintedCell: String = ""
        var hintUsed: Bool = false
        var solved: Bool = false
        var completionDate: Date?
        var source: String = "Daily"
        var difficulty: String = "Standard"
        var dateString: String = ""
        var proSetNumber: Int = 0

        init() {}
    }

    @Model final class PlayerStats {
        var totalPuzzlesCompleted: Int = 0
        var fastestCompletionTime: TimeInterval?
        var currentStreak: Int = 0
        var longestStreak: Int = 0
        var lastPlayedDate: Date?
        var totalHintsUsed: Int = 0

        init() {}
    }
}

/// Version 2 of the Berroku persistent schema.
///
/// Replaces the per-puzzle `hintUsed: Bool` with a `hintCount: Int` so
/// `PlayerStats.totalHintsUsed` can track every hint action rather than
/// just "puzzles solved with at least one hint."
enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [SchemaV2.GameState.self, SchemaV2.PlayerStats.self]
    }

    @Model final class GameState {
        var puzzleJSON: String
        var cellStates: String
        var undoHistory: String // Encoded undo stack: "r,c,old,new;r,c,old,new;..."
        var redoHistory: String = "" // Encoded redo stack (same format)
        var elapsedTime: TimeInterval
        var hintedCell: String = "" // Encoded hint cell: "r,c" or empty
        var hintCount: Int = 0
        var solved: Bool = false
        var completionDate: Date?
        var source: String
        var difficulty: String
        var dateString: String
        var proSetNumber: Int

        init(
            puzzleJSON: String,
            cellStates: String,
            undoHistory: String = "",
            redoHistory: String = "",
            elapsedTime: TimeInterval = 0,
            hintedCell: String = "",
            hintCount: Int = 0,
            solved: Bool = false,
            completionDate: Date? = nil,
            source: String = "Daily",
            difficulty: String = "Standard",
            dateString: String = "",
            proSetNumber: Int = 0
        ) {
            self.puzzleJSON = puzzleJSON
            self.cellStates = cellStates
            self.undoHistory = undoHistory
            self.redoHistory = redoHistory
            self.elapsedTime = elapsedTime
            self.hintedCell = hintedCell
            self.hintCount = hintCount
            self.solved = solved
            self.completionDate = completionDate
            self.source = source
            self.difficulty = difficulty
            self.dateString = dateString
            self.proSetNumber = proSetNumber
        }
    }

    @Model final class PlayerStats {
        var totalPuzzlesCompleted: Int
        var fastestCompletionTime: TimeInterval?
        var currentStreak: Int
        var longestStreak: Int
        var lastPlayedDate: Date?
        var totalHintsUsed: Int = 0

        init(
            totalPuzzlesCompleted: Int = 0,
            fastestCompletionTime: TimeInterval? = nil,
            currentStreak: Int = 0,
            longestStreak: Int = 0,
            lastPlayedDate: Date? = nil,
            totalHintsUsed: Int = 0
        ) {
            self.totalPuzzlesCompleted = totalPuzzlesCompleted
            self.fastestCompletionTime = fastestCompletionTime
            self.currentStreak = currentStreak
            self.longestStreak = longestStreak
            self.lastPlayedDate = lastPlayedDate
            self.totalHintsUsed = totalHintsUsed
        }

        /// Records a puzzle completion. `hintCount` is the number of hint
        /// actions the player took on the puzzle; fastest-time tracking is
        /// gated on a fully hint-free run (`hintCount == 0`). The running
        /// `totalHintsUsed` tally is updated at hint-press time (see
        /// GameView.useHint), so this method intentionally does not touch
        /// it — that lets the Hint helper achievement fire as soon as the
        /// hint button is pressed instead of waiting for completion.
        func recordCompletion(time: TimeInterval, date: Date, hintCount: Int = 0) {
            totalPuzzlesCompleted += 1

            // Only record fastest time for hint-free completions
            if hintCount == 0 {
                if let fastest = fastestCompletionTime {
                    if time < fastest {
                        fastestCompletionTime = time
                    }
                } else {
                    fastestCompletionTime = time
                }
            }

            let calendar = Calendar.current
            if let lastDate = lastPlayedDate {
                if calendar.isDate(date, inSameDayAs: lastDate) {
                    // Same day — streak unchanged
                } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: date),
                          calendar.isDate(yesterday, inSameDayAs: lastDate) {
                    currentStreak += 1
                    longestStreak = max(longestStreak, currentStreak)
                } else {
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }

            lastPlayedDate = date
        }
    }
}

/// Version 3 of the Berroku persistent schema.
///
/// Adds `lastPlayedAt: Date?` to `GameState` so the iOS 26 in-progress
/// tab-bar accessory can pick the most recently touched puzzle (rather
/// than the one with the most accumulated `elapsedTime`, which surfaced
/// "most invested" instead of "most recently active").
enum SchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)

    static var models: [any PersistentModel.Type] {
        [SchemaV3.GameState.self, SchemaV3.PlayerStats.self]
    }

    @Model final class GameState {
        var puzzleJSON: String
        var cellStates: String
        var undoHistory: String
        var redoHistory: String = ""
        var elapsedTime: TimeInterval
        var hintedCell: String = ""
        var hintCount: Int = 0
        var solved: Bool = false
        var completionDate: Date?
        var source: String
        var difficulty: String
        var dateString: String
        var proSetNumber: Int
        var lastPlayedAt: Date?

        init(
            puzzleJSON: String,
            cellStates: String,
            undoHistory: String = "",
            redoHistory: String = "",
            elapsedTime: TimeInterval = 0,
            hintedCell: String = "",
            hintCount: Int = 0,
            solved: Bool = false,
            completionDate: Date? = nil,
            source: String = "Daily",
            difficulty: String = "Standard",
            dateString: String = "",
            proSetNumber: Int = 0,
            lastPlayedAt: Date? = nil
        ) {
            self.puzzleJSON = puzzleJSON
            self.cellStates = cellStates
            self.undoHistory = undoHistory
            self.redoHistory = redoHistory
            self.elapsedTime = elapsedTime
            self.hintedCell = hintedCell
            self.hintCount = hintCount
            self.solved = solved
            self.completionDate = completionDate
            self.source = source
            self.difficulty = difficulty
            self.dateString = dateString
            self.proSetNumber = proSetNumber
            self.lastPlayedAt = lastPlayedAt
        }
    }

    @Model final class PlayerStats {
        var totalPuzzlesCompleted: Int
        var fastestCompletionTime: TimeInterval?
        var currentStreak: Int
        var longestStreak: Int
        var lastPlayedDate: Date?
        var totalHintsUsed: Int = 0

        init(
            totalPuzzlesCompleted: Int = 0,
            fastestCompletionTime: TimeInterval? = nil,
            currentStreak: Int = 0,
            longestStreak: Int = 0,
            lastPlayedDate: Date? = nil,
            totalHintsUsed: Int = 0
        ) {
            self.totalPuzzlesCompleted = totalPuzzlesCompleted
            self.fastestCompletionTime = fastestCompletionTime
            self.currentStreak = currentStreak
            self.longestStreak = longestStreak
            self.lastPlayedDate = lastPlayedDate
            self.totalHintsUsed = totalHintsUsed
        }

        /// Records a puzzle completion. `hintCount` is the number of hint
        /// actions the player took on the puzzle; fastest-time tracking is
        /// gated on a fully hint-free run (`hintCount == 0`). The running
        /// `totalHintsUsed` tally is updated at hint-press time (see
        /// GameView.useHint), so this method intentionally does not touch
        /// it — that lets the Hint helper achievement fire as soon as the
        /// hint button is pressed instead of waiting for completion.
        func recordCompletion(time: TimeInterval, date: Date, hintCount: Int = 0) {
            totalPuzzlesCompleted += 1

            if hintCount == 0 {
                if let fastest = fastestCompletionTime {
                    if time < fastest {
                        fastestCompletionTime = time
                    }
                } else {
                    fastestCompletionTime = time
                }
            }

            let calendar = Calendar.current
            if let lastDate = lastPlayedDate {
                if calendar.isDate(date, inSameDayAs: lastDate) {
                    // Same day — streak unchanged
                } else if let yesterday = calendar.date(byAdding: .day, value: -1, to: date),
                          calendar.isDate(yesterday, inSameDayAs: lastDate) {
                    currentStreak += 1
                    longestStreak = max(longestStreak, currentStreak)
                } else {
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }

            lastPlayedDate = date
        }
    }
}

// Typealiases so app code can keep referring to bare `GameState` /
// `PlayerStats` while the canonical definitions live inside the current
// schema version.
typealias GameState = SchemaV3.GameState
typealias PlayerStats = SchemaV3.PlayerStats

// MARK: - Migration plan

/// Migration plan for Berroku's SwiftData store.
///
/// Each entry in `schemas` is a frozen snapshot of the model shape at that
/// version. Each entry in `stages` describes how SwiftData should get from
/// one version to the next. For a lightweight (automatic) migration — which
/// is sufficient as long as every new property has a default value or is
/// optional — use `.lightweight(fromVersion:toVersion:)`.
///
/// For anything non-trivial (renaming a property, splitting an attribute,
/// backfilling from another model) use `.custom` instead.
enum BerrokuMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self, SchemaV3.self]
    }

    static var stages: [MigrationStage] {
        // V1 -> V2 drops `hintUsed` and adds `hintCount: Int = 0`. Both
        // shapes satisfy SwiftData's lightweight-migration constraints
        // (new attribute has a default value, dropped attribute simply
        // disappears). The prior hint-assisted flag on already-saved rows
        // is intentionally not backfilled — `PlayerStats.totalHintsUsed`
        // is the authoritative hint tally and is unaffected.
        //
        // V2 -> V3 adds `lastPlayedAt: Date?` to GameState. Optional, so
        // existing rows simply migrate with `nil` and the field gets
        // populated on the next save.
        [
            .lightweight(fromVersion: SchemaV1.self, toVersion: SchemaV2.self),
            .lightweight(fromVersion: SchemaV2.self, toVersion: SchemaV3.self),
        ]
    }
}
