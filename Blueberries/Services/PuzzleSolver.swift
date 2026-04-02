import Foundation

struct SolveMove {
    enum Technique: String {
        case fill     // All remaining cells must be berries
        case full     // Group is full, remaining cells are empty
        case minMax   // Min/max reasoning across intersecting groups
        case combos   // Deep lookahead with constraint propagation
        case solution // Fallback: derived from embedded solution
    }

    let technique: Technique
    let group: GroupID?
    let knowledge: [CellID: CellState] // Deduced cell states
}

struct PuzzleSolver {
    let model: PuzzleModel

    /// Find the next hint move, if any. Guaranteed to return a move if the puzzle is not solved.
    func findHint() -> SolveMove? {
        // Tier 1-3: logic-based deduction
        if let move = findLogicalMove() {
            return move
        }

        // Tier 4: solution fallback — always works
        return findSolutionMove()
    }

    /// Find a move using logic alone (no solution peeking)
    private func findLogicalMove() -> SolveMove? {
        let moves = findTechniquesInState(model.cells)
        return moves.first
    }

    /// Fallback: compare current state with embedded solution to find a correct cell
    private func findSolutionMove() -> SolveMove? {
        guard let solution = model.solutionCells else { return nil }

        // Prefer cells that are undecided (not yet touched)
        // Among those, prefer cells adjacent to already-placed berries (most useful)
        var bestCell: CellID?
        var bestScore = -1

        for cell in model.allCells {
            guard model.isInteractive(cell) else { continue }
            let current = model.cells[cell] ?? .undecided
            guard let correct = solution[cell] else { continue }

            // Only hint cells that are wrong or undecided
            guard current != correct else { continue }

            // Score: prefer undecided cells near existing berries (more helpful hints)
            var score = 0
            if current == .undecided { score += 10 }
            if correct == .berry { score += 5 } // Berry placements are more informative

            // Bonus for cells adjacent to already-resolved cells
            if let neighbors = model.neighborsOfCell[cell] {
                for neighbor in neighbors {
                    let neighborState = model.cells[neighbor] ?? .undecided
                    if neighborState != .undecided { score += 1 }
                }
            }

            if score > bestScore {
                bestScore = score
                bestCell = cell
            }
        }

        guard let cell = bestCell, let correct = solution[cell] else { return nil }
        return SolveMove(technique: .solution, group: nil, knowledge: [cell: correct])
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
        return checkComplete(workingCells)
    }

    // MARK: - Technique Finding

    private func findTechniquesInState(_ cells: [CellID: CellState]) -> [SolveMove] {
        var moves: [SolveMove] = []

        // Tier 1: Fill / Full techniques
        moves = findFillFullMoves(cells)
        if !moves.isEmpty { return moves }

        // Tier 2: Min/Max intersection reasoning
        moves = findMinMaxMoves(cells)
        if !moves.isEmpty { return moves }

        // Tier 3: Deep lookahead with constraint propagation
        moves = findDeepLookaheadMoves(cells)
        return moves
    }

    // MARK: - Tier 1: Fill / Full

    private func findFillFullMoves(_ cells: [CellID: CellState]) -> [SolveMove] {
        var moves: [SolveMove] = []

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

        return moves
    }

    // MARK: - Tier 2: Min/Max

    private func findMinMaxMoves(_ cells: [CellID: CellState]) -> [SolveMove] {
        var moves: [SolveMove] = []

        for (primaryGroup, primaryCells) in model.cellsOfGroup {
            guard model.clueForGroup[primaryGroup] != nil else { continue }
            let primaryCounts = countStates(in: primaryCells, cells: cells)
            if primaryCounts.undecided == 0 { continue }

            for (secondaryGroup, secondaryCells) in model.cellsOfGroup {
                guard secondaryGroup != primaryGroup else { continue }
                guard let secondaryClue = model.clueForGroup[secondaryGroup] else { continue }

                let intersection = primaryCells.intersection(secondaryCells)
                if intersection.isEmpty { continue }

                let intersectionCounts = countStates(in: intersection, cells: cells)
                if intersectionCounts.undecided == 0 { continue }

                let secondaryOnly = secondaryCells.subtracting(primaryCells)
                let secondaryOnlyCounts = countStates(in: secondaryOnly, cells: cells)

                let maxFromIntersection = min(
                    intersectionCounts.berry + intersectionCounts.undecided,
                    secondaryClue - secondaryOnlyCounts.berry
                )
                let minFromIntersection = max(
                    intersectionCounts.berry,
                    secondaryClue - secondaryOnlyCounts.berry - secondaryOnlyCounts.undecided
                )

                // MIN: intersection must provide at least minFromIntersection berries
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

                // MAX: intersection already has maximum berries
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

        return moves
    }

    // MARK: - Tier 3: Deep Lookahead with Constraint Propagation

    private func findDeepLookaheadMoves(_ cells: [CellID: CellState]) -> [SolveMove] {
        var moves: [SolveMove] = []

        for cell in model.allCells where cells[cell] == .undecided && model.isInteractive(cell) {
            for testState in [CellState.berry, CellState.empty] {
                var testCells = cells
                testCells[cell] = testState

                // Propagate all deductions from this assumption
                if propagateToContradiction(&testCells) {
                    // This assumption leads to a contradiction — the opposite must be true
                    let oppositeState: CellState = testState == .berry ? .empty : .berry
                    moves.append(SolveMove(technique: .combos, group: nil, knowledge: [cell: oppositeState]))
                    break
                }
            }
            // Return as soon as we find one deduction to keep hints incremental
            if !moves.isEmpty { return moves }
        }

        return moves
    }

    /// Propagate fill/full and min/max deductions until stable or contradiction found.
    /// Returns true if a contradiction is detected.
    private func propagateToContradiction(_ cells: inout [CellID: CellState]) -> Bool {
        // Check for immediate contradiction
        if hasContradiction(cells) { return true }

        // Iteratively apply deductions until no more changes
        for _ in 0..<200 {
            var changed = false

            // Apply fill/full
            for (group, groupCells) in model.cellsOfGroup {
                guard let clue = model.clueForGroup[group] else { continue }
                let counts = countStates(in: groupCells, cells: cells)
                if counts.undecided == 0 { continue }

                if counts.berry == clue {
                    for cell in groupCells where cells[cell] == .undecided {
                        cells[cell] = .empty
                        changed = true
                    }
                } else if counts.berry + counts.undecided == clue {
                    for cell in groupCells where cells[cell] == .undecided {
                        cells[cell] = .berry
                        changed = true
                    }
                }
            }

            // Apply min/max
            for (_, primaryCells) in model.cellsOfGroup {
                for (secondaryGroup, secondaryCells) in model.cellsOfGroup {
                    guard let secondaryClue = model.clueForGroup[secondaryGroup] else { continue }

                    let intersection = primaryCells.intersection(secondaryCells)
                    if intersection.isEmpty { continue }
                    let intersectionCounts = countStates(in: intersection, cells: cells)
                    if intersectionCounts.undecided == 0 { continue }

                    let secondaryOnly = secondaryCells.subtracting(primaryCells)
                    let secondaryOnlyCounts = countStates(in: secondaryOnly, cells: cells)

                    let maxFromIntersection = min(
                        intersectionCounts.berry + intersectionCounts.undecided,
                        secondaryClue - secondaryOnlyCounts.berry
                    )
                    let minFromIntersection = max(
                        intersectionCounts.berry,
                        secondaryClue - secondaryOnlyCounts.berry - secondaryOnlyCounts.undecided
                    )

                    if minFromIntersection > intersectionCounts.berry {
                        let needed = minFromIntersection - intersectionCounts.berry
                        if needed == intersectionCounts.undecided {
                            for cell in intersection where cells[cell] == .undecided {
                                cells[cell] = .berry
                                changed = true
                            }
                        }
                    }

                    if maxFromIntersection == intersectionCounts.berry {
                        for cell in intersection where cells[cell] == .undecided {
                            cells[cell] = .empty
                            changed = true
                        }
                    }
                }
            }

            if hasContradiction(cells) { return true }
            if !changed { break }
        }

        return false
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
