package com.altthree.berroku.data

import android.content.Context
import com.altthree.berroku.core.Difficulty
import com.altthree.berroku.core.PersistedSession
import com.altthree.berroku.core.PuzzleSource
import java.time.LocalDate
import kotlinx.serialization.Serializable
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json

@Serializable
data class PersistedGame(
    val session: PersistedSession,
    val elapsedSeconds: Long,
)

class GameStore(context: Context) {
    private val preferences = context.getSharedPreferences("berroku_games_v1", Context.MODE_PRIVATE)
    private val json = Json {
        encodeDefaults = true
        ignoreUnknownKeys = true
    }

    fun read(
        date: LocalDate,
        difficulty: Difficulty,
        source: PuzzleSource,
        setNumber: Int,
    ): PersistedGame? = preferences.getString(key(date, difficulty, source, setNumber), null)
        ?.let { encoded -> runCatching { json.decodeFromString<PersistedGame>(encoded) }.getOrNull() }

    fun write(
        date: LocalDate,
        difficulty: Difficulty,
        source: PuzzleSource,
        setNumber: Int,
        game: PersistedGame,
    ) {
        preferences.edit()
            .putString(key(date, difficulty, source, setNumber), json.encodeToString(game))
            .apply()
    }

    private fun key(
        date: LocalDate,
        difficulty: Difficulty,
        source: PuzzleSource,
        setNumber: Int,
    ): String = listOf(
        "game-v1",
        date.toString(),
        difficulty.seedName,
        source.seedName,
        setNumber,
    ).joinToString(":")
}
