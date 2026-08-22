package com.altthree.berroku.ui

import androidx.activity.compose.BackHandler
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import com.altthree.berroku.core.Difficulty
import com.altthree.berroku.game.GameScreen
import com.altthree.berroku.home.HomeScreen
import java.time.Duration
import java.time.LocalDate
import java.time.ZoneId
import java.time.ZonedDateTime
import kotlinx.coroutines.delay

@Composable
fun BerrokuApp() {
    var today by remember { mutableStateOf(LocalDate.now()) }
    var dateClockVersion by remember { mutableIntStateOf(0) }
    var selectedDifficultyName by rememberSaveable { mutableStateOf<String?>(null) }
    val selectedDifficulty = selectedDifficultyName?.let(Difficulty::valueOf)
    val lifecycleOwner = LocalLifecycleOwner.current

    DisposableEffect(lifecycleOwner) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_START) {
                today = LocalDate.now()
                dateClockVersion += 1
            }
        }
        lifecycleOwner.lifecycle.addObserver(observer)
        onDispose { lifecycleOwner.lifecycle.removeObserver(observer) }
    }

    // Keep the seed's local civil date current even if the app stays open
    // across midnight. The zone is resolved each loop so a time-zone change
    // is picked up on the next boundary (and immediately on the next start).
    LaunchedEffect(dateClockVersion) {
        while (true) {
            val zone = ZoneId.systemDefault()
            val now = ZonedDateTime.now(zone)
            val nextMidnight = now.toLocalDate().plusDays(1).atStartOfDay(zone)
            val sleepMillis = Duration.between(now, nextMidnight).toMillis().coerceAtLeast(1_000)
            delay(sleepMillis)
            today = LocalDate.now()
        }
    }

    BackHandler(enabled = selectedDifficulty != null) {
        selectedDifficultyName = null
    }

    if (selectedDifficulty == null) {
        HomeScreen(
            date = today,
            onPlay = { difficulty -> selectedDifficultyName = difficulty.name },
        )
    } else {
        GameScreen(
            date = today,
            difficulty = selectedDifficulty,
            onBack = { selectedDifficultyName = null },
        )
    }
}
