import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petfriendly/main.dart' as app;
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/backend/backend.dart';
import 'account_logout_flow_test.dart' show login, settleFor;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('QA helper logout must not emit unhandled authorization errors', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'language': 'ru',
      'theme': 'light',
      'locationPrompted': 'yes',
      'manualCity': 'true',
      'city': 'Минск',
    });
    await secureStorage.delete(key: SecureSessionStorage.key);
    await app.main();
    await tester.pumpAndSettle();
    await login(
      tester,
      const String.fromEnvironment('TEST_EMAIL_B'),
      const String.fromEnvironment('TEST_PASSWORD_B'),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PetFriendlyApp)),
    );
    final router = container.read(routerProvider);
    final client = container.read(backendProvider)!;

    await tester.pump(const Duration(seconds: 2));
    router.push('/settings');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Выйти из аккаунта'),
      200,
      scrollable: find.byType(Scrollable).hitTestable().last,
    );
    await binding.takeScreenshot('qa-helper-before-logout');

    await tester.tap(find.text('Выйти из аккаунта'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Выйти из аккаунта'));
    await settleFor(tester, () => client.auth.currentSession == null);
    await tester.pumpAndSettle();

    await binding.takeScreenshot('qa-helper-after-logout');
    expect(router.state.uri.path, '/login');
    expect(
      tester.takeException(),
      isNull,
      reason: 'Hidden Requests must stop authorized queries after logout',
    );
  }, timeout: const Timeout(Duration(minutes: 3)));
}
