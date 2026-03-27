import Foundation
import SwiftData

@Model
final class GameState {
    var puzzleJSON: String
    var cellStates: String // Encoded cell states: "x_o_x..." matching allCells order
    var elapsedTime: TimeInterval
    var hintUsed: Bool
    var solved: Bool
    var completionDate: Date?
    var source: String // "Daily" or "Pro"
    var difficulty: String // "Standard", "Advanced", "Expert"
    var dateString: String // "25 3 2026" format for daily identification
    var proSetNumber: Int

    init(
        puzzleJSON: String,
        cellStates: String,
        elapsedTime: TimeInterval = 0,
        hintUsed: Bool = false,
        solved: Bool = false,
        completionDate: Date? = nil,
        source: String = "Daily",
        difficulty: String = "Standard",
        dateString: String = "",
        proSetNumber: Int = 0
    ) {
        self.puzzleJSON = puzzleJSON
        self.cellStates = cellStates
        self.elapsedTime = elapsedTime
        self.hintUsed = hintUsed
        self.solved = solved
        self.completionDate = completionDate
        self.source = source
        self.difficulty = difficulty
        self.dateString = dateString
        self.proSetNumber = proSetNumber
    }
}

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
                // Consecutive day
                currentStreak += 1
                longestStreak = max(longestStreak, currentStreak)
            } else {
                // Streak broken
                currentStreak = 1
            }
        } else {
            currentStreak = 1
        }

        lastPlayedDate = date
    }
}
