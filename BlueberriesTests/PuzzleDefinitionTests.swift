import Testing
import Foundation
@testable import Blueberries

@Suite("PuzzleDefinition")
struct PuzzleDefinitionTests {
    private let sampleJSON = """
    {"size":{"rows":9,"columns":9},"rowClues":[3,3,3,3,3,3,3,3,3],"columnClues":[3,3,3,3,3,3,3,3,3],"blockClues":[3,3,3,3,3,3,3,3,3],"blocks":[0,0,0,1,1,1,2,2,2,0,0,0,1,1,1,2,2,2,0,0,0,1,1,1,2,2,2,3,3,3,4,4,4,5,5,5,3,3,3,4,4,4,5,5,5,3,3,3,4,4,4,5,5,5,6,6,6,7,7,7,8,8,8,6,6,6,7,7,7,8,8,8,6,6,6,7,7,7,8,8,8],"cellClues":[null,1,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null],"solution":"xoxxoxxxoxxxoxxxxooxooxoxxxxxxoxxoxxooxxxxooxxxoxoxxoxxoxxxoxoxxooxoxxxxxxxxoxxxoo"}
    """

    @Test("Decodes from JSON")
    func decodesJSON() throws {
        let data = sampleJSON.data(using: .utf8)!
        let def = try JSONDecoder().decode(PuzzleDefinition.self, from: data)
        #expect(def.numRows == 9)
        #expect(def.numColumns == 9)
        #expect(def.totalCells == 81)
    }

    @Test("Block index lookup")
    func blockIndex() throws {
        let data = sampleJSON.data(using: .utf8)!
        let def = try JSONDecoder().decode(PuzzleDefinition.self, from: data)
        #expect(def.blockIndex(row: 0, column: 0) == 0)
        #expect(def.blockIndex(row: 0, column: 3) == 1)
        #expect(def.blockIndex(row: 3, column: 3) == 4)
        #expect(def.blockIndex(row: 8, column: 8) == 8)
    }

    @Test("Cell clue lookup")
    func cellClue() throws {
        let data = sampleJSON.data(using: .utf8)!
        let def = try JSONDecoder().decode(PuzzleDefinition.self, from: data)
        #expect(def.cellClue(row: 0, column: 1) == 1)
        #expect(def.cellClue(row: 0, column: 0) == nil)
    }

    @Test("Solution is present")
    func solution() throws {
        let data = sampleJSON.data(using: .utf8)!
        let def = try JSONDecoder().decode(PuzzleDefinition.self, from: data)
        #expect(def.solution != nil)
        #expect(def.solution?.count == 81)
    }
}
