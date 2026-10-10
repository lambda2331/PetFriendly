import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const crashReportingPreference = 'crash_reporting_opt_in';
final diagnosticsPreferencesProvider = Provider<SharedPreferences?>(
  (ref) => null,
);
final crashReportingProvider = NotifierProvider<CrashReportingController, bool>(
  CrashReportingController.new,
);

// Exception messages can contain tokens, input or URLs. Send only their type.
String sanitizedErrorType(Object error) =>
    error.runtimeType.toString().replaceAll(RegExp(r'[^A-Za-z0-9_]'), '');

class CrashReportingController extends Notifier<bool> {
  @override
  bool build() =>
      ref
          .read(diagnosticsPreferencesProvider)
          ?.getBool(crashReportingPreference) ??
      false;

  Future<void> setEnabled(bool value) async {
    if (Firebase.apps.isEmpty) return;
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(value);
    if (!value) await FirebaseCrashlytics.instance.deleteUnsentReports();
    await ref
        .read(diagnosticsPreferencesProvider)
        ?.setBool(crashReportingPreference, value);
    state = value;
  }
}

Future<void> initializeCrashReporting(SharedPreferences preferences) async {
  if (Firebase.apps.isEmpty) return;
  final enabled = preferences.getBool(crashReportingPreference) ?? false;
  final sdk = FirebaseCrashlytics.instance;
  await sdk.setCrashlyticsCollectionEnabled(enabled);
  if (!enabled) await sdk.deleteUnsentReports();
  Future<void> report(Object error, StackTrace stack) async {
    if (!sdk.isCrashlyticsCollectionEnabled) return;
    try {
      await sdk.recordError(
        'Unhandled ${sanitizedErrorType(error)}',
        stack,
        fatal: true,
      );
    } catch (_) {
      /* Diagnostics must never interrupt application flows. */
    }
  }

  FlutterError.onError = (details) {
    report(details.exception, details.stack ?? StackTrace.empty);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    report(error, stack);
    return true;
  };
}
