import SwiftUI
import SwiftData
import StoreKit
import WidgetKit

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
    @State private var showHintConfirmPrompt: Bool = false
    @State private var showOutOfHintsPrompt: Bool = false
    @State private var isPurchasingHintPack: Bool = false
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
                        }
                    ) {
                        Label("Undo", systemImage: "arrow.uturn.backward")
                    }

                    HoldToRepeatButton(
                        isEnabled: model.canRedo && !solved,
                        onTap: { model.redo(); saveCurrentState() },
                        onHoldStep: {
                            guard model.canRedo, !model.isSolved else { return false }
                            model.redo()
                            saveCurrentState()
                            return true
                        }
                    ) {
                        Label("Redo", systemImage: "arrow.uturn.forward")
                    }

                    Button { model.erase(); saveCurrentState() } label: {
                        Label("Erase", systemImage: "eraser")
                    }
                    .disabled(solved)

                    Button { requestHint() } label: {
                        Label("Hint", systemImage: "lightbulb")
                    }
                    .disabled(solved)
                    .badge(solved ? 0 : (stats?.totalAvailableHints ?? 0))

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
            storeService.creditHintPack = { [modelContext] count in
                var descriptor = FetchDescriptor<PlayerStats>()
                descriptor.fetchLimit = 1
                let record = (try? modelContext.fetch(descriptor).first) ?? {
                    let new = PlayerStats()
                    modelContext.insert(new)
                    return new
                }()
                record.grantPurchasedHints(count)
                try? modelContext.save()
            }
            stats?.resetDailyHintsIfNeeded()
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
            if showRestartPrompt {
                restartPromptOverlay
            }
        }
        .overlay {
            if showHintConfirmPrompt {
                hintConfirmOverlay
            }
        }
        .overlay {
            if showOutOfHintsPrompt {
                outOfHintsOverlay
            }
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.3), value: model?.showSolvedOverlay)
        .animation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.3), value: showRestartPrompt)
        .animation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.3), value: showHintConfirmPrompt)
        .animation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.3), value: showOutOfHintsPrompt)
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

                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: solvedIconSize))
                        .foregroundStyle(.green)
                        .accessibilityHidden(true)
                        .symbolEffect(.bounce, isActive: !reduceMotion && model?.isSolved == true)
                    Text("Solved!")
                        .font(.title.bold())
                    TimerDisplayView(timer: gameTimer)
                }

                Spacer(minLength: 24)

                VStack(spacing: 10) {
                    if source == .pro && storeService.isProUnlocked {
                        HStack(spacing: 10) {
                            Button { sharePuzzle() } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .adaptiveSecondaryButton()
                            Button("New puzzle") { newProPuzzle() }
                                .adaptiveProminentButton()
                            Button("Next difficulty") { advanceToNextPuzzle() }
                                .adaptiveSecondaryButton()
                        }
                    } else {
                        HStack(spacing: 10) {
                            Button { sharePuzzle() } label: {
                                Label("Share", systemImage: "square.and.arrow.up")
                            }
                            .adaptiveSecondaryButton()
                            Button("Next puzzle") { advanceToNextPuzzle() }
                                .adaptiveProminentButton()
                        }

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

    // MARK: - Confirmation Overlay

    /// Compact confirmation-card overlay used by the restart nudge, the
    /// "use a hint?" prompt, and the out-of-hints upsell. Matches the
    /// card styling established by the restart prompt: corner-radius 16,
    /// max-width 340, glass background, soft shadow, scale+opacity
    /// transition honouring Reduce Motion.
    @ViewBuilder
    private func confirmationOverlay<Message: View, Actions: View>(
        icon: String,
        iconTint: Color = Theme.berryBlue,
        title: String,
        @ViewBuilder message: () -> Message,
        @ViewBuilder actions: () -> Actions
    ) -> some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: solvedIconSize))
                .foregroundStyle(iconTint)
                .accessibilityHidden(true)

            Text(title)
                .font(.title2.bold())

            message()
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 10) {
                actions()
            }
        }
        .padding(28)
        .frame(maxWidth: 340)
        .adaptiveGlass(in: 16)
        .shadow(radius: 10)
        .padding(32)
        .transition(reduceMotion ? .identity : .scale.combined(with: .opacity))
    }

    // MARK: - Restart Prompt Overlay

    private var restartPromptOverlay: some View {
        let hintCount = model?.hintCount ?? 0

        return confirmationOverlay(
            icon: "arrow.counterclockwise.circle.fill",
            title: "Fresh start?",
            message: {
                if hintCount <= 3 {
                    Text("Three hints in — sometimes a clean slate helps a puzzle click. Your hint count stays the same either way.")
                } else {
                    Text("Another three hints down. A fresh start might help this puzzle click. Your hint count stays the same either way.")
                }
            },
            actions: {
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
        )
    }

    // MARK: - Hint Confirm Overlay

    private var hintConfirmOverlay: some View {
        let free = stats?.availableFreeHints ?? 0
        let purchased = stats?.purchasedHintsRemaining ?? 0
        let usingFree = free > 0
        let freeRemaining = max(0, free - 1)
        let purchasedRemaining = max(0, purchased - 1)

        return confirmationOverlay(
            icon: "lightbulb.fill",
            title: "Use a hint?",
            message: {
                if usingFree && freeRemaining > 1 {
                    Text("Use this hint and you'll have \(freeRemaining) free hints left today.")
                } else if usingFree && freeRemaining == 1 {
                    Text("Use this hint and you'll have one free hint left today.")
                } else if usingFree && purchased > 1 {
                    Text("This is your last free hint for today. You'll still have \(purchased) saved hints in your pack.")
                } else if usingFree && purchased == 1 {
                    Text("This is your last free hint for today. You'll still have one saved hint in your pack.")
                } else if usingFree {
                    Text("This is your last free hint for today. Tomorrow you'll get three more.")
                } else if purchasedRemaining > 1 {
                    Text("Use this hint and you'll have \(purchasedRemaining) saved hints left in your pack.")
                } else if purchasedRemaining == 1 {
                    Text("Use this hint and you'll have one saved hint left in your pack.")
                } else {
                    Text("This is your last saved hint. You can buy more any time.")
                }
            },
            actions: {
                Button {
                    confirmHintUse()
                } label: {
                    Label("Use hint", systemImage: "lightbulb.fill")
                        .frame(maxWidth: .infinity)
                }
                .adaptiveProminentButton()

                Button("Cancel") {
                    withAnimation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.3)) {
                        showHintConfirmPrompt = false
                    }
                }
                .adaptiveSecondaryButton()
            }
        )
    }

    // MARK: - Out of Hints Overlay

    private var outOfHintsOverlay: some View {
        let product = storeService.hintPackProduct
        let priceLabel = product?.displayPrice ?? ""

        return confirmationOverlay(
            icon: "lightbulb.slash",
            title: "Out of hints",
            message: {
                Text("You've used all three of today's free hints. Tomorrow you'll get three more — or grab a pack of 10 to keep going now.")
            },
            actions: {
                Button {
                    Task { await purchaseHintPackFromPrompt() }
                } label: {
                    Group {
                        if isPurchasingHintPack {
                            ProgressView()
                                .tint(.white)
                        } else if let _ = product {
                            Label("Buy 10 hints · \(priceLabel)", systemImage: "cart.fill")
                        } else {
                            ProgressView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .adaptiveProminentButton()
                .disabled(product == nil || isPurchasingHintPack)

                Button("Maybe later") {
                    withAnimation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.3)) {
                        showOutOfHintsPrompt = false
                    }
                }
                .adaptiveSecondaryButton()
                .disabled(isPurchasingHintPack)
            }
        )
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

        if let saved = fetchSavedState(for: puzzleKey) {
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
            let alreadyStarted = fetchSavedState(for: key) != nil
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

        if let existing = fetchSavedState(for: puzzleKey) {
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

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to save GameState: \(error)")
        }
    }

    private func fetchSavedState(for key: String) -> GameState? {
        var descriptor = FetchDescriptor<GameState>(
            predicate: #Predicate { $0.puzzleJSON == key }
        )
        descriptor.fetchLimit = 1
        return (try? modelContext.fetch(descriptor))?.first
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

    // MARK: - Hint Economy

    /// Entry point for the Hint toolbar button. Lazily resets today's free
    /// allocation, then routes to either the hint-confirmation prompt or
    /// the out-of-hints upsell depending on balance.
    private func requestHint() {
        guard let model, !model.isSolved else { return }
        stats?.resetDailyHintsIfNeeded()
        let available = stats?.totalAvailableHints ?? 0
        if available == 0 {
            withAnimation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.3)) {
                showOutOfHintsPrompt = true
            }
        } else {
            withAnimation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.3)) {
                showHintConfirmPrompt = true
            }
        }
        _ = model
    }

    /// Called from the hint-confirmation prompt's primary action. Spends
    /// one hint (free first, then purchased), dismisses the prompt, and
    /// runs the existing hint-reveal logic.
    private func confirmHintUse() {
        guard let model else { return }
        stats?.consumeHint()
        withAnimation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.3)) {
            showHintConfirmPrompt = false
        }
        useHint(model: model)
    }

    /// Called from the out-of-hints prompt. On a successful purchase the
    /// credit is applied via `StoreKitService.creditHintPack`, so we just
    /// dismiss the upsell and immediately re-open the confirmation prompt
    /// — the player pressed Hint, they still want one.
    private func purchaseHintPackFromPrompt() async {
        isPurchasingHintPack = true
        defer { isPurchasingHintPack = false }
        do {
            let purchased = try await storeService.purchaseHintPack()
            guard purchased else { return }
            withAnimation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.3)) {
                showOutOfHintsPrompt = false
                showHintConfirmPrompt = true
            }
        } catch {
            #if DEBUG
            print("Hint pack purchase failed: \(error)")
            #endif
        }
    }

    private func useHint(model: PuzzleModel) {
        let solver = PuzzleSolver(model: model)
        if let move = solver.findHint() {
            let previousCount = model.hintCount
            model.hintCount += 1
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

        let cardView = ShareCardView(
            model: model,
            elapsedTime: gameTimer.elapsedTime,
            difficulty: difficulty,
            source: source,
            date: Date.now
        )

        let renderer = ImageRenderer(content: cardView)
        renderer.scale = 3

        guard let image = renderer.uiImage else { return }

        let hintCount = model.hintCount
        let hintStr = hintCount == 0 ? "No hints" : "\(hintCount) hint\(hintCount == 1 ? "" : "s")"
        let text = """
        \u{1FAD0} Berroku \u{2014} \(source.rawValue) \(difficulty.rawValue)
        \u{23F1}\u{FE0F} \(gameTimer.elapsedTime.formattedAsTimer) \u{00B7} \u{1F4A1} \(hintStr)
        \(Date.now.formatted(date: .long, time: .omitted))
        """

        let activityVC = UIActivityViewController(
            activityItems: [image, text],
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
        stats?.recordCompletion(time: time, date: Date.now, hintCount: hintCount)

        // Check if all daily puzzles are now solved (hint-free only for daily sweep)
        let allDailySolved = source == .daily && Difficulty.allCases.allSatisfy { diff in
            guard let def = puzzleStore.dailyPuzzle(date: Date.now, difficulty: diff) else { return false }
            let encoder = JSONEncoder()
            encoder.outputFormatting = .sortedKeys
            guard let data = try? encoder.encode(def),
                  let key = String(data: data, encoding: .utf8) else { return false }
            guard let saved = fetchSavedState(for: key) else { return false }
            return saved.solved && saved.hintCount == 0
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
                    if let state = fetchSavedState(for: key), state.solved {
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
    }

    private func handlePress(_ pressed: Bool) {
        if pressed {
            didRepeat = false
            holdTask?.cancel()
            holdTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(350))
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
