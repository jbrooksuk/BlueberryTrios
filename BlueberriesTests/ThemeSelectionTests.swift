import Foundation
import Testing
@testable import Blueberries

@Suite("Theme selection")
struct ThemeSelectionTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(
            year: year,
            month: month,
            day: day,
            hour: hour,
            minute: minute
        ))!
    }

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

    @Test("Halloween runs from October 26 until November 1")
    func halloweenDateWindow() {
        #expect(ThemeSelection.automaticTheme(on: date(2026, 10, 25, 23, 59), calendar: calendar) == .blueberry)
        #expect(ThemeSelection.automaticTheme(on: date(2026, 10, 26), calendar: calendar) == .halloween)
        #expect(ThemeSelection.automaticTheme(on: date(2026, 10, 31, 23, 59), calendar: calendar) == .halloween)
        #expect(ThemeSelection.automaticTheme(on: date(2026, 11, 1), calendar: calendar) == .blueberry)
    }

    @Test("Christmas runs from December 23 until January 1")
    func christmasDateWindow() {
        #expect(ThemeSelection.automaticTheme(on: date(2026, 12, 22, 23, 59), calendar: calendar) == .blueberry)
        #expect(ThemeSelection.automaticTheme(on: date(2026, 12, 23), calendar: calendar) == .christmas)
        #expect(ThemeSelection.automaticTheme(on: date(2026, 12, 31, 23, 59), calendar: calendar) == .christmas)
        #expect(ThemeSelection.automaticTheme(on: date(2027, 1, 1), calendar: calendar) == .blueberry)
    }

    @Test("An explicit theme overrides the seasonal automatic theme")
    func explicitThemeOverridesSeason() {
        #expect(ThemeSelection.resolve(
            overrideRawValue: AppTheme.blueberry.rawValue,
            on: date(2026, 10, 31),
            calendar: calendar
        ) == .blueberry)
    }

    @Test("Festive themes are available only inside their date windows")
    func seasonalAvailability() {
        #expect(ThemeSelection.availableThemes(on: date(2026, 9, 1), calendar: calendar) == [.blueberry])
        #expect(ThemeSelection.availableThemes(on: date(2026, 10, 26), calendar: calendar) == [.blueberry, .halloween])
        #expect(ThemeSelection.availableThemes(on: date(2026, 12, 23), calendar: calendar) == [.blueberry, .christmas])
        #expect(!ThemeSelection.availableThemes(on: date(2026, 9, 1), calendar: calendar).contains(.raspberry))
    }

    @Test("Expired festive choices return to automatic")
    func expiredFestiveThemeReturnsToAutomatic() {
        #expect(ThemeSelection.resolve(
            overrideRawValue: AppTheme.halloween.rawValue,
            on: date(2026, 11, 1),
            calendar: calendar
        ) == .blueberry)
        #expect(ThemeSelection.resolve(
            overrideRawValue: AppTheme.christmas.rawValue,
            on: date(2027, 1, 1),
            calendar: calendar
        ) == .blueberry)
    }

    @Test("Seasonal themes provide distinct puzzle markers")
    func seasonalPuzzleMarkers() {
        #expect(AppTheme.blueberry.palette.berrySymbol == nil)
        #expect(AppTheme.halloween.palette.berrySymbol == "🎃")
        #expect(AppTheme.christmas.palette.berrySymbol == "❄️")
        #expect(AppTheme.raspberry.palette.berrySymbol == nil)

        #expect(AppTheme.blueberry.palette.markerNamePlural == "berries")
        #expect(AppTheme.halloween.palette.markerName == "pumpkin")
        #expect(AppTheme.halloween.palette.markerNamePlural == "pumpkins")
        #expect(AppTheme.christmas.palette.markerName == "snowflake")
        #expect(AppTheme.christmas.palette.markerNamePlural == "snowflakes")
    }

    @Test("Seasonal themes provide matching attribution")
    func seasonalAttribution() {
        #expect(String(localized: AppTheme.blueberry.palette.attribution) == "Made with berries by James Brooks 🫐")
        #expect(String(localized: AppTheme.halloween.palette.attribution) == "Made with pumpkin spice by James Brooks 🎃")
        #expect(String(localized: AppTheme.christmas.palette.attribution) == "Made with gingerbread by James Brooks 🎅")

        #expect(String(localized: AppTheme.blueberry.palette.proTagline) == "An endless berry patch")
        #expect(String(localized: AppTheme.halloween.palette.proTagline) == "An endless pumpkin patch")
        #expect(String(localized: AppTheme.christmas.palette.proTagline) == "An endless flurry of snowflakes")
    }
}
