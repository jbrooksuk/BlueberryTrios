import SwiftUI

struct ThemeBackground: View {
    let theme: Theme

    var body: some View {
        ZStack {
            theme.backgroundGradient

            if theme.usesPaperTexture {
                Canvas { context, size in
                    drawFibres(context: context, size: size)
                }
                .opacity(0.16)
                .accessibilityHidden(true)
                .allowsHitTesting(false)
            }
        }
        .ignoresSafeArea()
    }

    private func drawFibres(context: GraphicsContext, size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }

        for index in 0..<180 {
            let x = fraction(index * 47 + 11) * size.width
            let y = fraction(index * 83 + 29) * size.height
            let length = 3 + fraction(index * 31 + 7) * 8
            let rise = (fraction(index * 59 + 19) - 0.5) * 2

            var fibre = Path()
            fibre.move(to: CGPoint(x: x, y: y))
            fibre.addLine(to: CGPoint(x: min(size.width, x + length), y: y + rise))
            context.stroke(
                fibre,
                with: .color(theme.gridLineThin),
                style: StrokeStyle(lineWidth: 0.45, lineCap: .round)
            )
        }
    }

    private func fraction(_ seed: Int) -> Double {
        let value = sin(Double(seed) * 12.9898) * 43_758.5453
        return value - floor(value)
    }
}
