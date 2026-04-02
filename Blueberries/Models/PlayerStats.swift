import Foundation
import SwiftData

@Model
final class PlayerStats {
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

    func recordCompletion(time: TimeInterval, date: Date, hintUsed: Bool = false) {
        totalPuzzlesCompleted += 1

        if hintUsed {
            totalHintsUsed += 1
        }

        // Only record fastest time for hint-free completions
        if !hintUsed {
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
