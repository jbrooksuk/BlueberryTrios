import SwiftUI
import SwiftData
import StoreKit
import WidgetKit

struct GameView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var savedStates: [GameState]
    @Query private var statsRecords: [PlayerStats]

    var storeService: StoreKitService
    var gameCenterService: GameCenterService
    var puzzleStore: PuzzleStore

    @State private var model: PuzzleModel?
    @State private var source: PuzzleSource
    @State private var difficulty: Difficulty
    @State private var proSetNumber: Int = 0
    @State private var showSettings: Bool = false
    @State private var showWalkthrough: Bool = false
    @State private var showRestartSuggestion: Bool = false
    @State private var restartSuggestionShown: Bool = false
    @AppStorage("autoCheck") private var autoCheck: Bool = true
    @AppStorage("showTimer") private var showTimer: Bool = true
    @AppStorage("fillHints") private var fillHints: Bool = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true
    @State private var gameTimer = GameTimer()
    @State private var soundService = SoundService()
    @State private var cachedPuzzleKey: String?
    @ScaledMetric(relativeTo: .largeTitle) private var solvedIconSize: CGFloat = 48

    init(
        storeService: StoreKitService,
        gameCenterService: GameCenterService,
        puzzleStore: PuzzleStore,
        initialSource: PuzzleSource = .daily,
        initialDifficulty: Difficulty = .standard
    ) {
        self.storeService = storeService
        self.gameCenterService = gameCenterService
        self.puzzleStore = puzzleStore
        _source = State(initialValue: initialSource)
        _difficulty = State(initialValue: initialDifficulty)
    }

    private var stats: PlayerStats? {
        statsRecords.first
    }

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.requestReview) private var requestReview

    var body: some View {
        VStack(spacing: 0) {
            headerView
                .frame(maxWidth: 600)
            Spacer(minLength: 12)

            if let model {
                if horizontalSizeClass == .regular {
                    // iPad landscape: grid centered with more padding
                    PuzzleGridView(model: model, autoCheck: autoCheck, hapticsEnabled: hapticsEnabled, soundService: soundService, onStateChanged: saveCurrentState)
                        .padding(.horizontal, 40)
                } else {
                    PuzzleGridView(model: model, autoCheck: autoCheck, hapticsEnabled: hapticsEnabled, soundService: soundService, onStateChanged: saveCurrentState)
                        .padding(.horizontal, 8)
                }

                Spacer(minLength: 0)
            } else {
                Spacer()
                Text("No puzzle available")
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                if let model {
                    let solved = model.isSolved
                    Button { model.undo(); saveCurrentState() } label: {
                        Label("Undo", systemImage: "arrow.uturn.backward")
                    }
                    .disabled(!model.canUndo || solved)
                    .onLongPressGesture {
                        model.undoAll()
                        saveCurrentState()
                    }

                    Button { model.redo(); saveCurrentState() } label: {
                        Label("Redo", systemImage: "arrow.uturn.forward")
                    }
                    .disabled(!model.canRedo || solved)

                    Button { model.erase(); saveCurrentState() } label: {
                        Label("Erase", systemImage: "eraser")
                    }
                    .disabled(solved)

                    Button { useHint(model: model) } label: {
                        Label("Hint", systemImage: "lightbulb")
                    }
                    .disabled(solved)

                    Button { _ = model.checkSolved() } label: {
                        Label("Check", systemImage: "checkmark.circle")
                    }
                    .disabled(solved)
                    .opacity(autoCheck ? 0 : 1)
                    .accessibilityHidden(autoCheck)
                }
            }
        }
        .toolbarRole(.automatic)
        .toolbar(.hidden, for: .tabBar)
        .background(Theme.backgroundGradient)
        .navigationTitle("Berroku")
        .navigationBarTitleDisplayMode(.inline)
        .gesture(DragGesture())
        .task {
            UIApplication.shared.isIdleTimerDisabled = true
            soundService.isEnabled = soundEnabled
            loadPuzzle()
            updateWidgetData()
        }
        .onDisappear {
            saveCurrentState()
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: scenePhase) {
            if scenePhase == .background || scenePhase == .inactive {
                saveCurrentState()
            }
        }
        .onChange(of: source) {
            if source == .pro && !storeService.isProUnlocked {
                source = .daily
                return
            }
            loadPuzzle()
        }
        .sheet(isPresented: $showSettings) {
            settingsSheet
        }
        .fullScreenCover(isPresented: $showWalkthrough) {
            WalkthroughView(isPresented: $showWalkthrough)
        }
        .overlay {
            if model?.showSolvedOverlay == true {
                solvedOverlay
            } else if showRestartSuggestion {
                restartSuggestionOverlay
            }
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.3), value: model?.showSolvedOverlay)
        .animation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.3), value: showRestartSuggestion)
        .onChange(of: soundEnabled) { soundService.isEnabled = soundEnabled }
        .onChange(of: model?.isSolved) {
            if let model, model.isSolved, !model.showSolvedOverlay {
                soundService.playSolved()
                if reduceMotion {
                    model.celebrationProgress = 1
                    model.showSolvedOverlay = true
                    promptReviewIfNeeded()
                } else {
                    Task {
                        let steps = 18
                        for i in 1...steps {
                            model.celebrationProgress = Double(i) / Double(steps)
                            try? await Task.sleep(for: .milliseconds(50))
                        }
                        try? await Task.sleep(for: .milliseconds(300))
                        withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
                            model.showSolvedOverlay = true
                        }
                        try? await Task.sleep(for: .seconds(1))
                        promptReviewIfNeeded()
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Spacer()

                if showTimer {
                    TimerDisplayView(timer: gameTimer)
                }

                Button("Settings", systemImage: "gearshape") {
                    showSettings = true
                }
                .labelStyle(.iconOnly)
                .font(.title3)
            }

            HStack(spacing: 8) {
                Picker("Source", selection: $source) {
                    Text("Daily").tag(PuzzleSource.daily)
                    Text("Pro").tag(PuzzleSource.pro)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 160)
                .disabled(!storeService.isProUnlocked && source == .daily)

                if source == .pro && storeService.isProUnlocked {
                    Button("New Puzzle", systemImage: "plus", action: newProPuzzle)
                        .labelStyle(.iconOnly)
                        .font(.subheadline.bold())
                        .padding(6)
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(.rect(cornerRadius: 6))
                }

                Spacer()

                HStack(spacing: 4) {
                    ForEach(Difficulty.allCases) { diff in
                        Button {
                            difficulty = diff
                            loadPuzzle()
                        } label: {
                            let isCurrent = diff == difficulty
                            Text("\(diff.displayIndex)")
                                .font(.subheadline.weight(isCurrent ? .bold : .regular))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(isCurrent ? Color.accentColor : Color(.tertiarySystemFill))
                                .foregroundStyle(isCurrent ? .white : .primary)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Settings

    private var settingsSheet: some View {
        NavigationStack {
            SettingsFormView(
                storeService: storeService,
                onShowWalkthrough: {
                    showSettings = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showWalkthrough = true
                    }
                }
            )
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { showSettings = false }
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Solved Overlay

    private var solvedOverlay: some View {
        ZStack {
            if !reduceMotion {
                ConfettiView()
            }
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: solvedIconSize))
                    .foregroundStyle(.green)
                    .accessibilityHidden(true)
                    .symbolEffect(.bounce, isActive: !reduceMotion && model?.isSolved == true)
                Text("Solved!")
                    .font(.title.bold())
                TimerDisplayView(timer: gameTimer)
            if source == .pro && storeService.isProUnlocked {
                HStack(spacing: 12) {
                    Button("New Puzzle") {
                        newProPuzzle()
                    }
                    .adaptiveProminentButton()
                    Button("Next Difficulty") {
                        advanceToNextPuzzle()
                    }
                    .adaptiveSecondaryButton()
                }
            } else {
                VStack(spacing: 10) {
                    Button("Next Puzzle") {
                        advanceToNextPuzzle()
                    }
                    .adaptiveProminentButton()

                    if !storeService.isProUnlocked {
                        Button {
                            Task { try? await storeService.purchasePro() }
                        } label: {
                            Label("Want more? Unlock Pro", systemImage: "infinity")
                                .font(.subheadline)
                        }
                        .adaptiveSecondaryButton()
                    }
                }
            }

                Button {
                    withAnimation { model?.showSolvedOverlay = false }
                } label: {
                    Text("View grid")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
        }
            .padding(32)
            .adaptiveGlass(in: 16)
            .shadow(radius: 10)
        }
        .transition(reduceMotion ? .identity : .scale.combined(with: .opacity))
    }

    // MARK: - Restart Suggestion Overlay

    private var restartSuggestionOverlay: some View {
        ZStack {
            VStack(spacing: 12) {
                Image(systemName: "arrow.counterclockwise.circle.fill")
                    .font(.system(size: solvedIconSize))
                    .foregroundStyle(Theme.berryBlue)
                    .accessibilityHidden(true)
                    .symbolEffect(.bounce, isActive: !reduceMotion && showRestartSuggestion)
                Text("Need a fresh start?")
                    .font(.title.bold())
                Text("You've used 3 hints on this puzzle. Restarting might help you see it with fresh eyes.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(spacing: 10) {
                    Button("Restart Puzzle") {
                        restartPuzzle()
                        withAnimation { showRestartSuggestion = false }
                    }
                    .adaptiveProminentButton()

                    Button("Keep Going") {
                        withAnimation { showRestartSuggestion = false }
                    }
                    .adaptiveSecondaryButton()
                }
            }
            .padding(32)
            .adaptiveGlass(in: 16)
            .shadow(radius: 10)
        }
        .transition(reduceMotion ? .identity : .scale.combined(with: .opacity))
    }

    private func restartPuzzle() {
        guard let model else { return }
        model.undoAll()
        model.hintedCell = nil
        gameTimer.reset()
        gameTimer.start()
        saveCurrentState()
    }

    // MARK: - Puzzle Loading

    private func loadPuzzle() {
        saveCurrentState()
        gameTimer.reset()
        restartSuggestionShown = false
        showRestartSuggestion = false
        let date = Date.now
        let definition: PuzzleDefinition?
        switch source {
        case .daily:
            definition = puzzleStore.dailyPuzzle(date: date, difficulty: difficulty)
        case .pro:
            definition = puzzleStore.proPuzzle(date: date, difficulty: difficulty, setNumber: proSetNumber)
        }
        guard let definition else { return }
        let newModel = PuzzleModel(definition: definition)

        // Cache the puzzle key for save operations
        let puzzleKey = puzzleIdentifier(definition)
        cachedPuzzleKey = puzzleKey

        if let saved = savedStates.first(where: { $0.puzzleJSON == puzzleKey }) {
            restoreState(saved, into: newModel)
        }

        // If restoring an already-solved puzzle, show overlay immediately without animation
        if newModel.isSolved {
            newModel.celebrationProgress = 1
            newModel.showSolvedOverlay = true
        }

        self.model = newModel
        if !newModel.isSolved {
            gameTimer.start()
        }
    }

    private func newProPuzzle() {
        // Skip over already-started or solved puzzle sets
        for _ in 0..<100 {
            proSetNumber += 1
            let date = Date.now
            guard let definition = puzzleStore.proPuzzle(date: date, difficulty: difficulty, setNumber: proSetNumber) else { break }
            let key = puzzleIdentifier(definition)
            let alreadyStarted = savedStates.contains { $0.puzzleJSON == key }
            if !alreadyStarted { break }
        }
        loadPuzzle()
    }

    private func advanceToNextPuzzle() {
        let nextDifficulty = Difficulty.allCases.first { diff in
            diff.displayIndex > difficulty.displayIndex
        }
        if let next = nextDifficulty {
            difficulty = next
        } else if source == .pro {
            proSetNumber += 1
            difficulty = .standard
        }
        loadPuzzle()
    }

    // MARK: - State Persistence

    private func puzzleIdentifier(_ definition: PuzzleDefinition) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(definition),
              let str = String(data: data, encoding: .utf8) else {
            return UUID().uuidString
        }
        return str
    }

    private func saveCurrentState() {
        guard let model, let puzzleKey = cachedPuzzleKey else { return }
        let cellString = model.allCells.map { (model.cells[$0] ?? .undecided).rawValue }.joined()
        let elapsed = gameTimer.elapsedTime
        let undoString = model.isSolved ? "" : encodeUndoStack(model.undoStack)
        let redoString = model.isSolved ? "" : encodeUndoStack(model.redoStack)

        if model.isSolved {
            gameTimer.stop()
        }

        let hintedCellString = model.hintedCell.map { "\($0.row),\($0.column)" } ?? ""

        if let existing = savedStates.first(where: { $0.puzzleJSON == puzzleKey }) {
            existing.cellStates = cellString
            existing.undoHistory = undoString
            existing.redoHistory = redoString
            existing.elapsedTime = elapsed
            existing.hintedCell = hintedCellString
            existing.hintCount = model.hintCount
            existing.solved = model.isSolved
            if model.isSolved && existing.completionDate == nil {
                existing.completionDate = Date.now
                recordCompletion(time: elapsed)
            }
        } else {
            let state = GameState(
                puzzleJSON: puzzleKey,
                cellStates: cellString,
                undoHistory: undoString,
                redoHistory: redoString,
                elapsedTime: elapsed,
                hintedCell: hintedCellString,
                hintCount: model.hintCount,
                solved: model.isSolved,
                completionDate: model.isSolved ? Date.now : nil,
                source: source.rawValue,
                difficulty: difficulty.rawValue,
                dateString: currentDateString(),
                proSetNumber: proSetNumber
            )
            modelContext.insert(state)
            if model.isSolved {
                recordCompletion(time: elapsed)
            }
        }

        try? modelContext.save()
    }

    private func restoreState(_ saved: GameState, into model: PuzzleModel) {
        let chars = Array(saved.cellStates)
        for (i, cell) in model.allCells.enumerated() {
            guard i < chars.count else { break }
            let char = String(chars[i])
            if let state = CellState(rawValue: char), model.isInteractive(cell) {
                model.cells[cell] = state
            }
        }
        gameTimer.elapsedTime = saved.elapsedTime
        if !saved.hintedCell.isEmpty {
            let parts = saved.hintedCell.split(separator: ",")
            if parts.count == 2, let row = Int(parts[0]), let col = Int(parts[1]) {
                model.hintedCell = CellID(row: row, column: col)
            }
        }
        model.hintCount = saved.hintCount
        model.isSolved = saved.solved
        if !model.isSolved {
            if !saved.undoHistory.isEmpty {
                model.undoStack = decodeUndoStack(saved.undoHistory)
            }
            if !saved.redoHistory.isEmpty {
                model.redoStack = decodeUndoStack(saved.redoHistory)
            }
        }
        _ = model.checkSolved()
    }

    // MARK: - Undo Stack Encoding

    private func encodeUndoStack(_ stack: [CellCommand]) -> String {
        stack.map { "\($0.cell.row),\($0.cell.column),\($0.oldState.rawValue),\($0.newState.rawValue)" }
            .joined(separator: ";")
    }

    private func decodeUndoStack(_ string: String) -> [CellCommand] {
        string.split(separator: ";").compactMap { entry in
            let parts = entry.split(separator: ",")
            guard parts.count == 4,
                  let row = Int(parts[0]),
                  let col = Int(parts[1]),
                  let oldState = CellState(rawValue: String(parts[2])),
                  let newState = CellState(rawValue: String(parts[3])) else {
                return nil
            }
            return CellCommand(cell: CellID(row: row, column: col), oldState: oldState, newState: newState)
        }
    }

    private func useHint(model: PuzzleModel) {
        let solver = PuzzleSolver(model: model)
        if let move = solver.findHint() {
            model.hintCount += 1
            if let (cell, state) = move.knowledge.first {
                if fillHints {
                    model.applyCell(cell, to: state)
                } else {
                    model.hintedCell = cell
                }
            }
            saveCurrentState()

            if model.hintCount >= 3 && !restartSuggestionShown && !model.isSolved {
                restartSuggestionShown = true
                withAnimation { showRestartSuggestion = true }
            }
        }
    }

    private func recordCompletion(time: TimeInterval) {
        let hintCount = model?.hintCount ?? 0
        let hintUsed = hintCount > 0
        stats?.recordCompletion(time: time, date: Date.now, hintCount: hintCount)

        // Check if all daily puzzles are now solved (hint-free only for daily sweep)
        let allDailySolved = source == .daily && Difficulty.allCases.allSatisfy { diff in
            guard let def = puzzleStore.dailyPuzzle(date: Date.now, difficulty: diff) else { return false }
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            guard let data = try? encoder.encode(def),
                  let key = String(data: data, encoding: .utf8) else { return false }
            return savedStates.contains { $0.puzzleJSON == key && $0.solved && !$0.hintUsed }
        }

        gameCenterService.reportPuzzleCompleted(
            totalCompleted: stats?.totalPuzzlesCompleted ?? 0,
            completionTime: time,
            streak: stats?.currentStreak ?? 0,
            difficulty: difficulty,
            isDaily: source == .daily,
            allDailySolved: allDailySolved,
            hintUsed: hintUsed,
            totalHintsUsed: stats?.totalHintsUsed ?? 0
        )
        updateWidgetData()
    }

    private func promptReviewIfNeeded() {
        let total = stats?.totalPuzzlesCompleted ?? 0
        if total == 3 {
            requestReview()
        }
    }

    private func updateWidgetData() {
        let defaults = UserDefaults(suiteName: "group.com.altthree.berroku")
        var solvedCount = 0
        var hintFlags = ""
        for diff in Difficulty.allCases {
            if let def = puzzleStore.dailyPuzzle(date: Date.now, difficulty: diff) {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .sortedKeys
                if let data = try? encoder.encode(def),
                   let key = String(data: data, encoding: .utf8) {
                    let state = savedStates.first { $0.puzzleJSON == key && $0.solved }
                    if state != nil {
                        solvedCount += 1
                        hintFlags += (state?.hintUsed == true) ? "1" : "0"
                    } else {
                        hintFlags += "0"
                    }
                } else {
                    hintFlags += "0"
                }
            } else {
                hintFlags += "0"
            }
        }
        defaults?.set(solvedCount, forKey: "widget.solvedCount")
        defaults?.set(stats?.currentStreak ?? 0, forKey: "widget.currentStreak")
        defaults?.set(hintFlags, forKey: "widget.hintFlags")
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func currentDateString() -> String {
        let cal = Calendar.current
        let d = Date.now
        return "\(cal.component(.day, from: d)) \(cal.component(.month, from: d)) \(cal.component(.year, from: d))"
    }

}

// MARK: - Isolated Timer Display

private struct TimerDisplayView: View {
    @Bindable var timer: GameTimer
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Text(timer.elapsedTime.formattedAsTimer)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(.secondary)
            .contentTransition(reduceMotion ? .identity : .numericText())
            .animation(reduceMotion ? nil : .default, value: timer.elapsedTime)
    }

}
