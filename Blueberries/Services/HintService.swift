import Foundation
import Observation

/// Manages the daily free hint allowance and purchased bonus hints.
///
/// Players get 3 free hints per calendar day. Once exhausted, they can
/// purchase consumable hint refill packs to continue receiving hints.
/// Bonus (purchased) hints carry over across days and never expire.
@MainActor
@Observable
final class HintService {
    /// Number of free hints granted each calendar day.
    static let dailyFreeHints = 3

    /// UserDefaults keys.
    private enum Keys {
        static let dailyHintsUsed = "hints.dailyUsed"
        static let lastHintDate = "hints.lastDate"
        static let bonusHints = "hints.bonus"
    }

    /// How many of today's free hints have been consumed.
    private(set) var dailyHintsUsed: Int

    /// Purchased hints that carry over across days.
    private(set) var bonusHints: Int

    init() {
        let defaults = UserDefaults.standard

        // Reset daily count if the stored date is not today.
        let storedDate = defaults.string(forKey: Keys.lastHintDate) ?? ""
        let today = HintService.todayString()
        if storedDate == today {
            dailyHintsUsed = defaults.integer(forKey: Keys.dailyHintsUsed)
        } else {
            dailyHintsUsed = 0
            defaults.set(0, forKey: Keys.dailyHintsUsed)
            defaults.set(today, forKey: Keys.lastHintDate)
        }

        bonusHints = defaults.integer(forKey: Keys.bonusHints)
    }

    // MARK: - Computed state

    /// Free hints still available today.
    var dailyHintsRemaining: Int {
        max(0, Self.dailyFreeHints - dailyHintsUsed)
    }

    /// Total hints available (daily + bonus).
    var totalHintsAvailable: Int {
        dailyHintsRemaining + bonusHints
    }

    /// Whether the player can use a hint right now.
    var canUseHint: Bool {
        totalHintsAvailable > 0
    }

    // MARK: - Actions

    /// Consumes one hint. Returns `true` if a hint was available and consumed.
    @discardableResult
    func consumeHint() -> Bool {
        resetDailyIfNeeded()

        if dailyHintsRemaining > 0 {
            dailyHintsUsed += 1
            persist()
            return true
        } else if bonusHints > 0 {
            bonusHints -= 1
            persist()
            return true
        }
        return false
    }

    /// Adds purchased hints to the bonus balance.
    func addBonusHints(_ count: Int) {
        bonusHints += count
        persist()
    }

    // MARK: - Persistence

    private func persist() {
        let defaults = UserDefaults.standard
        defaults.set(dailyHintsUsed, forKey: Keys.dailyHintsUsed)
        defaults.set(HintService.todayString(), forKey: Keys.lastHintDate)
        defaults.set(bonusHints, forKey: Keys.bonusHints)
    }

    /// Resets the daily counter if the calendar day has changed since the
    /// last recorded hint usage.
    private func resetDailyIfNeeded() {
        let defaults = UserDefaults.standard
        let storedDate = defaults.string(forKey: Keys.lastHintDate) ?? ""
        let today = HintService.todayString()
        if storedDate != today {
            dailyHintsUsed = 0
            defaults.set(0, forKey: Keys.dailyHintsUsed)
            defaults.set(today, forKey: Keys.lastHintDate)
        }
    }

    private static func todayString() -> String {
        let cal = Calendar.current
        let d = Date.now
        return "\(cal.component(.year, from: d))-\(cal.component(.month, from: d))-\(cal.component(.day, from: d))"
    }
}
