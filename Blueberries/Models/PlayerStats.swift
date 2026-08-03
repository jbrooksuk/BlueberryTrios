import Foundation

// The `PlayerStats` model lives inside the current schema version in
// BerrokuSchema.swift so each schema version can hold its own frozen
// snapshot for migrations. A top-level `typealias PlayerStats` (declared in
// BerrokuSchema.swift) lets the rest of the app keep using the short name.

extension PlayerStats {
    /// The streak as it stands *right now*, accounting for time elapsed
    /// since `lastPlayedDate`. `currentStreak` is only updated by
    /// `recordCompletion`, so a player whose last play was several days
    /// ago still has the old value stored — this property treats such a
    /// streak as broken (returns 0) until the next completion runs.
    var effectiveCurrentStreak: Int {
        guard let lastPlayed = lastPlayedDate else { return 0 }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let lastDay = calendar.startOfDay(for: lastPlayed)
        let daysSince = calendar.dateComponents([.day], from: lastDay, to: today).day ?? Int.max
        return daysSince <= 1 ? currentStreak : 0
    }
}
