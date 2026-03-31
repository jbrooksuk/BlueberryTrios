import XCTest

final class ScreenshotTests: XCTestCase {
    let app = XCUIApplication()

    override func setUp() {
        continueAfterFailure = false
        app.launchArguments = ["--uitesting"]
    }

    // MARK: - Light Mode

    func test01_HomeLight() {
        app.launch()
        sleep(3)
        // Dismiss walkthrough if shown
        dismissWalkthroughIfPresent()
        takeScreenshot(named: "01-home-light")
    }

    func test02_PuzzleInProgressLight() {
        app.launch()
        sleep(2)
        dismissWalkthroughIfPresent()

        // Tap Standard "1" button
        tapDifficultyButton("Standard")
        sleep(2)

        // Place a few berries to show "in progress"
        placeSomeMoves()
        sleep(1)

        takeScreenshot(named: "02-puzzle-inprogress-light")
    }

    func test03_PuzzleCompletedLight() {
        app.launch()
        sleep(2)
        dismissWalkthroughIfPresent()

        // Navigate to a puzzle that's already solved, or tap Standard
        tapDifficultyButton("Standard")
        sleep(2)

        // Take screenshot showing the puzzle (may be in progress or solved)
        takeScreenshot(named: "03-puzzle-completed-light")
    }

    func test04_AchievementsLight() {
        app.launch()
        sleep(2)
        dismissWalkthroughIfPresent()

        let achievementsTab = app.tabBars.buttons["Achievements"]
        if achievementsTab.waitForExistence(timeout: 5) {
            achievementsTab.tap()
            sleep(2)
        }
        takeScreenshot(named: "04-achievements-light")
    }

    // MARK: - Dark Mode (separate test class invoked by script with appearance override)

    func test05_HomeDark() {
        app.launch()
        sleep(3)
        dismissWalkthroughIfPresent()
        takeScreenshot(named: "05-home-dark")
    }

    func test06_PuzzleInProgressDark() {
        app.launch()
        sleep(2)
        dismissWalkthroughIfPresent()

        tapDifficultyButton("Standard")
        sleep(2)
        placeSomeMoves()
        sleep(1)

        takeScreenshot(named: "06-puzzle-inprogress-dark")
    }

    func test07_PuzzleCompletedDark() {
        app.launch()
        sleep(2)
        dismissWalkthroughIfPresent()

        tapDifficultyButton("Standard")
        sleep(2)

        takeScreenshot(named: "07-puzzle-completed-dark")
    }

    func test08_AchievementsDark() {
        app.launch()
        sleep(2)
        dismissWalkthroughIfPresent()

        let achievementsTab = app.tabBars.buttons["Achievements"]
        if achievementsTab.waitForExistence(timeout: 5) {
            achievementsTab.tap()
            sleep(2)
        }
        takeScreenshot(named: "08-achievements-dark")
    }

    // MARK: - Helpers

    private func dismissWalkthroughIfPresent() {
        // If walkthrough is showing, tap through to dismiss
        let letsPlayButton = app.buttons["Let's play!"]
        if letsPlayButton.waitForExistence(timeout: 2) {
            // Tap Next until we reach the last page
            let nextButton = app.buttons["Next"]
            for _ in 0..<10 {
                if letsPlayButton.exists {
                    letsPlayButton.tap()
                    sleep(1)
                    return
                }
                if nextButton.exists {
                    nextButton.tap()
                    sleep(0.5)
                }
            }
        }
    }

    private func tapDifficultyButton(_ difficulty: String) {
        // Try tapping the difficulty button text
        let button = app.staticTexts[difficulty]
        if button.waitForExistence(timeout: 3) {
            button.tap()
        }
    }

    private func placeSomeMoves() {
        // Tap a few cells on the puzzle grid to show in-progress state
        // The grid is roughly centered, try tapping cells
        let grid = app.otherElements.firstMatch
        if grid.waitForExistence(timeout: 3) {
            let frame = grid.frame
            // Tap at various positions within the grid area
            let positions: [(CGFloat, CGFloat)] = [
                (0.2, 0.3), (0.5, 0.2), (0.8, 0.5),
                (0.3, 0.7), (0.6, 0.4), (0.7, 0.8),
            ]
            for (xRatio, yRatio) in positions {
                let point = grid.coordinate(withNormalizedOffset: CGVector(dx: xRatio, dy: yRatio))
                point.tap()
                usleep(200_000)
            }
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
