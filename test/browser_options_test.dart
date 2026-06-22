import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_universal_in_app_browser/plugin_universal_in_app_browser.dart';

void main() {
  test('BrowserOptions toChannelPayload serializes toolbarColor and headers',
      () {
    const opts = BrowserOptions(
      showTitle: false,
      toolbarColor: Color(0xFF112233),
      headers: {'X-Test': 'true'},
    );

    final payload = opts.toChannelPayload();

    expect(payload['showTitle'], false);
    expect(payload['headers'], isA<Map<String, String>>());
    expect((payload['headers'] as Map)['X-Test'], 'true');
    // toolbarColor is serialized to ARGB/int
    expect(payload['toolbarColor'], isA<int>());
    expect(payload['toolbarColor'], equals(const Color(0xFF112233).toARGB32()));
  });
}
