package com.altthree.berroku.core

import java.time.LocalDate
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import org.junit.Test

class PuzzleSessionTest {
    private fun session(): PuzzleSession {
        val json = requireNotNull(javaClass.classLoader?.getResource("puzzles.json")).readText()
        val definition = requireNotNull(
            PuzzleCatalog.fromJson(json).select(
                LocalDate.of(2026, 6, 15),
                Difficulty.STANDARD,
                PuzzleSource.DAILY,
                0,
            ),
        ).definition
        return PuzzleSession(PuzzleTopology.build(definition))
    }

    @Test
    fun `clue cells cannot change`() {
        val session = session()
        val clue = session.topology.clueCells.first()
        session.tap(clue)
        assertEquals(CellState.EMPTY, session.snapshot().cells[clue])
        assertFalse(session.snapshot().canUndo)
    }

    @Test
    fun `cell state follows the iOS cycle`() {
        val session = session()
        val cell = session.topology.allCells.first(session.topology::isInteractive)
        assertEquals(CellState.UNDECIDED, session.snapshot().cells[cell])
        session.tap(cell)
        assertEquals(CellState.EMPTY, session.snapshot().cells[cell])
        session.tap(cell)
        assertEquals(CellState.BERRY, session.snapshot().cells[cell])
        session.tap(cell)
        assertEquals(CellState.UNDECIDED, session.snapshot().cells[cell])
    }

    @Test
    fun `one drag is one undo command`() {
        val session = session()
        val cells = session.topology.allCells.filter(session.topology::isInteractive).take(3)
        session.beginPaint(cells.first())
        cells.drop(1).forEach(session::continuePaint)
        session.endPaint()

        assertTrue(cells.all { session.snapshot().cells[it] == CellState.EMPTY })
        session.undo()
        assertTrue(cells.all { session.snapshot().cells[it] == CellState.UNDECIDED })
        session.redo()
        assertTrue(cells.all { session.snapshot().cells[it] == CellState.EMPTY })
    }

    @Test
    fun `restore preserves state and command history`() {
        val original = session()
        val cells = original.topology.allCells.filter(original.topology::isInteractive).take(2)
        original.beginPaint(cells.first())
        original.continuePaint(cells.last())
        original.endPaint()

        val restored = PuzzleSession(original.topology, original.export())
        assertEquals(original.snapshot().cells, restored.snapshot().cells)
        restored.undo()
        assertTrue(cells.all { restored.snapshot().cells[it] == CellState.UNDECIDED })
    }

    @Test
    fun `embedded iOS solution satisfies every Android constraint`() {
        val session = session()
        val solution = assertNotNull(session.topology.definition.solution)

        solution.forEachIndexed { index, symbol ->
            if (!session.topology.isInteractive(index)) return@forEachIndexed
            when (CellState.fromSymbol(symbol)) {
                CellState.EMPTY -> session.tap(index)
                CellState.BERRY -> {
                    session.tap(index)
                    session.tap(index)
                }
                CellState.UNDECIDED -> Unit
            }
        }

        assertTrue(session.snapshot().isSolved)
        assertTrue(session.snapshot().check.errorCells.isEmpty())
    }

    @Test
    fun `restart preserves hint count but clears board and mistake flag`() {
        val session = session()
        val hint = assertNotNull(session.useHint(fill = false))
        val hintedIndex = hint.knowledge.first().first
        val correctState = CellState.fromSymbol(
            assertNotNull(session.topology.definition.solution)[hintedIndex],
        )
        val wrongState = if (correctState == CellState.BERRY) CellState.EMPTY else CellState.BERRY

        while (session.snapshot().cells[hintedIndex] != wrongState) session.tap(hintedIndex)
        assertTrue(session.snapshot().madeMistake)

        session.restart()

        assertEquals(1, session.snapshot().hintCount)
        assertFalse(session.snapshot().madeMistake)
        assertTrue(
            session.topology.allCells.all { index ->
                session.snapshot().cells[index] == if (session.topology.isInteractive(index)) {
                    CellState.UNDECIDED
                } else {
                    CellState.EMPTY
                }
            },
        )
    }
}
