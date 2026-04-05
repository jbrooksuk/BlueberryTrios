import SwiftUI
import SwiftData

struct TutorialView: View {
    @Binding var isPresented: Bool
    @Environment(\.modelContext) private var modelContext
    @Query private var statsRecords: [PlayerStats]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var gameCenterService: GameCenterService
    var dismissable: Bool = false

    @State private var model: PuzzleModel
    @State private var step: TutorialStep = .welcome
    @State private var gridHighlightPhase: Int = 0
    @State private var gridHighlightTimer: Task<Void, Never>?
    @State private var gameTimer = GameTimer()
    @State private var soundService = SoundService()
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("soundEnabled") private var soundEnabled: Bool = true
    @ScaledMetric(relativeTo: .largeTitle) private var solvedIconSize: CGFloat = 48

    private var stats: PlayerStats? { statsRecords.first }

    // MARK: - Tutorial Puzzle

    // Cascading puzzle: blocks 0/1/2 each contain an entire row of berries.
    // Filling one block completes its row, unlocking adjacent blocks.
    // Three 0 clues, a 5, and several 4s for variety.
    //
    // Solution:
    //   o o o | x x x | x x x     ← all 3 in block 0
    //   x x x | o o o | x x x     ← all 3 in block 1
    //   x x x | x x x | o o o     ← all 3 in block 2
    //   x x o | x x o | x x o
    //   x o x | x o x | x o x
    //   o x x | o x x | o x x
    //   x o x | o x x | x x o
    //   o x x | x x o | x o x
    //   x x o | x o x | o x x

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
            nil, nil, nil, nil,   3,   2,   1,   0,   0,
              2,   3, nil, nil, nil, nil, nil,   3,   2,
              0,   1,   2, nil,   4,   4, nil, nil, nil,
              1,   2, nil,   2,   2, nil,   4,   5, nil,
              2, nil, nil,   3, nil, nil, nil, nil,   2,
            nil,   3,   4, nil, nil,   2, nil,   3,   2,
              3, nil, nil, nil,   3,   2, nil, nil, nil,
            nil,   3, nil,   3, nil, nil, nil, nil,   2,
              1,   2, nil,   2, nil, nil, nil,   2,   1,
        ],
        solution: "oooxxxxxxxxxoooxxxxxxxxxoooxxoxxoxxoxoxxoxxoxoxxoxxoxxxoxoxxxxooxxxxoxoxxxoxoxoxx"
    )

    init(isPresented: Binding<Bool>, gameCenterService: GameCenterService, dismissable: Bool = false) {
        _isPresented = isPresented
        self.gameCenterService = gameCenterService
        self.dismissable = dismissable
        _model = State(initialValue: PuzzleModel(definition: Self.tutorialPuzzle))
    }

    // MARK: - Steps

    enum TutorialStep: Int, CaseIterable, Comparable {
        case welcome
        case explainGrid       // Rows, columns, blocks
        case explainZero       // The 0 clue — cross neighbors
        case crossNeighbors    // Player crosses cells around the 0
        case fillBlock         // Fill remaining block cells with berries
        case crossRow          // Row 2 has 3 berries — cross the rest
        case cornerBerry       // The 1 in bottom-right has one empty neighbor
        case colBerry          // Place berries to complete col 8
        case fillRow           // Complete row 3 (has 1 berry from colBerry, needs 2 more)
        case freePlay          // Finish the puzzle
        case solved

        static func < (lhs: TutorialStep, rhs: TutorialStep) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            if dismissable {
                HStack {
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.trailing, 16)
                    .padding(.top, 8)
                }
            }

            coachMark
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .frame(maxHeight: 220, alignment: .top)

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
        .interactiveDismissDisabled(!dismissable)
        .task {
            soundService.isEnabled = soundEnabled
        }
        .overlay {
            if step == .solved {
                solvedOverlay
            }
        }
        .animation(reduceMotion ? nil : .spring(duration: 0.4, bounce: 0.3), value: step)
        .onChange(of: step) {
            gridHighlightTimer?.cancel()
            if step == .explainGrid && !reduceMotion {
                gridHighlightTimer = Task {
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .seconds(1.2))
                        if !Task.isCancelled {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                gridHighlightPhase += 1
                            }
                        }
                    }
                }
            }
        }
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
                    Text("Place 3 berries in every row, column, and 3×3 block.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Let's go!") {
                        withAnimation { step = .explainGrid }
                    }
                    .adaptiveProminentButton()
                    .padding(.top, 4)
                }

            case .explainGrid:
                VStack(spacing: 8) {
                    Text("The grid")
                        .font(.title3.bold())
                    Text("Each **row**, **column**, and **3×3 block** needs exactly 3 berries. Numbers tell you how many of the 8 surrounding cells have berries.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Next") {
                        withAnimation { step = .explainZero }
                    }
                    .adaptiveProminentButton()
                    .padding(.top, 4)
                }

            case .explainZero:
                VStack(spacing: 8) {
                    Text("Start with the **0**")
                        .font(.title3.bold())
                    Text("A **0** means none of its neighbors are berries. Cross them out with ✕!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
                        Text("Tap each highlighted cell once for ✕")
                            .font(.subheadline.weight(.medium))
                    }
                }

            case .fillBlock:
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.grid.3x3")
                            .foregroundStyle(Theme.berryBlue)
                        Text("Fill the block!")
                            .font(.subheadline.weight(.medium))
                    }
                    Text("This block needs 3 berries and has exactly 3 empty cells. They must all be berries! Tap each one **twice**.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

            case .crossRow:
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.circle")
                            .foregroundStyle(Theme.berryBlue)
                        Text("Row 2 has 3 berries!")
                            .font(.subheadline.weight(.medium))
                    }
                    Text("That row is full — cross out the remaining cells.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

            case .cornerBerry:
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "hand.tap.fill")
                            .foregroundStyle(Theme.berryBlue)
                        Text("Look at the **1** in the corner")
                            .font(.subheadline.weight(.medium))
                    }
                    Text("It has only one empty neighbor — that cell must be a berry! Tap it **twice**.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

            case .colBerry:
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle")
                            .foregroundStyle(Theme.berryBlue)
                        Text("Complete the column")
                            .font(.subheadline.weight(.medium))
                    }
                    Text("The last column has 1 berry. Place the other 2 to complete it! Tap each **twice**.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

            case .fillRow:
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.circle")
                            .foregroundStyle(Theme.berryBlue)
                        Text("Complete row 4")
                            .font(.subheadline.weight(.medium))
                    }
                    Text("This row already has 1 berry. Place the other 2 to finish it!")
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
                    Text("Keep going! If a cell turns **red**, it means there's an error — undo and try again. Tap \(Image(systemName: "lightbulb")) for a hint.")
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

    // MARK: - Highlights & Logic

    // 0 at (2,0): interactive neighbors to cross
    private var zeroCrossCells: Set<CellID> {
        // Neighbors of (2,0): (1,0), (1,1), (2,1), (3,1) are interactive
        // (2,1) has clue 1 — wait, let me check...
        // clues: (1,0)=2 NOT interactive, (1,1)=3 NOT interactive
        // Actually (1,0) and (1,1) have clues! Let me check properly.
        // Row 1: 2, 3, nil, nil, nil, nil, nil, 3, 2
        // So (1,0)=2 clue, (1,1)=3 clue — NOT interactive
        // Row 2: 0, 1, 2, ... so (2,1)=1 clue — NOT interactive
        // Row 3: 1, 2, nil, ... so (3,0)=1 clue, (3,1)=2 clue — NOT interactive
        // ALL neighbors of (2,0) are clue cells! None to cross.
        // We need to use a different 0 — try (0,7) or (0,8)
        // (0,7)=0: neighbors are (0,6)=1 clue, (0,8)=0 clue, (1,6)=nil, (1,7)=3 clue, (1,8)=2 clue
        // So (1,6) is the only interactive neighbor of (0,7)
        // (0,8)=0: neighbors are (0,7)=0 clue, (1,7)=3 clue, (1,8)=2 clue
        // ALL clue cells! No interactive neighbors.

        // The 0s don't have enough interactive neighbors for a good tutorial step.
        // Let me just highlight the top-right corner 0s to explain the concept,
        // then jump to filling block 2 (which has berries in row 2 cols 6,7,8)

        // Only (1,6) is crossable near the 0s
        return [CellID(row: 1, column: 6)]
    }

    // Block 2 berry cells: row 2, cols 6,7,8
    private let blockBerryCells: Set<CellID> = [
        CellID(row: 2, column: 6),
        CellID(row: 2, column: 7),
        CellID(row: 2, column: 8),
    ]

    // Row 2 non-berry cells to cross after block 2 is filled (cols 0-5 that are interactive)
    private var row2CrossCells: Set<CellID> {
        var cells: Set<CellID> = []
        for c in 0..<6 {
            let cell = CellID(row: 2, column: c)
            if model.isInteractive(cell) {
                cells.insert(cell)
            }
        }
        return cells
    }

    // The 1 at (8,8) — only interactive neighbor is (7,7) which is a berry
    private let cornerBerryCell = CellID(row: 7, column: 7)

    // Col 8 completion: (3,8) and (6,8) are the remaining berries needed
    private let colBerryCells: Set<CellID> = [
        CellID(row: 3, column: 8),
        CellID(row: 6, column: 8),
    ]

    // Row 3 remaining berries: (3,2) and (3,5) — (3,8) already placed in colBerry
    private let row3BerryCells: Set<CellID> = [
        CellID(row: 3, column: 2),
        CellID(row: 3, column: 5),
    ]

    // Grid explanation: cycle row → column → block
    private var gridExplainHighlights: Set<CellID> {
        let phase = gridHighlightPhase % 3
        switch phase {
        case 0:
            // Highlight row 4 (middle row, visible)
            return Set((0..<9).map { CellID(row: 4, column: $0) })
        case 1:
            // Highlight column 4 (middle column)
            return Set((0..<9).map { CellID(row: $0, column: 4) })
        default:
            // Highlight block 4 (center block, rows 3-5 cols 3-5)
            var cells: Set<CellID> = []
            for r in 3...5 { for c in 3...5 { cells.insert(CellID(row: r, column: c)) } }
            return cells
        }
    }

    private var currentHighlights: Set<CellID> {
        switch step {
        case .explainGrid:
            return gridExplainHighlights
        case .explainZero:
            return [CellID(row: 0, column: 7), CellID(row: 0, column: 8)]
        case .crossNeighbors:
            return zeroCrossCells.filter { model.cells[$0] == .undecided }
        case .fillBlock:
            return blockBerryCells.filter { model.cells[$0] != .berry }
        case .crossRow:
            return row2CrossCells.filter { model.cells[$0] == .undecided }
        case .cornerBerry:
            return [CellID(row: 8, column: 8), cornerBerryCell]
        case .colBerry:
            return colBerryCells.filter { model.cells[$0] != .berry }
        case .fillRow:
            return row3BerryCells.filter { model.cells[$0] != .berry }
        default:
            return []
        }
    }

    // MARK: - Progress

    private func checkProgress() {
        switch step {
        case .crossNeighbors:
            let allCrossed = zeroCrossCells.allSatisfy { model.cells[$0] != .undecided }
            if allCrossed {
                withAnimation { step = .fillBlock }
            }
        case .fillBlock:
            let allFilled = blockBerryCells.allSatisfy { model.cells[$0] == .berry }
            if allFilled {
                withAnimation { step = .crossRow }
            }
        case .crossRow:
            let allCrossed = row2CrossCells.allSatisfy { model.cells[$0] != .undecided }
            if allCrossed {
                withAnimation { step = .cornerBerry }
            }
        case .cornerBerry:
            if model.cells[cornerBerryCell] == .berry {
                withAnimation { step = .colBerry }
            }
        case .colBerry:
            let allFilled = colBerryCells.allSatisfy { model.cells[$0] == .berry }
            if allFilled {
                withAnimation { step = .fillRow }
            }
        case .fillRow:
            let allFilled = row3BerryCells.allSatisfy { model.cells[$0] == .berry }
            if allFilled {
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
            model.hintCount += 1
            if let (cell, state) = move.knowledge.first {
                model.applyCell(cell, to: state)
                checkProgress()
            }
        }
    }

    // MARK: - Completion

    private func recordCompletion() {
        let time = gameTimer.elapsedTime
        let hintCount = model.hintCount
        let hintUsed = hintCount > 0
        stats?.recordCompletion(time: time, date: Date.now, hintCount: hintCount)

        gameCenterService.reportPuzzleCompleted(
            totalCompleted: stats?.totalPuzzlesCompleted ?? 0,
            completionTime: time,
            streak: stats?.currentStreak ?? 0,
            hintUsed: hintUsed,
            totalHintsUsed: stats?.totalHintsUsed ?? 0
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
                    .font(.system(size: solvedIconSize))
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
