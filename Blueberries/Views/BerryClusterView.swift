import SwiftUI

/// Three kawaii berries matching the app icon layout.
struct BerryClusterView: View {
    var animated: Bool = true

    var body: some View {
        if animated {
            PhaseAnimator([false, true]) { phase in
                clusterContent(phase: phase)
            } animation: { _ in .easeInOut(duration: 1.5) }
        } else {
            clusterContent(phase: false)
        }
    }

    private func clusterContent(phase: Bool) -> some View {
        ZStack {
            BlueberryView(size: 48, expression: .smile)
                .offset(x: -32, y: phase ? -6 : 2)
                .rotationEffect(.degrees(phase ? -6 : -3))

            BlueberryView(size: 44, expression: .wink)
                .offset(x: 32, y: phase ? -4 : 4)
                .rotationEffect(.degrees(phase ? 8 : 4))

            BlueberryView(size: 64, expression: .happy)
                .offset(x: 0, y: phase ? 4 : -4)
                .shadow(color: Theme.berryBlue.opacity(0.3), radius: 8, y: 4)
        }
    }
}

#Preview {
    BerryClusterView(animated: true)
        .padding(60)
        .background(Color(red: 0.68, green: 0.82, blue: 0.95))
}
