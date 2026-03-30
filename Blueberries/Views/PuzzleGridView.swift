import SwiftUI

struct PuzzleGridView: View {
    @Bindable var model: PuzzleModel
    var autoCheck: Bool = true
    var hapticsEnabled: Bool = false
    var onStateChanged: (() -> Void)?

    @State private var dragState: DragState?
    @State private var cellSize: Double = 0
    @State private var hapticTrigger: Int = 0

    private struct DragState {
        let fromState: CellState
        let toState: CellState
        var lastCell: CellID?
    }

    var body: some View {
        Canvas { context, size in
            let cs = min(size.width, size.height) / Double(model.numColumns)
            drawGrid(context: context, cellSize: cs)
        }
        .aspectRatio(1, contentMode: .fit)
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
                        model.beginDrag()
                        model.dragSetCell(cell, to: nextState)
                        dragState = DragState(fromState: currentState, toState: nextState, lastCell: cell)
                        hapticTrigger += 1
                    } else if let ds = dragState, cell != ds.lastCell {
                        model.dragSetCell(cell, to: ds.toState)
                        dragState?.lastCell = cell
                        hapticTrigger += 1
                    }
                }
                .onEnded { _ in
                    model.endDrag()
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
            return "Row \(row), column \(col), clue \(clue)"
        }

        let stateDesc: String = switch state {
        case .undecided: "empty"
        case .empty: "crossed"
        case .berry: "berry"
        }
        return "Row \(row), column \(col), \(stateDesc)"
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

    private func drawGrid(context: GraphicsContext, cellSize: Double) {
        let check = autoCheck ? model.lastCheck : nil
        let berryRadius = cellSize * 0.3
        let dotRadius = cellSize * 0.06

        for cell in model.allCells {
            let rect = cellRect(cell, cellSize: cellSize)
            let isError = check?.errorCells.contains(cell) ?? false
            let isHinted = model.hintedCell == cell

            let bgColor: Color = isError ? Theme.errorCell : Theme.cellBackground
            context.fill(Path(rect), with: .color(bgColor))

            if isHinted {
                context.fill(Path(rect), with: .color(Theme.hintHighlight))
            }
        }

        drawThinGridLines(context: context, cellSize: cellSize)
        drawBlockBoundaries(context: context, cellSize: cellSize)

        for cell in model.allCells {
            let rect = cellRect(cell, cellSize: cellSize)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let state = model.cells[cell] ?? .undecided

            if let clue = model.clueForCell[cell] {
                let group = GroupID.number(cell)
                let isSatisfied = check?.satisfiedGroups.contains(group) ?? false
                let isGroupError = check?.errorGroups.contains(group) ?? false

                let textColor: Color = isGroupError ? Theme.errorText : Theme.clueText
                let opacity = isSatisfied ? Theme.satisfiedClueOpacity : 1.0

                var textContext = context
                textContext.opacity = opacity
                let text = Text("\(clue)")
                    .font(.system(size: cellSize * 0.55, weight: .medium, design: .rounded))
                    .foregroundStyle(textColor)
                textContext.draw(text, at: center)
            } else if state == .berry {
                let berryPath = Path(ellipseIn: CGRect(
                    x: center.x - berryRadius,
                    y: center.y - berryRadius,
                    width: berryRadius * 2,
                    height: berryRadius * 2
                ))
                context.fill(berryPath, with: .color(Theme.berryBlue))
            } else if state == .empty {
                let dotPath = Path(ellipseIn: CGRect(
                    x: center.x - dotRadius,
                    y: center.y - dotRadius,
                    width: dotRadius * 2,
                    height: dotRadius * 2
                ))
                context.fill(dotPath, with: .color(Theme.emptyDot))
            }
        }
    }

    private func drawThinGridLines(context: GraphicsContext, cellSize: Double) {
        let totalWidth = cellSize * Double(model.numColumns)
        let totalHeight = cellSize * Double(model.numRows)

        var path = Path()
        for r in 0...model.numRows {
            let y = Double(r) * cellSize
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: totalWidth, y: y))
        }
        for c in 0...model.numColumns {
            let x = Double(c) * cellSize
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: totalHeight))
        }
        context.stroke(path, with: .color(Theme.gridLineThin), lineWidth: 0.5)
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

        let totalWidth = cellSize * Double(model.numColumns)
        let totalHeight = cellSize * Double(model.numRows)
        path.addRect(CGRect(x: 0, y: 0, width: totalWidth, height: totalHeight))

        context.stroke(path, with: .color(Theme.gridLineThick), style: StrokeStyle(lineWidth: 2, lineCap: .square))
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
