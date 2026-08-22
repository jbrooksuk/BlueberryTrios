# Berroku for Android

The Android app is a native Kotlin and Jetpack Compose project. It packages
`../Blueberries/Resources/puzzles.json` directly so both platforms use the same
catalogue bytes and the same cyrb53 daily seed contract.

Open this directory in Android Studio, select the `app` run configuration, and
run it on an API 26+ emulator. From the command line with JDK 17 and Android SDK
36 installed:

```bash
./gradlew :game-core:test :app:lintDebug :app:assembleDebug
adb install -r app/build/outputs/apk/debug/app-debug.apk
```

Every push or pull request that changes Android or the shared puzzle catalogue
runs the `Android` GitHub Actions workflow. A successful run exposes a
`berroku-debug-apk` artifact; download and unzip it, then drag `app-debug.apk`
onto a running Android Studio emulator (or install it with the `adb` command
above). The APK uses the standard debug signature and needs no signing secret.
