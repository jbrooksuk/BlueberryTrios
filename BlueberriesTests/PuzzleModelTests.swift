import Testing
import Foundation
@testable import Blueberries

@Suite("PuzzleModel")
@MainActor
struct PuzzleModelTests {
    private static let puzzleJSON = """
    {"size":{"rows":9,"columns":9},"rowClues":[3,3,3,3,3,3,3,3,3],"columnClues":[3,3,3,3,3,3,3,3,3],"blockClues":[3,3,3,3,3,3,3,3,3],"blocks":[0,0,0,1,1,1,2,2,2,0,0,0,1,1,1,2,2,2,0,0,0,1,1,1,2,2,2,3,3,3,4,4,4,5,5,5,3,3,3,4,4,4,5,5,5,3,3,3,4,4,4,5,5,5,6,6,6,7,7,7,8,8,8,6,6,6,7,7,7,8,8,8,6,6,6,7,7,7,8,8,8],"cellClues":[null,1,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null],"solution":"xoxxoxxxoxxxoxxxxooxooxoxxxxxxoxxoxxooxxxxooxxxoxoxxoxxoxxxoxoxxooxoxxxxxxxxoxxxoo"}
    """

    private static func makeModel() -> PuzzleModel {
        let data = puzzleJSON.data(using: .utf8)!
        let def = try! JSONDecoder().decode(PuzzleDefinition.self, from: data)
        return PuzzleModel(definition: def)
    }

    @Test("Initializes with correct grid size")
    func gridSize() {
        let model = Self.makeModel()
        #expect(model.numRows == 9)
        #expect(model.numColumns == 9)
        #expect(model.allCells.count == 81)
    }

    @Test("Clue cells are not interactive")
    func clueCellsNotInteractive() {
        let model = Self.makeModel()
        let clueCell = CellID(row: 0, column: 1) // has clue "1"
        #expect(!model.isInteractive(clueCell))
        #expect(model.cells[clueCell] == .empty)
    }

    @Test("Non-clue cells are interactive")
    func nonClueCellsInteractive() {
        let model = Self.makeModel()
        let cell = CellID(row: 0, column: 0)
        #expect(model.isInteractive(cell))
        #expect(model.cells[cell] == .undecided)
    }

    @Test("Tap cycles cell state")
    func tapCycles() {
        let model = Self.makeModel()
        let cell = CellID(row: 0, column: 0)
        #expect(model.cells[cell] == .undecided)
        model.tapCell(cell)
        #expect(model.cells[cell] == .empty)
        model.tapCell(cell)
        #expect(model.cells[cell] == .berry)
        model.tapCell(cell)
        #expect(model.cells[cell] == .undecided)
    }

    @Test("Tap on clue cell does nothing")
    func tapClueCell() {
        let model = Self.makeModel()
        let clueCell = CellID(row: 0, column: 1)
        model.tapCell(clueCell)
        #expect(model.cells[clueCell] == .empty)
    }

    @Test("Apply cell sets specific state")
    func applyCell() {
        let model = Self.makeModel()
        let cell = CellID(row: 0, column: 0)
        model.applyCell(cell, to: .berry)
        #expect(model.cells[cell] == .berry)
    }

    @Test("Undo reverses last change")
    func undo() {
        let model = Self.makeModel()
        let cell = CellID(row: 0, column: 0)
        model.tapCell(cell)
        #expect(model.cells[cell] == .empty)
        model.undo()
        #expect(model.cells[cell] == .undecided)
    }

    @Test("Redo reapplies undone change")
    func redo() {
        let model = Self.makeModel()
        let cell = CellID(row: 0, column: 0)
        model.tapCell(cell)
        model.undo()
        model.redo()
        #expect(model.cells[cell] == .empty)
    }

    @Test("Undo all rewinds to start")
    func undoAll() {
        let model = Self.makeModel()
        let cell1 = CellID(row: 0, column: 0)
        let cell2 = CellID(row: 1, column: 0)
        model.tapCell(cell1)
        model.tapCell(cell2)
        model.undoAll()
        #expect(model.cells[cell1] == .undecided)
        #expect(model.cells[cell2] == .undecided)
    }

    @Test("Erase resets all interactive cells")
    func erase() {
        let model = Self.makeModel()
        let cell = CellID(row: 0, column: 0)
        model.applyCell(cell, to: .berry)
        model.erase()
        #expect(model.cells[cell] == .undecided)
    }

    @Test("Erase preserves clue cells")
    func erasePreservesClues() {
        let model = Self.makeModel()
        let clueCell = CellID(row: 0, column: 1)
        model.erase()
        #expect(model.cells[clueCell] == .empty)
    }

    @Test("canUndo and canRedo track state")
    func undoRedoState() {
        let model = Self.makeModel()
        #expect(!model.canUndo)
        #expect(!model.canRedo)
        model.tapCell(CellID(row: 0, column: 0))
        #expect(model.canUndo)
        #expect(!model.canRedo)
        model.undo()
        #expect(!model.canUndo)
        #expect(model.canRedo)
    }

    @Test("Initial check is ok, not solved")
    func initialCheck() {
        let model = Self.makeModel()
        let check = model.checkSolved()
        #expect(check.status == .ok)
    }

    @Test("Tracks recently placed berries")
    func recentlyPlacedBerries() {
        let model = Self.makeModel()
        let cell = CellID(row: 0, column: 0)
        model.applyCell(cell, to: .berry)
        #expect(model.recentlyPlacedBerries.contains(cell))
    }

    @Test("Removing berry clears from recently placed")
    func removeBerryFromRecent() {
        let model = Self.makeModel()
        let cell = CellID(row: 0, column: 0)
        model.applyCell(cell, to: .berry)
        model.applyCell(cell, to: .empty)
        #expect(!model.recentlyPlacedBerries.contains(cell))
    }

    @Test("New change clears redo stack")
    func newChangeClearsRedo() {
        let model = Self.makeModel()
        let cell = CellID(row: 0, column: 0)
        model.tapCell(cell)
        model.undo()
        #expect(model.canRedo)
        model.tapCell(CellID(row: 1, column: 0))
        #expect(!model.canRedo)
    }

    @Test("Neighbors computed correctly for corner cell")
    func cornerNeighbors() {
        let model = Self.makeModel()
        let corner = CellID(row: 0, column: 0)
        let neighbors = model.neighborsOfCell[corner]!
        #expect(neighbors.count == 3) // right, below, diagonal
    }

    @Test("Neighbors computed correctly for center cell")
    func centerNeighbors() {
        let model = Self.makeModel()
        let center = CellID(row: 4, column: 4)
        let neighbors = model.neighborsOfCell[center]!
        #expect(neighbors.count == 8)
    }
}
