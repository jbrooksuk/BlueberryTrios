package com.altthree.berroku.home

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowForward
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.altthree.berroku.core.Difficulty
import com.altthree.berroku.ui.theme.BerrokuColors
import java.time.LocalDate
import java.time.format.FormatStyle
import java.time.format.DateTimeFormatter

@Composable
fun HomeScreen(
    date: LocalDate,
    onPlay: (Difficulty) -> Unit,
) {
    BoxWithConstraints(
        modifier = Modifier
            .fillMaxSize()
            .statusBarsPadding()
            .navigationBarsPadding(),
    ) {
        val horizontalPadding = if (maxWidth >= 600.dp) 32.dp else 20.dp
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .widthIn(max = 620.dp)
                .align(Alignment.TopCenter)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = horizontalPadding, vertical = 24.dp),
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(20.dp),
            ) {
                BerryClusterMark(Modifier.size(104.dp))
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(
                        text = "Berroku",
                        style = MaterialTheme.typography.displayMedium,
                        color = MaterialTheme.colorScheme.primary,
                    )
                    Text(
                        text = "Three berries. Every row, column and block.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }

            Spacer(Modifier.height(40.dp))

            Row(
                modifier = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(3.dp)) {
                    Text("Today", style = MaterialTheme.typography.headlineMedium)
                    Text(
                        text = date.format(DateTimeFormatter.ofLocalizedDate(FormatStyle.FULL)),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                Surface(
                    shape = CircleShape,
                    color = MaterialTheme.colorScheme.primaryContainer,
                ) {
                    Icon(
                        imageVector = Icons.Default.CalendarToday,
                        contentDescription = null,
                        tint = MaterialTheme.colorScheme.onPrimaryContainer,
                        modifier = Modifier.padding(12.dp),
                    )
                }
            }

            Spacer(Modifier.height(20.dp))

            Surface(
                shape = MaterialTheme.shapes.medium,
                color = MaterialTheme.colorScheme.surface,
                tonalElevation = 1.dp,
            ) {
                Column {
                    Difficulty.entries.forEachIndexed { index, difficulty ->
                        DifficultyRow(difficulty, onPlay)
                        if (index != Difficulty.entries.lastIndex) {
                            HorizontalDivider(
                                modifier = Modifier.padding(horizontal = 18.dp),
                                color = MaterialTheme.colorScheme.outline.copy(alpha = 0.28f),
                            )
                        }
                    }
                }
            }

            Spacer(Modifier.height(32.dp))

            Text(
                text = "Unlimited puzzles",
                style = MaterialTheme.typography.titleLarge,
            )
            Spacer(Modifier.height(10.dp))
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                Icon(
                    imageVector = Icons.Default.Lock,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                Column(Modifier.weight(1f)) {
                    Text("Pro puzzles", fontWeight = FontWeight.SemiBold)
                    Text(
                        "Coming after the daily game is settled.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }

            Spacer(Modifier.height(48.dp))
            Text(
                text = "A quiet puzzle, picked fresh each day.",
                modifier = Modifier.fillMaxWidth(),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center,
            )
        }
    }
}

@Composable
private fun DifficultyRow(
    difficulty: Difficulty,
    onPlay: (Difficulty) -> Unit,
) {
    Surface(
        onClick = { onPlay(difficulty) },
        color = Color.Transparent,
        contentColor = MaterialTheme.colorScheme.onSurface,
        modifier = Modifier.fillMaxWidth(),
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 18.dp, vertical = 17.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(16.dp),
        ) {
            Surface(
                shape = CircleShape,
                color = MaterialTheme.colorScheme.primaryContainer,
                modifier = Modifier.size(42.dp),
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Text(
                        text = difficulty.displayIndex.toString(),
                        color = MaterialTheme.colorScheme.onPrimaryContainer,
                        fontWeight = FontWeight.Bold,
                    )
                }
            }
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(difficulty.seedName, fontWeight = FontWeight.SemiBold)
                Text(
                    text = when (difficulty) {
                        Difficulty.STANDARD -> "A gentle place to begin"
                        Difficulty.ADVANCED -> "A little more deduction"
                        Difficulty.EXPERT -> "Every clue earns its keep"
                    },
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Icon(
                imageVector = Icons.AutoMirrored.Filled.ArrowForward,
                contentDescription = "Play ${difficulty.seedName}",
                tint = MaterialTheme.colorScheme.primary,
            )
        }
    }
}

@Composable
private fun BerryClusterMark(modifier: Modifier = Modifier) {
    Canvas(
        modifier = modifier.semantics {
            contentDescription = "Three illustrated blueberries"
        },
    ) {
        drawBerry(center = Offset(size.width * 0.34f, size.height * 0.42f), radius = size.minDimension * 0.25f)
        drawBerry(center = Offset(size.width * 0.67f, size.height * 0.38f), radius = size.minDimension * 0.23f)
        drawBerry(center = Offset(size.width * 0.53f, size.height * 0.69f), radius = size.minDimension * 0.26f)
    }
}

private fun DrawScope.drawBerry(center: Offset, radius: Float) {
    drawCircle(BerrokuColors.BerryBlue, radius, center)
    drawCircle(
        color = Color(0xFF9AC6F3),
        radius = radius * 0.29f,
        center = Offset(center.x - radius * 0.31f, center.y - radius * 0.35f),
    )
    drawCircle(Color(0xFF14233A), radius * 0.055f, Offset(center.x - radius * 0.27f, center.y + radius * 0.04f))
    drawCircle(Color(0xFF14233A), radius * 0.055f, Offset(center.x + radius * 0.27f, center.y + radius * 0.04f))
}
