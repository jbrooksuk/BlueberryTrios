import SwiftUI
import SwiftData
import StoreKit
import WidgetKit

struct GameView: View {
    @Environment(\.modelContext) private var modelContext
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
    @AppStorage("autoCheck") private var autoCheck: Bool = true
    @AppStorage("showTimer") private var showTimer: Bool = true
    @AppStorage("fillHints") private var fillHints: Bool = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true
    @State private var gameTimer = GameTimer()
    @State private var soundService = SoundService()
    @State private var notificationService = NotificationService()
    @State private var cachedPuzzleKey: String?

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

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Spacer(minLength: 12)

            if let model {
                PuzzleGridView(model: model, autoCheck: autoCheck, hapticsEnabled: hapticsEnabled, soundService: soundService, onStateChanged: saveCurrentState)
                    .padding(.horizontal, 8)

                Spacer(minLength: 0)
            } else {
                Spacer()
                Text("No puzzle available")
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
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
                }
            }
        }
        .toolbarRole(.automatic)
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .gesture(DragGesture())
        .task {
            UIApplication.shared.isIdleTimerDisabled = true
            soundService.isEnabled = soundEnabled
            loadPuzzle()
            updateWidgetData()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
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
        .overlay {
            if model?.showSolvedOverlay == true {
                solvedOverlay
            }
        }
        .animation(.spring(duration: 0.4, bounce: 0.3), value: model?.showSolvedOverlay)
        .onChange(of: soundEnabled) { soundService.isEnabled = soundEnabled }
        .onChange(of: model?.isSolved) {
            if let model, model.isSolved {
                soundService.playSolved()
                // Run celebration cascade, then show overlay
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
                }
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Blueberry Trio")
                    .font(.title2.bold())

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
            Form {
                Section("Gameplay") {
                    Toggle("Auto Check", isOn: $autoCheck)
                    Toggle("Show Timer", isOn: $showTimer)
                    Toggle("Fill Hints", isOn: $fillHints)
                    Toggle("Haptics", isOn: $hapticsEnabled)
                    Toggle("Sound", isOn: $soundEnabled)
                    Toggle("Daily Reminder", isOn: $notificationService.isEnabled)
                }
                Section("Pro Puzzles") {
                    if storeService.isProUnlocked {
                        Label("Pro Unlocked", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    } else {
                        if let product = storeService.proProduct {
                            Button {
                                Task { try? await storeService.purchasePro() }
                            } label: {
                                HStack {
                                    Text("Unlock Pro Puzzles")
                                    Spacer()
                                    Text(product.displayPrice)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } else {
                            HStack {
                                ProgressView()
                                    .controlSize(.small)
                                Text("Loading products...")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Button("Restore Purchases") {
                            Task { await storeService.restorePurchases() }
                        }
                    }
                }
                Section("Rules") {
                    Text("Place 3 berries into each row, column, and block. Surround each number with the specified number of berries.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
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
            ConfettiView()
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, value: model?.isSolved)
                Text("Solved!")
                    .font(.title.bold())
                TimerDisplayView(timer: gameTimer)
            if source == .pro && storeService.isProUnlocked {
                HStack(spacing: 12) {
                    Button("New Puzzle") {
                        newProPuzzle()
                    }
                    .buttonStyle(.glassProminent)
                    Button("Next Difficulty") {
                        advanceToNextPuzzle()
                    }
                    .buttonStyle(.glass)
                }
            } else {
                Button("Next Puzzle") {
                    advanceToNextPuzzle()
                }
                .buttonStyle(.glassProminent)
            }
        }
            .padding(32)
            .glassEffect(in: .rect(cornerRadius: 16))
            .shadow(radius: 10)
        }
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Puzzle Loading

    private func loadPuzzle() {
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

        if let saved = savedStates.first(where: { $0.puzzleJSON == puzzleKey }) {
            restoreState(saved, into: newModel)
        }

        self.model = newModel
        if !newModel.isSolved {
            gameTimer.start()
        }
    }

    private func newProPuzzle() {
        // Skip over already-solved puzzle sets
        for _ in 0..<100 {
            proSetNumber += 1
            let date = Date.now
            guard let definition = puzzleStore.proPuzzle(date: date, difficulty: difficulty, setNumber: proSetNumber) else { break }
            let key = puzzleIdentifier(definition)
            let alreadySolved = savedStates.contains { $0.puzzleJSON == key && $0.solved }
            if !alreadySolved { break }
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

        if model.isSolved {
            gameTimer.stop()
        }

        if let existing = savedStates.first(where: { $0.puzzleJSON == puzzleKey }) {
            existing.cellStates = cellString
            existing.elapsedTime = elapsed
            existing.hintUsed = model.hintUsed
            existing.solved = model.isSolved
            if model.isSolved && existing.completionDate == nil {
                existing.completionDate = Date.now
                recordCompletion(time: elapsed)
            }
        } else {
            let state = GameState(
                puzzleJSON: puzzleKey,
                cellStates: cellString,
                elapsedTime: elapsed,
                hintUsed: model.hintUsed,
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
        model.hintUsed = saved.hintUsed
        model.isSolved = saved.solved
        _ = model.checkSolved()
    }

    private func useHint(model: PuzzleModel) {
        let solver = PuzzleSolver(model: model)
        if let move = solver.findHint() {
            model.hintUsed = true
            if let (cell, state) = move.knowledge.first {
                if fillHints {
                    model.applyCell(cell, to: state)
                } else {
                    model.hintedCell = cell
                }
            }
            saveCurrentState()
        }
    }

    private func recordCompletion(time: TimeInterval) {
        stats?.recordCompletion(time: time, date: Date.now)
        gameCenterService.reportPuzzleCompleted(
            totalCompleted: stats?.totalPuzzlesCompleted ?? 0,
            completionTime: time,
            streak: stats?.currentStreak ?? 0
        )
        updateWidgetData()
    }

    private func updateWidgetData() {
        let defaults = UserDefaults(suiteName: "group.com.alt-three.Blueberries")
        // Count how many daily puzzles are solved today
        var solvedCount = 0
        for diff in Difficulty.allCases {
            if let def = puzzleStore.dailyPuzzle(date: Date.now, difficulty: diff) {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .sortedKeys
                if let data = try? encoder.encode(def),
                   let key = String(data: data, encoding: .utf8),
                   savedStates.contains(where: { $0.puzzleJSON == key && $0.solved }) {
                    solvedCount += 1
                }
            }
        }
        defaults?.set(solvedCount, forKey: "widget.solvedCount")
        defaults?.set(stats?.currentStreak ?? 0, forKey: "widget.currentStreak")
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

    var body: some View {
        Text(timer.elapsedTime.formattedAsTimer)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(.secondary)
            .contentTransition(.numericText())
            .animation(.default, value: timer.elapsedTime)
    }

}
