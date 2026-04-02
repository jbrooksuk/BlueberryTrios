import SwiftUI

struct WalkthroughView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0
    @State private var sessionID = UUID()

    private let pages: [WalkthroughPage] = [
        WalkthroughPage(
            title: String(localized: "Welcome to Berroku", comment: "Walkthrough page 1 title"),
            subtitle: String(localized: "A berry logic puzzle inspired by Sudoku", comment: "Walkthrough page 1 subtitle"),
            illustration: .berries,
            description: String(localized: "Each day brings three new puzzles across Standard, Advanced, and Expert difficulties.", comment: "Walkthrough page 1 description")
        ),
        WalkthroughPage(
            title: String(localized: "Place 3 berries", comment: "Walkthrough page 2 title"),
            subtitle: String(localized: "In every row, column, and block", comment: "Walkthrough page 2 subtitle"),
            illustration: .grid,
            description: String(localized: "The 9×9 grid is divided into blocks. Each row, column, and block must contain exactly 3 berries.", comment: "Walkthrough page 2 description")
        ),
        WalkthroughPage(
            title: String(localized: "Follow the clues", comment: "Walkthrough page 3 title"),
            subtitle: String(localized: "Numbers guide your way", comment: "Walkthrough page 3 subtitle"),
            illustration: .clue,
            description: String(localized: "A number tells you how many of the 8 surrounding cells contain a berry. Use logic to work out where each berry goes.", comment: "Walkthrough page 3 description")
        ),
        WalkthroughPage(
            title: String(localized: "Tap and drag", comment: "Walkthrough page 4 title"),
            subtitle: String(localized: "Quick and intuitive controls", comment: "Walkthrough page 4 subtitle"),
            illustration: .interaction,
            description: String(localized: "Tap a cell to cycle: empty, crossed out, or berry. Use crossed to mark cells you've ruled out. Drag to paint multiple cells at once.", comment: "Walkthrough page 4 description")
        ),
        WalkthroughPage(
            title: String(localized: "Build your streak", comment: "Walkthrough page 5 title"),
            subtitle: String(localized: "Come back every day", comment: "Walkthrough page 5 subtitle"),
            illustration: .streak,
            description: String(localized: "Solve puzzles daily to build your streak. Earn achievements and compete on the leaderboard.", comment: "Walkthrough page 5 description")
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    WalkthroughPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut(duration: 0.3), value: currentPage)
            .id(sessionID)

            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    ForEach(pages.indices, id: \.self) { index in
                        Circle()
                            .fill(index == currentPage ? Theme.berryBlue : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentPage ? 1.2 : 1)
                            .animation(.spring(duration: 0.3), value: currentPage)
                    }
                }

                HStack {
                    if currentPage > 0 {
                        Button(String(localized: "Back", comment: "Walkthrough back button")) {
                            withAnimation { currentPage -= 1 }
                        }
                        .adaptiveSecondaryButton()
                    }

                    Spacer()

                    if currentPage < pages.count - 1 {
                        Button(String(localized: "Next", comment: "Walkthrough next button")) {
                            withAnimation { currentPage += 1 }
                        }
                        .adaptiveProminentButton()
                    } else {
                        Button(String(localized: "Let's play!", comment: "Walkthrough final button")) {
                            isPresented = false
                        }
                        .adaptiveProminentButton()
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
        .interactiveDismissDisabled()
        .onAppear {
            currentPage = 0
            sessionID = UUID()
        }
    }
}

// MARK: - Page Model

private struct WalkthroughPage {
    let title: String
    let subtitle: String
    let illustration: WalkthroughIllustration
    let description: String
}

private enum WalkthroughIllustration {
    case berries, grid, clue, interaction, streak
}

// MARK: - Page View

private struct WalkthroughPageView: View {
    let page: WalkthroughPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            illustrationView
                .frame(height: 200)

            VStack(spacing: 8) {
                Text(page.title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text(page.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.berryBlue)
                    .multilineTextAlignment(.center)
            }

            Text(page.description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var illustrationView: some View {
        switch page.illustration {
        case .berries:
            berriesIllustration
        case .grid:
            gridIllustration
        case .clue:
            clueIllustration
        case .interaction:
            interactionIllustration
        case .streak:
            streakIllustration
        }
    }

    // MARK: - Illustrations

    private var berriesIllustration: some View {
        BerryClusterView(animated: true)
    }

    // Real puzzle solve animation with berries AND crosses
    private static let solveClues: [(Int, Int, Int)] = [
        (0,1,1),(0,2,1),(0,6,3),(0,8,3),(1,1,3),(1,5,3),
        (2,3,4),(2,5,2),(3,6,3),(5,0,3),(5,2,2),(5,4,3),
        (6,7,2),(8,5,0),
    ]

    private struct SolveStep {
        let berries: [(Int, Int)]
        let crosses: [(Int, Int)]
    }

    private static let solveSteps: [SolveStep] = [
        SolveStep(berries: [], crosses: [(7,4),(7,5),(7,6),(8,4),(8,6)]),
        SolveStep(berries: [(0,5),(0,7)], crosses: [(0,0),(0,3)]),
        SolveStep(berries: [(0,4)], crosses: [(0,8)]),
        SolveStep(berries: [(1,2)], crosses: [(1,0),(1,3),(1,4)]),
        SolveStep(berries: [(1,7),(1,8)], crosses: [(1,6)]),
        SolveStep(berries: [(2,1),(2,2),(2,4)], crosses: [(2,0),(2,6),(2,7),(2,8)]),
        SolveStep(berries: [(3,2),(3,5)], crosses: [(3,0),(3,1),(3,3),(3,4)]),
        SolveStep(berries: [(3,8),(4,0)], crosses: [(3,7),(4,1),(4,2)]),
        SolveStep(berries: [(4,5),(4,6)], crosses: [(4,3),(4,4),(4,7),(4,8)]),
        SolveStep(berries: [(5,1),(5,3),(5,6)], crosses: [(5,2),(5,5),(5,7),(5,8)]),
        SolveStep(berries: [(6,0),(6,4),(6,6)], crosses: [(6,1),(6,2),(6,3),(6,5)]),
        SolveStep(berries: [(7,0),(7,1),(7,3)], crosses: [(7,2),(7,7),(7,8)]),
        SolveStep(berries: [(8,3),(8,7),(8,8)], crosses: [(8,0),(8,1),(8,2)]),
    ]

    private static let solveBlocks: [Int] = [
        0,0,0,1,1,1,2,2,2,
        0,0,0,1,1,1,2,2,2,
        0,0,0,1,1,1,2,2,2,
        3,3,3,4,4,4,5,5,5,
        3,3,3,4,4,4,5,5,5,
        3,3,3,4,4,4,5,5,5,
        6,6,6,7,7,7,8,8,8,
        6,6,6,7,7,7,8,8,8,
        6,6,6,7,7,7,8,8,8,
    ]

    private func isBerryVisible(row: Int, col: Int, stepsShown: Int) -> Bool {
        for step in 0..<min(stepsShown, Self.solveSteps.count) {
            if Self.solveSteps[step].berries.contains(where: { $0.0 == row && $0.1 == col }) {
                return true
            }
        }
        return false
    }

    private func isCrossVisible(row: Int, col: Int, stepsShown: Int) -> Bool {
        for step in 0..<min(stepsShown, Self.solveSteps.count) {
            if Self.solveSteps[step].crosses.contains(where: { $0.0 == row && $0.1 == col }) {
                return true
            }
        }
        return false
    }

    private func clueValue(row: Int, col: Int) -> Int? {
        Self.solveClues.first { $0.0 == row && $0.1 == col }?.2
    }

    private func isBlockBorder(r: Int, c: Int, dr: Int, dc: Int) -> Bool {
        let idx1 = r * 9 + c
        let nr = r + dr
        let nc = c + dc
        guard nr >= 0, nr < 9, nc >= 0, nc < 9 else { return true }
        let idx2 = nr * 9 + nc
        return Self.solveBlocks[idx1] != Self.solveBlocks[idx2]
    }

    private var gridIllustration: some View {
        PhaseAnimator(Array(0...14)) { phase in
            let stepsShown = min(phase, 13)

            Grid(horizontalSpacing: 0, verticalSpacing: 0) {
                ForEach(0..<9, id: \.self) { row in
                    GridRow {
                        ForEach(0..<9, id: \.self) { col in
                            let hasBerry = isBerryVisible(row: row, col: col, stepsShown: stepsShown)
                            let hasCross = isCrossVisible(row: row, col: col, stepsShown: stepsShown)
                            let clue = clueValue(row: row, col: col)

                            ZStack {
                                Rectangle()
                                    .fill(Theme.cellBackground)

                                // Block borders
                                Rectangle()
                                    .fill(.clear)
                                    .overlay(alignment: .leading) {
                                        if isBlockBorder(r: row, c: col, dr: 0, dc: -1) {
                                            Rectangle().fill(Theme.gridLineThick).frame(width: 1.5)
                                        }
                                    }
                                    .overlay(alignment: .top) {
                                        if isBlockBorder(r: row, c: col, dr: -1, dc: 0) {
                                            Rectangle().fill(Theme.gridLineThick).frame(height: 1.5)
                                        }
                                    }
                                    .overlay(alignment: .trailing) {
                                        if isBlockBorder(r: row, c: col, dr: 0, dc: 1) {
                                            Rectangle().fill(Theme.gridLineThick).frame(width: 1.5)
                                        }
                                    }
                                    .overlay(alignment: .bottom) {
                                        if isBlockBorder(r: row, c: col, dr: 1, dc: 0) {
                                            Rectangle().fill(Theme.gridLineThick).frame(height: 1.5)
                                        }
                                    }

                                if let clue {
                                    Text("\(clue)")
                                        .font(.system(.caption2, design: .rounded, weight: .medium))
                                        .foregroundStyle(Theme.clueText.opacity(0.6))
                                } else if hasBerry {
                                    Circle()
                                        .fill(Theme.berryBlue)
                                        .padding(3)
                                        .transition(.scale.combined(with: .opacity))
                                } else if hasCross {
                                    // X mark
                                    Canvas { context, size in
                                        let mid = CGPoint(x: size.width / 2, y: size.height / 2)
                                        let s = min(size.width, size.height) * 0.2
                                        var xPath = Path()
                                        xPath.move(to: CGPoint(x: mid.x - s, y: mid.y - s))
                                        xPath.addLine(to: CGPoint(x: mid.x + s, y: mid.y + s))
                                        xPath.move(to: CGPoint(x: mid.x + s, y: mid.y - s))
                                        xPath.addLine(to: CGPoint(x: mid.x - s, y: mid.y + s))
                                        context.stroke(xPath, with: .color(Theme.emptyDot),
                                                       style: StrokeStyle(lineWidth: 1, lineCap: .round))
                                    }
                                    .transition(.opacity)
                                }
                            }
                            .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
            .clipShape(.rect(cornerRadius: 4))
            .frame(maxWidth: 200, maxHeight: 200)
        } animation: { phase in
            if phase == 0 {
                .easeInOut(duration: 0.4)
            } else {
                .spring(duration: 0.5, bounce: 0.15)
            }
        }
    }

    // Animated clue demonstration: "3" at top-right (0,2) with berries surrounding it
    // Phases: 0=empty grid with clue, 1-3=berries appear, 4=crosses on remaining + pause
    private var clueIllustration: some View {
        PhaseAnimator([0, 1, 2, 3, 4]) { phase in
            // Clue "3" at (0,2). Its neighbors: (0,1), (1,1), (1,2) — all get berries
            let berryPositions: [(Int, Int)] = [(0, 1), (1, 2), (1, 1)]
            let crossedPositions: [(Int, Int)] = [(0, 0), (1, 0), (2, 0), (2, 1), (2, 2)]
            let berriesShown = min(phase, 3)

            VStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { col in
                            let isBerry = berryPositions.prefix(berriesShown).contains { $0.0 == row && $0.1 == col }
                            let isCrossed = phase >= 3 && crossedPositions.contains { $0.0 == row && $0.1 == col }
                            let isClue = row == 0 && col == 2
                            let isHinted = phase < 3 && berryPositions.dropFirst(berriesShown).prefix(1).contains { $0.0 == row && $0.1 == col }

                            ZStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(isHinted ? Theme.hintHighlight : Theme.cellBackground)
                                    .frame(width: 52, height: 52)

                                if isClue {
                                    Text("3")
                                        .font(.system(.title2, design: .rounded, weight: .bold))
                                        .foregroundStyle(phase >= 3 ? Theme.clueText.opacity(0.25) : Theme.clueText)
                                } else if isBerry {
                                    Circle()
                                        .fill(Theme.berryBlue)
                                        .frame(width: 28, height: 28)
                                        .transition(.scale)
                                } else if isCrossed {
                                    Canvas { context, size in
                                        let mid = CGPoint(x: size.width / 2, y: size.height / 2)
                                        let s = 8.0
                                        var xPath = Path()
                                        xPath.move(to: CGPoint(x: mid.x - s, y: mid.y - s))
                                        xPath.addLine(to: CGPoint(x: mid.x + s, y: mid.y + s))
                                        xPath.move(to: CGPoint(x: mid.x + s, y: mid.y - s))
                                        xPath.addLine(to: CGPoint(x: mid.x - s, y: mid.y + s))
                                        context.stroke(xPath, with: .color(Theme.emptyDot),
                                                       style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                                    }
                                    .frame(width: 52, height: 52)
                                }
                            }
                        }
                    }
                }
            }
        } animation: { phase in
            if phase == 0 {
                .easeInOut(duration: 0.3)
            } else {
                .spring(duration: 0.5, bounce: 0.2)
            }
        }
    }

    private var interactionIllustration: some View {
        PhaseAnimator([0, 1, 2, 3]) { phase in
            HStack(spacing: 12) {
                VStack(spacing: 4) {
                    cellStateView(.blank, active: phase == 0)
                    Text(String(localized: "Empty", comment: "Walkthrough cell state label"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Image(systemName: "arrow.right")
                    .foregroundStyle(.tertiary)
                VStack(spacing: 4) {
                    cellStateView(.crossed, active: phase == 1)
                    Text(String(localized: "Ruled out", comment: "Walkthrough crossed state label"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Image(systemName: "arrow.right")
                    .foregroundStyle(.tertiary)
                VStack(spacing: 4) {
                    cellStateView(.berryState, active: phase == 2)
                    Text(String(localized: "Berry", comment: "Walkthrough berry state label"))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        } animation: { _ in .easeInOut(duration: 1.0) }
    }

    private var streakIllustration: some View {
        HStack(spacing: 12) {
            ForEach(0..<7, id: \.self) { day in
                VStack(spacing: 6) {
                    ZStack {
                        Circle()
                            .fill(day < 5 ? Theme.berryBlue : Color.gray.opacity(0.2))
                            .frame(width: 36, height: 36)
                        if day < 5 {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundStyle(.white)
                        }
                    }
                    Text(weekdayLabel(day))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Helpers

    private enum CellContent {
        case berry, empty, clue(Int)
    }

    private enum CellDisplay {
        case blank, crossed, berryState
    }

    private func cellStateView(_ state: CellDisplay, active: Bool) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Theme.cellBackground)
                .frame(width: 56, height: 56)
                .overlay {
                    if active {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Theme.berryBlue, lineWidth: 2)
                    }
                }

            switch state {
            case .blank:
                EmptyView()
            case .crossed:
                // X mark matching the game grid style
                Canvas { context, size in
                    let mid = CGPoint(x: size.width / 2, y: size.height / 2)
                    let xSize = 8.0
                    var xPath = Path()
                    xPath.move(to: CGPoint(x: mid.x - xSize, y: mid.y - xSize))
                    xPath.addLine(to: CGPoint(x: mid.x + xSize, y: mid.y + xSize))
                    xPath.move(to: CGPoint(x: mid.x + xSize, y: mid.y - xSize))
                    xPath.addLine(to: CGPoint(x: mid.x - xSize, y: mid.y + xSize))
                    context.stroke(xPath, with: .color(Theme.emptyDot),
                                   style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                }
                .frame(width: 56, height: 56)
            case .berryState:
                Circle()
                    .fill(Theme.berryBlue)
                    .frame(width: 28, height: 28)
            }
        }
    }

    private func weekdayLabel(_ index: Int) -> String {
        let symbols = Calendar.current.shortWeekdaySymbols
        return symbols[index % symbols.count]
    }
}

#Preview {
    WalkthroughView(isPresented: .constant(true))
}
