package com.altthree.berroku.game

import android.graphics.Paint
import android.graphics.Typeface
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.weight
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.input.pointer.PointerId
import androidx.compose.ui.input.pointer.awaitEachGesture
import androidx.compose.ui.input.pointer.awaitFirstDown
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.semantics.traversalIndex
import androidx.compose.ui.unit.dp
import com.altthree.berroku.core.CellState
import com.altthree.berroku.core.GroupId
import com.altthree.berroku.core.PuzzleSnapshot
import com.altthree.berroku.ui.theme.BerrokuColors

private data class GridPalette(
    val berry: Color,
    val cell: Color,
    val thinLine: Color,
    val thickLine: Color,
    val clue: Color,
    val emptyMark: Color,
    val errorCell: Color,
    val errorText: Color,
    val hint: Color,
)

@Composable
fun PuzzleGrid(
    snapshot: PuzzleSnapshot,
    showErrors: Boolean,
    enabled: Boolean,
    onPaintStart: (Int) -> Unit,
    onPaint: (Int) -> Unit,
    onPaintEnd: () -> Unit,
    onCellClick: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    val dark = MaterialTheme.colorScheme.background == BerrokuColors.Navy
    val palette = if (dark) {
        GridPalette(
            berry = Color(0xFF5A9FE8),
            cell = Color(0xFF2C2C2E),
            thinLine = Color(0xFF555555),
            thickLine = Color(0xFFF5F8FC),
            clue = Color(0xFFF5F8FC),
            emptyMark = Color(0xFF999999),
            errorCell = Color(0xFF662638),
            errorText = Color(0xFFFF4D99),
            hint = Color(0x66FFBF1A),
        )
    } else {
        GridPalette(
            berry = Color(0xFF3584E4),
            cell = Color(0xFFF5F5F5),
            thinLine = Color(0xFF888888),
            thickLine = Color(0xFF172033),
            clue = Color(0xFF172033),
            emptyMark = Color(0xFF888888),
            errorCell = Color(0xFFFAD8E9),
            errorText = Color(0xFFD32169),
            hint = Color(0x66FFCC33),
        )
    }
    val topology = snapshot.topology
    val columns = topology.definition.numColumns
    val rows = topology.definition.numRows
    val currentPaintStart by rememberUpdatedState(onPaintStart)
    val currentPaint by rememberUpdatedState(onPaint)
    val currentPaintEnd by rememberUpdatedState(onPaintEnd)
    val currentCellClick by rememberUpdatedState(onCellClick)
    val cluePaint = remember {
        Paint(Paint.ANTI_ALIAS_FLAG).apply {
            textAlign = Paint.Align.CENTER
            typeface = Typeface.create(Typeface.DEFAULT, Typeface.BOLD)
        }
    }

    Box(
        modifier = modifier
            .fillMaxWidth()
            .aspectRatio(columns.toFloat() / rows),
    ) {
        Canvas(
            modifier = Modifier
                .fillMaxSize()
                .pointerInput(topology, enabled) {
                    if (!enabled) return@pointerInput
                    fun cellAt(position: Offset): Int? {
                        val cellSize = size.width.toFloat() / columns
                        val column = (position.x / cellSize).toInt()
                        val row = (position.y / cellSize).toInt()
                        if (row !in 0 until rows || column !in 0 until columns) return null
                        return row * columns + column
                    }

                    awaitEachGesture {
                        val down = awaitFirstDown(requireUnconsumed = false)
                        val pointerId: PointerId = down.id
                        cellAt(down.position)?.let(currentPaintStart)
                        try {
                            while (true) {
                                val event = awaitPointerEvent()
                                val change = event.changes.firstOrNull { it.id == pointerId } ?: break
                                if (!change.pressed) break
                                cellAt(change.position)?.let(currentPaint)
                                change.consume()
                            }
                        } finally {
                            currentPaintEnd()
                        }
                    }
                },
        ) {
            val cellSize = size.width / columns
            val inset = 1.dp.toPx()

            topology.allCells.forEach { index ->
                val row = index / columns
                val column = index % columns
                val topLeft = Offset(column * cellSize + inset, row * cellSize + inset)
                val cellDrawSize = Size(cellSize - inset * 2, cellSize - inset * 2)
                val background = when {
                    showErrors && index in snapshot.check.errorCells -> palette.errorCell
                    else -> palette.cell
                }
                drawRoundRect(background, topLeft, cellDrawSize, CornerRadius(2.dp.toPx()))
                if (snapshot.hintedCell == index) {
                    drawRoundRect(palette.hint, topLeft, cellDrawSize, CornerRadius(2.dp.toPx()))
                }
            }

            for (row in 1 until rows) {
                val y = row * cellSize
                drawLine(palette.thinLine.copy(alpha = 0.5f), Offset(0f, y), Offset(size.width, y), 0.5.dp.toPx())
            }
            for (column in 1 until columns) {
                val x = column * cellSize
                drawLine(palette.thinLine.copy(alpha = 0.5f), Offset(x, 0f), Offset(x, size.height), 0.5.dp.toPx())
            }

            topology.allCells.forEach { index ->
                val row = index / columns
                val column = index % columns
                val block = topology.blockOfCell[index]
                if (column < columns - 1 && block != topology.blockOfCell[index + 1]) {
                    val x = (column + 1) * cellSize
                    drawLine(
                        palette.thickLine,
                        Offset(x, row * cellSize),
                        Offset(x, (row + 1) * cellSize),
                        2.dp.toPx(),
                        StrokeCap.Round,
                    )
                }
                if (row < rows - 1 && block != topology.blockOfCell[index + columns]) {
                    val y = (row + 1) * cellSize
                    drawLine(
                        palette.thickLine,
                        Offset(column * cellSize, y),
                        Offset((column + 1) * cellSize, y),
                        2.dp.toPx(),
                        StrokeCap.Round,
                    )
                }
            }

            drawRoundRect(
                color = palette.thickLine,
                topLeft = Offset(1.25.dp.toPx(), 1.25.dp.toPx()),
                size = Size(size.width - 2.5.dp.toPx(), size.height - 2.5.dp.toPx()),
                cornerRadius = CornerRadius(5.dp.toPx()),
                style = Stroke(2.5.dp.toPx()),
            )

            topology.allCells.forEach { index ->
                val row = index / columns
                val column = index % columns
                val center = Offset((column + 0.5f) * cellSize, (row + 0.5f) * cellSize)
                val clue = topology.clueForCell[index]
                when {
                    clue != null -> {
                        val groupIndex = topology.groups.indexOfFirst { group ->
                            group.id == GroupId.Number(index)
                        }
                        val satisfied = groupIndex in snapshot.check.satisfiedGroups
                        val error = showErrors && groupIndex in snapshot.check.errorGroups
                        cluePaint.textSize = cellSize * 0.5f
                        cluePaint.color = (if (error) palette.errorText else palette.clue).toArgb()
                        cluePaint.alpha = if (satisfied) 64 else 255
                        val baseline = center.y - (cluePaint.ascent() + cluePaint.descent()) / 2f
                        drawContext.canvas.nativeCanvas.drawText(clue.toString(), center.x, baseline, cluePaint)
                    }
                    snapshot.cells[index] == CellState.BERRY -> {
                        val radius = cellSize * 0.3f
                        drawCircle(palette.berry, radius, center)
                        drawCircle(
                            Color.White.copy(alpha = 0.25f),
                            radius * 0.35f,
                            Offset(center.x - radius * 0.25f, center.y - radius * 0.3f),
                        )
                    }
                    snapshot.cells[index] == CellState.EMPTY -> {
                        val extent = cellSize * 0.12f
                        drawLine(
                            palette.emptyMark,
                            Offset(center.x - extent, center.y - extent),
                            Offset(center.x + extent, center.y + extent),
                            1.5.dp.toPx(),
                            StrokeCap.Round,
                        )
                        drawLine(
                            palette.emptyMark,
                            Offset(center.x + extent, center.y - extent),
                            Offset(center.x - extent, center.y + extent),
                            1.5.dp.toPx(),
                            StrokeCap.Round,
                        )
                    }
                }
            }
        }

        Column(Modifier.fillMaxSize()) {
            repeat(rows) { row ->
                Row(Modifier.weight(1f)) {
                    repeat(columns) { column ->
                        val index = row * columns + column
                        val clue = topology.clueForCell[index]
                        val state = snapshot.cells[index]
                        val hasError = showErrors && index in snapshot.check.errorCells
                        Box(
                            modifier = Modifier
                                .weight(1f)
                                .fillMaxSize()
                                .semantics {
                                    traversalIndex = index.toFloat()
                                    contentDescription = if (clue != null) {
                                        "Row ${row + 1}, column ${column + 1}, clue $clue"
                                    } else {
                                        "Row ${row + 1}, column ${column + 1}"
                                    }
                                    stateDescription = buildString {
                                        append(
                                            when {
                                                clue != null -> "Clue"
                                                state == CellState.UNDECIDED -> "Undecided"
                                                state == CellState.EMPTY -> "Crossed"
                                                else -> "Berry"
                                            },
                                        )
                                        if (hasError) append(", constraint error")
                                    }
                                    if (clue == null && enabled) {
                                        role = Role.Button
                                        onClick("Cycle cell") {
                                            currentCellClick(index)
                                            true
                                        }
                                    }
                                },
                        )
                    }
                }
            }
        }
    }
}

private fun Color.toArgb(): Int = android.graphics.Color.argb(
    (alpha * 255).toInt(),
    (red * 255).toInt(),
    (green * 255).toInt(),
    (blue * 255).toInt(),
)
