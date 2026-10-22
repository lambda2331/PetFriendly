import 'dart:io';
import 'support/native_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petfriendly/main.dart' as app;
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/backend/backend.dart';
import 'package:petfriendly/features/walks/account_mode.dart';

Future<void> settleFor(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 300; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (ready()) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  expect(ready(), isTrue, reason: 'Native/local response deadline');
}

Future<void> login(WidgetTester tester, String email, String password) async {
  await settleFor(
    tester,
    () => find.byType(TextFormField).evaluate().length == 2,
  );
  await tester.enterText(find.byType(TextFormField).at(0), email);
  await tester.enterText(find.byType(TextFormField).at(1), password);
  await tester.tap(find.widgetWithText(FilledButton, 'Войти'));
  await settleFor(tester, () => find.byType(StudioShell).evaluate().isNotEmpty);
  await tester.pumpAndSettle();
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'QA native local login, mode identity, draft isolation and logout',
    (tester) async {
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
        const String.fromEnvironment('TEST_EMAIL'),
        const String.fromEnvironment('TEST_PASSWORD'),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(PetFriendlyApp)),
      );
      final router = container.read(routerProvider);
      final client = container.read(backendProvider)!;
      final accountA = client.auth.currentUser!.id;
      expectNativeBranches(tester, [0, 1, 2, 3, 4]);
      // Product mode remains a server-backed account operation; the removed
      // role badge must not be reintroduced just to drive this regression.
      await container.read(accountModeProvider.notifier).switchMode('helper');
      await settleFor(
        tester,
        () => container.read(accountModeProvider).value?.mode == 'helper',
      );
      await tester.pumpAndSettle();
      expectNativeBranches(tester, [5, 6, 3, 4]);
      expect(client.auth.currentUser!.id, accountA);
      router.push('/edit/profile');
      await tester.pumpAndSettle();
      await settleFor(
        tester,
        () => find
            .byKey(const ValueKey('field.display_name'))
            .evaluate()
            .isNotEmpty,
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('field.display_name')),
            )
            .controller!
            .text,
        'QA Person A',
      );
      await tester.enterText(
        find.byKey(const ValueKey('field.display_name')),
        'QA Private Draft A',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton).hitTestable().last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Оставить черновик'));
      await tester.pumpAndSettle();
      router.push('/settings');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Выйти из аккаунта'),
        200,
        scrollable: find.byType(Scrollable).hitTestable().last,
      );
      await tester.tap(find.text('Выйти из аккаунта'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Выйти из аккаунта'));
      await settleFor(tester, () => client.auth.currentSession == null);
      await tester.pumpAndSettle();
      await login(
        tester,
        const String.fromEnvironment('TEST_EMAIL_B'),
        const String.fromEnvironment('TEST_PASSWORD_B'),
      );
      expect(client.auth.currentUser!.id, isNot(accountA));
      expectNativeBranches(tester, [5, 6, 3, 4]);
      router.push('/edit/profile');
      await tester.pumpAndSettle();
      await settleFor(
        tester,
        () => find
            .byKey(const ValueKey('field.display_name'))
            .evaluate()
            .isNotEmpty,
      );
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('field.display_name')),
            )
            .controller!
            .text,
        'QA Person B',
      );
      expect(find.text('QA Private Draft A'), findsNothing);
      if (Platform.isAndroid) {
        await binding.convertFlutterSurfaceToImage();
        await tester.pumpAndSettle();
      }
      await binding.takeScreenshot('qa-local-account-isolation');
      await tester.tap(find.byType(BackButton).hitTestable().last);
      await tester.pumpAndSettle();
      router.push('/helper/onboarding');
      await tester.pumpAndSettle();
      await settleFor(
        tester,
        () => find
            .byKey(const Key('helper-onboarding-action'))
            .evaluate()
            .isNotEmpty,
      );
      expect(tester.takeException(), isNull);
      await client.auth.signOut();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
