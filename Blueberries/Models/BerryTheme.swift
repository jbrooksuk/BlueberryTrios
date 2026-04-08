import SwiftUI

/// The four berry themes available in the app. Blueberry is the default (free);
/// the others are non-consumable IAPs that each come with a matching app icon.
enum BerryTheme: String, CaseIterable, Identifiable, Codable {
    case blueberry
    case strawberry
    case raspberry
    case cherry

    var id: String { rawValue }

    // MARK: - Active theme (reads from UserDefaults)

    private static let storageKey = "selectedTheme"

    /// The currently selected theme. Reads from UserDefaults so it is
    /// accessible from static contexts (Canvas drawing, Theme enum, etc.).
    static var active: BerryTheme {
        get {
            guard let raw = UserDefaults.standard.string(forKey: storageKey),
                  let theme = BerryTheme(rawValue: raw) else {
                return .blueberry
            }
            return theme
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: storageKey)
        }
    }

    // MARK: - Display

    var displayName: String {
        switch self {
        case .blueberry:  "Blueberry"
        case .strawberry: "Strawberry"
        case .raspberry:  "Raspberry"
        case .cherry:     "Cherry"
        }
    }

    var emoji: String {
        switch self {
        case .blueberry:  "\u{1FAD0}"  // 🫐
        case .strawberry: "\u{1F353}"  // 🍓
        case .raspberry:  "\u{1F347}"  // 🍇 (closest to raspberry)
        case .cherry:     "\u{1F352}"  // 🍒
        }
    }

    /// Whether this theme requires an IAP to use.
    var isPaid: Bool { self != .blueberry }

    // MARK: - StoreKit product IDs

    var productID: String? {
        switch self {
        case .blueberry:  nil
        case .strawberry: "com.altthree.Berroku.theme.strawberry"
        case .raspberry:  "com.altthree.Berroku.theme.raspberry"
        case .cherry:     "com.altthree.Berroku.theme.cherry"
        }
    }

    static let allProductIDs: Set<String> = {
        Set(allCases.compactMap(\.productID))
    }()

    // MARK: - Alternate app icon name

    /// The alternate icon name registered in the asset catalog, or `nil` for
    /// the default blueberry icon (which uses the primary `AppIcon`).
    var alternateIconName: String? {
        switch self {
        case .blueberry:  nil
        case .strawberry: "AppIcon-Strawberry"
        case .raspberry:  "AppIcon-Raspberry"
        case .cherry:     "AppIcon-Cherry"
        }
    }

    // MARK: - Primary color (the "berry" accent color)

    /// Light-mode primary berry color.
    var primaryColor: Color {
        switch self {
        case .blueberry:  Color(red: 0.208, green: 0.518, blue: 0.894)
        case .strawberry: Color(red: 0.89, green: 0.22, blue: 0.24)
        case .raspberry:  Color(red: 0.78, green: 0.14, blue: 0.42)
        case .cherry:     Color(red: 0.75, green: 0.10, blue: 0.18)
        }
    }

    /// Dark-mode primary berry color (slightly lighter/more vibrant).
    var primaryColorDark: Color {
        switch self {
        case .blueberry:  Color(red: 0.353, green: 0.624, blue: 0.910)
        case .strawberry: Color(red: 0.95, green: 0.35, blue: 0.36)
        case .raspberry:  Color(red: 0.85, green: 0.30, blue: 0.52)
        case .cherry:     Color(red: 0.85, green: 0.22, blue: 0.30)
        }
    }

    /// Adaptive primary color that responds to the current color scheme.
    func adaptivePrimary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? primaryColorDark : primaryColor
    }

    // MARK: - Illustrated berry palette

    /// Body gradient colors for the illustrated berry cluster (darkest to lightest).
    var bodyDark: Color {
        switch self {
        case .blueberry:  Color(red: 0.19, green: 0.29, blue: 0.51)
        case .strawberry: Color(red: 0.54, green: 0.10, blue: 0.10)
        case .raspberry:  Color(red: 0.42, green: 0.07, blue: 0.25)
        case .cherry:     Color(red: 0.42, green: 0.06, blue: 0.12)
        }
    }

    var bodyMid: Color {
        switch self {
        case .blueberry:  Color(red: 0.31, green: 0.42, blue: 0.63)
        case .strawberry: Color(red: 0.76, green: 0.19, blue: 0.19)
        case .raspberry:  Color(red: 0.63, green: 0.13, blue: 0.38)
        case .cherry:     Color(red: 0.63, green: 0.10, blue: 0.18)
        }
    }

    var bodyBase: Color {
        switch self {
        case .blueberry:  Color(red: 0.38, green: 0.51, blue: 0.72)
        case .strawberry: Color(red: 0.88, green: 0.28, blue: 0.28)
        case .raspberry:  Color(red: 0.77, green: 0.22, blue: 0.47)
        case .cherry:     Color(red: 0.77, green: 0.17, blue: 0.22)
        }
    }

    var bodyLight: Color {
        switch self {
        case .blueberry:  Color(red: 0.60, green: 0.74, blue: 0.89)
        case .strawberry: Color(red: 0.94, green: 0.53, blue: 0.53)
        case .raspberry:  Color(red: 0.88, green: 0.50, blue: 0.66)
        case .cherry:     Color(red: 0.88, green: 0.38, blue: 0.44)
        }
    }
}
