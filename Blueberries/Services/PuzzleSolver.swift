import Foundation

struct SolveMove {
    enum Technique: String {
        case fill     // All remaining cells must be berries
        case full     // Group is full, remaining cells are empty
        case minMax   // Min/max reasoning across intersecting groups
        case combos   // Combinatorial analysis
    }

    let technique: Technique
    let group: GroupID?
    let knowledge: [CellID: CellState] // Deduced cell states
}

struct PuzzleSolver {
    let model: PuzzleModel

    /// Find the next hint move, if any
    func findHint() -> SolveMove? {
        let moves = findTechniques()
        return moves.first
    }

    /// Apply a hint move to the model
    func applyMove(_ move: SolveMove) {
        for (cell, state) in move.knowledge {
            if model.isInteractive(cell) {
                model.tapCell(cell)
                // Cycle until we reach the desired state
                while model.cells[cell] != state {
                    model.tapCell(cell)
                }
            }
        }
    }

    /// Solve the puzzle completely (used for validation)
    func trySolve() -> Bool {
        var workingCells = model.cells
        for _ in 0..<200 {
            let moves = findTechniquesInState(workingCells)
            if moves.isEmpty { break }
            for (cell, state) in moves[0].knowledge {
                workingCells[cell] = state
            }
        }
        // Check if solved
        return checkComplete(workingCells)
    }

    // MARK: - Technique Finding

    private func findTechniques() -> [SolveMove] {
        findTechniquesInState(model.cells)
    }

    private func findTechniquesInState(_ cells: [CellID: CellState]) -> [SolveMove] {
        var moves: [SolveMove] = []

        // Fill / Full techniques
        for (group, groupCells) in model.cellsOfGroup {
            guard let clue = model.clueForGroup[group] else { continue }
            let counts = countStates(in: groupCells, cells: cells)

            if counts.undecided == 0 { continue }

            // FULL: enough berries placed — mark remaining as empty
            if counts.berry == clue {
                var knowledge: [CellID: CellState] = [:]
                for cell in groupCells where cells[cell] == .undecided {
                    knowledge[cell] = .empty
                }
                if !knowledge.isEmpty {
                    moves.append(SolveMove(technique: .full, group: group, knowledge: knowledge))
                }
            }

            // FILL: remaining undecided must all be berries
            if counts.berry + counts.undecided == clue {
                var knowledge: [CellID: CellState] = [:]
                for cell in groupCells where cells[cell] == .undecided {
                    knowledge[cell] = .berry
                }
                if !knowledge.isEmpty {
                    moves.append(SolveMove(technique: .fill, group: group, knowledge: knowledge))
                }
            }
        }

        if !moves.isEmpty { return moves }

        // Min/Max techniques
        for (primaryGroup, primaryCells) in model.cellsOfGroup {
            guard let primaryClue = model.clueForGroup[primaryGroup] else { continue }
            let primaryCounts = countStates(in: primaryCells, cells: cells)
            if primaryCounts.undecided == 0 { continue }

            // Look at intersecting secondary groups
            for (secondaryGroup, secondaryCells) in model.cellsOfGroup {
                guard secondaryGroup != primaryGroup else { continue }
                guard let secondaryClue = model.clueForGroup[secondaryGroup] else { continue }

                let intersection = primaryCells.intersection(secondaryCells)
                if intersection.isEmpty { continue }

                let secondaryCounts = countStates(in: secondaryCells, cells: cells)
                let intersectionCounts = countStates(in: intersection, cells: cells)

                // Cells only in the secondary group (not in primary)
                let secondaryOnly = secondaryCells.subtracting(primaryCells)
                let secondaryOnlyCounts = countStates(in: secondaryOnly, cells: cells)

                // Maximum berries the secondary group can contribute to the intersection
                let maxFromIntersection = min(
                    intersectionCounts.berry + intersectionCounts.undecided,
                    secondaryClue - secondaryOnlyCounts.berry
                )
                // Minimum berries the secondary group must contribute to the intersection
                let minFromIntersection = max(
                    intersectionCounts.berry,
                    secondaryClue - secondaryOnlyCounts.berry - secondaryOnlyCounts.undecided
                )

                // If the primary group needs the maximum from this intersection
                let primaryNeedsFromIntersection = primaryClue - primaryCounts.berry
                let primaryOnlyCells = primaryCells.subtracting(secondaryCells)
                let primaryOnlyCounts = countStates(in: primaryOnlyCells, cells: cells)
                let maxFromPrimaryOnly = primaryOnlyCounts.berry + primaryOnlyCounts.undecided

                if primaryNeedsFromIntersection > maxFromPrimaryOnly + maxFromIntersection {
                    continue // Impossible
                }

                // MIN: intersection must provide minimum berries
                if minFromIntersection > intersectionCounts.berry && intersectionCounts.undecided > 0 {
                    let needed = minFromIntersection - intersectionCounts.berry
                    if needed == intersectionCounts.undecided {
                        var knowledge: [CellID: CellState] = [:]
                        for cell in intersection where cells[cell] == .undecided {
                            knowledge[cell] = .berry
                        }
                        if !knowledge.isEmpty {
                            moves.append(SolveMove(technique: .minMax, group: primaryGroup, knowledge: knowledge))
                        }
                    }
                }

                // MAX: intersection can provide at most maxFromIntersection berries
                if maxFromIntersection == intersectionCounts.berry && intersectionCounts.undecided > 0 {
                    var knowledge: [CellID: CellState] = [:]
                    for cell in intersection where cells[cell] == .undecided {
                        knowledge[cell] = .empty
                    }
                    if !knowledge.isEmpty {
                        moves.append(SolveMove(technique: .minMax, group: primaryGroup, knowledge: knowledge))
                    }
                }
            }
        }

        if !moves.isEmpty { return moves }

        // Shallow lookahead: try placing a berry/empty in each undecided cell and check for contradictions
        for cell in model.allCells where cells[cell] == .undecided && model.isInteractive(cell) {
            for testState in [CellState.berry, CellState.empty] {
                var testCells = cells
                testCells[cell] = testState
                if hasContradiction(testCells) {
                    let oppositeState: CellState = testState == .berry ? .empty : .berry
                    moves.append(SolveMove(technique: .combos, group: nil, knowledge: [cell: oppositeState]))
                    break
                }
            }
        }

        return moves
    }

    // MARK: - Helpers

    private struct StateCounts {
        var berry: Int = 0
        var empty: Int = 0
        var undecided: Int = 0
    }

    private func countStates(in groupCells: Set<CellID>, cells: [CellID: CellState]) -> StateCounts {
        var counts = StateCounts()
        for cell in groupCells {
            switch cells[cell] {
            case .berry: counts.berry += 1
            case .empty: counts.empty += 1
            case .undecided, .none: counts.undecided += 1
            }
        }
        return counts
    }

    private func hasContradiction(_ cells: [CellID: CellState]) -> Bool {
        for (group, groupCells) in model.cellsOfGroup {
            guard let clue = model.clueForGroup[group] else { continue }
            let counts = countStates(in: groupCells, cells: cells)
            if counts.berry > clue { return true }
            if counts.berry + counts.undecided < clue { return true }
        }
        return false
    }

    private func checkComplete(_ cells: [CellID: CellState]) -> Bool {
        for (group, groupCells) in model.cellsOfGroup {
            guard let clue = model.clueForGroup[group] else { continue }
            let counts = countStates(in: groupCells, cells: cells)
            if counts.berry != clue { return false }
            if counts.undecided > 0 { return false }
        }
        return true
    }
}
