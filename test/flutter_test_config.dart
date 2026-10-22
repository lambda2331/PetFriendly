import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/location/city_directory.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  // Existing product fixtures are Russian; locale-specific tests opt in explicitly.
  setUp(
    () => binding.platformDispatcher.localesTestValue = const [Locale('ru')],
  );
  tearDown(binding.platformDispatcher.clearLocalesTestValue);
  await loadWorldCities();
  await testMain();
}
