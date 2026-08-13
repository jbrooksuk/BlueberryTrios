package com.altthree.berroku.core

import java.time.LocalDate
import kotlin.test.assertEquals
import kotlin.test.assertNotEquals
import kotlin.test.assertNotNull
import org.junit.Test

class PuzzleCatalogTest {
    private val catalog by lazy {
        val json = requireNotNull(javaClass.classLoader?.getResource("puzzles.json")).readText()
        PuzzleCatalog.fromJson(json)
    }

    @Test
    fun `catalogue is the exact six-thousand-puzzle iOS resource`() {
        Difficulty.entries.forEach { difficulty ->
            assertEquals(2_000, catalog.puzzles(difficulty).size)
        }
    }

    @Test
    fun `cyrb53 matches Swift parity fixtures`() {
        val fixtures = mapOf(
            "15 6 2026 Standard Daily 0" to 3_148_284_757_056_907uL,
            "15 6 2026 Advanced Daily 0" to 4_524_549_941_386_879uL,
            "15 6 2026 Expert Daily 0" to 1_585_399_588_196_278uL,
            "13 8 2026 Standard Daily 0" to 956_328_769_461_574uL,
            "15 6 2026 Standard Pro 0" to 2_881_334_161_874_746uL,
            "15 6 2026 Standard Pro 1" to 4_665_962_883_424_506uL,
        )

        fixtures.forEach { (seed, expected) ->
            assertEquals(expected, PuzzleCatalog.cyrb53(seed, 42u), seed)
        }
    }

    @Test
    fun `daily selection matches iOS catalogue indexes`() {
        val date = LocalDate.of(2026, 6, 15)
        assertEquals(907, catalog.select(date, Difficulty.STANDARD, PuzzleSource.DAILY, 0)?.index)
        assertEquals(879, catalog.select(date, Difficulty.ADVANCED, PuzzleSource.DAILY, 0)?.index)
        assertEquals(278, catalog.select(date, Difficulty.EXPERT, PuzzleSource.DAILY, 0)?.index)
    }

    @Test
    fun `same input always produces the same puzzle`() {
        val date = LocalDate.of(2026, 8, 13)
        val first = catalog.select(date, Difficulty.STANDARD, PuzzleSource.DAILY, 0)
        val second = catalog.select(date, Difficulty.STANDARD, PuzzleSource.DAILY, 0)
        assertNotNull(first)
        assertEquals(first.index, second?.index)
        assertEquals(first.definition, second?.definition)
    }

    @Test
    fun `pro set number remains part of the iOS-compatible seed`() {
        val date = LocalDate.of(2026, 6, 15)
        val first = catalog.select(date, Difficulty.STANDARD, PuzzleSource.PRO, 0)
        val second = catalog.select(date, Difficulty.STANDARD, PuzzleSource.PRO, 1)
        assertEquals(746, first?.index)
        assertEquals(506, second?.index)
        assertNotEquals(first?.definition, second?.definition)
    }
}
