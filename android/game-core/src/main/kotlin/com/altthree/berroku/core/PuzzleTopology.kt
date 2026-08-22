package com.altthree.berroku.core

sealed interface GroupId {
    data class Row(val index: Int) : GroupId
    data class Column(val index: Int) : GroupId
    data class Block(val index: Int) : GroupId
    data class Number(val cellIndex: Int) : GroupId
}

data class ConstraintGroup(
    val id: GroupId,
    val cells: Set<Int>,
    val clue: Int,
)

class PuzzleTopology private constructor(
    val definition: PuzzleDefinition,
    val groups: List<ConstraintGroup>,
    val groupsOfCell: List<List<Int>>,
    val neighboursOfCell: List<Set<Int>>,
    val clueForCell: List<Int?>,
    val blockOfCell: List<Int>,
) {
    val allCells: IntRange = 0 until definition.totalCells
    val clueCells: Set<Int> = clueForCell.indices.filterTo(linkedSetOf()) { clueForCell[it] != null }

    fun isInteractive(index: Int): Boolean = index in allCells && clueForCell[index] == null

    fun cellId(index: Int): CellId = CellId(index / definition.numColumns, index % definition.numColumns)

    fun cellIndex(cell: CellId): Int = cell.row * definition.numColumns + cell.column

    companion object {
        fun build(definition: PuzzleDefinition): PuzzleTopology {
            require(definition.totalCells > 0) { "Puzzle grid must not be empty" }
            require(definition.rowClues.size == definition.numRows)
            require(definition.columnClues.size == definition.numColumns)
            require(definition.blocks.size == definition.totalCells)
            require(definition.cellClues.size == definition.totalCells)

            val groups = mutableListOf<ConstraintGroup>()

            for (row in 0 until definition.numRows) {
                groups += ConstraintGroup(
                    GroupId.Row(row),
                    (0 until definition.numColumns).mapTo(linkedSetOf()) { column -> row * definition.numColumns + column },
                    definition.rowClues[row],
                )
            }

            for (column in 0 until definition.numColumns) {
                groups += ConstraintGroup(
                    GroupId.Column(column),
                    (0 until definition.numRows).mapTo(linkedSetOf()) { row -> row * definition.numColumns + column },
                    definition.columnClues[column],
                )
            }

            val blockCells = sortedMapOf<Int, MutableSet<Int>>()
            for (index in 0 until definition.totalCells) {
                blockCells.getOrPut(definition.blocks[index]) { linkedSetOf() }.add(index)
            }
            for ((block, cells) in blockCells) {
                require(block in definition.blockClues.indices) { "Missing clue for block $block" }
                groups += ConstraintGroup(GroupId.Block(block), cells, definition.blockClues[block])
            }

            val neighbours = List(definition.totalCells) { index ->
                val row = index / definition.numColumns
                val column = index % definition.numColumns
                buildSet {
                    for (rowOffset in -1..1) {
                        for (columnOffset in -1..1) {
                            if (rowOffset == 0 && columnOffset == 0) continue
                            val neighbourRow = row + rowOffset
                            val neighbourColumn = column + columnOffset
                            if (neighbourRow in 0 until definition.numRows &&
                                neighbourColumn in 0 until definition.numColumns
                            ) {
                                add(neighbourRow * definition.numColumns + neighbourColumn)
                            }
                        }
                    }
                }
            }

            for (index in 0 until definition.totalCells) {
                val clue = definition.cellClues[index] ?: continue
                val cells = neighbours[index].toMutableSet().apply { add(index) }
                groups += ConstraintGroup(GroupId.Number(index), cells.toSortedSet(), clue)
            }

            val groupsOfCell = List(definition.totalCells) { mutableListOf<Int>() }
            groups.forEachIndexed { groupIndex, group ->
                group.cells.forEach { cellIndex -> groupsOfCell[cellIndex] += groupIndex }
            }

            return PuzzleTopology(
                definition = definition,
                groups = groups,
                groupsOfCell = groupsOfCell,
                neighboursOfCell = neighbours,
                clueForCell = definition.cellClues,
                blockOfCell = definition.blocks,
            )
        }
    }
}
