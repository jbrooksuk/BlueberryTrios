import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case blueberry
    case halloween
    case christmas
    case raspberry

    var id: String { rawValue }

    var name: LocalizedStringResource {
        switch self {
        case .blueberry: "Blueberry"
        case .halloween: "Halloween"
        case .christmas: "Christmas"
        case .raspberry: "Raspberry"
        }
    }

    var symbolName: String {
        switch self {
        case .blueberry: "drop.fill"
        case .halloween: "moon.stars.fill"
        case .christmas: "snowflake"
        case .raspberry: "heart.fill"
        }
    }

    /// Add a product identifier here when a theme should be sold separately.
    /// Free and seasonal themes leave this nil.
    var productID: String? {
        switch self {
        case .raspberry: "com.altthree.Berroku.theme.raspberry"
        case .blueberry, .halloween, .christmas: nil
        }
    }

    var palette: Theme {
        switch self {
        case .blueberry:
            Theme(
                accent: Color("Berry"),
                berry: Color("Berry"),
                backgroundAccent: Color("Berry")
            )
        case .halloween:
            Theme(
                accent: Color(red: 0.92, green: 0.39, blue: 0.08),
                berry: Color(red: 0.48, green: 0.25, blue: 0.70),
                backgroundAccent: Color(red: 0.92, green: 0.39, blue: 0.08),
                hintHighlight: Color.orange.opacity(0.32)
            )
        case .christmas:
            Theme(
                accent: Color(red: 0.76, green: 0.12, blue: 0.16),
                berry: Color(red: 0.76, green: 0.12, blue: 0.16),
                backgroundAccent: Color(red: 0.12, green: 0.48, blue: 0.28),
                hintHighlight: Color.green.opacity(0.28)
            )
        case .raspberry:
            Theme(
                accent: Color(red: 0.82, green: 0.12, blue: 0.38),
                berry: Color(red: 0.82, green: 0.12, blue: 0.38),
                backgroundAccent: Color(red: 0.82, green: 0.12, blue: 0.38),
                hintHighlight: Color.pink.opacity(0.25)
            )
        }
    }
}

enum ThemeSelection {
    static let storageKey = "selectedThemeID"

    /// Change this value for a seasonal release. Players with no explicit
    /// selection receive it automatically; an explicit selection always wins.
    static let releaseDefault: AppTheme = .blueberry

    static func resolve(
        overrideRawValue: String?,
        releaseDefault fallback: AppTheme = ThemeSelection.releaseDefault
    ) -> AppTheme {
        guard let overrideRawValue,
              !overrideRawValue.isEmpty,
              let theme = AppTheme(rawValue: overrideRawValue) else {
            return fallback
        }
        return theme
    }
}

struct Theme {
    let accent: Color
    let berry: Color
    let backgroundAccent: Color
    let cellBackground: Color
    let gridLineThin: Color
    let gridLineThick: Color
    let errorCell: Color
    let errorText: Color
    let clueText: Color
    let emptyDot: Color
    let hintHighlight: Color
    let satisfiedClueOpacity: Double
    let errorAnimationDelay: TimeInterval

    init(
        accent: Color,
        berry: Color,
        backgroundAccent: Color,
        cellBackground: Color = Color("CellBackground"),
        gridLineThin: Color = Color("GridLineThin"),
        gridLineThick: Color = Color("GridLineThick"),
        errorCell: Color = Color("ErrorCell"),
        errorText: Color = Color("ErrorText"),
        clueText: Color = Color("ClueText"),
        emptyDot: Color = Color("EmptyDot"),
        hintHighlight: Color = Color("HintHighlight"),
        satisfiedClueOpacity: Double = 0.25,
        errorAnimationDelay: TimeInterval = 1.0
    ) {
        self.accent = accent
        self.berry = berry
        self.backgroundAccent = backgroundAccent
        self.cellBackground = cellBackground
        self.gridLineThin = gridLineThin
        self.gridLineThick = gridLineThick
        self.errorCell = errorCell
        self.errorText = errorText
        self.clueText = clueText
        self.emptyDot = emptyDot
        self.hintHighlight = hintHighlight
        self.satisfiedClueOpacity = satisfiedClueOpacity
        self.errorAnimationDelay = errorAnimationDelay
    }

    var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [backgroundAccent.opacity(0.10), Color(.systemGroupedBackground)],
            startPoint: .top,
            endPoint: .center
        )
    }
}

private struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue = AppTheme.blueberry.palette
}

extension EnvironmentValues {
    var appTheme: Theme {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}
