#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$PROJECT_DIR/build/screenshots"
DERIVED_DATA_DIR="$BUILD_DIR/DerivedData"
RESULT_DIR="$BUILD_DIR/results"
OUTPUT_DIR="$BUILD_DIR/output"
SIMULATOR="${SIMULATOR:-iPhone 17 Pro Max}"
SCHEME="Screenshots"

format_xcodebuild() {
    if command -v xcbeautify >/dev/null 2>&1; then
        xcbeautify
    else
        cat
    fi
}

expected_names() {
    local appearance="$1"
    printf '%s\n' \
        "01-blueberry-home-$appearance" \
        "02-blueberry-puzzle-$appearance" \
        "03-halloween-home-$appearance" \
        "04-christmas-home-$appearance" \
        "05-raspberry-home-$appearance" \
        "06-raspberry-puzzle-$appearance" \
        "07-blueberry-achievements-$appearance"
}

find_simulator() {
    xcrun simctl list devices available --json | python3 -c '
import json, sys

name = sys.argv[1]
devices = json.load(sys.stdin)["devices"]
for runtime in sorted(devices, reverse=True):
    for device in devices[runtime]:
        if device["name"] == name and device.get("isAvailable", True):
            print(device["udid"])
            raise SystemExit(0)
raise SystemExit(1)
' "$SIMULATOR"
}

extract_screenshots() {
    local appearance="$1"
    local result_bundle="$RESULT_DIR/$appearance.xcresult"
    local exported_dir="$RESULT_DIR/$appearance-attachments"
    local output_subdir="$OUTPUT_DIR/$appearance"

    rm -rf "$exported_dir"
    mkdir -p "$exported_dir" "$output_subdir"
    xcrun xcresulttool export attachments \
        --path "$result_bundle" \
        --output-path "$exported_dir"

    local manifest="$exported_dir/manifest.json"
    local name exported_filename source
    while IFS= read -r name; do
        exported_filename="$(python3 - "$manifest" "$name" <<'PY'
import json, sys

with open(sys.argv[1]) as file:
    results = json.load(file)

prefix = f"{sys.argv[2]}_"
for result in results:
    for attachment in result.get("attachments", []):
        if attachment.get("suggestedHumanReadableName", "").startswith(prefix):
            print(attachment["exportedFileName"])
            raise SystemExit(0)
raise SystemExit(1)
PY
)"
        source="$exported_dir/$exported_filename"
        if [[ ! -f "$source" ]]; then
            echo "Missing screenshot attachment: $name" >&2
            exit 1
        fi
        cp "$source" "$output_subdir/$name.png"
    done < <(expected_names "$appearance")
}

run_screenshots() {
    local appearance="$1"
    local method_prefix="$2"
    local only_testing=()
    local suffix

    for suffix in 01Blueberry 02Halloween 03Christmas 04Raspberry 05Achievements; do
        only_testing+=("-only-testing:BerrokuUITests/ScreenshotTests/test${method_prefix}${suffix}")
    done

    echo "Capturing $appearance screenshots..."
    xcrun simctl ui "$SIM_ID" appearance "$appearance"
    xcodebuild test-without-building \
        -project "$PROJECT_DIR/Blueberries.xcodeproj" \
        -scheme "$SCHEME" \
        -sdk iphonesimulator \
        -destination "platform=iOS Simulator,id=$SIM_ID" \
        -derivedDataPath "$DERIVED_DATA_DIR" \
        "${only_testing[@]}" \
        -resultBundlePath "$RESULT_DIR/$appearance.xcresult" \
        | format_xcodebuild
    extract_screenshots "$appearance"
}

cleanup() {
    xcrun simctl ui "$SIM_ID" appearance light >/dev/null 2>&1 || true
    xcrun simctl status_bar "$SIM_ID" clear >/dev/null 2>&1 || true
}

echo "Berroku screenshot capture"
echo "==========================="

rm -rf "$BUILD_DIR"
mkdir -p "$RESULT_DIR" "$OUTPUT_DIR"

if ! SIM_ID="$(find_simulator)"; then
    echo "Simulator '$SIMULATOR' is not installed. Available iPhone simulators:" >&2
    xcrun simctl list devices available | grep iPhone >&2 || true
    exit 1
fi

trap cleanup EXIT
xcrun simctl boot "$SIM_ID" >/dev/null 2>&1 || true
xcrun simctl bootstatus "$SIM_ID" -b
xcrun simctl status_bar "$SIM_ID" override \
    --time "9:41" \
    --batteryState charged \
    --batteryLevel 100 \
    --wifiBars 3 \
    --cellularBars 4 \
    --cellularMode active

echo "Building screenshot tests for $SIMULATOR..."
xcodebuild build-for-testing \
    -project "$PROJECT_DIR/Blueberries.xcodeproj" \
    -scheme "$SCHEME" \
    -sdk iphonesimulator \
    -destination "platform=iOS Simulator,id=$SIM_ID" \
    -derivedDataPath "$DERIVED_DATA_DIR" \
    | format_xcodebuild

run_screenshots light Light
run_screenshots dark Dark

count="$(find "$OUTPUT_DIR" -type f -name '*.png' | wc -l | tr -d ' ')"
if [[ "$count" != "14" ]]; then
    echo "Expected 14 screenshots, found $count" >&2
    exit 1
fi

echo "Generated $count screenshots in $OUTPUT_DIR"
