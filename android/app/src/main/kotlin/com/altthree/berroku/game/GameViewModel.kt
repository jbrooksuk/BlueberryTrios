package com.altthree.berroku.game

import android.app.Application
import android.os.SystemClock
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.altthree.berroku.core.Difficulty
import com.altthree.berroku.core.PuzzleSelection
import com.altthree.berroku.core.PuzzleSession
import com.altthree.berroku.core.PuzzleSnapshot
import com.altthree.berroku.core.PuzzleSource
import com.altthree.berroku.core.PuzzleTopology
import com.altthree.berroku.data.GameStore
import com.altthree.berroku.data.PersistedGame
import com.altthree.berroku.data.PuzzleRepository
import java.time.LocalDate
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

data class GameUiState(
    val loading: Boolean = true,
    val errorMessage: String? = null,
    val date: LocalDate,
    val difficulty: Difficulty,
    val selection: PuzzleSelection? = null,
    val puzzle: PuzzleSnapshot? = null,
    val elapsedSeconds: Long = 0,
    val showErrors: Boolean = false,
)

class GameViewModel(
    application: Application,
    private val difficulty: Difficulty,
    private val date: LocalDate,
) : AndroidViewModel(application) {
    private val source = PuzzleSource.DAILY
    private val setNumber = 0
    private val store = GameStore(application)

    private val mutableState = MutableStateFlow(GameUiState(date = date, difficulty = difficulty))
    val state: StateFlow<GameUiState> = mutableState.asStateFlow()

    private var session: PuzzleSession? = null
    private var elapsedBaseSeconds = 0L
    private var runningSinceMillis: Long? = null
    private var isForeground = false
    private var ticker: Job? = null
    private var errorDelay: Job? = null

    init {
        viewModelScope.launch {
            runCatching {
                val selection = requireNotNull(
                    PuzzleRepository.catalogue(application)
                        .select(date, difficulty, source, setNumber),
                )
                val saved = store.read(date, difficulty, source, setNumber)
                val loadedSession = PuzzleSession(PuzzleTopology.build(selection.definition), saved?.session)
                session = loadedSession
                elapsedBaseSeconds = saved?.elapsedSeconds ?: 0
                if (isForeground && !loadedSession.isSolved) startClock()
                mutableState.value = GameUiState(
                    loading = false,
                    date = date,
                    difficulty = difficulty,
                    selection = selection,
                    puzzle = loadedSession.snapshot(),
                    elapsedSeconds = elapsedBaseSeconds,
                )
            }.onFailure { error ->
                mutableState.value = mutableState.value.copy(
                    loading = false,
                    errorMessage = error.message ?: "The puzzle catalogue could not be opened.",
                )
            }
        }
    }

    fun setForeground(foreground: Boolean) {
        if (isForeground == foreground) return
        isForeground = foreground
        val loadedSession = session
        if (foreground && loadedSession != null && !loadedSession.isSolved) {
            startClock()
        } else if (!foreground) {
            stopClock()
            persist()
        }
    }

    fun beginPaint(index: Int) = mutateDuringGesture { beginPaint(index) }

    fun continuePaint(index: Int) = mutateDuringGesture { continuePaint(index) }

    fun endPaint() {
        session?.endPaint()
        afterMove(persist = true)
    }

    fun tap(index: Int) {
        session?.tap(index)
        afterMove(persist = true)
    }

    fun undo() {
        session?.undo()
        afterMove(persist = true)
    }

    fun redo() {
        session?.redo()
        afterMove(persist = true)
    }

    fun erase() {
        session?.erase()
        afterMove(persist = true)
    }

    fun useHint() {
        session?.useHint(fill = false)
        afterMove(persist = true, scheduleErrors = false)
    }

    fun manualCheck() {
        mutableState.value = mutableState.value.copy(
            puzzle = session?.snapshot(),
            showErrors = true,
        )
    }

    fun restart() {
        session?.restart()
        if (isForeground) startClock()
        afterMove(persist = true)
    }

    override fun onCleared() {
        stopClock()
        persist()
    }

    private fun mutateDuringGesture(action: PuzzleSession.() -> Unit) {
        session?.action()
        afterMove(persist = false)
    }

    private fun afterMove(persist: Boolean, scheduleErrors: Boolean = true) {
        val loadedSession = session ?: return
        if (loadedSession.isSolved) stopClock()
        mutableState.value = mutableState.value.copy(
            puzzle = loadedSession.snapshot(),
            elapsedSeconds = currentElapsedSeconds(),
            showErrors = false,
        )
        if (scheduleErrors && !loadedSession.isSolved) scheduleErrorReveal()
        if (persist) persist()
    }

    private fun scheduleErrorReveal() {
        errorDelay?.cancel()
        errorDelay = viewModelScope.launch {
            delay(1_000)
            mutableState.value = mutableState.value.copy(showErrors = true)
        }
    }

    private fun startClock() {
        if (runningSinceMillis == null) runningSinceMillis = SystemClock.elapsedRealtime()
        if (ticker?.isActive == true) return
        ticker = viewModelScope.launch {
            while (true) {
                val elapsed = currentElapsedSeconds()
                if (elapsed != mutableState.value.elapsedSeconds) {
                    mutableState.value = mutableState.value.copy(elapsedSeconds = elapsed)
                }
                delay(250)
            }
        }
    }

    private fun stopClock() {
        val started = runningSinceMillis
        if (started != null) {
            elapsedBaseSeconds += (SystemClock.elapsedRealtime() - started) / 1_000
            runningSinceMillis = null
        }
        ticker?.cancel()
        ticker = null
        mutableState.value = mutableState.value.copy(elapsedSeconds = elapsedBaseSeconds)
    }

    private fun currentElapsedSeconds(): Long {
        val started = runningSinceMillis ?: return elapsedBaseSeconds
        return elapsedBaseSeconds + (SystemClock.elapsedRealtime() - started) / 1_000
    }

    private fun persist() {
        val loadedSession = session ?: return
        store.write(
            date,
            difficulty,
            source,
            setNumber,
            PersistedGame(loadedSession.export(), currentElapsedSeconds()),
        )
    }

    class Factory(
        private val application: Application,
        private val difficulty: Difficulty,
        private val date: LocalDate,
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T =
            GameViewModel(application, difficulty, date) as T
    }
}
