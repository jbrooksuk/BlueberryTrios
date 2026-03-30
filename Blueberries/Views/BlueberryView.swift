import SwiftUI

/// A kawaii blueberry matching the app icon style.
struct BlueberryView: View {
    var size: Double = 40
    var expression: Expression = .happy

    enum Expression {
        case happy, wink, smile
    }

    // Colors sampled from the app icon
    private let berryBody = Color(red: 0.50, green: 0.55, blue: 0.68)
    private let berryLight = Color(red: 0.58, green: 0.62, blue: 0.74)
    private let berryShadow = Color(red: 0.38, green: 0.42, blue: 0.55)
    private let calyxColor = Color(red: 0.32, green: 0.36, blue: 0.52)
    private let blushColor = Color(red: 0.92, green: 0.58, blue: 0.52)

    var body: some View {
        Canvas { context, canvasSize in
            let s = min(canvasSize.width, canvasSize.height)
            let cx = canvasSize.width / 2
            let cy = canvasSize.height * 0.55
            let r = s * 0.40

            // Berry body
            let bodyRect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
            context.fill(Path(ellipseIn: bodyRect), with: .color(berryBody))

            // Lighter top half overlay
            let topRect = CGRect(x: cx - r * 0.85, y: cy - r * 0.95, width: r * 1.7, height: r * 1.2)
            context.fill(Path(ellipseIn: topRect), with: .color(berryLight.opacity(0.4)))

            // Bottom shadow
            let shadowRect = CGRect(x: cx - r * 0.7, y: cy + r * 0.4, width: r * 1.4, height: r * 0.5)
            context.fill(Path(ellipseIn: shadowRect), with: .color(berryShadow.opacity(0.35)))

            // Star calyx at top
            drawCalyx(context: context, cx: cx, cy: cy - r * 0.82, size: r * 0.38)

            // White highlight spots
            let hl1 = CGRect(x: cx - r * 0.5, y: cy - r * 0.6,
                             width: r * 0.25, height: r * 0.32)
            context.fill(Path(ellipseIn: hl1), with: .color(.white.opacity(0.5)))

            let hl2 = CGRect(x: cx - r * 0.2, y: cy - r * 0.4,
                             width: r * 0.13, height: r * 0.16)
            context.fill(Path(ellipseIn: hl2), with: .color(.white.opacity(0.35)))

            // Face
            drawFace(context: context, cx: cx, cy: cy + r * 0.08, r: r)
        }
        .frame(width: size, height: size)
    }

    // MARK: - Star Calyx

    private func drawCalyx(context: GraphicsContext, cx: Double, cy: Double, size: Double) {
        // 5-pointed star/X blossom end
        let points = 5
        for i in 0..<points {
            let angle = (Double(i) * 360.0 / Double(points) - 90) * .pi / 180
            let tipX = cx + cos(angle) * size
            let tipY = cy + sin(angle) * size * 0.7

            let spread = 18.0 * .pi / 180
            let baseR = size * 0.3

            var petal = Path()
            petal.move(to: CGPoint(x: cx + cos(angle - spread) * baseR,
                                    y: cy + sin(angle - spread) * baseR * 0.7))
            petal.addQuadCurve(
                to: CGPoint(x: tipX, y: tipY),
                control: CGPoint(x: cx + cos(angle - spread * 0.5) * size * 0.8,
                                  y: cy + sin(angle - spread * 0.5) * size * 0.6)
            )
            petal.addQuadCurve(
                to: CGPoint(x: cx + cos(angle + spread) * baseR,
                             y: cy + sin(angle + spread) * baseR * 0.7),
                control: CGPoint(x: cx + cos(angle + spread * 0.5) * size * 0.8,
                                  y: cy + sin(angle + spread * 0.5) * size * 0.6)
            )
            petal.closeSubpath()
            context.fill(petal, with: .color(calyxColor))
        }

        // Center dot
        let dotSize = size * 0.25
        context.fill(Path(ellipseIn: CGRect(x: cx - dotSize, y: cy - dotSize * 0.7,
                                             width: dotSize * 2, height: dotSize * 1.4)),
                     with: .color(calyxColor))
    }

    // MARK: - Face

    private func drawFace(context: GraphicsContext, cx: Double, cy: Double, r: Double) {
        let eyeSpacing = r * 0.30
        let eyeSize = r * 0.095
        let eyeY = cy - r * 0.02

        // Left eye
        let leftEyeRect = CGRect(x: cx - eyeSpacing - eyeSize,
                                  y: eyeY - eyeSize * 1.1,
                                  width: eyeSize * 2, height: eyeSize * 2.2)
        context.fill(Path(ellipseIn: leftEyeRect), with: .color(.black.opacity(0.85)))

        // Left eye shine
        let shineSize = eyeSize * 0.7
        context.fill(Path(ellipseIn: CGRect(x: cx - eyeSpacing + eyeSize * 0.1,
                                             y: eyeY - eyeSize * 0.8,
                                             width: shineSize, height: shineSize)),
                     with: .color(.white))

        // Right eye
        if expression == .wink {
            var wink = Path()
            let wx = cx + eyeSpacing
            wink.move(to: CGPoint(x: wx - eyeSize * 1.0, y: eyeY))
            wink.addQuadCurve(
                to: CGPoint(x: wx + eyeSize * 1.0, y: eyeY),
                control: CGPoint(x: wx, y: eyeY + eyeSize * 1.2)
            )
            context.stroke(wink, with: .color(.black.opacity(0.85)),
                          style: StrokeStyle(lineWidth: r * 0.035, lineCap: .round))
        } else {
            let rightEyeRect = CGRect(x: cx + eyeSpacing - eyeSize,
                                       y: eyeY - eyeSize * 1.1,
                                       width: eyeSize * 2, height: eyeSize * 2.2)
            context.fill(Path(ellipseIn: rightEyeRect), with: .color(.black.opacity(0.85)))

            context.fill(Path(ellipseIn: CGRect(x: cx + eyeSpacing + eyeSize * 0.1,
                                                 y: eyeY - eyeSize * 0.8,
                                                 width: shineSize, height: shineSize)),
                         with: .color(.white))
        }

        // Blush cheeks
        let blushW = r * 0.16
        let blushH = r * 0.10
        let blushY = cy + r * 0.1
        context.fill(Path(ellipseIn: CGRect(x: cx - eyeSpacing - blushW * 1.4,
                                             y: blushY, width: blushW * 1.6, height: blushH)),
                     with: .color(blushColor.opacity(0.45)))
        context.fill(Path(ellipseIn: CGRect(x: cx + eyeSpacing - blushW * 0.2,
                                             y: blushY, width: blushW * 1.6, height: blushH)),
                     with: .color(blushColor.opacity(0.45)))

        // Mouth
        let mouthY = cy + r * 0.18
        switch expression {
        case .happy:
            // Open smile with tongue
            var mouth = Path()
            mouth.move(to: CGPoint(x: cx - r * 0.11, y: mouthY))
            mouth.addQuadCurve(
                to: CGPoint(x: cx + r * 0.11, y: mouthY),
                control: CGPoint(x: cx, y: mouthY + r * 0.13)
            )
            mouth.closeSubpath()
            context.fill(mouth, with: .color(.black.opacity(0.75)))

            // Tongue
            let tongueRect = CGRect(x: cx - r * 0.04, y: mouthY + r * 0.04,
                                     width: r * 0.08, height: r * 0.05)
            context.fill(Path(ellipseIn: tongueRect), with: .color(blushColor.opacity(0.6)))

        case .wink, .smile:
            // Curved smile
            var mouth = Path()
            mouth.move(to: CGPoint(x: cx - r * 0.09, y: mouthY))
            mouth.addQuadCurve(
                to: CGPoint(x: cx + r * 0.09, y: mouthY),
                control: CGPoint(x: cx, y: mouthY + r * 0.08)
            )
            context.stroke(mouth, with: .color(.black.opacity(0.75)),
                          style: StrokeStyle(lineWidth: r * 0.035, lineCap: .round))
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        BlueberryView(size: 100, expression: .happy)
        BlueberryView(size: 80, expression: .wink)
        BlueberryView(size: 60, expression: .smile)
    }
    .padding(40)
    .background(Color(red: 0.68, green: 0.82, blue: 0.95))
}
