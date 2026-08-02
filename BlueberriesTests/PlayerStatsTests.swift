import Testing
import Foundation
@testable import Blueberries

@Suite("PlayerStats")
struct PlayerStatsTests {
    private func makeDate(day: Int, month: Int, year: Int, hour: Int = 12) -> Date {
        var components = DateComponents()
        components.day = day
        components.month = month
        components.year = year
        components.hour = hour
        return Calendar.current.date(from: components)!
    }

    @Test("Defaults to zero")
    func defaults() {
        let stats = PlayerStats()
        #expect(stats.totalPuzzlesCompleted == 0)
        #expect(stats.fastestCompletionTime == nil)
        #expect(stats.currentStreak == 0)
        #expect(stats.longestStreak == 0)
        #expect(stats.lastPlayedDate == nil)
    }

    @Test("Increments puzzle count")
    func incrementsPuzzleCount() {
        let stats = PlayerStats()
        stats.recordCompletion(time: 60, date: makeDate(day: 1, month: 1, year: 2026))
        #expect(stats.totalPuzzlesCompleted == 1)
        stats.recordCompletion(time: 60, date: makeDate(day: 1, month: 1, year: 2026))
        #expect(stats.totalPuzzlesCompleted == 2)
    }

    @Test("Tracks fastest time")
    func fastestTime() {
        let stats = PlayerStats()
        stats.recordCompletion(time: 120, date: makeDate(day: 1, month: 1, year: 2026))
        #expect(stats.fastestCompletionTime == 120)
        stats.recordCompletion(time: 60, date: makeDate(day: 1, month: 1, year: 2026))
        #expect(stats.fastestCompletionTime == 60)
        stats.recordCompletion(time: 90, date: makeDate(day: 1, month: 1, year: 2026))
        #expect(stats.fastestCompletionTime == 60) // stays at 60
    }

    @Test("First play starts streak at 1")
    func firstStreak() {
        let stats = PlayerStats()
        stats.recordCompletion(time: 60, date: makeDate(day: 1, month: 1, year: 2026))
        #expect(stats.currentStreak == 1)
    }

    @Test("Consecutive days increment streak")
    func consecutiveDays() {
        let stats = PlayerStats()
        stats.recordCompletion(time: 60, date: makeDate(day: 1, month: 1, year: 2026))
        stats.recordCompletion(time: 60, date: makeDate(day: 2, month: 1, year: 2026))
        #expect(stats.currentStreak == 2)
        stats.recordCompletion(time: 60, date: makeDate(day: 3, month: 1, year: 2026))
        #expect(stats.currentStreak == 3)
    }

    @Test("Same day doesn't change streak")
    func sameDayNoChange() {
        let stats = PlayerStats()
        stats.recordCompletion(time: 60, date: makeDate(day: 1, month: 1, year: 2026))
        stats.recordCompletion(time: 50, date: makeDate(day: 1, month: 1, year: 2026))
        #expect(stats.currentStreak == 1)
    }

    @Test("Skipping a day resets streak")
    func skippedDayResets() {
        let stats = PlayerStats()
        stats.recordCompletion(time: 60, date: makeDate(day: 1, month: 1, year: 2026))
        stats.recordCompletion(time: 60, date: makeDate(day: 2, month: 1, year: 2026))
        #expect(stats.currentStreak == 2)
        stats.recordCompletion(time: 60, date: makeDate(day: 4, month: 1, year: 2026)) // skipped day 3
        #expect(stats.currentStreak == 1)
    }

    @Test("Longest streak is tracked")
    func longestStreak() {
        let stats = PlayerStats()
        stats.recordCompletion(time: 60, date: makeDate(day: 1, month: 1, year: 2026))
        stats.recordCompletion(time: 60, date: makeDate(day: 2, month: 1, year: 2026))
        stats.recordCompletion(time: 60, date: makeDate(day: 3, month: 1, year: 2026))
        #expect(stats.longestStreak == 3)
        // Break streak
        stats.recordCompletion(time: 60, date: makeDate(day: 10, month: 1, year: 2026))
        #expect(stats.currentStreak == 1)
        #expect(stats.longestStreak == 3) // longest preserved
    }

    @Test("Updates lastPlayedDate")
    func updatesLastPlayed() {
        let stats = PlayerStats()
        let date = makeDate(day: 15, month: 6, year: 2026)
        stats.recordCompletion(time: 60, date: date)
        #expect(stats.lastPlayedDate != nil)
    }

    // MARK: - New achievement tracking (SchemaV4)

    @Test("New stat fields default to zero / false")
    func newDefaults() {
        let stats = PlayerStats()
        #expect(stats.proPuzzlesCompleted == 0)
        #expect(stats.flawlessStreak == 0)
        #expect(stats.bestFlawlessStreak == 0)
        #expect(stats.hasSolvedEarly == false)
        #expect(stats.dailySweepStreak == 0)
        #expect(stats.bestDailySweepStreak == 0)
        #expect(stats.lastSweepDate == nil)
    }

    @Test("Pro puzzles counted only for Pro completions")
    func proPuzzleCount() {
        let stats = PlayerStats()
        let date = makeDate(day: 1, month: 1, year: 2026)
        stats.recordCompletion(time: 60, date: date, isPro: true)
        stats.recordCompletion(time: 60, date: date, isPro: false)
        stats.recordCompletion(time: 60, date: date, isPro: true)
        #expect(stats.proPuzzlesCompleted == 2)
        #expect(stats.totalPuzzlesCompleted == 3)
    }

    @Test("Flawless streak grows on clean solves")
    func flawlessStreakGrows() {
        let stats = PlayerStats()
        let date = makeDate(day: 1, month: 1, year: 2026)
        stats.recordCompletion(time: 60, date: date)
        stats.recordCompletion(time: 60, date: date)
        #expect(stats.flawlessStreak == 2)
        #expect(stats.bestFlawlessStreak == 2)
    }

    @Test("A hint breaks the flawless streak")
    func flawlessStreakBreaksOnHint() {
        let stats = PlayerStats()
        let date = makeDate(day: 1, month: 1, year: 2026)
        stats.recordCompletion(time: 60, date: date)
        stats.recordCompletion(time: 60, date: date)
        stats.recordCompletion(time: 60, date: date, hintCount: 1)
        #expect(stats.flawlessStreak == 0)
        #expect(stats.bestFlawlessStreak == 2) // best preserved
    }

    @Test("A mistake breaks the flawless streak")
    func flawlessStreakBreaksOnMistake() {
        let stats = PlayerStats()
        let date = makeDate(day: 1, month: 1, year: 2026)
        stats.recordCompletion(time: 60, date: date)
        stats.recordCompletion(time: 60, date: date, madeMistake: true)
        #expect(stats.flawlessStreak == 0)
        #expect(stats.bestFlawlessStreak == 1)
    }

    @Test("Early bird set only before 6am")
    func earlyBird() {
        let stats = PlayerStats()
        stats.recordCompletion(time: 60, date: makeDate(day: 1, month: 1, year: 2026, hour: 9))
        #expect(stats.hasSolvedEarly == false)
        stats.recordCompletion(time: 60, date: makeDate(day: 1, month: 1, year: 2026, hour: 5))
        #expect(stats.hasSolvedEarly == true)
    }

    @Test("Daily sweep streak counts consecutive days")
    func sweepStreakConsecutive() {
        let stats = PlayerStats()
        stats.recordDailySweep(date: makeDate(day: 1, month: 1, year: 2026))
        stats.recordDailySweep(date: makeDate(day: 2, month: 1, year: 2026))
        stats.recordDailySweep(date: makeDate(day: 3, month: 1, year: 2026))
        #expect(stats.dailySweepStreak == 3)
        #expect(stats.bestDailySweepStreak == 3)
    }

    @Test("Repeating a sweep on the same day does not double count")
    func sweepStreakSameDay() {
        let stats = PlayerStats()
        let date = makeDate(day: 1, month: 1, year: 2026)
        stats.recordDailySweep(date: date)
        stats.recordDailySweep(date: date)
        #expect(stats.dailySweepStreak == 1)
    }

    @Test("Skipping a day resets the sweep streak")
    func sweepStreakResets() {
        let stats = PlayerStats()
        stats.recordDailySweep(date: makeDate(day: 1, month: 1, year: 2026))
        stats.recordDailySweep(date: makeDate(day: 2, month: 1, year: 2026))
        stats.recordDailySweep(date: makeDate(day: 5, month: 1, year: 2026)) // gap
        #expect(stats.dailySweepStreak == 1)
        #expect(stats.bestDailySweepStreak == 2)
    }

    // MARK: - Streak revival (SchemaV5)

    @Test("Restore sets a lapsed streak to 7 days")
    func restoreLapsedStreak() {
        let stats = PlayerStats()
        stats.recordCompletion(time: 60, date: makeDate(day: 1, month: 1, year: 2026))
        // Streak is dead by day 5 (last play was day 1)
        stats.restoreStreak(date: makeDate(day: 5, month: 1, year: 2026))
        #expect(stats.currentStreak == 7)
        #expect(stats.streaksRestored == 1)
    }

    @Test("Restored streak continues with next-day completion")
    func restoredStreakContinues() {
        let stats = PlayerStats()
        stats.recordCompletion(time: 60, date: makeDate(day: 1, month: 1, year: 2026))
        stats.restoreStreak(date: makeDate(day: 5, month: 1, year: 2026))
        stats.recordCompletion(time: 60, date: makeDate(day: 6, month: 1, year: 2026))
        #expect(stats.currentStreak == 8)
    }

    @Test("Restore never lowers a live streak")
    func restoreKeepsLargerLiveStreak() {
        let stats = PlayerStats()
        for day in 1...10 {
            stats.recordCompletion(time: 60, date: makeDate(day: day, month: 1, year: 2026))
        }
        #expect(stats.currentStreak == 10)
        stats.restoreStreak(date: makeDate(day: 10, month: 1, year: 2026))
        #expect(stats.currentStreak == 10)
        #expect(stats.streaksRestored == 1)
    }

    @Test("Restore does not raise longest streak")
    func restoreDoesNotTouchLongest() {
        let stats = PlayerStats()
        stats.recordCompletion(time: 60, date: makeDate(day: 1, month: 1, year: 2026))
        stats.recordCompletion(time: 60, date: makeDate(day: 2, month: 1, year: 2026))
        stats.recordCompletion(time: 60, date: makeDate(day: 3, month: 1, year: 2026))
        #expect(stats.longestStreak == 3)
        stats.restoreStreak(date: makeDate(day: 10, month: 1, year: 2026))
        #expect(stats.currentStreak == 7)
        #expect(stats.longestStreak == 3)
    }

    @Test("Restore counts as playing today for streak liveness")
    func restoreKeepsStreakAlive() {
        let stats = PlayerStats()
        stats.recordCompletion(time: 60, date: makeDate(day: 1, month: 1, year: 2026))
        let revivalDate = makeDate(day: 5, month: 1, year: 2026)
        stats.restoreStreak(date: revivalDate)
        #expect(stats.lastPlayedDate == revivalDate)
    }
}
