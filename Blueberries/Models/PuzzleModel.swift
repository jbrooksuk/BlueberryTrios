import Foundation
import Observation

struct CellID: Hashable, Comparable {
    let row: Int
    let column: Int

    static func < (lhs: CellID, rhs: CellID) -> Bool {
        if lhs.row != rhs.row { return lhs.row < rhs.row }
        return lhs.column < rhs.column
    }
}

enum GroupID: Hashable {
    case row(Int)
    case column(Int)
    case block(Int)
    case number(CellID)
}

struct CellCommand {
    let cell: CellID
    let oldState: CellState
    let newState: CellState
}

struct CheckResult {
    var status: SolveStatus
    var errorCells: Set<CellID>
    var errorGroups: Set<GroupID>
    var satisfiedGroups: Set<GroupID>

    enum SolveStatus {
        case ok
        case error
        case solved
    }
}

@MainActor
@Observable
final class PuzzleModel {
    let definition: PuzzleDefinition
    let numRows: Int
    let numColumns: Int

    // Grid structure
    let allCells: [CellID]
    let cellsOfGroup: [GroupID: Set<CellID>]
    let groupsOfCell: [CellID: Set<GroupID>]
    let clueForGroup: [GroupID: Int]
    let clueForCell: [CellID: Int]
    let blockOfCell: [CellID: Int]

    // Neighbors for number clues (orthogonal + diagonal)
    let neighborsOfCell: [CellID: Set<CellID>]

    // Game state
    var cells: [CellID: CellState]
    var undoStack: [[CellCommand]] = []
    var redoStack: [[CellCommand]] = []
    var isSolved: Bool = false
    var lastCheck: CheckResult?

    // Hint
    var hintedCell: CellID?

    // Stored set for quick lookup (avoid recomputing)
    let clueCells: Set<CellID>

    var hintUsed: Bool = false

    init(definition: PuzzleDefinition) {
        self.definition = definition
        self.numRows = definition.numRows
        self.numColumns = definition.numColumns

        var allCells: [CellID] = []
        var cellsOfGroup: [GroupID: Set<CellID>] = [:]
        var groupsOfCell: [CellID: Set<GroupID>] = [:]
        var clueForGroup: [GroupID: Int] = [:]
        var clueForCell: [CellID: Int] = [:]
        var blockOfCell: [CellID: Int] = [:]
        var neighborsOfCell: [CellID: Set<CellID>] = [:]
        var cells: [CellID: CellState] = [:]

        // Initialize all cells
        for r in 0..<definition.numRows {
            for c in 0..<definition.numColumns {
                let cell = CellID(row: r, column: c)
                allCells.append(cell)
                groupsOfCell[cell] = []
                neighborsOfCell[cell] = []
            }
        }

        // Row groups
        for r in 0..<definition.numRows {
            let group = GroupID.row(r)
            let clue = definition.rowClues[r]
            clueForGroup[group] = clue
            var groupCells: Set<CellID> = []
            for c in 0..<definition.numColumns {
                let cell = CellID(row: r, column: c)
                groupCells.insert(cell)
                groupsOfCell[cell]?.insert(group)
            }
            cellsOfGroup[group] = groupCells
        }

        // Column groups
        for c in 0..<definition.numColumns {
            let group = GroupID.column(c)
            let clue = definition.columnClues[c]
            clueForGroup[group] = clue
            var groupCells: Set<CellID> = []
            for r in 0..<definition.numRows {
                let cell = CellID(row: r, column: c)
                groupCells.insert(cell)
                groupsOfCell[cell]?.insert(group)
            }
            cellsOfGroup[group] = groupCells
        }

        // Block groups
        var blockCells: [Int: Set<CellID>] = [:]
        for r in 0..<definition.numRows {
            for c in 0..<definition.numColumns {
                let cell = CellID(row: r, column: c)
                let b = definition.blockIndex(row: r, column: c)
                blockOfCell[cell] = b
                blockCells[b, default: []].insert(cell)
            }
        }
        let numBlocks = (blockCells.keys.max() ?? -1) + 1
        for b in 0..<numBlocks {
            let group = GroupID.block(b)
            let clue = definition.blockClues[b]
            clueForGroup[group] = clue
            let cells = blockCells[b] ?? []
            cellsOfGroup[group] = cells
            for cell in cells {
                groupsOfCell[cell]?.insert(group)
            }
        }

        // Compute neighbors (orthogonal + diagonal) for each cell
        for r in 0..<definition.numRows {
            for c in 0..<definition.numColumns {
                let cell = CellID(row: r, column: c)
                var neighbors: Set<CellID> = []
                for dr in -1...1 {
                    for dc in -1...1 {
                        if dr == 0 && dc == 0 { continue }
                        let nr = r + dr
                        let nc = c + dc
                        if nr >= 0 && nr < definition.numRows && nc >= 0 && nc < definition.numColumns {
                            neighbors.insert(CellID(row: nr, column: nc))
                        }
                    }
                }
                neighborsOfCell[cell] = neighbors
            }
        }

        // Number (cell) clue groups
        for r in 0..<definition.numRows {
            for c in 0..<definition.numColumns {
                if let clue = definition.cellClue(row: r, column: c) {
                    let cell = CellID(row: r, column: c)
                    clueForCell[cell] = clue
                    let group = GroupID.number(cell)
                    clueForGroup[group] = clue
                    // The group includes the cell itself and all its neighbors
                    var groupCells = neighborsOfCell[cell] ?? []
                    groupCells.insert(cell)
                    cellsOfGroup[group] = groupCells
                    for gc in groupCells {
                        groupsOfCell[gc]?.insert(group)
                    }
                }
            }
        }

        // Initial cell states: clue cells are 'x' (empty), others are undecided
        for cell in allCells {
            if clueForCell[cell] != nil {
                cells[cell] = .empty
            } else {
                cells[cell] = .undecided
            }
        }

        self.allCells = allCells
        self.cellsOfGroup = cellsOfGroup
        self.groupsOfCell = groupsOfCell
        self.clueForGroup = clueForGroup
        self.clueForCell = clueForCell
        self.blockOfCell = blockOfCell
        self.neighborsOfCell = neighborsOfCell
        self.cells = cells
        self.clueCells = Set(clueForCell.keys)
        self.lastCheck = checkSolved()
    }

    // MARK: - Cell State Management

    func isInteractive(_ cell: CellID) -> Bool {
        clueForCell[cell] == nil
    }

    func setCellState(_ cell: CellID, to newState: CellState) {
        guard isInteractive(cell) else { return }
        let oldState = cells[cell] ?? .undecided
        guard oldState != newState else { return }
        cells[cell] = newState
        let command = CellCommand(cell: cell, oldState: oldState, newState: newState)
        if let last = undoStack.last, !last.isEmpty {
            // During a drag, append to current batch
        } else {
            undoStack.append([command])
        }
        redoStack.removeAll()
        updateCheck()
    }

    func beginDrag() {
        undoStack.append([])
    }

    func dragSetCell(_ cell: CellID, to newState: CellState) {
        guard isInteractive(cell) else { return }
        let oldState = cells[cell] ?? .undecided
        guard oldState != newState else { return }
        cells[cell] = newState
        let command = CellCommand(cell: cell, oldState: oldState, newState: newState)
        if undoStack.isEmpty {
            undoStack.append([command])
        } else {
            undoStack[undoStack.count - 1].append(command)
        }
        redoStack.removeAll()
        updateCheck()
    }

    func endDrag() {
        // Remove empty batches
        if let last = undoStack.last, last.isEmpty {
            undoStack.removeLast()
        }
    }

    func tapCell(_ cell: CellID) {
        guard isInteractive(cell) else { return }
        let oldState = cells[cell] ?? .undecided
        let newState = oldState.next
        cells[cell] = newState
        undoStack.append([CellCommand(cell: cell, oldState: oldState, newState: newState)])
        redoStack.removeAll()
        updateCheck()
    }

    // MARK: - Undo / Redo

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func undo() {
        guard let batch = undoStack.popLast() else { return }
        for command in batch.reversed() {
            cells[command.cell] = command.oldState
        }
        redoStack.append(batch)
        updateCheck()
    }

    func redo() {
        guard let batch = redoStack.popLast() else { return }
        for command in batch {
            cells[command.cell] = command.newState
        }
        undoStack.append(batch)
        updateCheck()
    }

    func erase() {
        var batch: [CellCommand] = []
        for cell in allCells {
            if isInteractive(cell) {
                let oldState = cells[cell] ?? .undecided
                if oldState != .undecided {
                    batch.append(CellCommand(cell: cell, oldState: oldState, newState: .undecided))
                    cells[cell] = .undecided
                }
            }
        }
        if !batch.isEmpty {
            undoStack.append(batch)
            redoStack.removeAll()
        }
        updateCheck()
    }

    // MARK: - Validation

    func checkSolved() -> CheckResult {
        var errorGroups: Set<GroupID> = []
        var satisfiedGroups: Set<GroupID> = []

        for (group, groupCells) in cellsOfGroup {
            guard let clue = clueForGroup[group] else {
                satisfiedGroups.insert(group)
                continue
            }

            var berryCount = 0
            var undecidedCount = 0
            var emptyCount = 0

            for cell in groupCells {
                switch cells[cell] {
                case .berry: berryCount += 1
                case .undecided: undecidedCount += 1
                case .empty: emptyCount += 1
                case .none: undecidedCount += 1
                }
            }

            let isError = (berryCount + undecidedCount < clue) || (berryCount > clue)
            let isSatisfied = (berryCount == clue)

            if isError {
                errorGroups.insert(group)
            }
            if isSatisfied {
                satisfiedGroups.insert(group)
            }
        }

        var errorCells: Set<CellID> = []
        for group in errorGroups {
            if let groupCells = cellsOfGroup[group] {
                errorCells.formUnion(groupCells)
            }
        }

        let allSatisfied = satisfiedGroups.count == cellsOfGroup.count
        let hasErrors = !errorCells.isEmpty
        let status: CheckResult.SolveStatus = hasErrors ? .error : allSatisfied ? .solved : .ok

        return CheckResult(
            status: status,
            errorCells: errorCells,
            errorGroups: errorGroups,
            satisfiedGroups: satisfiedGroups
        )
    }

    private func updateCheck() {
        let result = checkSolved()
        lastCheck = result
        if result.status == .solved && !isSolved {
            isSolved = true
        }
    }

    // MARK: - Solution

    var solutionCells: [CellID: CellState]? {
        guard let solutionString = definition.solution else { return nil }
        var result: [CellID: CellState] = [:]
        for (i, char) in solutionString.enumerated() {
            guard i < allCells.count else { break }
            let cell = allCells[i]
            switch char {
            case "_": result[cell] = .undecided
            case "x": result[cell] = .empty
            case "o": result[cell] = .berry
            default: result[cell] = .undecided
            }
        }
        return result
    }
}
