# Plugin Universal In-App Browser

A lightweight Flutter plugin for opening web content with a small, friendly API.

The goal is simple: give Flutter apps one clean place to open a URL, listen to browser events, and use an embedded WebView when the app needs headers or a small JavaScript bridge.

## Status

This package is in release preparation.

The first public release is focused on:

- Android: Chrome Custom Tabs
- iOS: `SFSafariViewController`
- Embedded WebView: powered by `flutter_inappwebview` for simple JS bridge use cases

Web, macOS, Windows, and Linux are not being claimed as stable targets yet. They can be explored later after the mobile API is solid.

## Features

- Open a URL from Flutter with `UniversalInAppBrowser.openUrl(...)`.
- Configure basic browser options with `BrowserOptions`.
- Listen to browser events with `browserEvents`.
- Use an embedded WebView when you need custom headers or JavaScript helpers.
- Evaluate JavaScript, post simple messages, register JS handlers, and access the underlying `InAppWebViewController` when needed.

## Install

The package is not published on pub.dev yet. Until the first release is published, use the Git dependency:

```yaml
dependencies:
  plugin_universal_in_app_browser:
    git:
      url: https://github.com/bushra-muneer/Plugin-Universal-in-app-browser.git
      ref: main
```

After the package is published, installation will be:

```sh
flutter pub add plugin_universal_in_app_browser
```

## Basic usage

```dart
import 'package:flutter/material.dart';
import 'package:plugin_universal_in_app_browser/plugin_universal_in_app_browser.dart';

final browser = UniversalInAppBrowser();

await browser.openUrl(
  'https://flutter.dev',
  options: const BrowserOptions(
    showTitle: true,
    toolbarColor: Color(0xFF202020),
  ),
);
```

## Listen to browser events

```dart
browserEvents.listen((event) {
  debugPrint('Browser event: $event');
});
```

Common event names:

- `opened`
- `dismissed`
- `error`
- `pageStarted`
- `pageFinished`

## Embedded WebView and JavaScript bridge

Use the embedded flow when you need custom headers, JavaScript evaluation, or simple app-to-page communication.

```dart
final embedded = await browser.openEmbedded(
  context,
  'https://example.com',
  options: const BrowserOptions(
    showTitle: true,
  ),
);

await embedded?.addJavascriptHandler('demo', (message) {
  debugPrint('Message from page: $message');
});

await embedded?.evaluateJavascript('document.title');
await embedded?.postMessage('hello from Flutter');
```

For advanced cases, you can access the underlying controller:

```dart
final controller = embedded?.getUnderlyingController();
await controller?.reload();
```

## Platform notes

### Android

Android uses Chrome Custom Tabs through a small native wrapper activity. The wrapper is used so the plugin can send a best-effort `dismissed` event when the user returns to the app.

Custom Tabs do not reliably support arbitrary request headers for the first navigation. Use the embedded WebView mode if headers are required.

### iOS

iOS uses `SFSafariViewController`. It supports a native Safari-style in-app browser and sends a dismiss event when the user closes it.

`SFSafariViewController` does not support arbitrary request headers. Use the embedded WebView mode if headers are required.

## Example app

```sh
git clone https://github.com/bushra-muneer/Plugin-Universal-in-app-browser.git
cd Plugin-Universal-in-app-browser/example
flutter pub get
flutter run
```

The example app includes:

- native browser open flow
- embedded WebView flow
- JS handler demo
- postMessage demo
- underlying controller demo

## Development

From the package root:

```sh
flutter pub get
dart format .
flutter analyze
flutter test
```

Before publishing:

```sh
dart pub publish --dry-run
```

## Release checklist

Before the first pub.dev release, confirm:

- `flutter analyze` passes.
- `flutter test` passes.
- the example app runs on Android.
- the example app runs on iOS.
- `dart pub publish --dry-run` has no blocking issues.
- the README matches the real supported platforms.

## Known limitations

- Android dismiss detection is best-effort because Chrome Custom Tabs do not provide a perfect close callback in every case.
- System browser modes cannot attach arbitrary request headers consistently. Use embedded mode for headers.
- Embedded WebView support is intentionally small. For advanced WebView features, use the underlying `flutter_inappwebview` controller.
- Web and desktop support are not stable release targets yet.

## License

MIT License. See [LICENSE](LICENSE) for details.
