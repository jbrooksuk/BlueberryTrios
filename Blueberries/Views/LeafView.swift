import SwiftUI

/// A single kawaii leaf matching the app icon style.
struct LeafView: View {
    var size: Double = 40
    var flipped: Bool = false

    private let leafGreen = Color(red: 0.35, green: 0.65, blue: 0.25)
    private let leafDark = Color(red: 0.25, green: 0.50, blue: 0.18)
    private let veinColor = Color(red: 0.28, green: 0.55, blue: 0.20)

    var body: some View {
        Canvas { context, canvasSize in
            let w = canvasSize.width
            let h = canvasSize.height
            let flipX: Double = flipped ? -1 : 1

            // Leaf body
            var leaf = Path()
            leaf.move(to: CGPoint(x: w * 0.5, y: h * 0.95))
            leaf.addQuadCurve(
                to: CGPoint(x: w * (0.5 + 0.45 * flipX), y: h * 0.05),
                control: CGPoint(x: w * (0.5 + 0.55 * flipX), y: h * 0.5)
            )
            leaf.addQuadCurve(
                to: CGPoint(x: w * 0.5, y: h * 0.95),
                control: CGPoint(x: w * (0.5 - 0.1 * flipX), y: h * 0.35)
            )
            context.fill(leaf, with: .color(leafGreen))

            // Central vein
            var vein = Path()
            vein.move(to: CGPoint(x: w * 0.5, y: h * 0.9))
            vein.addQuadCurve(
                to: CGPoint(x: w * (0.5 + 0.3 * flipX), y: h * 0.15),
                control: CGPoint(x: w * (0.5 + 0.2 * flipX), y: h * 0.5)
            )
            context.stroke(vein, with: .color(veinColor), lineWidth: 1.2)

            // Side veins
            for t in stride(from: 0.3, through: 0.7, by: 0.2) {
                let baseX = w * (0.5 + 0.2 * flipX * t)
                let baseY = h * (0.9 - 0.7 * t)
                var sideVein = Path()
                sideVein.move(to: CGPoint(x: baseX, y: baseY))
                sideVein.addLine(to: CGPoint(
                    x: baseX + w * 0.12 * flipX,
                    y: baseY - h * 0.08
                ))
                context.stroke(sideVein, with: .color(veinColor), lineWidth: 0.8)
            }
        }
        .frame(width: size * 0.6, height: size)
    }
}

#Preview {
    HStack(spacing: 20) {
        LeafView(size: 80, flipped: false)
        LeafView(size: 80, flipped: true)
        LeafView(size: 50, flipped: false)
    }
    .padding(40)
    .background(Color(red: 0.68, green: 0.82, blue: 0.95))
}
