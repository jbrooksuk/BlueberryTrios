import Foundation
import SwiftData

@Model
final class GameState {
    var puzzleJSON: String
    var cellStates: String
    var elapsedTime: TimeInterval
    var hintUsed: Bool
    var solved: Bool
    var completionDate: Date?
    var source: String
    var difficulty: String
    var dateString: String
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
