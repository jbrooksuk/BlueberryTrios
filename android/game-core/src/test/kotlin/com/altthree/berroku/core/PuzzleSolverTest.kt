package com.altthree.berroku.core

import java.time.LocalDate
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import org.junit.Test

class PuzzleSolverTest {
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
    fun `fresh iOS puzzle yields a valid deterministic hint`() {
        val session = session()
        val first = assertNotNull(PuzzleSolver(session.topology, session.snapshot().cells).findHint())
        val second = assertNotNull(PuzzleSolver(session.topology, session.snapshot().cells).findHint())

        assertTrue(first.knowledge.isNotEmpty())
        assertTrue(first.knowledge.all { (index, state) ->
            session.topology.isInteractive(index) && state != CellState.UNDECIDED
        })
        assertTrue(first == second)
    }
}
