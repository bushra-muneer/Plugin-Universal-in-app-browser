import 'package:flutter/material.dart';
import 'package:plugin_universal_in_app_browser/plugin_universal_in_app_browser.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UniversalInAppBrowserExampleApp());
}

class UniversalInAppBrowserExampleApp extends StatelessWidget {
  const UniversalInAppBrowserExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Universal In-App Browser',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const BrowserDemoScreen(),
    );
  }
}

class BrowserDemoScreen extends StatefulWidget {
  const BrowserDemoScreen({super.key});

  @override
  State<BrowserDemoScreen> createState() => _BrowserDemoScreenState();
}

class _BrowserDemoScreenState extends State<BrowserDemoScreen> {
  final UniversalInAppBrowser _browser = UniversalInAppBrowser();
  bool _isOpening = false;
  EmbeddedWebViewController? _embeddedController;
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    // listen to plugin/browser events
    browserEvents.listen((event) {
      setState(() {
        _logs.insert(0, event.toString());
      });
    });
  }

  Future<void> _openDocs() async {
    setState(() => _isOpening = true);

    try {
      await _browser.openUrl(
        'https://flutter.dev',
        options: const BrowserOptions(
          showTitle: true,
          toolbarColor: Color(0xFF0A0A0A),
          headers: {'User-Agent': 'UniversalInAppBrowser/0.1'},
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('Failed to open browser: $error\n$stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open browser: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isOpening = false);
      }
    }
  }

  Future<void> _openEmbedded() async {
    setState(() => _isOpening = true);
    try {
      final controller = await _browser.openEmbedded(
        context,
        'about:blank', // we'll load a small data URL
        options: const BrowserOptions(
          showTitle: true,
          toolbarColor: Color(0xFF0A0A0A),
        ),
      );

      _embeddedController = controller;

      if (_embeddedController != null) {
        // register a JS handler
        await _embeddedController!.addJavascriptHandler('demo', (args) {
          setState(() {
            _logs.insert(0, 'handler called: $args');
          });
        });

        // inject a small interactive page that calls the handler and listens for
        // postMessage events from Flutter. When it receives a message it will
        // call the 'demo' handler back with the received data.
        const html = r'''
          <html>
            <body>
              <div id="log">no messages yet</div>
              <button id="callBtn">Call Flutter Handler</button>
              <script>
                document.getElementById('callBtn').addEventListener('click', function(){
                  if(window.flutter_inappwebview && window.flutter_inappwebview.callHandler){
                    window.flutter_inappwebview.callHandler('demo', {msg: 'manual call from page'});
                  }
                });

                window.addEventListener('message', function(e){
                  try{
                    document.getElementById('log').innerText = JSON.stringify(e.data);
                    if(window.flutter_inappwebview && window.flutter_inappwebview.callHandler){
                      window.flutter_inappwebview.callHandler('demo', {fromMessage: e.data});
                    }
                  }catch(_){ }
                }, false);

                // call once on load to exercise the handler
                if(window.flutter_inappwebview && window.flutter_inappwebview.callHandler){
                  window.flutter_inappwebview.callHandler('demo', {msg: 'hello from page on load'});
                }
              </script>
            </body>
          </html>
  ''';

        // Avoid navigating the top frame to a data: URL (some WebView builds
        // disallow top-frame data navigation and it can trigger renderer
        // instability on certain emulator images). Instead, write the HTML
        // into the document via document.open/document.write/document.close.
        final escaped = html.replaceAll("'", "\\'").replaceAll('\n', '\\n');
        final inject =
            "(function(){document.open();document.write('$escaped');document.close();})();";
        await _embeddedController!.evaluateJavascript(inject);
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to open embedded: $error\n$stackTrace');
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  Future<void> _evalJsInEmbedded() async {
    if (_embeddedController == null) return;
    try {
      final res = await _embeddedController!.evaluateJavascript(
          '(function(){return document.title||\'embedded\';})()');
      setState(() => _logs.insert(0, 'eval result: $res'));
    } catch (e) {
      setState(() => _logs.insert(0, 'eval error: $e'));
    }
  }

  Future<void> _postMessageToEmbedded() async {
    if (_embeddedController == null) return;
    try {
      await _embeddedController!.postMessage('hello from flutter');
      setState(() => _logs.insert(0, 'postMessage sent'));
    } catch (e) {
      setState(() => _logs.insert(0, 'postMessage error: $e'));
    }
  }

  Future<void> _removeDemoHandler() async {
    if (_embeddedController == null) return;
    try {
      await _embeddedController!.removeJavascriptHandler('demo');
      setState(() => _logs.insert(0, 'removed handler demo'));
    } catch (e) {
      setState(() => _logs.insert(0, 'remove handler error: $e'));
    }
  }

  void _disposeEmbedded() {
    try {
      _embeddedController?.dispose();
    } catch (_) {}
    setState(() {
      _embeddedController = null;
      _logs.insert(0, 'embedded disposed');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Universal In-App Browser'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tap the button to open Flutter.dev inside the universal in-app browser.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              if (_embeddedController != null) ...[
                // Use a Wrap so buttons flow to additional lines on narrow screens
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonal(
                      onPressed: _evalJsInEmbedded,
                      child: const Text('Eval JS'),
                    ),
                    FilledButton.tonal(
                      onPressed: _postMessageToEmbedded,
                      child: const Text('Post Message'),
                    ),
                    FilledButton.tonal(
                      onPressed: _removeDemoHandler,
                      child: const Text('Remove Handler'),
                    ),
                    FilledButton.tonal(
                      onPressed: () async {
                        if (_embeddedController == null) return;
                        final underlying =
                            _embeddedController!.getUnderlyingController();
                        if (underlying == null) {
                          setState(() => _logs.insert(
                              0, 'Underlying controller not available'));
                          return;
                        }
                        try {
                          final cur = await underlying.getUrl();
                          setState(() => _logs.insert(
                              0, 'underlying.getUrl(): ${cur?.toString()}'));
                          await underlying.reload();
                          setState(() =>
                              _logs.insert(0, 'underlying.reload() called'));
                        } catch (e) {
                          setState(() =>
                              _logs.insert(0, 'underlying call error: $e'));
                        }
                      },
                      child: const Text('Use underlying controller'),
                    ),
                    FilledButton.tonal(
                      onPressed: _disposeEmbedded,
                      child: const Text('Dispose'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              FilledButton(
                onPressed: _isOpening ? null : _openDocs,
                child: _isOpening
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Open Flutter Docs'),
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: _isOpening ? null : _openEmbedded,
                child: const Text('Open Embedded WebView'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 160,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Event logs (latest first):'),
                        const SizedBox(height: 6),
                        Expanded(
                          child: ListView.builder(
                            itemCount: _logs.length,
                            itemBuilder: (context, index) => Text(_logs[index]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
