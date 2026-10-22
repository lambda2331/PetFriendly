import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petfriendly/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('City autocomplete selects canonical city on device', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'language': 'ru',
      'locationPrompted': 'yes',
      'manualCity': 'true',
      'city': 'Минск',
      'theme': 'light',
    });
    await app.main();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('choose-city')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('city-input')), 'hrod');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('city-suggestion-Гродно')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('choose-city')),
        matching: find.text('Гродно'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('choose-city')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('city-input')), 'Гр');
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('city-suggestion-Гродно')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
