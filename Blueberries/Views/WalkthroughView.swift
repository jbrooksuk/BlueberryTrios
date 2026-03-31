import SwiftUI

struct WalkthroughView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0

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
                        .buttonStyle(.glass)
                    }

                    Spacer()

                    if currentPage < pages.count - 1 {
                        Button(String(localized: "Next", comment: "Walkthrough next button")) {
                            withAnimation { currentPage += 1 }
                        }
                        .buttonStyle(.glassProminent)
                    } else {
                        Button(String(localized: "Let's play!", comment: "Walkthrough final button")) {
                            isPresented = false
                        }
                        .buttonStyle(.glassProminent)
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 40)
        }
        .background(Color(.systemBackground))
        .interactiveDismissDisabled()
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
        PhaseAnimator([false, true]) { phase in
            HStack(spacing: -8) {
                BlueberryView(size: 64, expression: .smile)
                    .offset(y: phase ? -6 : 2)
                    .rotationEffect(.degrees(phase ? -5 : -2))
                BlueberryView(size: 80, expression: .happy)
                    .offset(y: phase ? 3 : -3)
                    .zIndex(1)
                BlueberryView(size: 60, expression: .wink)
                    .offset(y: phase ? -4 : 4)
                    .rotationEffect(.degrees(phase ? 6 : 3))
            }
        } animation: { _ in .easeInOut(duration: 1.5) }
    }

    // Berry layouts from real puzzles, animated between two states
    private static let layoutA: [(Int, Int)] = [
        (0,2), (0,5), (0,7),
        (1,0), (1,3), (1,8),
        (2,1), (2,4), (2,6),
        (3,0), (3,5), (3,7),
        (4,2), (4,3), (4,8),
        (5,1), (5,4), (5,6),
        (6,3), (6,6), (6,8),
        (7,0), (7,2), (7,5),
        (8,1), (8,4), (8,7),
    ]

    private static let layoutB: [(Int, Int)] = [
        (0,0), (0,4), (0,8),
        (1,2), (1,5), (1,7),
        (2,1), (2,3), (2,6),
        (3,2), (3,4), (3,8),
        (4,0), (4,6), (4,7),
        (5,1), (5,3), (5,5),
        (6,4), (6,7), (6,8),
        (7,0), (7,2), (7,6),
        (8,1), (8,3), (8,5),
    ]

    private var gridIllustration: some View {
        PhaseAnimator([false, true]) { phase in
            Canvas { context, size in
                let gridSize = min(size.width, size.height) * 0.85
                let cellSize = gridSize / 9
                let offsetX = (size.width - gridSize) / 2
                let offsetY = (size.height - gridSize) / 2

                // Cell backgrounds
                for r in 0..<9 {
                    for c in 0..<9 {
                        let rect = CGRect(x: offsetX + Double(c) * cellSize + 0.5,
                                          y: offsetY + Double(r) * cellSize + 0.5,
                                          width: cellSize - 1, height: cellSize - 1)
                        context.fill(Path(roundedRect: rect, cornerRadius: 1),
                                     with: .color(Theme.cellBackground))
                    }
                }

                // Block lines
                for i in 0...3 {
                    let pos = Double(i) * cellSize * 3
                    var hLine = Path()
                    hLine.move(to: CGPoint(x: offsetX, y: offsetY + pos))
                    hLine.addLine(to: CGPoint(x: offsetX + gridSize, y: offsetY + pos))
                    context.stroke(hLine, with: .color(Theme.gridLineThick), lineWidth: 2)

                    var vLine = Path()
                    vLine.move(to: CGPoint(x: offsetX + pos, y: offsetY))
                    vLine.addLine(to: CGPoint(x: offsetX + pos, y: offsetY + gridSize))
                    context.stroke(vLine, with: .color(Theme.gridLineThick), lineWidth: 2)
                }

                // Animated berries
                let layout = phase ? Self.layoutB : Self.layoutA
                for (r, c) in layout {
                    let cx = offsetX + Double(c) * cellSize + cellSize / 2
                    let cy = offsetY + Double(r) * cellSize + cellSize / 2
                    let br = cellSize * 0.3
                    context.fill(Path(ellipseIn: CGRect(x: cx - br, y: cy - br, width: br * 2, height: br * 2)),
                                 with: .color(Theme.berryBlue))
                }
            }
        } animation: { _ in .easeInOut(duration: 1.8) }
    }

    // Animated clue demonstration: berries appear one-by-one around a "3" clue
    // Phases: 0=empty grid with clue, 1=first berry, 2=second berry, 3=third berry + crossed empties, 4=pause then reset
    private var clueIllustration: some View {
        PhaseAnimator([0, 1, 2, 3, 4]) { phase in
            // Grid positions: (row, col) -> content
            // Center is the clue "3", berries appear at (0,0), (0,2), (2,2)
            let berryPositions: [(Int, Int)] = [(0, 0), (0, 2), (2, 2)]
            let crossedPositions: [(Int, Int)] = [(0, 1), (1, 0), (1, 2), (2, 0), (2, 1)]
            let berriesShown = min(phase, 3)

            VStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(0..<3, id: \.self) { col in
                            let isBerry = berryPositions.prefix(berriesShown).contains { $0.0 == row && $0.1 == col }
                            let isCrossed = phase >= 3 && crossedPositions.contains { $0.0 == row && $0.1 == col }
                            let isClue = row == 1 && col == 1
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
                        .font(.system(size: 10))
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
