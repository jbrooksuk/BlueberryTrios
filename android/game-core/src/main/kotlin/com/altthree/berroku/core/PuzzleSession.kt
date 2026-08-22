package com.altthree.berroku.core

import kotlinx.serialization.Serializable

@Serializable
data class CellChange(
    val index: Int,
    val oldState: CellState,
    val newState: CellState,
)

@Serializable
data class PersistedCommand(val changes: List<CellChange>)

@Serializable
data class PersistedSession(
    val cellStates: String,
    val undo: List<PersistedCommand> = emptyList(),
    val redo: List<PersistedCommand> = emptyList(),
    val hintedCell: Int? = null,
    val hintCount: Int = 0,
    val madeMistake: Boolean = false,
    val solved: Boolean = false,
)

enum class SolveStatus { OK, ERROR, SOLVED }

data class CheckResult(
    val status: SolveStatus,
    val errorCells: Set<Int>,
    val errorGroups: Set<Int>,
    val satisfiedGroups: Set<Int>,
)

data class PuzzleSnapshot(
    val topology: PuzzleTopology,
    val cells: List<CellState>,
    val check: CheckResult,
    val canUndo: Boolean,
    val canRedo: Boolean,
    val isSolved: Boolean,
    val hintedCell: Int?,
    val hintCount: Int,
    val madeMistake: Boolean,
)

class PuzzleSession(
    val topology: PuzzleTopology,
    restored: PersistedSession? = null,
) {
    private val cells = MutableList(topology.definition.totalCells) { index ->
        if (topology.isInteractive(index)) CellState.UNDECIDED else CellState.EMPTY
    }
    private val undoStack = ArrayDeque<PersistedCommand>()
    private val redoStack = ArrayDeque<PersistedCommand>()
    private val solution = topology.definition.solution?.map(CellState::fromSymbol)

    private var activePaint: ActivePaint? = null

    var isSolved: Boolean = false
        private set
    var hintedCell: Int? = null
        private set
    var hintCount: Int = 0
        private set
    var madeMistake: Boolean = false
        private set
    var lastCheck: CheckResult = checkSolved()
        private set

    init {
        if (restored != null) restore(restored)
        updateCheck()
    }

    fun snapshot(): PuzzleSnapshot = PuzzleSnapshot(
        topology = topology,
        cells = cells.toList(),
        check = lastCheck,
        canUndo = undoStack.isNotEmpty(),
        canRedo = redoStack.isNotEmpty(),
        isSolved = isSolved,
        hintedCell = hintedCell,
        hintCount = hintCount,
        madeMistake = madeMistake,
    )

    fun beginPaint(index: Int) {
        if (isSolved || !topology.isInteractive(index)) return
        endPaint()
        hintedCell = null
        val transition = cells[index].next
        activePaint = ActivePaint(transition)
        continuePaint(index)
    }

    fun continuePaint(index: Int) {
        val paint = activePaint ?: return
        if (isSolved || !topology.isInteractive(index) || !paint.visited.add(index)) return
        val oldState = cells[index]
        if (oldState == paint.targetState) return
        applyState(index, paint.targetState)
        paint.changes += CellChange(index, oldState, paint.targetState)
        updateCheck()
    }

    fun endPaint() {
        val changes = activePaint?.changes.orEmpty()
        activePaint = null
        if (changes.isNotEmpty()) {
            undoStack.addLast(PersistedCommand(changes.toList()))
            redoStack.clear()
        }
    }

    fun tap(index: Int) {
        beginPaint(index)
        endPaint()
    }

    fun undo() {
        endPaint()
        val command = undoStack.removeLastOrNull() ?: return
        command.changes.asReversed().forEach { change -> cells[change.index] = change.oldState }
        redoStack.addLast(command)
        updateCheck()
    }

    fun redo() {
        endPaint()
        val command = redoStack.removeLastOrNull() ?: return
        command.changes.forEach { change -> cells[change.index] = change.newState }
        undoStack.addLast(command)
        updateCheck()
    }

    fun erase() {
        endPaint()
        val changes = topology.allCells.mapNotNull { index ->
            if (!topology.isInteractive(index) || cells[index] == CellState.UNDECIDED) {
                null
            } else {
                CellChange(index, cells[index], CellState.UNDECIDED)
            }
        }
        if (changes.isEmpty()) return
        changes.forEach { cells[it.index] = it.newState }
        undoStack.addLast(PersistedCommand(changes))
        redoStack.clear()
        hintedCell = null
        updateCheck()
    }

    /** Restart preserves hint count, matching the iOS game contract. */
    fun restart() {
        activePaint = null
        topology.allCells.forEach { index ->
            cells[index] = if (topology.isInteractive(index)) CellState.UNDECIDED else CellState.EMPTY
        }
        undoStack.clear()
        redoStack.clear()
        hintedCell = null
        madeMistake = false
        isSolved = false
        updateCheck()
    }

    fun useHint(fill: Boolean): SolveMove? {
        if (isSolved) return null
        val move = PuzzleSolver(topology, cells).findHint() ?: return null
        hintCount += 1
        val (index, state) = move.knowledge.first()
        if (fill) {
            applyCommand(index, state)
        } else {
            hintedCell = index
        }
        return move
    }

    fun revealHint(index: Int?) {
        hintedCell = index?.takeIf(topology::isInteractive)
    }

    fun checkSolved(): CheckResult {
        val errorGroups = linkedSetOf<Int>()
        val satisfiedGroups = linkedSetOf<Int>()

        topology.groups.forEachIndexed { groupIndex, group ->
            val berryCount = group.cells.count { cells[it] == CellState.BERRY }
            val undecidedCount = group.cells.count { cells[it] == CellState.UNDECIDED }
            if (berryCount > group.clue || berryCount + undecidedCount < group.clue) {
                errorGroups += groupIndex
            }
            // This intentionally matches iOS: remaining undecided non-berry
            // cells do not prevent a group (or puzzle) being satisfied.
            if (berryCount == group.clue) satisfiedGroups += groupIndex
        }

        val errorCells = errorGroups.flatMapTo(linkedSetOf()) { topology.groups[it].cells }
        val status = when {
            errorCells.isNotEmpty() -> SolveStatus.ERROR
            satisfiedGroups.size == topology.groups.size -> SolveStatus.SOLVED
            else -> SolveStatus.OK
        }
        return CheckResult(status, errorCells, errorGroups, satisfiedGroups)
    }

    fun export(): PersistedSession {
        endPaint()
        return PersistedSession(
            cellStates = cells.joinToString(separator = "") { it.symbol.toString() },
            undo = undoStack.toList(),
            redo = redoStack.toList(),
            hintedCell = hintedCell,
            hintCount = hintCount,
            madeMistake = madeMistake,
            solved = isSolved,
        )
    }

    private fun applyCommand(index: Int, state: CellState) {
        endPaint()
        if (!topology.isInteractive(index) || cells[index] == state) return
        val change = CellChange(index, cells[index], state)
        applyState(index, state)
        undoStack.addLast(PersistedCommand(listOf(change)))
        redoStack.clear()
        updateCheck()
    }

    private fun applyState(index: Int, state: CellState) {
        cells[index] = state
        if (!madeMistake && state != CellState.UNDECIDED) {
            val correct = solution?.getOrNull(index)
            if (correct != null && correct != state) madeMistake = true
        }
    }

    private fun updateCheck() {
        lastCheck = checkSolved()
        if (lastCheck.status == SolveStatus.SOLVED) isSolved = true
    }

    private fun restore(restored: PersistedSession) {
        restored.cellStates.forEachIndexed { index, symbol ->
            if (index in topology.allCells && topology.isInteractive(index)) {
                cells[index] = CellState.fromSymbol(symbol)
            }
        }
        undoStack.addAll(restored.undo)
        redoStack.addAll(restored.redo)
        hintedCell = restored.hintedCell?.takeIf(topology::isInteractive)
        hintCount = restored.hintCount
        madeMistake = restored.madeMistake
        isSolved = restored.solved
    }

    private class ActivePaint(val targetState: CellState) {
        val visited = linkedSetOf<Int>()
        val changes = mutableListOf<CellChange>()
    }
}
