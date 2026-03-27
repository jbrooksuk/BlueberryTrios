import Foundation

enum Difficulty: String, CaseIterable, Identifiable, Codable {
    case standard = "Standard"
    case advanced = "Advanced"
    case expert = "Expert"

    var id: String { rawValue }

    var displayIndex: Int {
        switch self {
        case .standard: return 1
        case .advanced: return 2
        case .expert: return 3
        }
    }
}

enum PuzzleSource: String, CaseIterable, Identifiable, Codable {
    case daily = "Daily"
    case pro = "Pro"

    var id: String { rawValue }
}

struct PuzzleStore {
    private let puzzlesByDifficulty: [String: [PuzzleDefinition]]

    init() {
        guard let url = Bundle.main.url(forResource: "puzzles", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: [PuzzleDefinition]].self, from: data) else {
            puzzlesByDifficulty = [:]
            return
        }
        puzzlesByDifficulty = decoded
    }

    func puzzles(for difficulty: Difficulty) -> [PuzzleDefinition] {
        puzzlesByDifficulty[difficulty.rawValue] ?? []
    }

    func dailyPuzzle(date: Date, difficulty: Difficulty) -> PuzzleDefinition? {
        selectPuzzle(date: date, difficulty: difficulty, source: .daily, setNumber: 0)
    }

    func proPuzzle(date: Date, difficulty: Difficulty, setNumber: Int) -> PuzzleDefinition? {
        selectPuzzle(date: date, difficulty: difficulty, source: .pro, setNumber: setNumber)
    }

    private func selectPuzzle(date: Date, difficulty: Difficulty, source: PuzzleSource, setNumber: Int) -> PuzzleDefinition? {
        let puzzleList = puzzles(for: difficulty)
        guard !puzzleList.isEmpty else { return nil }

        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        let dateString = "\(day) \(month) \(year)"
        let seed = "\(dateString) \(difficulty.rawValue) \(source.rawValue) \(setNumber)"
        let hash = cyrb53(seed)
        let index = Int(hash % UInt64(puzzleList.count))
        return puzzleList[index]
    }

    /// Port of the cyrb53 hash function from the original JS.
    /// Uses UInt32 to match Math.imul and .utf16 to match charCodeAt.
    private func cyrb53(_ str: String, seed: UInt32 = 0) -> UInt64 {
        var h1: UInt32 = 0xdeadbeef ^ seed
        var h2: UInt32 = 0x41c6ce57 ^ seed
        for ch in str.utf16 {
            let c = UInt32(ch)
            h1 = (h1 ^ c) &* 2654435761
            h2 = (h2 ^ c) &* 1597334677
        }
        h1 = (h1 ^ (h1 >> 16)) &* 2246822507
        h1 ^= (h2 ^ (h2 >> 13)) &* 3266489909
        h2 = (h2 ^ (h2 >> 16)) &* 2246822507
        h2 ^= (h1 ^ (h1 >> 13)) &* 3266489909
        return UInt64(2097151 & h2) &* 4294967296 &+ UInt64(h1)
    }
}
