import 'dart:convert';
import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    final output =
        Platform.environment['PF_AUDIT_OUTPUT'] ??
        'docs/screenshots/simulator-audit-20261016';
    final device = name.startsWith('ipad') ? 'ipad' : 'iphone';
    final file = File('$output/$device/$name.png');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes);
    return true;
  },
  responseDataCallback: (data) async {
    final logs =
        Platform.environment['PF_AUDIT_LOGS'] ??
        'tooling/.logs/simulator-audit-20261016';
    final file = File(
      '$logs/metrics-${DateTime.now().millisecondsSinceEpoch}.json',
    );
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(data));
  },
);
