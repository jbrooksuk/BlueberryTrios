import Foundation
import SwiftData

@Model
final class PlayerStats {
    var totalPuzzlesCompleted: Int
    var fastestCompletionTime: TimeInterval?
    var currentStreak: Int
    var longestStreak: Int
    var lastPlayedDate: Date?

    init(
        totalPuzzlesCompleted: Int = 0,
        fastestCompletionTime: TimeInterval? = nil,
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        lastPlayedDate: Date? = nil
    ) {
        self.totalPuzzlesCompleted = totalPuzzlesCompleted
        self.fastestCompletionTime = fastestCompletionTime
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastPlayedDate = lastPlayedDate
    }

    func recordCompletion(time: TimeInterval, date: Date) {
        totalPuzzlesCompleted += 1

        if let fastest = fastestCompletionTime {
            if time < fastest {
                fastestCompletionTime = time
            }
        } else {
            fastestCompletionTime = time
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
