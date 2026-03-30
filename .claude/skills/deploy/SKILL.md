# Deploy to iPhone

Build and wirelessly deploy the Blueberries app to a connected iPhone.

## Usage

Invoke with `/deploy` or ask "deploy to my phone".

## Steps

1. Build for device:
```bash
xcodebuild -project Blueberries.xcodeproj -scheme Blueberries -sdk iphoneos -configuration Debug -derivedDataPath /Users/james/Code/Blueberries/build
```

2. List available devices to find the target:
```bash
xcrun devicectl list devices
```

3. Install wirelessly (use the device identifier from step 2):
```bash
xcrun devicectl device install app --device <DEVICE_ID> /Users/james/Code/Blueberries/build/Build/Products/Debug-iphoneos/Blueberries.app
```

## Known devices

- **iPhone 17** (primary): `7722C014-C97A-5414-8D3B-0FCA0901AEA6` (James-iPhone.coredevice.local)
- **iPhone 15 Pro** (old): `762A2089-1695-597E-8006-8E1CC475AB28`

## Troubleshooting

- If install fails with "connection reset by peer", ensure the iPhone is **unlocked** and on the **same Wi-Fi network**.
- If the device shows as "unavailable", the wireless debugging trust may have expired — re-pair in Xcode (Window > Devices and Simulators > Connect via network).
- Build errors: check with `xcodebuild ... 2>&1 | grep error:`.
