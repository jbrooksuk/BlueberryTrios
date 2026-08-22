package com.altthree.berroku.core

import java.time.LocalDate
import kotlinx.serialization.json.Json

data class PuzzleSelection(
    val index: Int,
    val definition: PuzzleDefinition,
    val seed: String,
)

class PuzzleCatalog private constructor(
    private val puzzlesByDifficulty: Map<String, List<PuzzleDefinition>>,
) {
    fun puzzles(difficulty: Difficulty): List<PuzzleDefinition> =
        puzzlesByDifficulty[difficulty.seedName].orEmpty()

    fun select(
        date: LocalDate,
        difficulty: Difficulty,
        source: PuzzleSource,
        setNumber: Int,
    ): PuzzleSelection? {
        val puzzles = puzzles(difficulty)
        if (puzzles.isEmpty()) return null

        // This string is a compatibility contract with PuzzleStore.swift.
        // Preserve spaces, local civil-date components, capitalization, and
        // the seed value unless both platforms migrate together.
        val seed = buildString {
            append(date.dayOfMonth)
            append(' ')
            append(date.monthValue)
            append(' ')
            append(date.year)
            append(' ')
            append(difficulty.seedName)
            append(' ')
            append(source.seedName)
            append(' ')
            append(setNumber)
        }
        val index = (cyrb53(seed, 42u) % puzzles.size.toULong()).toInt()
        return PuzzleSelection(index, puzzles[index], seed)
    }

    companion object {
        private val json = Json {
            ignoreUnknownKeys = false
            explicitNulls = true
        }

        fun fromJson(contents: String): PuzzleCatalog =
            PuzzleCatalog(json.decodeFromString<Map<String, List<PuzzleDefinition>>>(contents))

        /**
         * Exact port of the iOS/JavaScript cyrb53 implementation.
         *
         * Kotlin `Char` iteration visits UTF-16 code units, matching JS
         * `charCodeAt` and Swift's `.utf16`. UInt arithmetic deliberately wraps
         * at 32 bits, matching `Math.imul` and Swift's `&*` operations.
         */
        fun cyrb53(text: String, seed: UInt = 0u): ULong {
            var h1 = 0xdeadbeefu xor seed
            var h2 = 0x41c6ce57u xor seed

            for (character in text) {
                val codeUnit = character.code.toUInt()
                h1 = (h1 xor codeUnit) * 2_654_435_761u
                h2 = (h2 xor codeUnit) * 1_597_334_677u
            }

            h1 = (h1 xor (h1 shr 16)) * 2_246_822_507u
            h1 = h1 xor ((h2 xor (h2 shr 13)) * 3_266_489_909u)
            h2 = (h2 xor (h2 shr 16)) * 2_246_822_507u
            h2 = h2 xor ((h1 xor (h1 shr 13)) * 3_266_489_909u)

            return (h2 and 2_097_151u).toULong() * 4_294_967_296uL + h1.toULong()
        }
    }
}
