import Testing
import Foundation
@testable import Blueberries

@Suite("PlayerStats")
struct PlayerStatsTests {
    private func makeDate(day: Int, month: Int, year: Int) -> Date {
        var components = DateComponents()
        components.day = day
        components.month = month
        components.year = year
        components.hour = 12
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
}
