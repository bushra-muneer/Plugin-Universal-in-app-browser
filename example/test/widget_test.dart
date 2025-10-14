import 'package:flutter_test/flutter_test.dart';
import 'package:universal_in_app_browser_example/main.dart' as app;

void main() {
  testWidgets('example builds and shows buttons', (WidgetTester tester) async {
    await tester.pumpWidget(const app.UniversalInAppBrowserExampleApp());
    await tester.pumpAndSettle();

    expect(find.text('Open Flutter Docs'), findsOneWidget);
    expect(find.text('Open Embedded WebView'), findsOneWidget);
  });
}
