import SwiftUI

/// A kawaii blueberry matching the app icon style.
struct BlueberryView: View {
    var size: Double = 40
    var expression: Expression = .happy

    enum Expression {
        case happy, wink, smile
    }

    // Colors — richer blue-purple matching the app icon
    private let berryBody = Color(red: 0.45, green: 0.48, blue: 0.64)
    private let berryLight = Color(red: 0.55, green: 0.58, blue: 0.72)
    private let berryShadow = Color(red: 0.32, green: 0.35, blue: 0.50)
    private let calyxColor = Color(red: 0.30, green: 0.34, blue: 0.50)
    private let blushColor = Color(red: 0.94, green: 0.52, blue: 0.48)

    var body: some View {
        Canvas { context, canvasSize in
            let s = min(canvasSize.width, canvasSize.height)
            let cx = canvasSize.width / 2
            let cy = canvasSize.height * 0.55
            let r = s * 0.40

            // Berry body — base
            let bodyRect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
            context.fill(Path(ellipseIn: bodyRect), with: .color(berryBody))

            // Lighter top half — gives 3D roundness
            let topRect = CGRect(x: cx - r * 0.8, y: cy - r * 0.9, width: r * 1.6, height: r * 1.1)
            context.fill(Path(ellipseIn: topRect), with: .color(berryLight.opacity(0.45)))

            // Bottom shadow crescent
            let shadowRect = CGRect(x: cx - r * 0.65, y: cy + r * 0.35, width: r * 1.3, height: r * 0.55)
            context.fill(Path(ellipseIn: shadowRect), with: .color(berryShadow.opacity(0.4)))

            // Star calyx at top
            drawCalyx(context: context, cx: cx, cy: cy - r * 0.82, size: r * 0.35)

            // White highlight spots — bigger and more visible
            let hl1 = CGRect(x: cx - r * 0.52, y: cy - r * 0.62,
                             width: r * 0.3, height: r * 0.38)
            context.fill(Path(ellipseIn: hl1), with: .color(.white.opacity(0.55)))

            let hl2 = CGRect(x: cx - r * 0.18, y: cy - r * 0.38,
                             width: r * 0.16, height: r * 0.2)
            context.fill(Path(ellipseIn: hl2), with: .color(.white.opacity(0.4)))

            // Face — bigger features
            drawFace(context: context, cx: cx, cy: cy + r * 0.05, r: r)
        }
        .frame(width: size, height: size)
    }

    // MARK: - Star Calyx

    private func drawCalyx(context: GraphicsContext, cx: Double, cy: Double, size: Double) {
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

        let dotSize = size * 0.25
        context.fill(Path(ellipseIn: CGRect(x: cx - dotSize, y: cy - dotSize * 0.7,
                                             width: dotSize * 2, height: dotSize * 1.4)),
                     with: .color(calyxColor))
    }

    // MARK: - Face

    private func drawFace(context: GraphicsContext, cx: Double, cy: Double, r: Double) {
        let eyeSpacing = r * 0.32
        let eyeSize = r * 0.12
        let eyeY = cy - r * 0.02

        // Left eye — bigger
        let leftEyeRect = CGRect(x: cx - eyeSpacing - eyeSize,
                                  y: eyeY - eyeSize * 1.1,
                                  width: eyeSize * 2, height: eyeSize * 2.2)
        context.fill(Path(ellipseIn: leftEyeRect), with: .color(.black.opacity(0.85)))

        // Left eye shine — bigger
        let shineSize = eyeSize * 0.8
        context.fill(Path(ellipseIn: CGRect(x: cx - eyeSpacing + eyeSize * 0.05,
                                             y: eyeY - eyeSize * 0.85,
                                             width: shineSize, height: shineSize)),
                     with: .color(.white))

        // Right eye
        if expression == .wink {
            var wink = Path()
            let wx = cx + eyeSpacing
            wink.move(to: CGPoint(x: wx - eyeSize * 1.1, y: eyeY))
            wink.addQuadCurve(
                to: CGPoint(x: wx + eyeSize * 1.1, y: eyeY),
                control: CGPoint(x: wx, y: eyeY + eyeSize * 1.4)
            )
            context.stroke(wink, with: .color(.black.opacity(0.85)),
                          style: StrokeStyle(lineWidth: r * 0.04, lineCap: .round))
        } else {
            let rightEyeRect = CGRect(x: cx + eyeSpacing - eyeSize,
                                       y: eyeY - eyeSize * 1.1,
                                       width: eyeSize * 2, height: eyeSize * 2.2)
            context.fill(Path(ellipseIn: rightEyeRect), with: .color(.black.opacity(0.85)))

            context.fill(Path(ellipseIn: CGRect(x: cx + eyeSpacing + eyeSize * 0.05,
                                                 y: eyeY - eyeSize * 0.85,
                                                 width: shineSize, height: shineSize)),
                         with: .color(.white))
        }

        // Blush cheeks — more prominent
        let blushW = r * 0.18
        let blushH = r * 0.12
        let blushY = cy + r * 0.1
        context.fill(Path(ellipseIn: CGRect(x: cx - eyeSpacing - blushW * 1.3,
                                             y: blushY, width: blushW * 1.8, height: blushH)),
                     with: .color(blushColor.opacity(0.5)))
        context.fill(Path(ellipseIn: CGRect(x: cx + eyeSpacing - blushW * 0.5,
                                             y: blushY, width: blushW * 1.8, height: blushH)),
                     with: .color(blushColor.opacity(0.5)))

        // Mouth — bigger and more expressive
        let mouthY = cy + r * 0.2
        switch expression {
        case .happy:
            // Wide open smile
            var mouth = Path()
            mouth.move(to: CGPoint(x: cx - r * 0.14, y: mouthY))
            mouth.addQuadCurve(
                to: CGPoint(x: cx + r * 0.14, y: mouthY),
                control: CGPoint(x: cx, y: mouthY + r * 0.16)
            )
            mouth.closeSubpath()
            context.fill(mouth, with: .color(.black.opacity(0.75)))

            // Tongue
            let tongueRect = CGRect(x: cx - r * 0.06, y: mouthY + r * 0.04,
                                     width: r * 0.12, height: r * 0.06)
            context.fill(Path(ellipseIn: tongueRect), with: .color(blushColor.opacity(0.65)))

        case .smile:
            // Open smile (like happy but slightly smaller — left berry in icon)
            var mouth = Path()
            mouth.move(to: CGPoint(x: cx - r * 0.12, y: mouthY))
            mouth.addQuadCurve(
                to: CGPoint(x: cx + r * 0.12, y: mouthY),
                control: CGPoint(x: cx, y: mouthY + r * 0.13)
            )
            mouth.closeSubpath()
            context.fill(mouth, with: .color(.black.opacity(0.75)))

            let tongueRect = CGRect(x: cx - r * 0.04, y: mouthY + r * 0.03,
                                     width: r * 0.08, height: r * 0.05)
            context.fill(Path(ellipseIn: tongueRect), with: .color(blushColor.opacity(0.6)))

        case .wink:
            // Curved smile
            var mouth = Path()
            mouth.move(to: CGPoint(x: cx - r * 0.10, y: mouthY))
            mouth.addQuadCurve(
                to: CGPoint(x: cx + r * 0.10, y: mouthY),
                control: CGPoint(x: cx, y: mouthY + r * 0.10)
            )
            context.stroke(mouth, with: .color(.black.opacity(0.75)),
                          style: StrokeStyle(lineWidth: r * 0.04, lineCap: .round))
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        BlueberryView(size: 100, expression: .smile)
        BlueberryView(size: 100, expression: .happy)
        BlueberryView(size: 100, expression: .wink)
    }
    .padding(40)
    .background(Color(red: 0.68, green: 0.82, blue: 0.95))
}
