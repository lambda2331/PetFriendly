import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petfriendly/main.dart' as app;
import 'package:petfriendly/core/backend/backend.dart';
import 'package:petfriendly/features/nearby/place_row.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Local email login, own pets and server-backed editing', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'language': 'ru',
      'locationPrompted': 'yes',
      'manualCity': 'true',
      'city': 'Минск',
    });
    await secureStorage.delete(key: SecureSessionStorage.key);
    await app.main();
    await tester.pumpAndSettle();
    const email = String.fromEnvironment('TEST_EMAIL');
    const password = String.fromEnvironment('TEST_PASSWORD');
    expect(email.isNotEmpty && password.isNotEmpty, isTrue);
    await tester.enterText(find.byType(TextFormField).at(0), email);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.tap(find.text('Войти'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 200),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 30),
    );
    await waitFor(tester, find.byKey(const Key('nearby-places-list')));
    expect(find.byKey(const Key('nearby-places-list')), findsOneWidget);
    await tester.tap(find.byKey(const Key('nearby-places-list')));
    await tester.pumpAndSettle();
    for (
      var attempt = 0;
      attempt < 150 && find.byType(PlaceRow).evaluate().isEmpty;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    expect(find.byType(PlaceRow), findsWidgets);
    await tester.enterText(
      find.byKey(const Key('places-search')),
      'Александровский',
    );
    await tester.pump(const Duration(milliseconds: 400));
    for (
      var attempt = 0;
      attempt < 100 && find.byType(PlaceRow).evaluate().length != 1;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(PlaceRow), findsOneWidget);
    expect(find.text('Александровский сквер'), findsWidgets);
    await tester.tap(find.byType(BackButton).hitTestable().last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-4')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byTooltip('Добавить питомца').hitTestable(),
      150,
      scrollable: find.byType(Scrollable).hitTestable().last,
    );
    await tester.tap(find.byTooltip('Добавить питомца'));
    await tester.pumpAndSettle();
    final petName = 'Малыш ${DateTime.now().millisecondsSinceEpoch}';
    await waitFor(tester, find.byKey(const ValueKey('field.name')));
    await tester.enterText(find.byKey(const ValueKey('field.name')), petName);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('field.age')),
      100,
      scrollable: find.byType(Scrollable).hitTestable().last,
    );
    await tester.enterText(find.byKey(const ValueKey('field.age')), '2');
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Сохранить').hitTestable(),
      150,
      scrollable: find.byType(Scrollable).hitTestable().last,
    );
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 200),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 30),
    );
    for (
      var attempt = 0;
      attempt < 100 &&
          find.byKey(const ValueKey('field.name')).evaluate().isNotEmpty;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byKey(const ValueKey('field.name')), findsNothing);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text(petName).hitTestable(),
      150,
      scrollable: find.byType(Scrollable).hitTestable().last,
    );
    expect(find.text(petName), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> waitFor(
  WidgetTester tester,
  Finder finder, {
  bool optional = false,
}) async {
  final end = DateTime.now().add(Duration(seconds: optional ? 3 : 30));
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  if (!optional) expect(finder, findsWidgets);
}
