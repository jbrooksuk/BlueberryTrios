package com.altthree.berroku.core

enum class SolveTechnique { FILL, FULL, MIN_MAX, COMBOS, SOLUTION }

data class SolveMove(
    val technique: SolveTechnique,
    val groupIndex: Int?,
    val knowledge: List<Pair<Int, CellState>>,
)

class PuzzleSolver(
    private val topology: PuzzleTopology,
    cells: List<CellState>,
) {
    private val initialCells = cells.toList()

    fun findHint(): SolveMove? = findLogicalMove(initialCells) ?: findSolutionMove()

    private fun findLogicalMove(cells: List<CellState>): SolveMove? =
        findFillFullMove(cells) ?: findMinMaxMove(cells) ?: findDeepLookaheadMove(cells)

    private fun findFillFullMove(cells: List<CellState>): SolveMove? {
        topology.groups.forEachIndexed { groupIndex, group ->
            val counts = countStates(group.cells, cells)
            if (counts.undecided == 0) return@forEachIndexed

            if (counts.berry == group.clue) {
                val knowledge = group.cells
                    .filter { cells[it] == CellState.UNDECIDED }
                    .sorted()
                    .map { it to CellState.EMPTY }
                if (knowledge.isNotEmpty()) return SolveMove(SolveTechnique.FULL, groupIndex, knowledge)
            }

            if (counts.berry + counts.undecided == group.clue) {
                val knowledge = group.cells
                    .filter { cells[it] == CellState.UNDECIDED }
                    .sorted()
                    .map { it to CellState.BERRY }
                if (knowledge.isNotEmpty()) return SolveMove(SolveTechnique.FILL, groupIndex, knowledge)
            }
        }
        return null
    }

    private fun findMinMaxMove(cells: List<CellState>): SolveMove? {
        topology.groups.forEachIndexed primaryLoop@ { primaryIndex, primary ->
            if (countStates(primary.cells, cells).undecided == 0) return@primaryLoop

            topology.groups.forEachIndexed secondaryLoop@ { secondaryIndex, secondary ->
                if (primaryIndex == secondaryIndex) return@secondaryLoop
                val intersection = primary.cells.intersect(secondary.cells)
                val intersectionCounts = countStates(intersection, cells)
                if (intersectionCounts.undecided == 0) return@secondaryLoop

                val secondaryOnlyCounts = countStates(secondary.cells - primary.cells, cells)
                val maximum = minOf(
                    intersectionCounts.berry + intersectionCounts.undecided,
                    secondary.clue - secondaryOnlyCounts.berry,
                )
                val minimum = maxOf(
                    intersectionCounts.berry,
                    secondary.clue - secondaryOnlyCounts.berry - secondaryOnlyCounts.undecided,
                )

                if (minimum - intersectionCounts.berry == intersectionCounts.undecided) {
                    val knowledge = intersection.filter { cells[it] == CellState.UNDECIDED }
                        .sorted().map { it to CellState.BERRY }
                    if (knowledge.isNotEmpty()) return SolveMove(SolveTechnique.MIN_MAX, primaryIndex, knowledge)
                }

                if (maximum == intersectionCounts.berry) {
                    val knowledge = intersection.filter { cells[it] == CellState.UNDECIDED }
                        .sorted().map { it to CellState.EMPTY }
                    if (knowledge.isNotEmpty()) return SolveMove(SolveTechnique.MIN_MAX, primaryIndex, knowledge)
                }
            }
        }
        return null
    }

    private fun findDeepLookaheadMove(cells: List<CellState>): SolveMove? {
        topology.allCells.forEach { index ->
            if (!topology.isInteractive(index) || cells[index] != CellState.UNDECIDED) return@forEach
            for (testState in listOf(CellState.BERRY, CellState.EMPTY)) {
                val working = cells.toMutableList()
                working[index] = testState
                if (propagatesToContradiction(working)) {
                    val opposite = if (testState == CellState.BERRY) CellState.EMPTY else CellState.BERRY
                    return SolveMove(SolveTechnique.COMBOS, null, listOf(index to opposite))
                }
            }
        }
        return null
    }

    private fun findSolutionMove(): SolveMove? {
        val solution = topology.definition.solution?.map(CellState::fromSymbol) ?: return null
        var bestIndex: Int? = null
        var bestScore = Int.MIN_VALUE

        topology.allCells.forEach { index ->
            if (!topology.isInteractive(index) || initialCells[index] == solution[index]) return@forEach
            var score = 0
            if (initialCells[index] == CellState.UNDECIDED) score += 10
            if (solution[index] == CellState.BERRY) score += 5
            score += topology.neighboursOfCell[index].count { initialCells[it] != CellState.UNDECIDED }
            if (score > bestScore) {
                bestScore = score
                bestIndex = index
            }
        }

        val index = bestIndex ?: return null
        return SolveMove(SolveTechnique.SOLUTION, null, listOf(index to solution[index]))
    }

    private fun propagatesToContradiction(cells: MutableList<CellState>): Boolean {
        if (hasContradiction(cells)) return true

        repeat(200) {
            var changed = false

            topology.groups.forEach { group ->
                val counts = countStates(group.cells, cells)
                if (counts.undecided == 0) return@forEach
                val replacement = when {
                    counts.berry == group.clue -> CellState.EMPTY
                    counts.berry + counts.undecided == group.clue -> CellState.BERRY
                    else -> null
                }
                if (replacement != null) {
                    group.cells.filter { cells[it] == CellState.UNDECIDED }.forEach { index ->
                        cells[index] = replacement
                        changed = true
                    }
                }
            }

            topology.groups.forEach { primary ->
                topology.groups.forEach secondaryLoop@ { secondary ->
                    val intersection = primary.cells.intersect(secondary.cells)
                    val intersectionCounts = countStates(intersection, cells)
                    if (intersectionCounts.undecided == 0) return@secondaryLoop
                    val secondaryOnlyCounts = countStates(secondary.cells - primary.cells, cells)
                    val maximum = minOf(
                        intersectionCounts.berry + intersectionCounts.undecided,
                        secondary.clue - secondaryOnlyCounts.berry,
                    )
                    val minimum = maxOf(
                        intersectionCounts.berry,
                        secondary.clue - secondaryOnlyCounts.berry - secondaryOnlyCounts.undecided,
                    )
                    val replacement = when {
                        minimum - intersectionCounts.berry == intersectionCounts.undecided -> CellState.BERRY
                        maximum == intersectionCounts.berry -> CellState.EMPTY
                        else -> null
                    }
                    if (replacement != null) {
                        intersection.filter { cells[it] == CellState.UNDECIDED }.forEach { index ->
                            cells[index] = replacement
                            changed = true
                        }
                    }
                }
            }

            if (hasContradiction(cells)) return true
            if (!changed) return false
        }
        return false
    }

    private fun hasContradiction(cells: List<CellState>): Boolean = topology.groups.any { group ->
        val counts = countStates(group.cells, cells)
        counts.berry > group.clue || counts.berry + counts.undecided < group.clue
    }

    private fun countStates(indices: Set<Int>, cells: List<CellState>): StateCounts {
        var berry = 0
        var undecided = 0
        indices.forEach { index ->
            when (cells[index]) {
                CellState.BERRY -> berry += 1
                CellState.UNDECIDED -> undecided += 1
                CellState.EMPTY -> Unit
            }
        }
        return StateCounts(berry, undecided)
    }

    private data class StateCounts(val berry: Int, val undecided: Int)
}
