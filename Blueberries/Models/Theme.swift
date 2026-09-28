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

    /// The asset-catalog app icon name passed to UIApplication. The primary
    /// blueberry icon uses nil; future paid themes unlock their icon through
    /// the same product entitlement as the theme.
    var alternateIconName: String? {
        switch self {
        case .blueberry: nil
        case .halloween: "AppIcon-Halloween"
        case .christmas: "AppIcon-Christmas"
        case .raspberry: "AppIcon-Raspberry"
        }
    }

    var iconPreviewName: String? {
        #if DEBUG
        if self == .blueberry {
            return "IconPreview-Debug"
        }
        #endif

        switch self {
        case .blueberry: "IconPreview-Blueberry"
        case .halloween: "IconPreview-Halloween"
        case .christmas: "IconPreview-Christmas"
        case .raspberry: "IconPreview-Raspberry"
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
                berry: Color(red: 0.92, green: 0.39, blue: 0.08),
                backgroundAccent: Color(red: 0.92, green: 0.39, blue: 0.08),
                hintHighlight: Color.orange.opacity(0.32),
                berrySymbol: "🎃",
                markerName: String(localized: "pumpkin"),
                markerNamePlural: String(localized: "pumpkins"),
                proTagline: "An endless pumpkin patch",
                attribution: "Made with pumpkin spice by James Brooks 🎃"
            )
        case .christmas:
            Theme(
                accent: Color(red: 0.76, green: 0.12, blue: 0.16),
                berry: Color(red: 0.76, green: 0.12, blue: 0.16),
                backgroundAccent: Color(red: 0.12, green: 0.48, blue: 0.28),
                hintHighlight: Color.green.opacity(0.28),
                berrySymbol: "❄️",
                markerName: String(localized: "snowflake"),
                markerNamePlural: String(localized: "snowflakes"),
                proTagline: "An endless flurry of snowflakes",
                attribution: "Made with gingerbread by James Brooks 🎅"
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

    /// The non-seasonal fallback used outside the automatic date windows.
    static let releaseDefault: AppTheme = .blueberry

    static func automaticTheme(
        on date: Date = .now,
        calendar: Calendar = .current
    ) -> AppTheme {
        let components = calendar.dateComponents([.month, .day], from: date)
        guard let month = components.month, let day = components.day else {
            return releaseDefault
        }

        if month == 10 && day >= 26 {
            return .halloween
        }
        if month == 12 && day >= 23 {
            return .christmas
        }
        return releaseDefault
    }

    static func isAvailable(
        _ theme: AppTheme,
        on date: Date = .now,
        calendar: Calendar = .current
    ) -> Bool {
        switch theme {
        case .blueberry:
            true
        case .halloween, .christmas:
            theme == automaticTheme(on: date, calendar: calendar)
        case .raspberry:
            false
        }
    }

    static func availableThemes(
        on date: Date = .now,
        calendar: Calendar = .current
    ) -> [AppTheme] {
        AppTheme.allCases.filter { isAvailable($0, on: date, calendar: calendar) }
    }

    static func themesForCurrentBuild(
        on date: Date = .now,
        calendar: Calendar = .current
    ) -> [AppTheme] {
        #if DEBUG
        AppTheme.allCases
        #else
        availableThemes(on: date, calendar: calendar)
        #endif
    }

    static func isAvailableInCurrentBuild(
        _ theme: AppTheme,
        on date: Date = .now,
        calendar: Calendar = .current
    ) -> Bool {
        #if DEBUG
        true
        #else
        isAvailable(theme, on: date, calendar: calendar)
        #endif
    }

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

    static func resolve(
        overrideRawValue: String?,
        on date: Date,
        calendar: Calendar = .current
    ) -> AppTheme {
        let automaticTheme = automaticTheme(on: date, calendar: calendar)
        guard let overrideRawValue,
              !overrideRawValue.isEmpty,
              let theme = AppTheme(rawValue: overrideRawValue),
              isAvailable(theme, on: date, calendar: calendar) else {
            return automaticTheme
        }
        return theme
    }

    static func resolveForCurrentBuild(
        overrideRawValue: String?,
        on date: Date,
        calendar: Calendar = .current
    ) -> AppTheme {
        #if DEBUG
        resolve(
            overrideRawValue: overrideRawValue,
            releaseDefault: automaticTheme(on: date, calendar: calendar)
        )
        #else
        resolve(overrideRawValue: overrideRawValue, on: date, calendar: calendar)
        #endif
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
    let berrySymbol: String?
    let markerName: String
    let markerNamePlural: String
    let proTagline: LocalizedStringResource
    let attribution: LocalizedStringResource

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
        errorAnimationDelay: TimeInterval = 1.0,
        berrySymbol: String? = nil,
        markerName: String = String(localized: "berry"),
        markerNamePlural: String = String(localized: "berries"),
        proTagline: LocalizedStringResource = "An endless berry patch",
        attribution: LocalizedStringResource = "Made with berries by James Brooks 🫐"
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
        self.berrySymbol = berrySymbol
        self.markerName = markerName
        self.markerNamePlural = markerNamePlural
        self.proTagline = proTagline
        self.attribution = attribution
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
