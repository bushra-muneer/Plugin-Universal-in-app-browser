import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

const MethodChannel _channel = MethodChannel('plugin_universal_in_app_browser');

/// Broadcast stream of platform/browser events (opened, dismissed, navigation, errors)
final StreamController<Map<String, dynamic>> _eventController =
    StreamController<Map<String, dynamic>>.broadcast();

Stream<Map<String, dynamic>> get browserEvents => _eventController.stream;

Future<void> _ensureChannelHandler() async {
  // set handler repeatedly is harmless; ensures Dart receives invocations from native
  _channel.setMethodCallHandler((call) async {
    final method = call.method;
    final args = (call.arguments as Map?)?.cast<String, dynamic>();
    switch (method) {
      case 'onOpened':
        _eventController.add({'event': 'opened', ...?args});
        break;
      case 'onDismissed':
        _eventController.add({'event': 'dismissed', ...?args});
        break;
      case 'onError':
        _eventController.add({'event': 'error', ...?args});
        break;
      case 'onPageStarted':
        _eventController.add({'event': 'pageStarted', ...?args});
        break;
      case 'onPageFinished':
        _eventController.add({'event': 'pageFinished', ...?args});
        break;
      default:
        // ignore
        break;
    }
  });
}

/// Configuration options for the universal in-app browser presentation.
@immutable
class BrowserOptions {
  const BrowserOptions({
    this.showTitle = true,
    this.toolbarColor,
    this.headers,
  });

  /// Whether to show the page title in the native toolbar (where supported).
  final bool showTitle;

  /// Optional toolbar/background colour for the browser chrome.
  final Color? toolbarColor;

  /// Additional HTTP headers to include with the initial request.
  final Map<String, String>? headers;

  Map<String, dynamic> toChannelPayload() {
    return <String, dynamic>{
      'showTitle': showTitle,
      if (toolbarColor != null) 'toolbarColor': toolbarColor!.toARGB32(),
      if (headers != null && headers!.isNotEmpty) 'headers': headers,
    };
  }

  BrowserOptions copyWith({
    bool? showTitle,
    Color? toolbarColor,
    Map<String, String>? headers,
  }) {
    return BrowserOptions(
      showTitle: showTitle ?? this.showTitle,
      toolbarColor: toolbarColor ?? this.toolbarColor,
      headers: headers ?? this.headers,
    );
  }
}

/// Universal in-app browser wrapper with native implementations for Android/iOS
/// and a package fallback elsewhere.
class UniversalInAppBrowser {
  /// Opens the provided [url] inside a platform native in-app browser surface.
  Future<void> openUrl(
    String url, {
    BrowserOptions? options,
  }) async {
    await _ensureChannelHandler();
    final sanitized = WebUri(url);
    if (sanitized.scheme.isEmpty) {
      throw ArgumentError.value(
          url, 'url', 'A valid scheme (eg. https) is required.');
    }

    final payload = <String, dynamic>{
      'url': sanitized.toString(),
      'options': (options ?? const BrowserOptions()).toChannelPayload(),
    };

    if (_isMobilePlatform) {
      await _channel.invokeMethod<void>('openUrl', payload);
      return;
    }

    await _openFallback(payload);
  }

  Future<void> _openFallback(Map<String, dynamic> payload) async {
    final options = payload['options'] as Map<String, dynamic>;
    final headers = (options['headers'] as Map?)?.cast<String, String>();

    final browser = _FallbackBrowser();
    final chromeSafariOptions = ChromeSafariBrowserSettings(
      showTitle: options['showTitle'] as bool? ?? true,
      toolbarBackgroundColor: _colorFromValue(options['toolbarColor']),
      preferredBarTintColor: _colorFromValue(options['toolbarColor']),
      dismissButtonStyle: DismissButtonStyle.CLOSE,
      barCollapsingEnabled: true,
    );

    await browser.open(
      url: WebUri(payload['url'] as String),
      settings: chromeSafariOptions,
      headers: (headers == null || headers.isEmpty) ? null : headers,
    );
  }

  /// Opens an embedded webview inside the app using `InAppWebView`.
  /// This provides headers, JS execution and navigation events.
  Future<EmbeddedWebViewController?> openEmbedded(
    BuildContext context,
    String url, {
    BrowserOptions? options,
  }) async {
    final navigator = Navigator.of(context);

    await _ensureChannelHandler();

    final sanitized = WebUri(url);
    if (sanitized.scheme.isEmpty) {
      throw ArgumentError.value(
          url, 'url', 'A valid scheme (eg. https) is required.');
    }

    final headers = options?.headers;

    final result = await navigator.push<EmbeddedWebViewController?>(
      MaterialPageRoute<EmbeddedWebViewController?>(
        builder: (ctx) => _EmbeddedWebViewPage(
          url: sanitized.toString(),
          options: options ?? const BrowserOptions(),
          initialHeaders: headers,
        ),
      ),
    );
    return result;
  }

  Color? _colorFromValue(dynamic value) {
    if (value is int) {
      return Color(value);
    }
    return null;
  }
}

class _FallbackBrowser extends ChromeSafariBrowser {}

class _EmbeddedWebViewPage extends StatefulWidget {
  final String url;
  final BrowserOptions options;
  final Map<String, String>? initialHeaders;

  const _EmbeddedWebViewPage({
    super.key,
    required this.url,
    required this.options,
    this.initialHeaders,
  });

  @override
  State<_EmbeddedWebViewPage> createState() => _EmbeddedWebViewPageState();
}

class _EmbeddedWebViewPageState extends State<_EmbeddedWebViewPage> {
  InAppWebViewController? _controller;
  final Map<String, Function(dynamic)> _jsHandlers = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.options.showTitle ? const Text('Browser') : null,
        backgroundColor: widget.options.toolbarColor,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop();
            _eventController.add({'event': 'dismissed', 'url': widget.url});
          },
        ),
      ),
      body: InAppWebView(
        initialUrlRequest:
            URLRequest(url: WebUri(widget.url), headers: widget.initialHeaders),
        onWebViewCreated: (controller) {
          _controller = controller;
          // when webview is ready, return a controller to the caller
          // schedule after frame so push completes
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop(
                  EmbeddedWebViewController._fromController(
                      _controller!, _jsHandlers));
            }
          });
        },
        onLoadStart: (controller, uri) {
          _eventController
              .add({'event': 'pageStarted', 'url': uri?.toString()});
        },
        onLoadStop: (controller, uri) {
          _eventController
              .add({'event': 'pageFinished', 'url': uri?.toString()});
        },
        onConsoleMessage: (controller, consoleMessage) {
          // forward console messages if desired
        },
      ),
    );
  }
}

/// Controller helpers for the embedded webview
class EmbeddedWebViewController {
  InAppWebViewController? _controller;
  final Map<String, Function(dynamic)> _jsHandlers;
  bool _disposed = false;

  /// Whether this controller has been disposed. Calls after dispose will throw.
  bool get isDisposed => _disposed;

  EmbeddedWebViewController._fromController(this._controller, this._jsHandlers);

  /// Returns the underlying `InAppWebViewController` from `flutter_inappwebview`.
  /// This is nullable: when the embedded view is created with that package the
  /// underlying controller is available and can be used to call power APIs
  /// directly. Callers should check for null before invoking package-specific
  /// methods.
  InAppWebViewController? getUnderlyingController() => _controller;

  /// Evaluate JavaScript inside the embedded webview and return the result.
  Future<dynamic> evaluateJavascript(String script) async {
    final c = _controller;
    if (c == null) throw StateError('WebView not ready');
    return c.evaluateJavascript(source: script);
  }

  Future<void> reload() async {
    final c = _controller;
    if (c == null) throw StateError('WebView not ready');
    await c.reload();
  }

  Future<void> goBack() async {
    final c = _controller;
    if (c == null) throw StateError('WebView not ready');
    if (await c.canGoBack()) {
      await c.goBack();
    }
  }

  Future<void> goForward() async {
    final c = _controller;
    if (c == null) throw StateError('WebView not ready');
    if (await c.canGoForward()) {
      await c.goForward();
    }
  }

  Future<void> postMessage(String message) async {
    final c = _controller;
    if (c == null) throw StateError('WebView not ready');
    if (_disposed) throw StateError('WebView controller disposed');
    // best-effort: use evaluateJavascript to post a message to the page
    final safe =
        "(function(){try{window.postMessage(${_jsEscape(message)}, '*');}catch(e){}})();";
    try {
      await c.evaluateJavascript(source: safe);
    } catch (_) {}
  }

  String _jsEscape(String s) {
    // jsonEncode returns a quoted string literal which is safe to inject
    return jsonEncode(s);
  }

  /// Add a JavaScript handler that page JS can call via `window.flutter_inappwebview.callHandler(handlerName, ...args)`
  Future<void> addJavascriptHandler(
      String handlerName, Function(dynamic) handler) async {
    final c = _controller;
    if (c == null) throw StateError('WebView not ready');
    if (_disposed) throw StateError('WebView controller disposed');
    _jsHandlers[handlerName] = handler;
    c.addJavaScriptHandler(
        handlerName: handlerName,
        callback: (args) {
          try {
            handler(args.length == 1 ? args[0] : args);
          } catch (_) {}
        });
  }

  /// Remove a JavaScript handler
  Future<void> removeJavascriptHandler(String handlerName) async {
    _jsHandlers.remove(handlerName);
    final c = _controller;
    if (c == null) return;
    if (_disposed) return;
    // Try native removal first (some versions of flutter_inappwebview expose this).
    try {
      // Use dynamic invocation to avoid hard dependency on API surface.
      final dynamic dyn = c;
      if (dyn != null) {
        await dyn.removeJavaScriptHandler(handlerName: handlerName);
      }
      return;
    } catch (_) {
      // ignore - fallback to JS shim
    }

    // Fallback: flutter_inappwebview doesn't provide a direct remove API for
    // handler. Inject a small runtime shim to override the handler with a
    // no-op so calls from the page will effectively be ignored. This is
    // best-effort and relies on the page invoking via
    // `window.flutter_inappwebview.callHandler`.
    try {
      final shim =
          "(function(){try{if(window.flutter_inappwebview){var h=window.flutter_inappwebview._callHandler;if(h){h['$handlerName']=function(){return null;}}} }catch(e){} })();";
      await c.evaluateJavascript(source: shim);
    } catch (_) {
      // ignore failures - best-effort only
    }
  }

  /// Dispose the controller when the embedded webview is being torn down.
  /// After dispose, further calls will throw [StateError].
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _jsHandlers.clear();
    _controller = null;
  }
}

bool get _isMobilePlatform {
  if (kIsWeb) {
    return false;
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      return true;
    default:
      return false;
  }
}
