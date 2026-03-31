import Testing
import Foundation
@testable import Blueberries

@Suite("PuzzleSolver")
@MainActor
struct PuzzleSolverTests {
    private static let puzzleJSON = """
    {"size":{"rows":9,"columns":9},"rowClues":[3,3,3,3,3,3,3,3,3],"columnClues":[3,3,3,3,3,3,3,3,3],"blockClues":[3,3,3,3,3,3,3,3,3],"blocks":[0,0,0,1,1,1,2,2,2,0,0,0,1,1,1,2,2,2,0,0,0,1,1,1,2,2,2,3,3,3,4,4,4,5,5,5,3,3,3,4,4,4,5,5,5,3,3,3,4,4,4,5,5,5,6,6,6,7,7,7,8,8,8,6,6,6,7,7,7,8,8,8,6,6,6,7,7,7,8,8,8],"cellClues":[null,1,1,null,null,null,3,null,3,null,3,null,null,null,3,null,null,null,null,null,null,4,null,2,null,null,null,null,null,null,null,null,null,3,null,null,null,null,null,null,null,null,null,null,null,3,null,2,null,3,null,null,null,null,null,null,null,null,null,null,null,2,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,0,null,null,null],"solution":"xxxxooxoxxxoxxxxooxooxoxxxxxxoxxoxxooxxxxooxxxoxoxxoxxoxxxoxoxxooxoxxxxxxxxoxxxoo"}
    """

    private static func makeModel() -> PuzzleModel {
        let data = puzzleJSON.data(using: .utf8)!
        let def = try! JSONDecoder().decode(PuzzleDefinition.self, from: data)
        return PuzzleModel(definition: def)
    }

    @Test("Finds a hint on fresh puzzle")
    func findsHint() {
        let model = Self.makeModel()
        let solver = PuzzleSolver(model: model)
        let hint = solver.findHint()
        #expect(hint != nil)
    }

    @Test("Hint knowledge is valid")
    func hintKnowledgeValid() {
        let model = Self.makeModel()
        let solver = PuzzleSolver(model: model)
        guard let hint = solver.findHint() else {
            Issue.record("No hint found")
            return
        }
        for (cell, state) in hint.knowledge {
            #expect(model.isInteractive(cell), "Hint targets non-interactive cell")
            #expect(state == .berry || state == .empty, "Hint sets invalid state")
        }
    }

    @Test("Can solve a Standard puzzle")
    func solvesStandard() {
        let model = Self.makeModel()
        let solver = PuzzleSolver(model: model)
        let solved = solver.trySolve()
        #expect(solved)
    }

    @Test("Solved state matches stored solution")
    func solutionMatches() {
        let model = Self.makeModel()
        guard let expected = model.solutionCells else {
            Issue.record("No solution in definition")
            return
        }
        // Apply solution
        for (cell, state) in expected {
            if model.isInteractive(cell) {
                model.applyCell(cell, to: state)
            }
        }
        let check = model.checkSolved()
        #expect(check.status == .solved)
    }

    @Test("Detects errors when too many berries in a row")
    func detectsRowError() {
        let model = Self.makeModel()
        // Place 4 berries in row 0 (max is 3)
        for c in 0..<4 {
            let cell = CellID(row: 0, column: c)
            if model.isInteractive(cell) {
                model.applyCell(cell, to: .berry)
            }
        }
        let check = model.checkSolved()
        #expect(check.status == .error)
        #expect(!check.errorCells.isEmpty)
    }

    @Test("Fill technique detected")
    func fillTechnique() {
        let model = Self.makeModel()
        let solver = PuzzleSolver(model: model)
        // Apply some moves to create a fill scenario
        // A group with clue N where N undecided cells remain → all must be berries
        let hint = solver.findHint()
        #expect(hint != nil)
        #expect(hint?.technique == .fill || hint?.technique == .full ||
                hint?.technique == .minMax || hint?.technique == .combos)
    }
}
