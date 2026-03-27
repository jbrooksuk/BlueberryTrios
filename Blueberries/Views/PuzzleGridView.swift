import SwiftUI
import UIKit

struct PuzzleGridView: View {
    @Bindable var model: PuzzleModel
    var autoCheck: Bool = true
    var hapticsEnabled: Bool = false
    var onStateChanged: (() -> Void)?

    @State private var dragState: DragState?
    @State private var lightImpact = UIImpactFeedbackGenerator(style: .light)

    private struct DragState {
        let fromState: CellState
        let toState: CellState
        var lastCell: CellID?
    }

    var body: some View {
        GeometryReader { geo in
            let gridSize = min(geo.size.width, geo.size.height)
            let cellSize = gridSize / CGFloat(model.numColumns)

            Canvas { context, size in
                drawGrid(context: context, cellSize: cellSize)
            }
            .frame(width: gridSize, height: gridSize)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        let cell = cellAt(point: value.location, cellSize: cellSize)
                        guard let cell, model.isInteractive(cell) else { return }

                        // Clear hint highlight on any interaction
                        if model.hintedCell != nil {
                            model.hintedCell = nil
                        }

                        if dragState == nil {
                            // First touch — determine transition
                            let currentState = model.cells[cell] ?? .undecided
                            let nextState = currentState.next
                            model.beginDrag()
                            model.dragSetCell(cell, to: nextState)
                            dragState = DragState(fromState: currentState, toState: nextState, lastCell: cell)
                            if hapticsEnabled { lightImpact.impactOccurred() }
                        } else if let ds = dragState, cell != ds.lastCell {
                            // Dragging over a new cell
                            model.dragSetCell(cell, to: ds.toState)
                            dragState?.lastCell = cell
                            if hapticsEnabled { lightImpact.impactOccurred() }
                        }
                    }
                    .onEnded { _ in
                        model.endDrag()
                        dragState = nil
                        onStateChanged?()
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func cellAt(point: CGPoint, cellSize: CGFloat) -> CellID? {
        let col = Int(point.x / cellSize)
        let row = Int(point.y / cellSize)
        guard row >= 0 && row < model.numRows && col >= 0 && col < model.numColumns else {
            return nil
        }
        return CellID(row: row, column: col)
    }

    // MARK: - Drawing

    private func drawGrid(context: GraphicsContext, cellSize: CGFloat) {
        let check = autoCheck ? model.lastCheck : nil
        let berryRadius = cellSize * 0.3
        let dotRadius = cellSize * 0.06

        // Draw cell backgrounds
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

        // Draw thin grid lines
        drawThinGridLines(context: context, cellSize: cellSize)

        // Draw block boundaries (thick lines)
        drawBlockBoundaries(context: context, cellSize: cellSize)

        // Draw cell contents
        for cell in model.allCells {
            let rect = cellRect(cell, cellSize: cellSize)
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let state = model.cells[cell] ?? .undecided

            if let clue = model.clueForCell[cell] {
                // Draw number clue
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
                // Draw berry circle
                let berryPath = Path(ellipseIn: CGRect(
                    x: center.x - berryRadius,
                    y: center.y - berryRadius,
                    width: berryRadius * 2,
                    height: berryRadius * 2
                ))
                context.fill(berryPath, with: .color(Theme.berryBlue))
            } else if state == .empty {
                // Draw small dot for crossed/empty cells
                let dotPath = Path(ellipseIn: CGRect(
                    x: center.x - dotRadius,
                    y: center.y - dotRadius,
                    width: dotRadius * 2,
                    height: dotRadius * 2
                ))
                context.fill(dotPath, with: .color(Theme.emptyDot))
            }
            // undecided cells show nothing
        }
    }

    private func drawThinGridLines(context: GraphicsContext, cellSize: CGFloat) {
        let totalWidth = cellSize * CGFloat(model.numColumns)
        let totalHeight = cellSize * CGFloat(model.numRows)

        var path = Path()
        // Horizontal lines
        for r in 0...model.numRows {
            let y = CGFloat(r) * cellSize
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: totalWidth, y: y))
        }
        // Vertical lines
        for c in 0...model.numColumns {
            let x = CGFloat(c) * cellSize
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: totalHeight))
        }
        context.stroke(path, with: .color(Theme.gridLineThin), lineWidth: 0.5)
    }

    private func drawBlockBoundaries(context: GraphicsContext, cellSize: CGFloat) {
        var path = Path()

        for r in 0..<model.numRows {
            for c in 0..<model.numColumns {
                let cell = CellID(row: r, column: c)
                let block = model.blockOfCell[cell] ?? 0

                // Right edge
                if c < model.numColumns - 1 {
                    let rightCell = CellID(row: r, column: c + 1)
                    let rightBlock = model.blockOfCell[rightCell] ?? 0
                    if block != rightBlock {
                        let x = CGFloat(c + 1) * cellSize
                        let y = CGFloat(r) * cellSize
                        path.move(to: CGPoint(x: x, y: y))
                        path.addLine(to: CGPoint(x: x, y: y + cellSize))
                    }
                }

                // Bottom edge
                if r < model.numRows - 1 {
                    let bottomCell = CellID(row: r + 1, column: c)
                    let bottomBlock = model.blockOfCell[bottomCell] ?? 0
                    if block != bottomBlock {
                        let x = CGFloat(c) * cellSize
                        let y = CGFloat(r + 1) * cellSize
                        path.move(to: CGPoint(x: x, y: y))
                        path.addLine(to: CGPoint(x: x + cellSize, y: y))
                    }
                }
            }
        }

        // Outer border
        let totalWidth = cellSize * CGFloat(model.numColumns)
        let totalHeight = cellSize * CGFloat(model.numRows)
        path.addRect(CGRect(x: 0, y: 0, width: totalWidth, height: totalHeight))

        context.stroke(path, with: .color(Theme.gridLineThick), style: StrokeStyle(lineWidth: 2, lineCap: .square))
    }

    private func cellRect(_ cell: CellID, cellSize: CGFloat) -> CGRect {
        CGRect(
            x: CGFloat(cell.column) * cellSize,
            y: CGFloat(cell.row) * cellSize,
            width: cellSize,
            height: cellSize
        )
    }
}
