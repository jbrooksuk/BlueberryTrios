import Foundation

struct PuzzleSize: Codable {
    let rows: Int
    let columns: Int
}

struct PuzzleDefinition: Codable {
    let size: PuzzleSize
    let rowClues: [Int]
    let columnClues: [Int]
    let blockClues: [Int]
    let blocks: [Int]
    let cellClues: [Int?]
    let solution: String?

    var numRows: Int { size.rows }
    var numColumns: Int { size.columns }
    var totalCells: Int { size.rows * size.columns }

    func blockIndex(row: Int, column: Int) -> Int {
        blocks[row * numColumns + column]
    }

    func cellClue(row: Int, column: Int) -> Int? {
        cellClues[row * numColumns + column]
    }
}
