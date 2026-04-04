import Foundation
import SwiftData

@Model
final class GameState {
    var puzzleJSON: String
    var cellStates: String
    var undoHistory: String // Encoded undo stack: "r,c,old,new;r,c,old,new;..."
    var redoHistory: String = "" // Encoded redo stack (same format)
    var elapsedTime: TimeInterval
    var hintedCell: String = "" // Encoded hint cell: "r,c" or empty
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
        undoHistory: String = "",
        redoHistory: String = "",
        elapsedTime: TimeInterval = 0,
        hintedCell: String = "",
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
        self.undoHistory = undoHistory
        self.redoHistory = redoHistory
        self.elapsedTime = elapsedTime
        self.hintedCell = hintedCell
        self.hintUsed = hintUsed
        self.solved = solved
        self.completionDate = completionDate
        self.source = source
        self.difficulty = difficulty
        self.dateString = dateString
        self.proSetNumber = proSetNumber
    }
}
