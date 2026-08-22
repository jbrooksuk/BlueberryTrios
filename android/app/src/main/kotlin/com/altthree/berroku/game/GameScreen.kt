package com.altthree.berroku.game

import android.app.Application
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.DeleteSweep
import androidx.compose.material.icons.filled.Lightbulb
import androidx.compose.material.icons.filled.Redo
import androidx.compose.material.icons.filled.RestartAlt
import androidx.compose.material.icons.filled.Undo
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.altthree.berroku.core.Difficulty
import java.time.LocalDate

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GameScreen(
    date: LocalDate,
    difficulty: Difficulty,
    onBack: () -> Unit,
) {
    val application = LocalContext.current.applicationContext as Application
    val factory = remember(application, difficulty, date) {
        GameViewModel.Factory(application, difficulty, date)
    }
    val gameViewModel: GameViewModel = viewModel(
        key = "daily:${date}:${difficulty.name}",
        factory = factory,
    )
    val state by gameViewModel.state.collectAsStateWithLifecycle()
    val lifecycleOwner = LocalLifecycleOwner.current

    DisposableEffect(lifecycleOwner, gameViewModel) {
        val observer = LifecycleEventObserver { _, event ->
            when (event) {
                Lifecycle.Event.ON_START -> gameViewModel.setForeground(true)
                Lifecycle.Event.ON_STOP -> gameViewModel.setForeground(false)
                else -> Unit
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        if (lifecycleOwner.lifecycle.currentState.isAtLeast(Lifecycle.State.STARTED)) {
            gameViewModel.setForeground(true)
        }
        onDispose {
            lifecycleOwner.lifecycle.removeObserver(observer)
            gameViewModel.setForeground(false)
        }
    }

    val puzzle = state.puzzle
    val solved = puzzle?.isSolved == true

    Scaffold(
        modifier = Modifier.fillMaxSize(),
        containerColor = MaterialTheme.colorScheme.background,
        topBar = {
            TopAppBar(
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background,
                    titleContentColor = MaterialTheme.colorScheme.onBackground,
                ),
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back to today's puzzles")
                    }
                },
                title = {
                    Column {
                        Text("Berroku", style = MaterialTheme.typography.titleLarge)
                        Text(
                            "Daily · ${difficulty.seedName}",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                },
                actions = {
                    Text(
                        text = formatElapsed(state.elapsedSeconds),
                        modifier = Modifier.padding(horizontal = 16.dp),
                        fontFamily = FontFamily.Monospace,
                        fontWeight = FontWeight.SemiBold,
                    )
                },
            )
        },
        bottomBar = {
            if (puzzle != null) {
                GameToolbar(
                    canUndo = puzzle.canUndo && !solved,
                    canRedo = puzzle.canRedo && !solved,
                    enabled = !solved,
                    onUndo = gameViewModel::undo,
                    onRedo = gameViewModel::redo,
                    onErase = gameViewModel::erase,
                    onHint = gameViewModel::useHint,
                    onCheck = gameViewModel::manualCheck,
                )
            }
        },
    ) { contentPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(contentPadding),
            contentAlignment = Alignment.Center,
        ) {
            when {
                state.loading -> CircularProgressIndicator()
                state.errorMessage != null -> ErrorState(state.errorMessage.orEmpty(), onBack)
                puzzle != null -> {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .widthIn(max = 620.dp)
                            .padding(horizontal = 12.dp, vertical = 16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 8.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(
                                text = "Puzzle ${difficulty.displayIndex}",
                                style = MaterialTheme.typography.labelLarge,
                                color = MaterialTheme.colorScheme.primary,
                            )
                            if (puzzle.hintCount > 0) {
                                Text(
                                    text = "${puzzle.hintCount} ${if (puzzle.hintCount == 1) "hint" else "hints"}",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                )
                            }
                        }
                        Spacer(Modifier.height(12.dp))
                        Box {
                            PuzzleGrid(
                                snapshot = puzzle,
                                showErrors = state.showErrors,
                                enabled = !solved,
                                onPaintStart = gameViewModel::beginPaint,
                                onPaint = gameViewModel::continuePaint,
                                onPaintEnd = gameViewModel::endPaint,
                                onCellClick = gameViewModel::tap,
                            )
                            androidx.compose.animation.AnimatedVisibility(
                                visible = solved,
                                enter = fadeIn(),
                                exit = fadeOut(),
                            ) {
                                SolvedOverlay(
                                    elapsedSeconds = state.elapsedSeconds,
                                    hintCount = puzzle.hintCount,
                                    onBack = onBack,
                                    onRestart = gameViewModel::restart,
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun GameToolbar(
    canUndo: Boolean,
    canRedo: Boolean,
    enabled: Boolean,
    onUndo: () -> Unit,
    onRedo: () -> Unit,
    onErase: () -> Unit,
    onHint: () -> Unit,
    onCheck: () -> Unit,
) {
    NavigationBar(
        containerColor = MaterialTheme.colorScheme.surface,
        tonalElevation = 0.dp,
    ) {
        NavigationBarItem(
            selected = false,
            onClick = onUndo,
            enabled = canUndo,
            icon = { Icon(Icons.Default.Undo, contentDescription = null) },
            label = { Text("Undo") },
        )
        NavigationBarItem(
            selected = false,
            onClick = onRedo,
            enabled = canRedo,
            icon = { Icon(Icons.Default.Redo, contentDescription = null) },
            label = { Text("Redo") },
        )
        NavigationBarItem(
            selected = false,
            onClick = onErase,
            enabled = enabled,
            icon = { Icon(Icons.Default.DeleteSweep, contentDescription = null) },
            label = { Text("Erase") },
        )
        NavigationBarItem(
            selected = false,
            onClick = onHint,
            enabled = enabled,
            icon = { Icon(Icons.Default.Lightbulb, contentDescription = null) },
            label = { Text("Hint") },
        )
        NavigationBarItem(
            selected = false,
            onClick = onCheck,
            enabled = enabled,
            icon = { Icon(Icons.Default.CheckCircle, contentDescription = null) },
            label = { Text("Check") },
        )
    }
}

@Composable
private fun SolvedOverlay(
    elapsedSeconds: Long,
    hintCount: Int,
    onBack: () -> Unit,
    onRestart: () -> Unit,
) {
    Surface(
        modifier = Modifier.fillMaxSize(),
        shape = MaterialTheme.shapes.small,
        color = MaterialTheme.colorScheme.surface.copy(alpha = 0.97f),
        tonalElevation = 4.dp,
    ) {
        Column(
            modifier = Modifier.padding(28.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
        ) {
            Text(
                text = "Sweet!",
                style = MaterialTheme.typography.displayMedium,
                color = MaterialTheme.colorScheme.primary,
            )
            Spacer(Modifier.height(8.dp))
            Text(
                text = "Today's puzzle, solved.",
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Spacer(Modifier.height(28.dp))
            Text(
                text = formatElapsed(elapsedSeconds),
                style = MaterialTheme.typography.headlineMedium,
                fontFamily = FontFamily.Monospace,
            )
            Text(
                text = if (hintCount == 0) "No hints" else "$hintCount ${if (hintCount == 1) "hint" else "hints"}",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Spacer(Modifier.height(32.dp))
            Button(onClick = onBack, modifier = Modifier.fillMaxWidth()) {
                Text("Back to today's puzzles")
            }
            TextButton(onClick = onRestart) {
                Icon(Icons.Default.RestartAlt, contentDescription = null)
                Text("Restart puzzle", modifier = Modifier.padding(start = 8.dp))
            }
        }
    }
}

@Composable
private fun ErrorState(message: String, onBack: () -> Unit) {
    Column(
        modifier = Modifier.padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Text("This puzzle could not be opened", style = MaterialTheme.typography.titleLarge)
        Text(
            message,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            style = MaterialTheme.typography.bodyMedium,
        )
        Button(onClick = onBack) { Text("Back to today's puzzles") }
    }
}

private fun formatElapsed(seconds: Long): String {
    val minutes = seconds / 60
    val remainder = seconds % 60
    return "%d:%02d".format(minutes, remainder)
}
