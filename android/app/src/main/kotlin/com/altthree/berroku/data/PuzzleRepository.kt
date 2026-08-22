package com.altthree.berroku.data

import android.content.Context
import com.altthree.berroku.core.PuzzleCatalog
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

object PuzzleRepository {
    private val lock = Any()

    @Volatile
    private var cached: PuzzleCatalog? = null

    suspend fun catalogue(context: Context): PuzzleCatalog = withContext(Dispatchers.IO) {
        cached ?: synchronized(lock) {
            cached ?: context.assets.open("puzzles.json").bufferedReader().use { reader ->
                PuzzleCatalog.fromJson(reader.readText()).also { cached = it }
            }
        }
    }
}
