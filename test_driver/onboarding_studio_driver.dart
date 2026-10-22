import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    await Directory(
      '/tmp/petfriendly-onboarding-native',
    ).create(recursive: true);
    await File(
      '/tmp/petfriendly-onboarding-native/$name.png',
    ).writeAsBytes(bytes);
    return true;
  },
);
