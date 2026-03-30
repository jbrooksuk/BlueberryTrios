import SwiftUI

/// A single blueberry with two leaves, matching the original icon style.
struct BlueberryView: View {
    var size: Double = 40

    private var berryBlue: Color { Color(red: 0.19, green: 0.45, blue: 0.74) }
    private var leafGreen: Color { Color(red: 0.18, green: 0.81, blue: 0.32) }

    var body: some View {
        Canvas { context, canvasSize in
            let s = min(canvasSize.width, canvasSize.height)
            let cx = canvasSize.width / 2
            let cy = canvasSize.height * 0.55

            // Berry body
            let berryRadius = s * 0.38
            let berryRect = CGRect(
                x: cx - berryRadius, y: cy - berryRadius,
                width: berryRadius * 2, height: berryRadius * 2
            )
            context.fill(Path(ellipseIn: berryRect), with: .color(berryBlue))

            // Berry highlight
            let hlRadius = berryRadius * 0.3
            let hlRect = CGRect(
                x: cx - berryRadius * 0.3 - hlRadius,
                y: cy - berryRadius * 0.35 - hlRadius,
                width: hlRadius * 2, height: hlRadius * 2
            )
            context.fill(Path(ellipseIn: hlRect), with: .color(.white.opacity(0.2)))

            // Left leaf
            let leafBase = CGPoint(x: cx - berryRadius * 0.1, y: cy - berryRadius * 0.85)
            var leftLeaf = Path()
            leftLeaf.move(to: leafBase)
            leftLeaf.addQuadCurve(
                to: CGPoint(x: cx - berryRadius * 0.9, y: cy - berryRadius * 1.4),
                control: CGPoint(x: cx - berryRadius * 0.7, y: cy - berryRadius * 0.7)
            )
            leftLeaf.addQuadCurve(
                to: leafBase,
                control: CGPoint(x: cx - berryRadius * 0.2, y: cy - berryRadius * 1.3)
            )
            context.fill(leftLeaf, with: .color(leafGreen))

            // Right leaf
            var rightLeaf = Path()
            rightLeaf.move(to: CGPoint(x: cx + berryRadius * 0.05, y: cy - berryRadius * 0.9))
            rightLeaf.addQuadCurve(
                to: CGPoint(x: cx + berryRadius * 0.65, y: cy - berryRadius * 1.35),
                control: CGPoint(x: cx + berryRadius * 0.15, y: cy - berryRadius * 1.25)
            )
            rightLeaf.addQuadCurve(
                to: CGPoint(x: cx + berryRadius * 0.05, y: cy - berryRadius * 0.9),
                control: CGPoint(x: cx + berryRadius * 0.55, y: cy - berryRadius * 0.85)
            )
            context.fill(rightLeaf, with: .color(leafGreen))
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    HStack(spacing: 20) {
        BlueberryView(size: 80)
        BlueberryView(size: 50)
        BlueberryView(size: 30)
    }
    .padding()
}
