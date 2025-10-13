# Universal In-App Browser Example

This Flutter app demonstrates how to integrate the Universal In-App Browser
plugin in a real project. The UI provides a single button that launches
`https://flutter.dev` inside the universal browser interface once the plugin
implementation is available.

## Prerequisites
- Flutter 3.x installed (`flutter --version`)
- An emulator or device for the platform you wish to run

## Running the Example
```sh
flutter pub get
flutter run -d chrome # or ios, android, windows, macos, linux
```

The app uses the local path dependency declared in `pubspec.yaml`, so ensure you
are running the app from inside the `example/` directory or pass `--target`
accordingly.

## Notes
- Error handling is included to surface issues while the plugin API is taking
  shape. The snack bar will display errors returned by the browser invocation.
- The plugin is still under development; the example may require updates as the
  API evolves.

## Platform Setup (One-Time)
- **Android**
  - Flutter templates already target `minSdkVersion` 21; confirm that value in `android/app/build.gradle`.
  - Ensure `android/app/src/main/AndroidManifest.xml` includes the internet permission:
    ```xml
    <uses-permission android:name="android.permission.INTERNET" />
    ```
- **iOS**
  - Set the deployment target to at least iOS 12 in `ios/Podfile`.
  - Add the App Transport Security configuration to `ios/Runner/Info.plist` so the embedded browser can reach external URLs:
    ```xml
    <key>NSAppTransportSecurity</key>
    <dict>
      <key>NSAllowsArbitraryLoads</key>
      <true/>
      <key>NSAllowsArbitraryLoadsInWebContent</key>
      <true/>
    </dict>
    ```
