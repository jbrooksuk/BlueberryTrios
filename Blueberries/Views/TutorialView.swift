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

    // Easy 9×9 with 0 clues at (0,0) and (1,0) for teaching crosses first.
    // 34 clues for easy solving. All solutions verified.
    //
    // Solution:
    //   x x o | x o x | x o x
    //   x x o | x x o | o x x
    //   x x o | o x x | x x o
    //   ------+-------+------
    //   o x x | x o x | o x x
    //   x o x | o x x | x x o
    //   o x x | x x o | x o x
    //   ------+-------+------
    //   x o x | x x o | x x o
    //   o x x | o x x | x o x
    //   x o x | x o x | o x x

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
              0, nil, nil, nil, nil, nil,   3, nil,   1,
              0, nil, nil, nil, nil, nil, nil,   3,   2,
              1, nil, nil, nil,   3, nil,   3, nil, nil,
            nil,   3, nil, nil, nil,   2, nil,   3,   2,
              3, nil,   2, nil,   3, nil,   3, nil, nil,
            nil,   3, nil,   1, nil, nil, nil, nil, nil,
              3, nil,   2,   1,   3, nil, nil, nil, nil,
            nil,   3, nil, nil, nil,   3, nil, nil,   2,
              2, nil,   2,   2, nil,   2, nil,   2,   1,
        ],
        solution: "xxoxoxxoxxxoxxooxxxxooxxxxooxxxoxoxxxoxoxxxxooxxxxoxoxxoxxxoxxooxxoxxxoxxoxxoxoxx"
    )

    init(isPresented: Binding<Bool>, gameCenterService: GameCenterService) {
        _isPresented = isPresented
        self.gameCenterService = gameCenterService
        _model = State(initialValue: PuzzleModel(definition: Self.tutorialPuzzle))
    }

    // MARK: - Steps

    enum TutorialStep: Int, CaseIterable, Comparable {
        case welcome
        case explainZero       // Teach the 0 clue — all neighbors are empty
        case crossNeighbors    // Player crosses out cells around the 0
        case explainBerry      // Now teach placing a berry
        case firstBerry        // Player places their first berry
        case freePlay          // Finish the puzzle
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
            .allowsHitTesting(step >= .crossNeighbors && step < .solved)

            Spacer(minLength: 8)

            if step >= .crossNeighbors && step < .solved {
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
                        withAnimation { step = .explainZero }
                    }
                    .adaptiveProminentButton()
                    .padding(.top, 4)
                }

            case .explainZero:
                VStack(spacing: 8) {
                    Text("Start with the **0**")
                        .font(.title3.bold())
                    Text("See the **0** on the left? It means **none** of its neighbors have a berry. We can **cross them all out** with an ✕!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Text("Tap each highlighted cell to mark it")
                        .font(.subheadline.weight(.medium))
                        .multilineTextAlignment(.center)
                    Button("Got it") {
                        withAnimation {
                            step = .crossNeighbors
                            gameTimer.start()
                        }
                    }
                    .adaptiveProminentButton()
                    .padding(.top, 4)
                }

            case .crossNeighbors:
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "xmark.circle")
                            .foregroundStyle(Theme.berryBlue)
                        Text("Cross out the highlighted cells")
                            .font(.subheadline.weight(.medium))
                    }
                    Text("Tap once for ✕ (ruled out). These cells can't have berries.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

            case .explainBerry:
                VStack(spacing: 8) {
                    Text("Now place a berry!")
                        .font(.title3.bold())
                    Text("Look at the top-left block — it still needs 3 berries. The highlighted cell is forced! Tap it **twice** to cycle to a berry.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

            case .firstBerry:
                HStack(spacing: 8) {
                    Image(systemName: "hand.tap.fill")
                        .foregroundStyle(Theme.berryBlue)
                    Text("Tap the highlighted cell twice for a berry")
                        .font(.subheadline.weight(.medium))
                }

            case .freePlay:
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(Theme.berryBlue)
                        Text("You've got the hang of it!")
                            .font(.subheadline.weight(.medium))
                    }
                    Text("Finish the puzzle. Use ✕ to rule out cells and berries to fill them in. Tap \(Image(systemName: "lightbulb")) for a hint.")
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

    // The 0 clue at (0,0) — its interactive neighbors (not clue cells) should be crossed
    private var zeroInteractiveNeighbors: Set<CellID> {
        // Neighbors of (0,0): (0,1) and (1,1) are now interactive (clues removed)
        // (1,0) is still a clue cell (also 0)
        let neighbors: [CellID] = [
            CellID(row: 0, column: 1),
            CellID(row: 1, column: 1),
        ]
        return Set(neighbors.filter { model.isInteractive($0) })
    }

    // First berry target — (0,2) which is a berry forced by the block constraint
    private let firstBerryCell = CellID(row: 0, column: 2)

    private var currentHighlights: Set<CellID> {
        switch step {
        case .explainZero:
            // Highlight the 0 clue and its crossable neighbors
            var cells: Set<CellID> = [CellID(row: 0, column: 0)]
            cells.formUnion(zeroInteractiveNeighbors)
            return cells
        case .crossNeighbors:
            // Highlight only the uncrossed neighbors
            return zeroInteractiveNeighbors.filter { model.cells[$0] == .undecided }
        case .explainBerry, .firstBerry:
            return [firstBerryCell]
        default:
            return []
        }
    }

    // MARK: - Progress

    private func checkProgress() {
        switch step {
        case .crossNeighbors:
            // Advance when all interactive neighbors of 0 are crossed
            let allCrossed = zeroInteractiveNeighbors.allSatisfy { model.cells[$0] == .empty }
            if allCrossed {
                withAnimation { step = .explainBerry }
            }
        case .explainBerry, .firstBerry:
            if model.cells[firstBerryCell] == .berry {
                withAnimation { step = .freePlay }
            } else if step == .explainBerry {
                // Auto-advance to firstBerry once they start interacting
                withAnimation { step = .firstBerry }
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
