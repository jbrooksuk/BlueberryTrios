import SwiftUI
import SwiftData
import StoreKit
import WidgetKit
import SiriusRating

struct GameView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
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
    @AppStorage("autoCheck") private var autoCheck: Bool = true
    @AppStorage("showTimer") private var showTimer: Bool = true
    @AppStorage("fillHints") private var fillHints: Bool = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true
    @State private var gameTimer = GameTimer()
    @State private var soundService = SoundService()
    @State private var cachedPuzzleKey: String?
    @State private var showRestartPrompt: Bool = false
    @State private var currentDay: Date = Calendar.current.startOfDay(for: .now)
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

    var body: some View {
        VStack(spacing: 0) {
            headerView
                .frame(maxWidth: 600)
            Spacer(minLength: 12)

            if let model {
                gridSection(model: model)

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
                    HoldToRepeatButton(
                        isEnabled: model.canUndo && !solved,
                        onTap: { model.undo(); saveCurrentState() },
                        onHoldStep: {
                            guard model.canUndo, !model.isSolved else { return false }
                            model.undo()
                            saveCurrentState()
                            return true
                        },
                        accessibilityRepeatLabel: String(
                            localized: "Undo step",
                            comment: "VoiceOver custom action label for repeated undo")
                    ) {
                        Label("Undo", systemImage: "arrow.uturn.backward")
                    }
                    .accessibilityHint(String(
                        localized: "Hold to undo multiple steps",
                        comment: "Accessibility hint for undo toolbar button"))

                    HoldToRepeatButton(
                        isEnabled: model.canRedo && !solved,
                        onTap: { model.redo(); saveCurrentState() },
                        onHoldStep: {
                            guard model.canRedo, !model.isSolved else { return false }
                            model.redo()
                            saveCurrentState()
                            return true
                        },
                        accessibilityRepeatLabel: String(
                            localized: "Redo step",
                            comment: "VoiceOver custom action label for repeated redo")
                    ) {
                        Label("Redo", systemImage: "arrow.uturn.forward")
                    }
                    .accessibilityHint(String(
                        localized: "Hold to redo multiple steps",
                        comment: "Accessibility hint for redo toolbar button"))

                    Button { model.erase(); saveCurrentState() } label: {
                        Label("Erase", systemImage: "eraser")
                    }
                    .disabled(solved)
                    .accessibilityHint(String(
                        localized: "Clears all cells",
                        comment: "Accessibility hint for erase toolbar button"))

                    Button { useHint(model: model) } label: {
                        Label("Hint", systemImage: "lightbulb")
                    }
                    .disabled(solved)
                    .accessibilityHint(String(
                        localized: "Reveals a logical next step",
                        comment: "Accessibility hint for hint toolbar button"))

                    Button { _ = model.checkSolved() } label: {
                        Label("Check", systemImage: "checkmark.circle")
                    }
                    .disabled(solved)
                    .opacity(autoCheck ? 0 : 1)
                    .accessibilityHidden(autoCheck)
                    .accessibilityHint(String(
                        localized: "Checks your current solution for errors",
                        comment: "Accessibility hint for check toolbar button"))
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
            } else if scenePhase == .active {
                let today = Calendar.current.startOfDay(for: .now)
                if today != currentDay { currentDay = today }
                reloadIfDailyDateChanged()
            }
        }
        .task(id: currentDay) {
            let calendar = Calendar.current
            let now = Date.now
            let nextMidnight = calendar.nextDate(
                after: now,
                matching: DateComponents(hour: 0, minute: 0, second: 0),
                matchingPolicy: .nextTime
            ) ?? now.addingTimeInterval(86400)
            let interval = max(1, nextMidnight.timeIntervalSince(now))
            try? await Task.sleep(for: .seconds(interval))
            if Task.isCancelled { return }
            let today = calendar.startOfDay(for: .now)
            if today != currentDay {
                currentDay = today
                reloadIfDailyDateChanged()
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
            if showRestartPrompt {
                restartPromptOverlay
            }
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.3), value: model?.showSolvedOverlay)
        .animation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.3), value: showRestartPrompt)
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
                    Button("New puzzle", systemImage: "plus", action: newProPuzzle)
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

    @ViewBuilder
    private func gridSection(model: PuzzleModel) -> some View {
        let hPad: CGFloat = horizontalSizeClass == .regular ? 40 : 8
        PuzzleGridView(
            model: model,
            autoCheck: autoCheck,
            hapticsEnabled: hapticsEnabled,
            soundService: soundService,
            onStateChanged: saveCurrentState
        )
        .overlay { gridSolvedOverlay }
        .padding(.horizontal, hPad)
    }

    @ViewBuilder
    private var gridSolvedOverlay: some View {
        if model?.showSolvedOverlay == true {
            solvedOverlay
        }
    }

    private var solvedOverlay: some View {
        ZStack {
            if !reduceMotion {
                ConfettiView()
            }
            VStack(spacing: 0) {
                Spacer(minLength: 0)

                VStack(spacing: 6) {
                    Text("Sweet!")
                        .font(.system(.largeTitle, design: .serif).weight(.bold))
                    Text(solvedSubtitle)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer(minLength: 24)

                solvedStatsCard

                Spacer(minLength: 20)

                VStack(spacing: 10) {
                    Button {
                        if source == .pro && storeService.isProUnlocked {
                            newProPuzzle()
                        } else {
                            advanceToNextPuzzle()
                        }
                    } label: {
                        Text("Next puzzle")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .adaptiveProminentButton()
                    .controlSize(.large)

                    Button { sharePuzzle() } label: {
                        Text("Share my time")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                    }
                    .adaptiveSecondaryButton()
                    .controlSize(.large)

                    if source == .pro && storeService.isProUnlocked {
                        Button("Next difficulty") { advanceToNextPuzzle() }
                            .adaptiveSecondaryButton()
                    } else if !storeService.isProUnlocked {
                        Button {
                            Task { try? await storeService.purchasePro() }
                        } label: {
                            Label("Want more? Unlock Pro", systemImage: "infinity")
                                .font(.subheadline)
                        }
                        .adaptiveSecondaryButton()
                    }
                }

                Spacer(minLength: 16)

                Button {
                    withAnimation { model?.showSolvedOverlay = false }
                } label: {
                    Text("View grid")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .adaptiveGlass(in: 6)
            .shadow(radius: 10)
        }
        .transition(reduceMotion ? .identity : .scale.combined(with: .opacity))
    }

    private var solvedSubtitle: String {
        let lower = difficulty.rawValue.lowercased()
        switch source {
        case .daily: return "Today's \(lower) puzzle, solved."
        case .pro: return "Pro \(lower) puzzle, solved."
        }
    }

    private var solvedStatsCard: some View {
        HStack(spacing: 0) {
            solvedStat(value: gameTimer.elapsedTime.formattedAsTimer, label: "Your time")
            Divider().frame(height: 36)
            solvedStat(value: "\(stats?.effectiveCurrentStreak ?? 0)", label: "Streak")
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity)
        .adaptiveGlass(in: 16)
    }

    private func solvedStat(value: String, label: LocalizedStringKey) -> some View {
        VStack(spacing: 4) {
            Text(verbatim: value)
                .font(.system(.title2, design: .serif).weight(.bold))
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Restart Prompt Overlay

    private var restartPromptOverlay: some View {
        let hintCount = model?.hintCount ?? 0
        return VStack(spacing: 14) {
            Image(systemName: "arrow.counterclockwise.circle.fill")
                .font(.system(size: solvedIconSize))
                .foregroundStyle(Theme.berryBlue)
                .accessibilityHidden(true)

            Text("Fresh start?")
                .font(.title2.bold())

            Group {
                if hintCount <= 3 {
                    Text("Three hints in — sometimes a clean slate helps a puzzle click. Your hint count stays the same either way.")
                } else {
                    Text("Another three hints down. A fresh start might help this puzzle click. Your hint count stays the same either way.")
                }
            }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                Button {
                    withAnimation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.3)) {
                        showRestartPrompt = false
                    }
                    restartCurrentPuzzle()
                } label: {
                    Label("Restart puzzle", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .adaptiveProminentButton()

                Button("Keep going") {
                    withAnimation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.3)) {
                        showRestartPrompt = false
                    }
                }
                .adaptiveSecondaryButton()
            }
        }
        .padding(28)
        .frame(maxWidth: 340)
        .adaptiveGlass(in: 16)
        .shadow(radius: 10)
        .padding(32)
        .transition(reduceMotion ? .identity : .scale.combined(with: .opacity))
    }

    // MARK: - Puzzle Loading

    private func loadPuzzle() {
        saveCurrentState()
        showRestartPrompt = false
        gameTimer.reset()
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

        if let saved = fetchSavedState(for: puzzleKey, matching: source, on: currentDateString(), proSetNumber: proSetNumber) {
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

    private func reloadIfDailyDateChanged() {
        guard source == .daily, let cachedPuzzleKey else { return }
        guard let todayDefinition = puzzleStore.dailyPuzzle(date: Date.now, difficulty: difficulty) else { return }
        let todayKey = puzzleIdentifier(todayDefinition)
        if todayKey != cachedPuzzleKey {
            loadPuzzle()
            updateWidgetData()
        }
    }

    private func newProPuzzle() {
        // Skip over already-started or solved puzzle sets
        for _ in 0..<100 {
            proSetNumber += 1
            let date = Date.now
            guard let definition = puzzleStore.proPuzzle(date: date, difficulty: difficulty, setNumber: proSetNumber) else { break }
            let key = puzzleIdentifier(definition)
            let alreadyStarted = fetchSavedState(for: key, matching: .pro, on: currentDateString(), proSetNumber: proSetNumber) != nil
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

        if let existing = fetchSavedState(for: puzzleKey, matching: source, on: currentDateString(), proSetNumber: proSetNumber) {
            existing.cellStates = cellString
            existing.undoHistory = undoString
            existing.redoHistory = redoString
            existing.elapsedTime = elapsed
            existing.hintedCell = hintedCellString
            existing.hintCount = model.hintCount
            existing.solved = model.isSolved
            existing.lastPlayedAt = Date.now
            existing.madeMistake = model.madeMistake
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
                proSetNumber: proSetNumber,
                lastPlayedAt: Date.now,
                madeMistake: model.madeMistake
            )
            modelContext.insert(state)
            if model.isSolved {
                recordCompletion(time: elapsed)
            }
        }

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to save GameState: \(error)")
        }
    }

    /// Fetch a saved state that matches the puzzle *and* the (source, day /
    /// set) tuple. Matching on `puzzleJSON` alone is ambiguous: two different
    /// daily dates — or a daily and a pro with the same underlying
    /// `PuzzleDefinition` — can share the same JSON.
    private func fetchSavedState(for key: String, matching source: PuzzleSource, on dateString: String, proSetNumber: Int) -> GameState? {
        let sourceRaw = source.rawValue
        let descriptor: FetchDescriptor<GameState>
        switch source {
        case .daily:
            descriptor = FetchDescriptor<GameState>(
                predicate: #Predicate {
                    $0.puzzleJSON == key
                        && $0.source == sourceRaw
                        && $0.dateString == dateString
                }
            )
        case .pro:
            descriptor = FetchDescriptor<GameState>(
                predicate: #Predicate {
                    $0.puzzleJSON == key
                        && $0.source == sourceRaw
                        && $0.proSetNumber == proSetNumber
                }
            )
        }
        var d = descriptor
        d.fetchLimit = 1
        return (try? modelContext.fetch(d))?.first
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
        model.madeMistake = saved.madeMistake
        model.isSolved = saved.solved
        if !model.isSolved {
            if !saved.undoHistory.isEmpty {
                model.undoStack = decodeUndoStack(saved.undoHistory)
            }
            if !saved.redoHistory.isEmpty {
                model.redoStack = decodeUndoStack(saved.redoHistory)
            }
        }
        model.lastCheck = model.checkSolved()
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
            let previousCount = model.hintCount
            model.hintCount += 1
            if let stats {
                stats.totalHintsUsed += 1
                gameCenterService.reportHintUsed(totalHintsUsed: stats.totalHintsUsed)
            }
            if let (cell, state) = move.knowledge.first {
                if fillHints {
                    model.applyCell(cell, to: state)
                } else {
                    model.hintedCell = cell
                }
            }
            saveCurrentState()
            // Nudge the player to restart every time they rack up another
            // three hints (3, 6, 9, ...) regardless of whether they took
            // the previous nudge. `hintCount` is monotonic and preserved
            // across a restart, so this fires once per threshold crossing.
            if model.hintCount % 3 == 0 && model.hintCount > previousCount && !model.isSolved {
                withAnimation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.3)) {
                    showRestartPrompt = true
                }
            }
        }
    }

    private func restartCurrentPuzzle() {
        guard let model else { return }
        model.restart()
        // Leave `gameTimer` running — restart preserves hint count *and*
        // elapsed time so the puzzle still reflects the full effort spent.
        saveCurrentState()
    }

    private func sharePuzzle() {
        guard let model else { return }

        let hintCount = model.hintCount
        let hintStr = hintCount == 0 ? "No hints" : "\(hintCount) hint\(hintCount == 1 ? "" : "s")"
        let text = """
        \u{1FAD0} Berroku \u{2014} \(source.rawValue) \(difficulty.rawValue)
        \u{23F1}\u{FE0F} \(gameTimer.elapsedTime.formattedAsTimer) \u{00B7} \u{1F4A1} \(hintStr)
        \(Date.now.formatted(date: .long, time: .omitted))
        """

        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else { return }

        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }

        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = topVC.view
            popover.sourceRect = CGRect(
                x: topVC.view.bounds.midX,
                y: topVC.view.bounds.midY,
                width: 0, height: 0
            )
        }

        topVC.present(activityVC, animated: true)
    }

    private func recordCompletion(time: TimeInterval) {
        let hintCount = model?.hintCount ?? 0
        let hintUsed = hintCount > 0
        let madeMistake = model?.madeMistake ?? false
        let isPro = source == .pro
        stats?.recordCompletion(time: time, date: Date.now, hintCount: hintCount, isPro: isPro, madeMistake: madeMistake)

        // Check if all daily puzzles are now solved (hint-free only for daily sweep)
        let allDailySolved = source == .daily && Difficulty.allCases.allSatisfy { diff in
            guard let def = puzzleStore.dailyPuzzle(date: Date.now, difficulty: diff) else { return false }
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            guard let data = try? encoder.encode(def),
                  let key = String(data: data, encoding: .utf8) else { return false }
            guard let saved = fetchSavedState(for: key, matching: .daily, on: currentDateString(), proSetNumber: 0) else { return false }
            return saved.solved && saved.hintCount == 0
        }

        // A hint-free sweep of all three dailies extends the Marathon streak.
        // `allDailySolved` only flips true on the completion of the third
        // daily, so this records the sweep exactly once per day.
        if allDailySolved {
            stats?.recordDailySweep(date: Date.now)
        }

        let isEarlyBird = Calendar.current.component(.hour, from: Date.now) < 6

        gameCenterService.reportPuzzleCompleted(
            totalCompleted: stats?.totalPuzzlesCompleted ?? 0,
            completionTime: time,
            streak: stats?.currentStreak ?? 0,
            difficulty: difficulty,
            isDaily: source == .daily,
            allDailySolved: allDailySolved,
            hintUsed: hintUsed,
            totalHintsUsed: stats?.totalHintsUsed ?? 0,
            isEarlyBird: isEarlyBird,
            flawlessStreak: stats?.flawlessStreak ?? 0,
            dailySweepStreak: stats?.dailySweepStreak ?? 0,
            proPuzzlesCompleted: stats?.proPuzzlesCompleted ?? 0
        )
        updateWidgetData()
    }

    private func promptReviewIfNeeded() {
        SiriusRating.shared.userDidSignificantEvent()
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
                    if let state = fetchSavedState(for: key, matching: .daily, on: currentDateString(), proSetNumber: 0), state.solved {
                        solvedCount += 1
                        hintFlags += state.hintCount > 0 ? "1" : "0"
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

// MARK: - Hold-to-Repeat Button

/// Toolbar button that fires `onTap` on a short press and enters an accelerating
/// repeat loop (`onHoldStep`) while held. Observes the Button's own press state
/// via `ButtonStyle.configuration.isPressed` because SwiftUI gesture modifiers
/// are dropped when a Button is bridged into a `.bottomBar` toolbar item.
private struct HoldToRepeatButton<L: View>: View {
    let isEnabled: Bool
    let onTap: () -> Void
    let onHoldStep: () -> Bool
    let accessibilityRepeatLabel: String
    @ViewBuilder var label: () -> L

    @State private var holdTask: Task<Void, Never>?
    @State private var didRepeat = false

    var body: some View {
        Button {
            if didRepeat {
                didRepeat = false
            } else {
                onTap()
            }
        } label: {
            label()
        }
        .disabled(!isEnabled)
        .buttonStyle(PressObservingButtonStyle { pressed in
            handlePress(pressed)
        })
        .accessibilityAction(named: accessibilityRepeatLabel) {
            _ = onHoldStep()
        }
    }

    private func handlePress(_ pressed: Bool) {
        if pressed {
            didRepeat = false
            holdTask?.cancel()
            holdTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                if Task.isCancelled { return }
                didRepeat = true
                var delay: TimeInterval = 0.18
                while !Task.isCancelled {
                    if !onHoldStep() { return }
                    try? await Task.sleep(for: .seconds(delay))
                    if Task.isCancelled { return }
                    delay = max(0.04, delay * 0.82)
                }
            }
        } else {
            holdTask?.cancel()
            holdTask = nil
        }
    }
}

private struct PressObservingButtonStyle: ButtonStyle {
    let onPressChange: (Bool) -> Void
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.55 : 1)
            .contentShape(Rectangle())
            .onChange(of: configuration.isPressed) { _, pressed in
                onPressChange(pressed)
            }
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
