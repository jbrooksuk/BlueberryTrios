import Foundation
import Observation

@MainActor
@Observable
final class AppClipInvocation {
    var difficulty: Difficulty = .standard

    func apply(userActivity: NSUserActivity) {
        guard let url = userActivity.webpageURL else { return }
        difficulty = Self.difficulty(from: url)
    }

    static func difficulty(from url: URL) -> Difficulty {
        let components = url.pathComponents.filter { $0 != "/" }
        for component in components {
            let lower = component.lowercased()
            if let match = Difficulty.allCases.first(where: { $0.rawValue.lowercased() == lower }) {
                return match
            }
        }
        return .standard
    }
}
