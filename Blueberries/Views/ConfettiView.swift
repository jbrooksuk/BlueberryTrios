import SwiftUI

struct ConfettiView: View {
    @State private var particles: [Particle] = Self.makeParticles()
    @State private var isAnimating = false

    private struct Particle: Identifiable {
        let id = UUID()
        let color: Color
        let size: Double
        let xOffset: Double
        let yStart: Double
        let rotation: Double
        let delay: Double
    }

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Circle()
                    .fill(particle.color)
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

    private static func makeParticles() -> [Particle] {
        let colors: [Color] = [
            Theme.berryBlue, .green, .orange, .purple, .pink, .yellow,
        ]
        return (0..<40).map { _ in
            Particle(
                color: colors.randomElement()!,
                size: Double.random(in: 4...10),
                xOffset: Double.random(in: -180...180),
                yStart: Double.random(in: -60...0),
                rotation: Double.random(in: 180...720),
                delay: Double.random(in: 0...0.3)
            )
        }
    }
}
