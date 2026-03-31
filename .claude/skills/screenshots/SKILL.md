# Capture App Store Screenshots

Automatically capture App Store screenshots in light and dark mode.

## Usage

Invoke with `/screenshots` or ask "capture screenshots".

## What it does

Runs XCUITests on iPhone 17 Pro Max simulator to capture:

1. **Home screen** — light & dark
2. **Puzzle in progress** — light & dark (auto-places some moves)
3. **Puzzle completed** — light & dark
4. **Achievements** — light & dark

Total: 8 screenshots (4 screens × 2 modes)

## Steps

1. Run the capture script:
```bash
./scripts/capture-screenshots.sh
```

2. Screenshots are saved to `screenshots/appstore/light/` and `screenshots/appstore/dark/`

3. Result bundles are at `build/screenshots/` — open in Xcode to inspect individual test attachments if extraction fails:
```bash
open build/screenshots/light.xcresult
```

## Requirements

- Xcode with iPhone 17 Pro Max simulator installed
- BerrokuUITests target configured in the project
- App must be buildable for simulator

## Manual extraction

If the script can't extract PNGs automatically, open the `.xcresult` in Xcode → Tests → click each test → Attachments → right-click screenshot → Export.
