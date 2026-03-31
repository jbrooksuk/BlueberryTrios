#!/bin/bash
set -euo pipefail

# Berroku App Store Screenshot Automation
# Captures screenshots in light and dark mode on iPhone 17 Pro Max

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="$PROJECT_DIR/screenshots/appstore"
RESULT_DIR="$PROJECT_DIR/build/screenshots"
SIMULATOR="iPhone 17 Pro Max"
SCHEME="Blueberries"
BUNDLE_ID="com.altthree.Berroku"

echo "🫐 Berroku Screenshot Capture"
echo "=============================="

# Clean output
rm -rf "$OUTPUT_DIR" "$RESULT_DIR"
mkdir -p "$OUTPUT_DIR/light" "$OUTPUT_DIR/dark" "$RESULT_DIR"

# Boot simulator
echo "📱 Booting $SIMULATOR..."
SIM_ID=$(xcrun simctl list devices available | grep "$SIMULATOR" | grep -oE '[0-9A-F-]{36}' | head -1)
if [ -z "$SIM_ID" ]; then
    echo "❌ Simulator '$SIMULATOR' not found"
    exit 1
fi
xcrun simctl boot "$SIM_ID" 2>/dev/null || true

# Clean status bar
echo "🔋 Setting clean status bar..."
xcrun simctl status_bar "$SIM_ID" override \
    --time "9:41" \
    --batteryState charged \
    --batteryLevel 100 \
    --wifiBars 3 \
    --cellularBars 4 \
    --cellularMode active

# Build for testing
echo "🔨 Building..."
xcodebuild build-for-testing \
    -project "$PROJECT_DIR/Blueberries.xcodeproj" \
    -scheme "$SCHEME" \
    -sdk iphonesimulator \
    -destination "platform=iOS Simulator,id=$SIM_ID" \
    -derivedDataPath "$PROJECT_DIR/build" \
    2>&1 | tail -1

# --- Light Mode ---
echo ""
echo "☀️  Capturing Light Mode..."
xcrun simctl ui "$SIM_ID" appearance light
sleep 1

# Reset app state for clean screenshots
xcrun simctl terminate "$SIM_ID" "$BUNDLE_ID" 2>/dev/null || true
xcrun simctl privacy "$SIM_ID" reset all "$BUNDLE_ID" 2>/dev/null || true

xcodebuild test-without-building \
    -project "$PROJECT_DIR/Blueberries.xcodeproj" \
    -scheme "$SCHEME" \
    -sdk iphonesimulator \
    -destination "platform=iOS Simulator,id=$SIM_ID" \
    -derivedDataPath "$PROJECT_DIR/build" \
    -only-testing "BerrokuUITests/ScreenshotTests/test01_HomeLight" \
    -only-testing "BerrokuUITests/ScreenshotTests/test02_PuzzleInProgressLight" \
    -only-testing "BerrokuUITests/ScreenshotTests/test03_PuzzleCompletedLight" \
    -only-testing "BerrokuUITests/ScreenshotTests/test04_AchievementsLight" \
    -resultBundlePath "$RESULT_DIR/light.xcresult" \
    2>&1 | grep -E 'Test Suite|Test Case|passed|failed' || true

# --- Dark Mode ---
echo ""
echo "🌙 Capturing Dark Mode..."
xcrun simctl ui "$SIM_ID" appearance dark
sleep 1

xcrun simctl terminate "$SIM_ID" "$BUNDLE_ID" 2>/dev/null || true

xcodebuild test-without-building \
    -project "$PROJECT_DIR/Blueberries.xcodeproj" \
    -scheme "$SCHEME" \
    -sdk iphonesimulator \
    -destination "platform=iOS Simulator,id=$SIM_ID" \
    -derivedDataPath "$PROJECT_DIR/build" \
    -only-testing "BerrokuUITests/ScreenshotTests/test05_HomeDark" \
    -only-testing "BerrokuUITests/ScreenshotTests/test06_PuzzleInProgressDark" \
    -only-testing "BerrokuUITests/ScreenshotTests/test07_PuzzleCompletedDark" \
    -only-testing "BerrokuUITests/ScreenshotTests/test08_AchievementsDark" \
    -resultBundlePath "$RESULT_DIR/dark.xcresult" \
    2>&1 | grep -E 'Test Suite|Test Case|passed|failed' || true

# --- Extract Screenshots ---
echo ""
echo "📸 Extracting screenshots..."

extract_screenshots() {
    local result_bundle="$1"
    local output_subdir="$2"

    xcresulttool get \
        --path "$result_bundle" \
        --format json \
        2>/dev/null | python3 -c "
import json, sys, subprocess, os

data = json.load(sys.stdin)
output_dir = '$OUTPUT_DIR/$output_subdir'

def find_attachments(obj, path=''):
    if isinstance(obj, dict):
        if obj.get('_type', {}).get('_name') == 'ActionTestAttachment':
            name = obj.get('name', {}).get('_value', 'unknown')
            payload_ref = obj.get('payloadRef', {}).get('id', {}).get('_value')
            if payload_ref and name.endswith(('-light', '-dark')):
                output_path = os.path.join(output_dir, f'{name}.png')
                subprocess.run([
                    'xcresulttool', 'get',
                    '--path', '$result_bundle',
                    '--id', payload_ref,
                    '--output-path', output_path
                ], check=True)
                print(f'  ✅ {name}.png')
        for v in obj.values():
            find_attachments(v, path)
    elif isinstance(obj, list):
        for item in obj:
            find_attachments(item, path)

find_attachments(data)
" 2>/dev/null || echo "  ⚠️  Could not extract from $result_bundle (try manual extraction)"
}

extract_screenshots "$RESULT_DIR/light.xcresult" "light"
extract_screenshots "$RESULT_DIR/dark.xcresult" "dark"

# Reset appearance
xcrun simctl ui "$SIM_ID" appearance light
xcrun simctl status_bar "$SIM_ID" clear

echo ""
echo "✨ Done! Screenshots saved to: $OUTPUT_DIR"
echo ""
ls -la "$OUTPUT_DIR/light/" 2>/dev/null || echo "  (light dir empty — check xcresult manually)"
ls -la "$OUTPUT_DIR/dark/" 2>/dev/null || echo "  (dark dir empty — check xcresult manually)"
echo ""
echo "💡 Result bundles at: $RESULT_DIR/"
echo "   Open in Xcode: open $RESULT_DIR/light.xcresult"
