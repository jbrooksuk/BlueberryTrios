import XCTest

final class ScreenshotTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDown() {
        if app.state != .notRunning {
            app.terminate()
        }
        app = nil
    }

    func testLight01Blueberry() {
        captureTheme("blueberry", appearance: "light", homeNumber: 1, puzzleNumber: 2)
    }

    func testLight02Halloween() {
        captureTheme("halloween", appearance: "light", homeNumber: 3)
    }

    func testLight03Christmas() {
        captureTheme("christmas", appearance: "light", homeNumber: 4)
    }

    func testLight04Raspberry() {
        captureTheme("raspberry", appearance: "light", homeNumber: 5, puzzleNumber: 6)
    }

    func testLight05Achievements() {
        captureAchievements(appearance: "light")
    }

    func testLight06BerryRevival() {
        captureBerryRevival(appearance: "light")
    }

    func testLight07PurchasesAreDiscoverable() {
        launch(theme: "blueberry", fixture: "berry-revival-demo")

        let settingsTab = app.tabBars.buttons["Settings"]
        XCTAssertTrue(settingsTab.waitForExistence(timeout: 5), "Settings tab did not appear")
        settingsTab.tap()

        let berryRevival = app.staticTexts["Berry Revival"]
        for _ in 0..<5 where !berryRevival.isHittable {
            app.swipeUp(velocity: .slow)
        }
        XCTAssertTrue(berryRevival.isHittable, "Berry Revival did not appear in Settings")
        XCTAssertTrue(app.staticTexts["Available after a streak lapses."].exists)

        let demoMode = app.switches["Berry Revival Demo Mode"]
        XCTAssertTrue(demoMode.isHittable, "Berry Revival Demo Mode did not appear in Settings")
        demoMode.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        expectation(for: NSPredicate(format: "value == '1'"), evaluatedWith: demoMode)
        waitForExpectations(timeout: 3)
        takeScreenshot(named: "09-blueberry-purchases-light")
        XCTAssertTrue(app.buttons["Buy Berry Revival for £0.99"].waitForExistence(timeout: 3))

        let raspberryTheme = app.staticTexts["Raspberry Theme"]
        for _ in 0..<5 where !raspberryTheme.isHittable {
            app.swipeUp(velocity: .slow)
        }
        XCTAssertTrue(raspberryTheme.isHittable, "Raspberry Theme did not appear in Settings")
        takeScreenshot(named: "10-raspberry-theme-purchase-light")
    }

    func testDark01Blueberry() {
        captureTheme("blueberry", appearance: "dark", homeNumber: 1, puzzleNumber: 2)
    }

    func testDark02Halloween() {
        captureTheme("halloween", appearance: "dark", homeNumber: 3)
    }

    func testDark03Christmas() {
        captureTheme("christmas", appearance: "dark", homeNumber: 4)
    }

    func testDark04Raspberry() {
        captureTheme("raspberry", appearance: "dark", homeNumber: 5, puzzleNumber: 6)
    }

    func testDark05Achievements() {
        captureAchievements(appearance: "dark")
    }

    func testDark06BerryRevival() {
        captureBerryRevival(appearance: "dark")
    }

    private func captureTheme(
        _ theme: String,
        appearance: String,
        homeNumber: Int,
        puzzleNumber: Int? = nil
    ) {
        launch(theme: theme)
        takeScreenshot(named: filename(number: homeNumber, theme: theme, screen: "home", appearance: appearance))

        if let puzzleNumber {
            openStandardPuzzle()
            placeMarkers()
            takeScreenshot(named: filename(number: puzzleNumber, theme: theme, screen: "puzzle", appearance: appearance))
        }
    }

    private func captureAchievements(appearance: String) {
        launch(theme: "blueberry")
        let achievementsTab = app.tabBars.buttons["Achievements"]
        XCTAssertTrue(achievementsTab.waitForExistence(timeout: 5), "Achievements tab did not appear")
        achievementsTab.tap()
        XCTAssertTrue(app.staticTexts["Achievements earned"].waitForExistence(timeout: 5), "Achievements screen did not appear")
        takeScreenshot(named: "07-blueberry-achievements-\(appearance)")
    }

    private func captureBerryRevival(appearance: String) {
        launch(theme: "blueberry", fixture: "berry-revival")
        XCTAssertTrue(app.staticTexts["Berry Revival"].waitForExistence(timeout: 5), "Berry Revival offer did not appear")
        XCTAssertTrue(app.buttons["Buy Berry Revival for £0.99"].exists, "Berry Revival purchase button did not appear")
        takeScreenshot(named: "08-blueberry-berry-revival-\(appearance)")
    }

    private func launch(theme: String, fixture: String? = nil) {
        if app.state != .notRunning {
            app.terminate()
        }

        app.launchArguments = [
            "--uitesting",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_GB",
            "-hasSeenWalkthrough", "YES",
            "-hasCompletedTutorial", "YES",
            "-selectedThemeID", theme,
            "-autoCheck", "NO",
            "-showTimer", "YES",
        ]
        if let fixture {
            app.launchArguments += ["--screenshot-fixture", fixture]
        }
        app.launch()

        XCTAssertTrue(app.staticTexts["Berroku"].waitForExistence(timeout: 8), "Home screen did not appear for \(theme)")
    }

    private func openStandardPuzzle() {
        let standardLabel = app.staticTexts["Standard"]
        XCTAssertTrue(standardLabel.waitForExistence(timeout: 5), "Standard puzzle row did not appear")
        standardLabel.tap()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 8), "Puzzle screen did not appear")
    }

    private func placeMarkers() {
        let undecidedCells = app.descendants(matching: .any).matching(
            NSPredicate(format: "label BEGINSWITH 'Row ' AND label ENDSWITH ', empty'")
        )

        // Two markers make the themed puzzle treatment visible while keeping
        // each simulator test short enough to avoid testmanagerd timeouts.
        for _ in 0..<2 {
            let cell = undecidedCells.firstMatch
            XCTAssertTrue(cell.waitForExistence(timeout: 3), "Could not find an editable puzzle cell")
            let crossedLabel = cell.label.replacingOccurrences(of: ", empty", with: ", crossed")
            cell.tap()

            let crossedCell = app.descendants(matching: .any).matching(
                NSPredicate(format: "label == %@", crossedLabel)
            ).firstMatch
            XCTAssertTrue(crossedCell.waitForExistence(timeout: 3), "Cell did not advance to crossed")
            crossedCell.tap()
        }
    }

    private func filename(number: Int, theme: String, screen: String, appearance: String) -> String {
        "\(String(format: "%02d", number))-\(theme)-\(screen)-\(appearance)"
    }

    private func takeScreenshot(named name: String) {
        // Give SwiftUI animations and Canvas drawing one frame to settle.
        usleep(500_000)
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
