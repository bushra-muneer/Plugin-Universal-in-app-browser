# Plugin Universal In-App Browser

Universal In-App Browser is a Flutter plugin project that aims to offer a single,
customisable API for presenting web content inside your Flutter apps on Android,
iOS, Web, and desktop.

> Status: The plugin scaffold is being prepared. Contributions, ideas, and issue
> reports are welcome while the first release is assembled.

## Features (Planned)
  exposed through a single Flutter API.
- Event stream `browserEvents` provides platform/browser events: opened, dismissed, error, pageStarted, pageFinished.

### Embedded WebView & JS Bridge

The plugin exposes an embedded webview mode which returns an `EmbeddedWebViewController`.
This controller supports:

- `evaluateJavascript(String)` — evaluate arbitrary JS in the embedded page and return the result.
- `postMessage(String)` — best-effort postMessage into the page (uses JS injection).
- `addJavascriptHandler(String, Function)` — register a Dart callback that page JS can invoke via `window.flutter_inappwebview.callHandler(handlerName, ...args)`.
- `removeJavascriptHandler(String)` — best-effort removal: removes the Dart-side callback and attempts to inject a small no-op shim into the page to prevent further calls. `flutter_inappwebview` does not currently provide a direct handler removal API.
- `dispose()` — release the controller and prevent further calls.

Platform notes
- Android: uses Custom Tabs; toolbar color and title support. Custom Tabs cannot attach arbitrary request headers for the initial navigation; if headers are required the embedded mode should be used. Dismiss detection is implemented by detecting app resume after opening custom tabs; this is heuristic and may not be perfect across all devices.
- iOS: uses SFSafariViewController and supports toolbar color. SFSafariViewController cannot set arbitrary request headers — use embedded mode for header support. Dismissed events are sent to Dart when the user dismisses the SFSafariViewController.

Event payloads
- opened: { 'event': 'opened', 'url': '<opened-url>' }
- dismissed: { 'event': 'dismissed', 'url': '<url-if-available>' }
- error: { 'event': 'error', 'message': '<error-message>' }
- pageStarted: { 'event': 'pageStarted', 'url': '<navigated-url>' }
- pageFinished: { 'event': 'pageFinished', 'url': '<navigated-url>' }

## Getting Started
The plugin is not yet published on pub.dev. Once the first release is ready, you
will be able to depend on it directly from your Flutter project.

```sh
flutter pub add plugin_universal_in_app_browser
```

To try the main branch before publication:
1. Add the Git dependency to your `pubspec.yaml`.
2. Fetch packages with `flutter pub get`.
3. Import the library and interact with the `UniversalInAppBrowser` API.

```yaml
dependencies:
  plugin_universal_in_app_browser:
    git:
      url: https://github.com/bushra-muneer/Plugin-Universal-in-app-browser.git
      ref: main
```

### Basic Usage (Draft API)
```dart
import 'package:plugin_universal_in_app_browser/plugin_universal_in_app_browser.dart';

final browser = UniversalInAppBrowser();
await browser.openUrl(
  'https://example.com',
  options: BrowserOptions(
    showTitle: true,
    toolbarColor: const Color(0xFF202020),
    headers: {'Authorization': 'Bearer <token>'},
  ),
);
```

> The API surface is subject to change while the plugin is stabilised.
> Internally, the plugin builds on [`flutter_inappwebview`](https://pub.dev/packages/flutter_inappwebview)
> and currently pins `^6.0.0` while the implementation evolves.

## How this differs from flutter_inappwebview

This plugin targets the common, high-level browser flows (open a URL in the system browser or an embedded WebView with a small JS bridge). It focuses on being lightweight and easy to use for the most common scenarios: opening links, receiving open/dismiss events, and exchanging simple messages with an embedded page. By contrast, `flutter_inappwebview` is a full-featured WebView toolkit that exposes the entire WebView API surface (page navigation events, advanced settings, WebRTC, service workers, inspectors, etc.).

Key differences:

- Scope: this plugin = opinionated, small API; `flutter_inappwebview` = complete WebView control.
- Size & complexity: this plugin aims to be a thin wrapper (few APIs); `flutter_inappwebview` is large and exposes many platform-specific knobs.
- Use-case fit: choose this plugin for simple browser interactions and quick JS-bridge messages. Choose `flutter_inappwebview` when you need fine-grained control, complex WebView features, or custom native hooks.

If you need advanced WebView features you can either use `flutter_inappwebview` directly or access the underlying `InAppWebViewController` using the helper in this package (see the API comparison and example below).

## API comparison (common use-case → recommended API)

| Common use-case | This plugin (recommended) | `flutter_inappwebview` (recommended) |
|---|---:|---:|
| Open a URL in the system browser (with callbacks for open/dismiss) | `UniversalInAppBrowser.openUrl(...)` + `browserEvents` stream | Use `ChromeSafariBrowser` from `flutter_inappwebview` and wire up its events |
| Embed a page with a simple JS bridge (callHandler/postMessage) | `UniversalInAppBrowser.openEmbedded(...)` → `EmbeddedWebViewController.addJavascriptHandler(...)` / `postMessage(...)` | Create `InAppWebView` and manage `InAppWebViewController`, add JavaScript handlers and message channels directly |
| Evaluate JS and get results | `EmbeddedWebViewController.evaluateJavascript(...)` | `InAppWebViewController.evaluateJavascript(...)` (more options/extra callbacks) |
| Advanced WebView features (custom headers on every request, service workers, WebRTC, cookie manager, resource interception) | Use `flutter_inappwebview` directly (or call underlying controller) | Use `flutter_inappwebview` APIs (native-level control) |
| Deep debugging (inspect WebView, set user-agent per request, intercept requests) | Not supported directly — use `flutter_inappwebview` | Fully supported by `flutter_inappwebview` |

## Migration guide: moving from flutter_inappwebview to this plugin

If you currently use `flutter_inappwebview` but want to move to a thinner API for simple browser flows, follow these steps:

1. Identify common patterns you use. If they're limited to "open a URL", "embedded page with a small JS bridge", and "evaluate JS", you can switch to this plugin with minimal changes.

2. Replace boilerplate code:

- Opening a system browser

  - Before (flutter_inappwebview): create `ChromeSafariBrowser`, attach events, call `open`.
  - After (this plugin): call `UniversalInAppBrowser.openUrl(url, options)` and listen to `UniversalInAppBrowser.browserEvents` for `onOpened`/`onDismissed`.

- Embedded page with a small JS bridge

  - Before: instantiate `InAppWebView`, keep `InAppWebViewController`, register `addJavaScriptHandler`.
  - After: call `UniversalInAppBrowser.openEmbedded(...)` to get an `EmbeddedWebViewController`. Use `addJavascriptHandler`, `evaluateJavascript`, and `postMessage` for simple flows.

3. When you need an advanced feature not supported by this plugin, either:

  - Keep using `flutter_inappwebview` for that part of your app; or
  - Use the `EmbeddedWebViewController.getUnderlyingController()` helper (nullable) to get the `InAppWebViewController` instance and call `flutter_inappwebview` APIs directly.

4. Test your flows on device/emulator. The embedded WebView uses `flutter_inappwebview` under the hood so behavior should be similar, but verify native-level features.

## Bypass / advanced: access the underlying InAppWebViewController

For users who want to use the convenience APIs most of the time but drop down to `flutter_inappwebview` for specific power features, `EmbeddedWebViewController` exposes a nullable helper `getUnderlyingController()` that returns the underlying `InAppWebViewController` when available. Use it like:

```dart
final embedded = await UniversalInAppBrowser.openEmbedded(context, url: url);
final underlying = embedded.getUnderlyingController(); // nullable
if (underlying != null) {
  // Use flutter_inappwebview APIs directly
  final currentUrl = await underlying.getUrl();
  await underlying.reload();
}
```

This keeps the common path simple while allowing power users to drop to the full feature set on demand.


## Example App
You can explore integration patterns in the bundled example project.

```sh
git clone https://github.com/bushra-muneer/Plugin-Universal-in-app-browser.git
cd Plugin-Universal-in-app-browser/example
flutter pub get
flutter run # specify -d chrome, ios, android, etc. as needed
```

The example will be kept up to date with the recommended configuration for each
platform. Feel free to copy snippets into your own application.

## Implementation Notes
- Android invocations rely on Chrome Custom Tabs through the native plugin shim.
- iOS uses `SFSafariViewController` for a seamless in-app experience.
- Other platforms currently fall back to `flutter_inappwebview`'s browser helper
  until dedicated native integrations are added.

## Platform Setup (One-Time)
- **Android**
  - Ensure your app's `minSdkVersion` is at least 21 (Flutter's default already uses 21).
  - Declare the internet permission in `android/app/src/main/AndroidManifest.xml`:
    ```xml
    <uses-permission android:name="android.permission.INTERNET" />
    ```
  - Add any required intent filters or custom scheme handling to
    `android/app/src/main/AndroidManifest.xml` if you plan to deep link back.
  - If you customise toolbar icons, place assets in `android/app/src/main/res/`
    and supply them via the plugin options.
  - When releasing, update `android/app/proguard-rules.pro` to keep any Dart
    deferred components that communicate with the WebView.
- **iOS**
  - Confirm your deployment target is iOS 12 or higher inside `ios/Podfile`.
  - Add the base App Transport Security configuration in `ios/Runner/Info.plist`
    so the embedded browser can load remote content:
    ```xml
    <key>NSAppTransportSecurity</key>
    <dict>
      <key>NSAllowsArbitraryLoads</key>
      <true/>
      <key>NSAllowsArbitraryLoadsInWebContent</key>
      <true/>
    </dict>
    ```
  - Add domains that require arbitrary loads to `Info.plist` under
    `NSAppTransportSecurity` if the remote content is served over HTTP.
  - Enable associated domains in your app's entitlements when using universal
    links or hand-off back to Safari.
  - Run the example through Xcode once so it installs the plugin pod and validates
    signing settings.
- **Web and Desktop**
  - Enable the target platform you intend to support (`flutter config --enable-<platform>`).
  - For web builds, confirm the `web/index.html` file includes any CSP headers
    necessary for the sites you embed and that pop-up blocking is accounted for.
  - On desktop, test with `flutter run -d windows` (or macOS/Linux) and adjust
    window sizing logic from the example if you need a constrained browser view.

> Additional platform specifics will be documented alongside the first stable
> release once the API is solidified.

## Development Workflow
1. Ensure you have Flutter 3.x with the latest stable channel.
2. Clone the repository and generate the plugin scaffold if it is missing:
   ```sh
   flutter create --template=plugin --platforms=android,ios,web,macos,windows,linux .
   ```
3. Install dependencies:
   ```sh
   flutter pub get
   ```
4. Open the example app (`example/`) to validate changes across platforms.
5. Run the analyzer and formatter before submitting a pull request:
   ```sh
   flutter analyze
   dart format .
   ```

## Contributing
1. Fork the repository and create a feature branch.
2. Implement your changes with tests where applicable.
3. Ensure `flutter test` succeeds on all supported platforms.
4. Submit a pull request detailing the motivation and behaviour changes.

Please open an issue to discuss large changes or new feature ideas.

## License
Distributed under the MIT License. See [`LICENSE`](LICENSE) for details.
