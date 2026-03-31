import Testing
@testable import Blueberries

@Suite("CellState")
struct CellStateTests {
    @Test("Cycles undecided → empty → berry → undecided")
    func cycleThroughStates() {
        #expect(CellState.undecided.next == .empty)
        #expect(CellState.empty.next == .berry)
        #expect(CellState.berry.next == .undecided)
    }

    @Test("Raw values match expected characters")
    func rawValues() {
        #expect(CellState.undecided.rawValue == "_")
        #expect(CellState.empty.rawValue == "x")
        #expect(CellState.berry.rawValue == "o")
    }

    @Test("Initializes from raw value")
    func initFromRawValue() {
        #expect(CellState(rawValue: "_") == .undecided)
        #expect(CellState(rawValue: "x") == .empty)
        #expect(CellState(rawValue: "o") == .berry)
        #expect(CellState(rawValue: "z") == nil)
    }
}
