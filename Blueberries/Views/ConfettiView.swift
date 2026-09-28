import SwiftUI

struct ConfettiView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.appTheme) private var theme
    @State private var particles: [Particle] = Self.makeParticles()
    @State private var isAnimating = false

    private struct Particle: Identifiable {
        let id = UUID()
        let colorIndex: Int
        let size: Double
        let xOffset: Double
        let yStart: Double
        let rotation: Double
        let delay: Double
    }

    var body: some View {
        let colors: [Color] = [theme.berry, .green, .orange, .purple, .pink, .yellow]
        if !reduceMotion {
            ZStack {
                ForEach(particles) { particle in
                    Circle()
                        .fill(colors[particle.colorIndex])
                        .frame(width: particle.size, height: particle.size)
                        .offset(
                            x: particle.xOffset,
                            y: isAnimating ? particle.yStart + 400 : particle.yStart - 100
                        )
                        .rotationEffect(.degrees(isAnimating ? particle.rotation : 0))
                        .opacity(isAnimating ? 0 : 1)
                        .animation(
                            .easeIn(duration: 2.0).delay(particle.delay),
                            value: isAnimating
                        )
                }
            }
            .allowsHitTesting(false)
            .task {
                isAnimating = true
            }
        }
    }

    private static func makeParticles() -> [Particle] {
        return (0..<40).map { _ in
            Particle(
                colorIndex: Int.random(in: 0..<6),
                size: Double.random(in: 4...10),
                xOffset: Double.random(in: -180...180),
                yStart: Double.random(in: -60...0),
                rotation: Double.random(in: 180...720),
                delay: Double.random(in: 0...0.3)
            )
        }
    }
}
