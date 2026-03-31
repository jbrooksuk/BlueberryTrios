import XCTest

final class ScreenshotTests: XCTestCase {
    let app = XCUIApplication(bundleIdentifier: "com.altthree.Berroku")

    override func setUp() {
        continueAfterFailure = false
    }

    func testCaptureScreenshots() throws {
        app.launch()
        sleep(3)

        // Home light
        takeScreenshot(named: "01-home-light")

        // Tap Advanced "2" button
        let advancedButton = app.staticTexts["Advanced"]
        if advancedButton.waitForExistence(timeout: 5) {
            advancedButton.tap()
            sleep(2)
            takeScreenshot(named: "02-puzzle-light")
        }

        // Go back
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.waitForExistence(timeout: 3) {
            backButton.tap()
            sleep(1)
        }

        // Tap Achievements tab
        let achievementsTab = app.buttons["Achievements"]
        if achievementsTab.waitForExistence(timeout: 3) {
            achievementsTab.tap()
            sleep(2)
            takeScreenshot(named: "03-achievements-light")
        }
    }

    private func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
