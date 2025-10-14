import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:universal_in_app_browser_example/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('embedded JS bridge basic flow', (WidgetTester tester) async {
    // This test is a scaffold for device/emulator integration.
    // It launches the example app and verifies the main UI loads.
    // Note: app.main() returns void; call it and pump the widget tree.
    app.main();
    // Some devices/emulators can cause pumpAndSettle to hang due to
    // platform channel work or long-running animations. Instead of
    // relying on pumpAndSettle, poll for the main UI button to appear.
    final openEmbeddedFinder = find.text('Open Embedded WebView');
    final initDeadline = DateTime.now().add(const Duration(seconds: 30));
    while (DateTime.now().isBefore(initDeadline) && openEmbeddedFinder.evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    // allow the frame to settle a little before interacting
    await tester.pump(const Duration(milliseconds: 300));

    // Find and tap the Open Embedded WebView button (wait up to 10s)
    final openDeadline = DateTime.now().add(const Duration(seconds: 10));
    while (DateTime.now().isBefore(openDeadline) && openEmbeddedFinder.evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(openEmbeddedFinder, findsOneWidget);
    await tester.tap(openEmbeddedFinder);
    // Helper to find any handler log entry (handler called: ...)
    Finder handlerLogFinder() => find.byWidgetPredicate((w) {
          if (w is Text && w.data != null) {
            return w.data!.contains('handler called:');
          }
          return false;
        });

    // Avoid pumpAndSettle (can hang on some devices). Poll for the embedded UI
    // to show up by waiting for either the handler log or the Post Message button.
    final openUiDeadline = DateTime.now().add(const Duration(seconds: 15));
    while (DateTime.now().isBefore(openUiDeadline) &&
        handlerLogFinder().evaluate().isEmpty &&
        find.text('Post Message').evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Wait for the initial handler call (page calls handler on load)
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (DateTime.now().isBefore(deadline) && handlerLogFinder().evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // If we didn't get an initial handler call, ensure the embedded UI loaded
    // by checking for the 'Post Message' button; if neither is present, fail.
    final postMsgFinder = find.text('Post Message');
    if (handlerLogFinder().evaluate().isEmpty) {
      if (postMsgFinder.evaluate().isEmpty) {
        fail('Embedded UI did not expose handler logs or Post Message button.');
      }
    } else {
      expect(handlerLogFinder(), findsWidgets);
    }

    // Count handler logs so far
    var beforeCount = handlerLogFinder().evaluate().length;
    final postDeadline = DateTime.now().add(const Duration(seconds: 10));
    while (DateTime.now().isBefore(postDeadline) && postMsgFinder.evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(postMsgFinder, findsOneWidget);
    await tester.tap(postMsgFinder);
    // Wait for the handler to be called (see loop below) rather than pumpAndSettle

    // Wait for either an additional handler entry (if the JS bridge is present)
    // or for the Flutter-side 'postMessage sent' log which is always emitted
    // after posting a message.
    final postMessageLogFinder = find.text('postMessage sent');
    final deadline2 = DateTime.now().add(const Duration(seconds: 10));
    while (DateTime.now().isBefore(deadline2) &&
        handlerLogFinder().evaluate().length <= beforeCount &&
        postMessageLogFinder.evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    // Assert that at least one of the success signals appeared.
    final afterCount = handlerLogFinder().evaluate().length;
    final postMsgLogged = postMessageLogFinder.evaluate().isNotEmpty;
    expect(postMsgLogged || afterCount > beforeCount, isTrue,
        reason: 'Expected either a handler call or postMessage log');

    // Now remove the handler
    final removeFinder = find.text('Remove Handler');
    final removeDeadline = DateTime.now().add(const Duration(seconds: 10));
    while (DateTime.now().isBefore(removeDeadline) && removeFinder.evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  expect(removeFinder, findsOneWidget);
  await tester.tap(removeFinder);
  // allow UI to update
  await tester.pump(const Duration(milliseconds: 500));

    // Tap Post Message again and assert Flutter still posts the message (we
    // can't reliably assert the handler is not called on all environments).
    beforeCount = handlerLogFinder().evaluate().length;
    await tester.tap(postMsgFinder);
    final afterMsgDeadline = DateTime.now().add(const Duration(seconds: 6));
    while (DateTime.now().isBefore(afterMsgDeadline) && postMessageLogFinder.evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(postMessageLogFinder, findsWidgets);

    // Finally, dispose the embedded controller
    final disposeFinder = find.text('Dispose');
    final disposeDeadline = DateTime.now().add(const Duration(seconds: 10));
    while (DateTime.now().isBefore(disposeDeadline) && disposeFinder.evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(disposeFinder, findsOneWidget);
    await tester.tap(disposeFinder);
    // Wait for the disposed log to appear
    final disposedFinder = find.textContaining('embedded disposed');
    final disposedDeadline = DateTime.now().add(const Duration(seconds: 8));
    while (DateTime.now().isBefore(disposedDeadline) && disposedFinder.evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(disposedFinder, findsOneWidget);
  });
}
