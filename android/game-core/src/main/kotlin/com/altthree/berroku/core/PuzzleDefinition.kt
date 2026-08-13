package com.altthree.berroku.core

import kotlinx.serialization.Serializable

@Serializable
data class PuzzleSize(
    val rows: Int,
    val columns: Int,
)

@Serializable
data class PuzzleDefinition(
    val size: PuzzleSize,
    val rowClues: List<Int>,
    val columnClues: List<Int>,
    val blockClues: List<Int>,
    val blocks: List<Int>,
    val cellClues: List<Int?>,
    val solution: String? = null,
) {
    val numRows: Int get() = size.rows
    val numColumns: Int get() = size.columns
    val totalCells: Int get() = numRows * numColumns

    fun blockIndex(row: Int, column: Int): Int = blocks[row * numColumns + column]

    fun cellClue(row: Int, column: Int): Int? = cellClues[row * numColumns + column]
}

enum class Difficulty(
    val seedName: String,
    val displayIndex: Int,
) {
    STANDARD("Standard", 1),
    ADVANCED("Advanced", 2),
    EXPERT("Expert", 3),
}

enum class PuzzleSource(val seedName: String) {
    DAILY("Daily"),
    PRO("Pro"),
}

@Serializable
enum class CellState(val symbol: Char) {
    UNDECIDED('_'),
    EMPTY('x'),
    BERRY('o');

    val next: CellState
        get() = when (this) {
            UNDECIDED -> EMPTY
            EMPTY -> BERRY
            BERRY -> UNDECIDED
        }

    companion object {
        fun fromSymbol(symbol: Char): CellState = entries.firstOrNull { it.symbol == symbol } ?: UNDECIDED
    }
}

@Serializable
data class CellId(
    val row: Int,
    val column: Int,
) : Comparable<CellId> {
    override fun compareTo(other: CellId): Int = compareValuesBy(this, other, CellId::row, CellId::column)
}
