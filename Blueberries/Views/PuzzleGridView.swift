import SwiftUI

struct PuzzleGridView: View {
    @Bindable var model: PuzzleModel
    var autoCheck: Bool = true
    var hapticsEnabled: Bool = false
    var soundService: SoundService?
    var onStateChanged: (() -> Void)?

    @State private var dragState: DragState?
    @State private var cellSize: Double = 0
    @State private var hapticTrigger: Int = 0
    @State private var errorDelayTask: Task<Void, Never>?

    private struct DragState {
        let fromState: CellState
        let toState: CellState
        var lastCell: CellID?
    }

    var body: some View {
        Canvas { context, size in
            let cs = min(size.width, size.height) / Double(model.numColumns)
            drawGrid(context: context, cellSize: cs, canvasSize: size)
        }
        .aspectRatio(1, contentMode: .fit)
        .frame(maxWidth: 500)
        .clipShape(.rect(cornerRadius: 6))
        .shadow(color: .black.opacity(0.08), radius: 8, y: 2)
        .onGeometryChange(for: Double.self) { proxy in
            min(proxy.size.width, proxy.size.height) / Double(model.numColumns)
        } action: { newValue in
            cellSize = newValue
        }
        .contentShape(Rectangle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { value in
                    guard !model.isSolved else { return }
                    let cell = cellAt(point: value.location)
                    guard let cell, model.isInteractive(cell) else { return }

                    if model.hintedCell != nil {
                        model.hintedCell = nil
                    }

                    if dragState == nil {
                        let currentState = model.cells[cell] ?? .undecided
                        let nextState = currentState.next
                        model.applyCell(cell, to: nextState)
                        dragState = DragState(fromState: currentState, toState: nextState, lastCell: cell)
                        hapticTrigger += 1
                        soundService?.playTap()
                        scheduleErrorDelay()
                    } else if let ds = dragState, cell != ds.lastCell {
                        model.applyCell(cell, to: ds.toState)
                        dragState?.lastCell = cell
                        hapticTrigger += 1
                        soundService?.playTap()
                        scheduleErrorDelay()
                    }
                }
                .onEnded { _ in
                    dragState = nil
                    onStateChanged?()
                }
        )
        .defersSystemGestures(on: .all)
        .sensoryFeedback(.impact(flexibility: .solid, intensity: 0.5), trigger: hapticTrigger) { _, _ in
            hapticsEnabled
        }
        .accessibilityElement(children: .contain)
        .overlay {
            accessibilityGrid
        }
    }

    // MARK: - Error Delay

    private func scheduleErrorDelay() {
        errorDelayTask?.cancel()
        errorDelayTask = Task {
            try? await Task.sleep(for: .milliseconds(150))
            if !Task.isCancelled {
                model.recentlyPlacedBerries.removeAll()
            }
            try? await Task.sleep(for: .milliseconds(850))
            if !Task.isCancelled {
                model.showErrors = true
            }
        }
    }

    // MARK: - Accessibility

    private var accessibilityGrid: some View {
        Grid(horizontalSpacing: 0, verticalSpacing: 0) {
            ForEach(0..<model.numRows, id: \.self) { row in
                GridRow {
                    ForEach(0..<model.numColumns, id: \.self) { col in
                        let cell = CellID(row: row, column: col)
                        Color.clear
                            .accessibilityLabel(accessibilityLabel(for: cell))
                            .accessibilityAddTraits(.isButton)
                            .accessibilityAction {
                                if model.isInteractive(cell) {
                                    model.tapCell(cell)
                                    onStateChanged?()
                                }
                            }
                    }
                }
            }
        }
    }

    private func accessibilityLabel(for cell: CellID) -> String {
        let state = model.cells[cell] ?? .undecided
        let row = cell.row + 1
        let col = cell.column + 1

        if let clue = model.clueForCell[cell] {
            return String(localized: "Row \(row), column \(col), clue \(clue)")
        }

        let stateDesc: String = switch state {
        case .undecided: String(localized: "empty")
        case .empty: String(localized: "crossed")
        case .berry: String(localized: "berry")
        }
        return String(localized: "Row \(row), column \(col), \(stateDesc)")
    }

    // MARK: - Hit Testing

    private func cellAt(point: CGPoint) -> CellID? {
        guard cellSize > 0 else { return nil }
        let col = Int(point.x / cellSize)
        let row = Int(point.y / cellSize)
        guard row >= 0, row < model.numRows, col >= 0, col < model.numColumns else {
            return nil
        }
        return CellID(row: row, column: col)
    }

    // MARK: - Drawing

    private func drawGrid(context: GraphicsContext, cellSize: Double, canvasSize: CGSize) {
        let check = autoCheck ? model.lastCheck : nil
        let berryRadius = cellSize * 0.3
        let dotRadius = cellSize * 0.06
        let shouldShowErrors = model.showErrors && autoCheck
        let celebrating = model.celebrationProgress > 0

        // Cell backgrounds with subtle rounded rects
        let cellInset = 1.0
        for cell in model.allCells {
            let rect = cellRect(cell, cellSize: cellSize)
            let insetRect = rect.insetBy(dx: cellInset, dy: cellInset)
            let isError = shouldShowErrors && (check?.errorCells.contains(cell) ?? false)
            let isHinted = model.hintedCell == cell

            // Celebration color cascade
            let isCelebrated = celebrating && celebrationReached(cell)

            let bgColor: Color
            if isCelebrated {
                bgColor = Theme.berryBlue.opacity(0.2)
            } else if isError {
                bgColor = Theme.errorCell
            } else {
                bgColor = Theme.cellBackground
            }

            let cellPath = Path(roundedRect: insetRect, cornerRadius: 2)
            context.fill(cellPath, with: .color(bgColor))

            if isHinted {
                context.fill(cellPath, with: .color(Theme.hintHighlight))
            }
        }

        // Thin grid lines — subtle, anti-aliased
        drawThinGridLines(context: context, cellSize: cellSize)

        // Block boundaries — refined thickness with round caps
        drawBlockBoundaries(context: context, cellSize: cellSize)

        // Cell contents
        for cell in model.allCells {
            let rect = cellRect(cell, cellSize: cellSize)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let state = model.cells[cell] ?? .undecided

            if let clue = model.clueForCell[cell] {
                let group = GroupID.number(cell)
                let isSatisfied = check?.satisfiedGroups.contains(group) ?? false
                let isGroupError = shouldShowErrors && (check?.errorGroups.contains(group) ?? false)

                let textColor: Color = isGroupError ? Theme.errorText : Theme.clueText
                let opacity = isSatisfied ? Theme.satisfiedClueOpacity : 1.0

                var textContext = context
                textContext.opacity = opacity
                let text = Text("\(clue)")
                    .font(.system(size: cellSize * 0.5, weight: .semibold, design: .rounded))
                    .foregroundStyle(textColor)
                textContext.draw(text, at: center)
            } else if state == .berry {
                let isNew = model.recentlyPlacedBerries.contains(cell)
                let scale = isNew ? 1.15 : 1.0
                let r = berryRadius * scale

                // Berry with subtle gradient effect via layered circles
                let berryPath = Path(ellipseIn: CGRect(
                    x: center.x - r, y: center.y - r, width: r * 2, height: r * 2
                ))
                context.fill(berryPath, with: .color(Theme.berryBlue))

                // Highlight spot
                let highlightR = r * 0.35
                let highlightPath = Path(ellipseIn: CGRect(
                    x: center.x - r * 0.25 - highlightR,
                    y: center.y - r * 0.3 - highlightR,
                    width: highlightR * 2,
                    height: highlightR * 2
                ))
                context.fill(highlightPath, with: .color(.white.opacity(0.25)))
            } else if state == .empty {
                // Refined X mark instead of dot
                let xSize = cellSize * 0.12
                var xPath = Path()
                xPath.move(to: CGPoint(x: center.x - xSize, y: center.y - xSize))
                xPath.addLine(to: CGPoint(x: center.x + xSize, y: center.y + xSize))
                xPath.move(to: CGPoint(x: center.x + xSize, y: center.y - xSize))
                xPath.addLine(to: CGPoint(x: center.x - xSize, y: center.y + xSize))
                context.stroke(xPath, with: .color(Theme.emptyDot), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            }
        }
    }

    private func celebrationReached(_ cell: CellID) -> Bool {
        let totalRows = Double(model.numRows)
        let rowProgress = (Double(cell.row) + 0.5) / totalRows
        return model.celebrationProgress >= rowProgress
    }

    private func drawThinGridLines(context: GraphicsContext, cellSize: Double) {
        let totalWidth = cellSize * Double(model.numColumns)
        let totalHeight = cellSize * Double(model.numRows)

        var path = Path()
        for r in 1..<model.numRows {
            let y = Double(r) * cellSize
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: totalWidth, y: y))
        }
        for c in 1..<model.numColumns {
            let x = Double(c) * cellSize
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: totalHeight))
        }
        context.stroke(path, with: .color(Theme.gridLineThin.opacity(0.5)), lineWidth: 0.5)
    }

    private func drawBlockBoundaries(context: GraphicsContext, cellSize: Double) {
        var path = Path()

        for r in 0..<model.numRows {
            for c in 0..<model.numColumns {
                let cell = CellID(row: r, column: c)
                let block = model.blockOfCell[cell] ?? 0

                if c < model.numColumns - 1 {
                    let rightCell = CellID(row: r, column: c + 1)
                    let rightBlock = model.blockOfCell[rightCell] ?? 0
                    if block != rightBlock {
                        let x = Double(c + 1) * cellSize
                        let y = Double(r) * cellSize
                        path.move(to: CGPoint(x: x, y: y))
                        path.addLine(to: CGPoint(x: x, y: y + cellSize))
                    }
                }

                if r < model.numRows - 1 {
                    let bottomCell = CellID(row: r + 1, column: c)
                    let bottomBlock = model.blockOfCell[bottomCell] ?? 0
                    if block != bottomBlock {
                        let x = Double(c) * cellSize
                        let y = Double(r + 1) * cellSize
                        path.move(to: CGPoint(x: x, y: y))
                        path.addLine(to: CGPoint(x: x + cellSize, y: y))
                    }
                }
            }
        }

        context.stroke(path, with: .color(Theme.gridLineThick), style: StrokeStyle(lineWidth: 2, lineCap: .round))

        // Outer border — slightly thicker, rounded corners handled by clipShape
        let totalWidth = cellSize * Double(model.numColumns)
        let totalHeight = cellSize * Double(model.numRows)
        let borderPath = Path(CGRect(x: 0, y: 0, width: totalWidth, height: totalHeight))
        context.stroke(borderPath, with: .color(Theme.gridLineThick), lineWidth: 2.5)
    }

    private func cellRect(_ cell: CellID, cellSize: Double) -> CGRect {
        CGRect(
            x: Double(cell.column) * cellSize,
            y: Double(cell.row) * cellSize,
            width: cellSize,
            height: cellSize
        )
    }
}
