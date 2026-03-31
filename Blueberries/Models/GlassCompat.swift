import SwiftUI

// MARK: - Glass Effect Compatibility (iOS 26+ with fallback)

extension View {
    @ViewBuilder
    func adaptiveGlass(in cornerRadius: CGFloat) -> some View {
        if #available(iOS 26, *) {
            self.glassEffect(in: .rect(cornerRadius: cornerRadius))
        } else {
            self.background(.regularMaterial)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        }
    }

    @ViewBuilder
    func adaptiveProminentButton() -> some View {
        if #available(iOS 26, *) {
            self.buttonStyle(.glassProminent)
        } else {
            self.buttonStyle(.borderedProminent)
        }
    }

    @ViewBuilder
    func adaptiveSecondaryButton() -> some View {
        if #available(iOS 26, *) {
            self.buttonStyle(.glass)
        } else {
            self.buttonStyle(.bordered)
        }
    }
}

struct AdaptiveGlassContainer<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: Content

    var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: spacing) { content }
        } else {
            content
        }
    }
}
