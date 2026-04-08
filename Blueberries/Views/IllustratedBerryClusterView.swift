import SwiftUI

// MARK: - Palette (derived from active BerryTheme)

private enum BerryPalette {
    private static var theme: BerryTheme { .active }

    // Berry body — driven by the active theme
    static var bodyDark:  Color { theme.bodyDark }
    static var bodyMid:   Color { theme.bodyMid }
    static var bodyBase:  Color { theme.bodyBase }
    static var bodyLight: Color { theme.bodyLight }
    static let bodyShine = Color(red: 0.96, green: 0.98, blue: 1.00)

    // Face (shared across all themes)
    static let eye       = Color(red: 0.22, green: 0.15, blue: 0.29) // #38274B
    static let eyeShine  = Color.white
    static let cheek     = Color(red: 0.82, green: 0.51, blue: 0.50) // #D18482
    static let mouthDark = Color(red: 0.37, green: 0.14, blue: 0.26) // #602441
    static let mouthRed  = Color(red: 0.93, green: 0.44, blue: 0.42) // #EF716B

    // Leaves (shared across all themes)
    static let leafLight = Color(red: 0.67, green: 0.82, blue: 0.40) // #ABD167
    static let leafMid   = Color(red: 0.50, green: 0.66, blue: 0.28) // #80A847
    static let leafDark  = Color(red: 0.33, green: 0.49, blue: 0.20) // #547D33
}

// MARK: - Cluster

/// Illustrated cluster of three blueberries with leaves.
///
/// This view replaces the earlier kawaii `BerryClusterView` used on the home
/// screen hero header. It is composed of discrete layers — leaves behind, the
/// two flanking berries, then the central berry in front — so each element
/// can be animated and styled independently.
struct IllustratedBerryClusterView: View {
    var animated: Bool = true

    var body: some View {
        if animated {
            PhaseAnimator([false, true]) { phase in
                cluster(phase: phase)
            } animation: { _ in .easeInOut(duration: 1.6) }
        } else {
            cluster(phase: false)
        }
    }

    private func cluster(phase: Bool) -> some View {
        // Canvas aspect roughly 3:2 — wider than tall to accommodate leaves.
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let scale = min(w / 300, h / 200)

            ZStack {
                // Leaves + stem behind the top of the cluster.
                TopFoliage(scale: scale)
                    .rotationEffect(.degrees(phase ? -3 : 3))
                    .offset(y: (phase ? -20 : -30) * scale - 24)

                // Leaves peeking out from under the bottom of the center berry.
                BottomFoliage(scale: scale)
                    .rotationEffect(.degrees(phase ? 3 : -2))
                    .offset(y: (phase ? 12 : 18) * scale)

                // Left berry
                IllustratedBerry(expression: .smile, size: 80 * scale)
                    .rotationEffect(.degrees(phase ? -6 : -3))
                    .offset(x: -70 * scale, y: (phase ? -4 : 4) * scale + 22 * scale)

                // Right berry
                IllustratedBerry(expression: .wink, size: 76 * scale)
                    .rotationEffect(.degrees(phase ? 8 : 4))
                    .offset(x: 70 * scale, y: (phase ? -2 : 6) * scale + 24 * scale)

                // Center berry (largest, front)
                IllustratedBerry(expression: .happy, size: 102 * scale)
                    .offset(x: 0, y: (phase ? 4 : -4) * scale + 10 * scale)
                    .shadow(color: BerryPalette.bodyDark.opacity(0.25), radius: 8 * scale, y: 4 * scale)
            }
            .frame(width: w, height: h)
        }
    }
}

// MARK: - Single Berry

private struct IllustratedBerry: View {
    enum Expression { case happy, smile, wink }

    let expression: Expression
    let size: Double

    var body: some View {
        ZStack {
            // Main body — a near-circle with a radial gradient for roundness.
            // The lighter periwinkle dominates; darker shades only tint the edges.
            Circle()
                .fill(
                    RadialGradient(
                        colors: [BerryPalette.bodyLight, BerryPalette.bodyBase, BerryPalette.bodyMid],
                        center: UnitPoint(x: 0.38, y: 0.35),
                        startRadius: 0,
                        endRadius: size * 0.62
                    )
                )

            // Crown calyx (dark star at top)
            Calyx()
                .fill(BerryPalette.bodyDark)
                .frame(width: size * 0.44, height: size * 0.26)
                .offset(y: -size * 0.44)
            
            // Single soft specular highlight, upper-left.
            Ellipse()
                .fill(BerryPalette.bodyLight)
                .frame(width: size * 0.12, height: size * 0.06)
                .rotationEffect(.degrees(-28))
                .offset(x: -size * 0.30, y: -size * 0.30)
            
            if expression == .happy {
                // Single soft specular highlight, upper-left.
                Ellipse()
                    .fill(BerryPalette.bodyLight)
                    .frame(width: size * 0.06, height: size * 0.06)
                    .rotationEffect(.degrees(-20))
                    .offset(x: -size * 0.36, y: -size * 0.20)
            }

            // Face
            face
        }
        .frame(width: size, height: size)
    }

    private var face: some View {
        ZStack {
            // Cheeks
            Ellipse()
                .fill(BerryPalette.cheek.opacity(0.75))
                .frame(width: size * 0.16, height: size * 0.10)
                .offset(x: -size * 0.30, y: size * 0.14)

            Ellipse()
                .fill(BerryPalette.cheek.opacity(0.60))
                .frame(width: size * 0.16, height: size * 0.10)
                .offset(x: size * 0.30, y: size * 0.14)

            // Eyes — closed upside-down U arcs for the .wink berry,
            // round dots-with-shine otherwise.
            if expression == .wink {
                ClosedEyeArc()
                    .stroke(BerryPalette.eye, style: StrokeStyle(lineWidth: size * 0.04, lineCap: .round))
                    .frame(width: size * 0.18, height: size * 0.10)
                    .offset(x: -size * 0.16, y: size * 0.03)
                ClosedEyeArc()
                    .stroke(BerryPalette.eye, style: StrokeStyle(lineWidth: size * 0.04, lineCap: .round))
                    .frame(width: size * 0.18, height: size * 0.10)
                    .offset(x: size * 0.16, y: size * 0.03)
            } else {
                Eye(size: size * 0.14)
                    .offset(x: -size * 0.16, y: size * 0.02)
                Eye(size: size * 0.14)
                    .offset(x: size * 0.16, y: size * 0.02)
            }

            // Mouth
            mouth
        }
    }

    @ViewBuilder
    private var mouth: some View {
        switch expression {
        case .happy:
            // Open smiling mouth with tongue
            ZStack {
                MouthOpen()
                    .fill(BerryPalette.mouthDark)
                    .frame(width: size * 0.22, height: size * 0.13)
                Ellipse()
                    .fill(BerryPalette.mouthRed.opacity(0.85))
                    .frame(width: size * 0.11, height: size * 0.05)
                    .offset(y: size * 0.03)
            }
            .offset(y: size * 0.22)
        case .smile:
            // Smaller open smile
            ZStack {
                MouthOpen()
                    .fill(BerryPalette.mouthDark)
                    .frame(width: size * 0.17, height: size * 0.10)
                Ellipse()
                    .fill(BerryPalette.mouthRed.opacity(0.8))
                    .frame(width: size * 0.08, height: size * 0.04)
                    .offset(y: size * 0.02)
            }
            .offset(y: size * 0.22)
        case .wink:
            // Curved line smile
            SmileArc()
                .stroke(BerryPalette.mouthDark, style: StrokeStyle(lineWidth: size * 0.035, lineCap: .round))
                .frame(width: size * 0.2, height: size * 0.09)
                .offset(y: size * 0.22)
        }
    }
}

// MARK: - Sub-shapes

/// Five-point calyx crown at the top of the berry.
private struct Calyx: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        let cx = w * 0.5, cy = h * 0.5
        let rOuter = min(w, h) * 0.5
        var p = Path()
        let points = 5
        for i in 0..<(points * 2) {
            let r = i.isMultiple(of: 2) ? rOuter : rOuter * 0.45
            let angle = (Double(i) * .pi / Double(points)) - .pi / 2
            let x = cx + cos(angle) * r
            let y = cy + sin(angle) * r * 0.8
            if i == 0 {
                p.move(to: CGPoint(x: x, y: y))
            } else {
                p.addLine(to: CGPoint(x: x, y: y))
            }
        }
        p.closeSubpath()
        return p
    }
}

private struct Eye: View {
    let size: Double
    var body: some View {
        ZStack {
            Ellipse()
                .fill(BerryPalette.eye)
                .frame(width: size * 0.85, height: size)
            Ellipse()
                .fill(BerryPalette.eyeShine)
                .frame(width: size * 0.35, height: size * 0.38)
                .offset(x: -size * 0.12, y: -size * 0.18)
        }
    }
}

/// Closed happy eye — an upside-down U. Both endpoints sit on the baseline
/// and the curve bulges upward to the top of the frame.
private struct ClosedEyeArc: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.2)
        )
        return p
    }
}

private struct SmileArc: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.minY))
        p.addQuadCurve(
            to: CGPoint(x: rect.width, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY + rect.height * 0.2)
        )
        return p
    }
}

private struct MouthOpen: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: 0))
        // Bottom curve — bulges downward for the open mouth.
        p.addQuadCurve(
            to: CGPoint(x: rect.width, y: 0),
            control: CGPoint(x: rect.midX, y: rect.maxY * 1.6)
        )
        // Top curve — gentle dip so the corners are rounded rather than sharp.
        p.addQuadCurve(
            to: CGPoint(x: 0, y: 0),
            control: CGPoint(x: rect.midX, y: rect.maxY * 0.25)
        )
        p.closeSubpath()
        return p
    }
}

// MARK: - Leaves

/// A broad rounded leaf. Anchored at the bottom-center (the stem point) with
/// the widest part at ~60% up and a soft point at the top.
private struct Leaf: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        // Stem base
        p.move(to: CGPoint(x: w * 0.5, y: h))
        // Left side — bulge outward then taper to the tip.
        p.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.02),
            control1: CGPoint(x: w * -0.12, y: h * 0.70),
            control2: CGPoint(x: w * 0.05, y: h * 0.10)
        )
        // Right side back down to the stem.
        p.addCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control1: CGPoint(x: w * 0.95, y: h * 0.10),
            control2: CGPoint(x: w * 1.12, y: h * 0.70)
        )
        p.closeSubpath()
        return p
    }
}

/// Leaf veins: central midrib plus four side ribs branching outward.
private struct LeafVeins: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()

        // Central midrib from base to tip (slight curve for organic feel).
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.96))
        p.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.08),
            control: CGPoint(x: w * 0.52, y: h * 0.5)
        )

        // Side ribs — branch off the midrib toward the leaf edges.
        let ribYs: [Double] = [0.78, 0.58, 0.38]
        for ribY in ribYs {
            // Left rib
            p.move(to: CGPoint(x: w * 0.5, y: h * ribY))
            p.addQuadCurve(
                to: CGPoint(x: w * 0.18, y: h * (ribY - 0.08)),
                control: CGPoint(x: w * 0.32, y: h * (ribY - 0.02))
            )
            // Right rib
            p.move(to: CGPoint(x: w * 0.5, y: h * ribY))
            p.addQuadCurve(
                to: CGPoint(x: w * 0.82, y: h * (ribY - 0.08)),
                control: CGPoint(x: w * 0.68, y: h * (ribY - 0.02))
            )
        }
        return p
    }
}

/// A single styled leaf (shape + gradient fill + veins).
private struct StyledLeaf: View {
    let scale: Double
    var body: some View {
        ZStack {
            Leaf()
                .fill(
                    LinearGradient(
                        colors: [BerryPalette.leafLight, BerryPalette.leafMid, BerryPalette.leafDark],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            LeafVeins()
                .stroke(BerryPalette.leafDark.opacity(0.65), style: StrokeStyle(lineWidth: 1.0 * scale, lineCap: .round))
        }
    }
}

/// Upright stem between the two top leaves.
private struct Stem: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.5, y: h))
        // Rises mostly straight from the base, then curls out to the right at the tip.
        p.addCurve(
            to: CGPoint(x: w * 0.95, y: 0),
            control1: CGPoint(x: w * 0.45, y: h * 0.55),
            control2: CGPoint(x: w * 0.50, y: h * 0.15)
        )
        return p
    }
}

/// Two large leaves and a central stem emerging from behind the top of the
/// center berry, matching the reference kawaii-blueberry illustration.
private struct TopFoliage: View {
    let scale: Double

    var body: some View {
        ZStack {
            // Stem poking up between the leaves.
            Stem()
                .stroke(BerryPalette.leafMid, style: StrokeStyle(lineWidth: 6 * scale, lineCap: .round))
                .frame(width: 10 * scale, height: 34 * scale)

            // Small accent leaf sprouting from the upper-left of the stem.
            StyledLeaf(scale: scale)
                .frame(width: 22 * scale, height: 30 * scale)
                .rotationEffect(.degrees(-60), anchor: .bottom)
                .offset(x: -3 * scale, y: -16 * scale)

            // Left leaf — angled out to the upper left.
            StyledLeaf(scale: scale)
                .frame(width: 66 * scale, height: 90 * scale)
                .rotationEffect(.degrees(-48), anchor: .bottom)
                .offset(x: -18 * scale, y: 16 * scale)

            // Right leaf — mirror of the left.
            StyledLeaf(scale: scale)
                .frame(width: 66 * scale, height: 90 * scale)
                .rotationEffect(.degrees(48), anchor: .bottom)
                .offset(x: 18 * scale, y: 16 * scale)
        }
    }
}

/// A pair of smaller leaves peeking out from under the bottom of the cluster.
private struct BottomFoliage: View {
    let scale: Double

    var body: some View {
        ZStack {
            StyledLeaf(scale: scale)
                .frame(width: 44 * scale, height: 62 * scale)
                .rotationEffect(.degrees(-158), anchor: .bottom)
                .offset(x: -20 * scale, y: -6 * scale)

            StyledLeaf(scale: scale)
                .frame(width: 44 * scale, height: 62 * scale)
                .rotationEffect(.degrees(158), anchor: .bottom)
                .offset(x: 20 * scale, y: -6 * scale)
        }
    }
}

// MARK: - Preview

#Preview("Animated") {
    IllustratedBerryClusterView(animated: true)
        .frame(width: 300, height: 200)
        .padding(40)
}

#Preview("Static") {
    IllustratedBerryClusterView(animated: false)
        .frame(width: 300, height: 200)
        .padding(40)

}
