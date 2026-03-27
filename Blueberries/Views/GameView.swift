import SwiftUI
import SwiftData
import StoreKit

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
    @State private var autoCheck: Bool = true
    @State private var showTimer: Bool = true
    @State private var fillHints: Bool = false
    @State private var hapticsEnabled: Bool = true
    @State private var timerTask: Task<Void, Never>?

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

    private var stats: PlayerStats {
        if let existing = statsRecords.first { return existing }
        let new = PlayerStats()
        modelContext.insert(new)
        return new
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Spacer(minLength: 12)

            if let model {
                PuzzleGridView(model: model, autoCheck: autoCheck, hapticsEnabled: hapticsEnabled, onStateChanged: saveCurrentState)
                    .padding(.horizontal, 8)

                Spacer(minLength: 12)
                toolbarView(model: model)
            } else {
                Spacer()
                Text("No puzzle available")
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Spacer(minLength: 8)
        }
        .background(Color(.systemBackground))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            loadPuzzle()
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
            if model?.isSolved == true {
                solvedOverlay
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

                if showTimer, let model {
                    Text(formatTime(model.elapsedTime))
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }

                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.title3)
                }
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
                    Button {
                        newProPuzzle()
                    } label: {
                        Image(systemName: "plus")
                            .font(.subheadline.bold())
                            .padding(6)
                            .background(Color.accentColor)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
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

    // MARK: - Toolbar

    private func toolbarView(model: PuzzleModel) -> some View {
        HStack(spacing: 20) {
            toolbarButton("arrow.uturn.backward", label: "Undo", enabled: model.canUndo) {
                model.undo()
                saveCurrentState()
            }
            toolbarButton("arrow.uturn.forward", label: "Redo", enabled: model.canRedo) {
                model.redo()
                saveCurrentState()
            }
            toolbarButton("eraser", label: "Erase", enabled: true) {
                model.erase()
                saveCurrentState()
            }
            toolbarButton("lightbulb", label: "Hint", enabled: !model.isSolved) {
                useHint(model: model)
            }
            toolbarButton("checkmark.circle", label: "Check", enabled: true) {
                _ = model.checkSolved()
            }
        }
        .padding(.horizontal, 16)
    }

    private func toolbarButton(_ systemImage: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.title3)
                Text(label)
                    .font(.caption2)
            }
            .frame(minWidth: 50)
        }
        .disabled(!enabled)
        .foregroundStyle(enabled ? .primary : .tertiary)
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
        VStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text("Solved!")
                .font(.title.bold())
            if let model {
                Text(formatTime(model.elapsedTime))
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
            Button("Next Puzzle") {
                advanceToNextPuzzle()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 10)
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Puzzle Loading

    private func loadPuzzle() {
        stopTimer()
        let date = Date()
        let definition: PuzzleDefinition?
        switch source {
        case .daily:
            definition = puzzleStore.dailyPuzzle(date: date, difficulty: difficulty)
        case .pro:
            definition = puzzleStore.proPuzzle(date: date, difficulty: difficulty, setNumber: proSetNumber)
        }
        guard let definition else { return }
        let newModel = PuzzleModel(definition: definition)

        // Try to restore saved state
        let puzzleKey = puzzleIdentifier(definition)
        if let saved = savedStates.first(where: { $0.puzzleJSON == puzzleKey }) {
            restoreState(saved, into: newModel)
        }

        self.model = newModel
        if !newModel.isSolved {
            startTimer()
        }
    }

    private func newProPuzzle() {
        // Skip over already-solved puzzle sets
        for _ in 0..<100 {
            proSetNumber += 1
            let date = Date()
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
        guard let model else { return }
        let puzzleKey = puzzleIdentifier(model.definition)
        let cellString = model.allCells.map { (model.cells[$0] ?? .undecided).rawValue }.joined()
        let dateString = currentDateString()

        if let existing = savedStates.first(where: { $0.puzzleJSON == puzzleKey }) {
            existing.cellStates = cellString
            existing.elapsedTime = model.elapsedTime
            existing.hintUsed = model.hintUsed
            existing.solved = model.isSolved
            if model.isSolved && existing.completionDate == nil {
                existing.completionDate = Date()
                recordCompletion(time: model.elapsedTime)
            }
        } else {
            let state = GameState(
                puzzleJSON: puzzleKey,
                cellStates: cellString,
                elapsedTime: model.elapsedTime,
                hintUsed: model.hintUsed,
                solved: model.isSolved,
                completionDate: model.isSolved ? Date() : nil,
                source: source.rawValue,
                difficulty: difficulty.rawValue,
                dateString: dateString,
                proSetNumber: proSetNumber
            )
            modelContext.insert(state)
            if model.isSolved {
                recordCompletion(time: model.elapsedTime)
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
        model.elapsedTime = saved.elapsedTime
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
                    let oldState = model.cells[cell] ?? .undecided
                    if oldState != state {
                        model.undoStack.append([CellCommand(cell: cell, oldState: oldState, newState: state)])
                        model.cells[cell] = state
                        model.redoStack.removeAll()
                        _ = model.checkSolved()
                    }
                } else {
                    model.hintedCell = cell
                }
            }
            saveCurrentState()
        }
    }

    private func recordCompletion(time: TimeInterval) {
        stats.recordCompletion(time: time, date: Date())
        gameCenterService.reportPuzzleCompleted(
            totalCompleted: stats.totalPuzzlesCompleted,
            completionTime: time,
            streak: stats.currentStreak
        )
    }

    private func currentDateString() -> String {
        let cal = Calendar.current
        let d = Date()
        return "\(cal.component(.day, from: d)) \(cal.component(.month, from: d)) \(cal.component(.year, from: d))"
    }

    // MARK: - Timer

    private func startTimer() {
        guard let model else { return }
        model.isTimerRunning = true
        timerTask = Task {
            while !Task.isCancelled && model.isTimerRunning {
                try? await Task.sleep(for: .seconds(1))
                if !Task.isCancelled && model.isTimerRunning {
                    model.elapsedTime += 1
                }
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
        model?.isTimerRunning = false
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
