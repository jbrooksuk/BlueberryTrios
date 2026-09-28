import Testing
@testable import Blueberries

@Suite("Theme selection")
struct ThemeSelectionTests {
    @Test("Release theme applies when the player has not made a choice")
    func releaseDefaultAppliesAutomatically() {
        #expect(ThemeSelection.resolve(overrideRawValue: nil, releaseDefault: .halloween) == .halloween)
        #expect(ThemeSelection.resolve(overrideRawValue: "", releaseDefault: .christmas) == .christmas)
    }

    @Test("Player choice survives a later seasonal release")
    func playerChoiceWins() {
        #expect(ThemeSelection.resolve(overrideRawValue: AppTheme.blueberry.rawValue, releaseDefault: .christmas) == .blueberry)
        #expect(ThemeSelection.resolve(overrideRawValue: AppTheme.halloween.rawValue, releaseDefault: .christmas) == .halloween)
    }

    @Test("Unknown saved themes safely use the release default")
    func unknownThemeFallsBack() {
        #expect(ThemeSelection.resolve(overrideRawValue: "retired-theme", releaseDefault: .blueberry) == .blueberry)
    }
}
