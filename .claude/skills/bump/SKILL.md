# Bump Version

Bump the app's marketing version or build number.

## Usage

Invoke with `/bump` or ask "bump the version".

## How it works

Versions are stored in `Blueberries.xcodeproj/project.pbxproj`:

- **MARKETING_VERSION** — the user-facing version (e.g., `1.0`, `1.1`, `2.0`). Shown on the App Store.
- **CURRENT_PROJECT_VERSION** — the build number (e.g., `1`, `2`, `3`). Must increment for each upload to App Store Connect.

Both appear in multiple build configurations (Debug/Release for main app and widget). All occurrences must be updated together.

## Steps

1. Ask the user what to bump:
   - **Build** — increment `CURRENT_PROJECT_VERSION` by 1 (most common, needed for each App Store upload)
   - **Patch** — bump `MARKETING_VERSION` patch (e.g., 1.0 → 1.0.1) and reset build to 1
   - **Minor** — bump `MARKETING_VERSION` minor (e.g., 1.0 → 1.1) and reset build to 1
   - **Major** — bump `MARKETING_VERSION` major (e.g., 1.0 → 2.0) and reset build to 1

2. Use `sed` or the Edit tool to replace ALL occurrences in `project.pbxproj`:
   ```bash
   # Example: bump build number from 2 to 3
   sed -i '' 's/CURRENT_PROJECT_VERSION = 2;/CURRENT_PROJECT_VERSION = 3;/g' Blueberries.xcodeproj/project.pbxproj
   ```

3. Confirm the change by grepping the file:
   ```bash
   grep 'MARKETING_VERSION\|CURRENT_PROJECT_VERSION' Blueberries.xcodeproj/project.pbxproj
   ```

4. Commit with message: `Bump version to X.Y.Z (build N)`
