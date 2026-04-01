import SwiftUI
import SwiftData

struct TutorialView: View {
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext
    @Query private var statsRecords: [PlayerStats]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var gameCenterService: GameCenterService

    @State private var model: PuzzleModel
    @State private var step: TutorialStep = .welcome
    @State private var gameTimer = GameTimer()
    @State private var soundService = SoundService()
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true

    private var stats: PlayerStats? { statsRecords.first }

    // MARK: - Tutorial Puzzle

    // Hand-crafted easy 9×9 puzzle with 23 clues.
    // All four corners have clue "1" with two clue-cell neighbors,
    // making the first deductions trivially forced.
    //
    // Solution:
    //   x x o | x o x | o x x
    //   o x x | o x x | x o x
    //   x o x | x x o | x x o
    //   ------+-------+------
    //   x o x | x x o | x o x
    //   x x o | o x x | o x x
    //   o x x | x o x | x x o
    //   ------+-------+------
    //   o x x | o x x | x x o
    //   x x o | x x o | o x x
    //   x o x | x o x | x o x

    static let tutorialPuzzle = PuzzleDefinition(
        size: PuzzleSize(rows: 9, columns: 9),
        rowClues: [3, 3, 3, 3, 3, 3, 3, 3, 3],
        columnClues: [3, 3, 3, 3, 3, 3, 3, 3, 3],
        blockClues: [3, 3, 3, 3, 3, 3, 3, 3, 3],
        blocks: [
            0, 0, 0, 1, 1, 1, 2, 2, 2,
            0, 0, 0, 1, 1, 1, 2, 2, 2,
            0, 0, 0, 1, 1, 1, 2, 2, 2,
            3, 3, 3, 4, 4, 4, 5, 5, 5,
            3, 3, 3, 4, 4, 4, 5, 5, 5,
            3, 3, 3, 4, 4, 4, 5, 5, 5,
            6, 6, 6, 7, 7, 7, 8, 8, 8,
            6, 6, 6, 7, 7, 7, 8, 8, 8,
            6, 6, 6, 7, 7, 7, 8, 8, 8,
        ],
        cellClues: [
              1,   2, nil, nil, nil,   2, nil,   2,   1,
            nil,   3, nil, nil,   3, nil, nil, nil,   2,
            nil, nil, nil,   1, nil, nil, nil, nil, nil,
            nil, nil, nil,   2, nil, nil, nil, nil,   2,
            nil, nil, nil, nil,   3, nil, nil, nil, nil,
            nil, nil, nil, nil, nil, nil,   1, nil, nil,
            nil,   3, nil, nil, nil,   3, nil, nil, nil,
              2,   3, nil,   3, nil, nil, nil,   3,   2,
              1, nil, nil,   2, nil, nil, nil, nil,   1,
        ],
        solution: "xxoxoxoxxoxxoxxxoxxoxxxoxxoxoxxxoxoxxxooxxoxxoxxxoxxxooxxoxxxxoxxoxxooxxxoxxoxxox"
    )

    init(isPresented: Binding<Bool>, gameCenterService: GameCenterService) {
        _isPresented = isPresented
        self.gameCenterService = gameCenterService
        _model = State(initialValue: PuzzleModel(definition: Self.tutorialPuzzle))
    }

    // MARK: - Steps

    enum TutorialStep: Int, CaseIterable, Comparable {
        case welcome
        case explainClues
        case firstBerry
        case crossingOut
        case freePlay
        case solved

        static func < (lhs: TutorialStep, rhs: TutorialStep) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            coachMark
                .padding(.horizontal, 16)
                .padding(.top, 12)

            Spacer(minLength: 12)

            PuzzleGridView(
                model: model,
                autoCheck: true,
                hapticsEnabled: hapticsEnabled,
                soundService: soundService,
                onStateChanged: { checkProgress() },
                highlightedCells: currentHighlights
            )
            .padding(.horizontal, 8)
            .allowsHitTesting(step >= .firstBerry && step < .solved)

            Spacer(minLength: 8)

            if step >= .firstBerry && step < .solved {
                actionButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
        }
        .frame(maxWidth: .infinity)
        .background(Theme.backgroundGradient)
        .interactiveDismissDisabled()
        .task {
            soundService.isEnabled = soundEnabled
        }
        .overlay {
            if step == .solved {
                solvedOverlay
            }
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.3), value: step)
        .onChange(of: soundEnabled) { soundService.isEnabled = soundEnabled }
        .onChange(of: model.isSolved) {
            if model.isSolved {
                soundService.playSolved()
                gameTimer.stop()
                recordCompletion()
                if reduceMotion {
                    model.celebrationProgress = 1
                    step = .solved
                } else {
                    Task {
                        let steps = 18
                        for i in 1...steps {
                            model.celebrationProgress = Double(i) / Double(steps)
                            try? await Task.sleep(for: .milliseconds(50))
                        }
                        try? await Task.sleep(for: .milliseconds(300))
                        withAnimation(.spring(duration: 0.4, bounce: 0.3)) {
                            step = .solved
                        }
                    }
                }
            }
        }
    }

    // MARK: - Coach Marks

    @ViewBuilder
    private var coachMark: some View {
        VStack(spacing: 12) {
            switch step {
            case .welcome:
                VStack(spacing: 8) {
                    Image(systemName: "hand.wave.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Theme.berryBlue)
                    Text("Let's solve your first puzzle!")
                        .font(.title3.bold())
                    Text("Place 3 berries in every row, column, and block. Numbers tell you how many berries surround them.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Let's go!") {
                        withAnimation { step = .explainClues }
                    }
                    .adaptiveProminentButton()
                    .padding(.top, 4)
                }

            case .explainClues:
                VStack(spacing: 8) {
                    Text("See the numbers?")
                        .font(.title3.bold())
                    Text("The **1** in the top-left corner means exactly 1 of its neighbors has a berry. Its other two neighbors are number clues \u{2014} they never contain berries.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Text("That means the remaining cell **must** be a berry!")
                        .font(.subheadline.weight(.medium))
                        .multilineTextAlignment(.center)
                    Button("Show me") {
                        withAnimation {
                            step = .firstBerry
                            gameTimer.start()
                        }
                    }
                    .adaptiveProminentButton()
                    .padding(.top, 4)
                }

            case .firstBerry:
                HStack(spacing: 8) {
                    Image(systemName: "hand.tap.fill")
                        .foregroundStyle(Theme.berryBlue)
                    Text("Tap the highlighted cell to place a berry")
                        .font(.subheadline.weight(.medium))
                }

            case .crossingOut:
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle")
                            .foregroundStyle(Theme.berryBlue)
                        Text("Nice! Now try the other corners")
                            .font(.subheadline.weight(.medium))
                    }
                    Text("Each corner '1' works the same way. You can also tap empty cells to cross them out with an X.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

            case .freePlay:
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Theme.berryBlue)
                        Text("You've got the hang of it!")
                            .font(.subheadline.weight(.medium))
                    }
                    Text("Finish the puzzle using the same logic. Tap \(Image(systemName: "lightbulb")) for a hint if you get stuck.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

            case .solved:
                EmptyView()
            }
        }
        .padding(16)
        .frame(maxWidth: 600)
        .adaptiveGlass(in: 16)
    }

    // MARK: - Highlights

    private var currentHighlights: Set<CellID> {
        switch step {
        case .explainClues:
            // Highlight the top-left corner clue and its only interactive neighbor
            return [CellID(row: 0, column: 0), CellID(row: 1, column: 0)]
        case .firstBerry:
            // Highlight the cell the player should tap
            return [CellID(row: 1, column: 0)]
        case .crossingOut:
            // Highlight the other three corner berry cells
            return [
                CellID(row: 1, column: 7),  // top-right corner deduction
                CellID(row: 8, column: 1),  // bottom-left corner deduction
                CellID(row: 8, column: 7),  // bottom-right corner deduction
            ]
        default:
            return []
        }
    }

    // MARK: - Progress

    private func checkProgress() {
        switch step {
        case .firstBerry:
            if model.cells[CellID(row: 1, column: 0)] == .berry {
                withAnimation { step = .crossingOut }
            }
        case .crossingOut:
            // Advance once they've placed at least 3 more berries (the other corners + any)
            let berryCount = model.allCells.filter { model.cells[$0] == .berry }.count
            if berryCount >= 4 {
                withAnimation { step = .freePlay }
            }
        default:
            break
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 20) {
            Button { model.undo() } label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
            }
            .disabled(!model.canUndo)

            Button { model.redo() } label: {
                Label("Redo", systemImage: "arrow.uturn.forward")
            }
            .disabled(!model.canRedo)

            Button { model.erase() } label: {
                Label("Erase", systemImage: "eraser")
            }

            Button { useHint() } label: {
                Label("Hint", systemImage: "lightbulb")
            }
        }
        .labelStyle(.iconOnly)
        .font(.title3)
    }

    // MARK: - Hint

    private func useHint() {
        let solver = PuzzleSolver(model: model)
        if let move = solver.findHint() {
            model.hintUsed = true
            if let (cell, state) = move.knowledge.first {
                model.applyCell(cell, to: state)
                checkProgress()
            }
        }
    }

    // MARK: - Completion

    private func recordCompletion() {
        let time = gameTimer.elapsedTime
        stats?.recordCompletion(time: time, date: Date.now)

        gameCenterService.reportPuzzleCompleted(
            totalCompleted: stats?.totalPuzzlesCompleted ?? 0,
            completionTime: time,
            streak: stats?.currentStreak ?? 0
        )
    }

    // MARK: - Solved Overlay

    private var solvedOverlay: some View {
        ZStack {
            if !reduceMotion {
                ConfettiView()
            }
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, isActive: !reduceMotion)
                Text("Puzzle Solved!")
                    .font(.title.bold())
                Text("You've completed the tutorial!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button("Play Today's Puzzle") {
                    isPresented = false
                }
                .adaptiveProminentButton()
                .padding(.top, 8)
            }
            .padding(32)
            .adaptiveGlass(in: 16)
            .shadow(radius: 10)
        }
        .transition(reduceMotion ? .identity : .scale.combined(with: .opacity))
    }
}

#Preview {
    TutorialView(isPresented: .constant(true), gameCenterService: GameCenterService())
        .modelContainer(for: [GameState.self, PlayerStats.self], inMemory: true)
}
