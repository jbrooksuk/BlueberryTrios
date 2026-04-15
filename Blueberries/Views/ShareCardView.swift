import SwiftUI

struct ShareCardView: View {
    let model: PuzzleModel
    let elapsedTime: TimeInterval
    let difficulty: Difficulty
    let source: PuzzleSource
    let date: Date

    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 4) {
                HStack(spacing: 8) {
                    berryIcon
                    Text("Berroku")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                }

                Text("\(source.rawValue) · \(difficulty.rawValue)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Completed grid
            PuzzleGridView(model: model)
                .frame(width: 260, height: 260)
                .allowsHitTesting(false)

            // Stats
            HStack(spacing: 20) {
                HStack(spacing: 5) {
                    Image(systemName: "timer")
                    Text(elapsedTime.formattedAsTimer)
                }

                HStack(spacing: 5) {
                    Image(systemName: "lightbulb")
                    Text(hintText)
                }
            }
            .font(.callout.weight(.semibold))
            .foregroundStyle(Theme.berryBlue)

            Text(date.formatted(date: .long, time: .omitted))
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(width: 340)
        .background {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [.white, Color(red: 0.94, green: 0.95, blue: 1.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        }
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .environment(\.colorScheme, .light)
    }

    private var berryIcon: some View {
        Circle()
            .fill(Theme.berryBlue)
            .frame(width: 24, height: 24)
            .overlay {
                Circle()
                    .fill(.white.opacity(0.3))
                    .frame(width: 9, height: 9)
                    .offset(x: -4, y: -4)
            }
    }

    private var hintText: String {
        switch model.hintCount {
        case 0: "No hints"
        case 1: "1 hint"
        default: "\(model.hintCount) hints"
        }
    }
}
