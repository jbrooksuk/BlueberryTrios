import SwiftUI

enum Theme {
    /// The primary berry color, driven by the active `BerryTheme`.
    /// Uses the theme's programmatic color instead of the asset catalog
    /// so it updates when the player switches themes.
    static var berryBlue: Color { BerryTheme.active.primaryColor }

    static let cellBackground = Color("CellBackground")
    static let gridLineThin = Color("GridLineThin")
    static let gridLineThick = Color("GridLineThick")
    static let errorCell = Color("ErrorCell")
    static let errorText = Color("ErrorText")
    static let clueText = Color("ClueText")
    static let emptyDot = Color("EmptyDot")
    static let hintHighlight = Color("HintHighlight")
    static let satisfiedClueOpacity: Double = 0.25
    static let errorAnimationDelay: TimeInterval = 1.0

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [berryBlue.opacity(0.08), Color(.systemGroupedBackground)],
            startPoint: .top,
            endPoint: .center
        )
    }
}
