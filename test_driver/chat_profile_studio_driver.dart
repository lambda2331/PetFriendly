import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() => integrationDriver(
  onScreenshot: (name, bytes, [args]) async {
    await Directory(
      '/tmp/petfriendly-chat-profile-native',
    ).create(recursive: true);
    await File(
      '/tmp/petfriendly-chat-profile-native/$name.png',
    ).writeAsBytes(bytes);
    return true;
  },
);
