import Testing
import Foundation
@testable import Blueberries

@Suite("PuzzleStore")
struct PuzzleStoreTests {
    @Test("Loads puzzles from bundle")
    func loadsPuzzles() {
        let store = PuzzleStore()
        #expect(store.puzzles(for: .standard).count == 2000)
        #expect(store.puzzles(for: .advanced).count == 2000)
        #expect(store.puzzles(for: .expert).count == 2000)
    }

    @Test("Daily puzzle is deterministic")
    func dailyDeterministic() {
        let store = PuzzleStore()
        let date = makeDate(day: 15, month: 6, year: 2026)
        let p1 = store.dailyPuzzle(date: date, difficulty: .standard)
        let p2 = store.dailyPuzzle(date: date, difficulty: .standard)
        #expect(p1?.cellClues == p2?.cellClues)
    }

    @Test("Different dates give different puzzles")
    func differentDates() {
        let store = PuzzleStore()
        let d1 = makeDate(day: 1, month: 1, year: 2026)
        let d2 = makeDate(day: 2, month: 1, year: 2026)
        let p1 = store.dailyPuzzle(date: d1, difficulty: .standard)
        let p2 = store.dailyPuzzle(date: d2, difficulty: .standard)
        #expect(p1?.cellClues != p2?.cellClues)
    }

    @Test("Different difficulties give different puzzles")
    func differentDifficulties() {
        let store = PuzzleStore()
        let date = makeDate(day: 15, month: 6, year: 2026)
        let std = store.dailyPuzzle(date: date, difficulty: .standard)
        let adv = store.dailyPuzzle(date: date, difficulty: .advanced)
        #expect(std?.cellClues != adv?.cellClues)
    }

    @Test("Pro puzzles differ by set number")
    func proSetNumbers() {
        let store = PuzzleStore()
        let date = makeDate(day: 15, month: 6, year: 2026)
        let p1 = store.proPuzzle(date: date, difficulty: .standard, setNumber: 0)
        let p2 = store.proPuzzle(date: date, difficulty: .standard, setNumber: 1)
        #expect(p1?.cellClues != p2?.cellClues)
    }

    @Test("All puzzles have solutions")
    func allHaveSolutions() {
        let store = PuzzleStore()
        for diff in Difficulty.allCases {
            for puzzle in store.puzzles(for: diff) {
                #expect(puzzle.solution != nil, "Missing solution in \(diff.rawValue)")
            }
        }
    }

    private func makeDate(day: Int, month: Int, year: Int) -> Date {
        var components = DateComponents()
        components.day = day
        components.month = month
        components.year = year
        return Calendar.current.date(from: components)!
    }
}
