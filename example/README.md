# Universal In-App Browser Example

This example app shows how the plugin feels inside a real Flutter screen.

It currently demonstrates:

- opening `https://flutter.dev` in the native in-app browser
- opening an embedded WebView
- listening to browser events
- calling JavaScript from Flutter
- receiving a simple JavaScript handler call
- posting a message into the embedded page
- accessing the underlying `flutter_inappwebview` controller

## Run the example

```sh
cd example
flutter pub get
flutter run
```

Use a real Android or iOS device/emulator when checking the native browser flow.

## Platform notes

### Android

Make sure the app has internet permission:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS

Use iOS 12 or higher. If you load non-HTTPS content during local testing, update `Info.plist` carefully for that development case only.

## Developer checks

From the package root:

```sh
flutter analyze
flutter test
```

From this example folder:

```sh
flutter analyze
```
