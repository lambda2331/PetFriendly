import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/nearby/city_sheet.dart';

Future<void> openCitySheet(
  WidgetTester tester,
  List<String> selected, {
  VoidCallback? onLocate,
  double scale = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(Brightness.light),
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: Scaffold(
            body: TextButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) => MediaQuery(
                    data: MediaQuery.of(
                      ctx,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: CitySheet(
                      city: 'Минск',
                      onSelected: (city) {
                        selected.add(city);
                        Navigator.pop(ctx);
                      },
                      onLocate: () {
                        onLocate?.call();
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                );
              },
              child: const Text('Открыть города'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Открыть города'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Search starts empty and a Belarus alias selects immediately', (
    tester,
  ) async {
    final selected = <String>[];
    await openCitySheet(tester, selected);
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('city-input')))
          .controller!
          .text,
      isEmpty,
    );
    expect(find.byKey(const Key('city-current')), findsOneWidget);
    expect(find.text('Выбрать город'), findsNothing);
    await tester.enterText(find.byKey(const Key('city-input')), 'Hrodna');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('city-custom')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('city-suggestion-Гродно')));
    await tester.pumpAndSettle();
    expect(selected, ['Гродно']);
    expect(find.byType(CitySheet), findsNothing);
  });

  testWidgets(
    'Russian aliases retain country and select without confirmation',
    (tester) async {
      final selected = <String>[];
      await openCitySheet(tester, selected);
      await tester.enterText(find.byKey(const Key('city-input')), 'Moscow');
      await tester.pumpAndSettle();
      expect(find.text('Россия'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('city-suggestion-Москва')));
      await tester.pumpAndSettle();
      expect(selected, ['Москва']);
    },
  );

  testWidgets(
    'Search submission does not change city; custom row selects arbitrary city',
    (tester) async {
      final selected = <String>[];
      await openCitySheet(tester, selected);
      await tester.enterText(
        find.byKey(const Key('city-input')),
        '  Новый Тестовый Город  ',
      );
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();
      expect(selected, isEmpty);
      expect(find.byType(CitySheet), findsOneWidget);
      await tester.tap(find.byKey(const Key('city-custom')));
      await tester.pumpAndSettle();
      expect(selected, ['Новый Тестовый Город']);
      expect(find.byType(CitySheet), findsNothing);
    },
  );

  testWidgets(
    'Nearby switch calls location action without changing manual city first',
    (tester) async {
      final selected = <String>[];
      var nearby = 0;
      await openCitySheet(tester, selected, onLocate: () => nearby++);
      await tester.ensureVisible(find.byKey(const Key('city-nearby')));
      await tester.tap(find.byKey(const Key('city-nearby')));
      await tester.pumpAndSettle();
      expect(nearby, 1);
      expect(selected, isEmpty);
      expect(find.byType(CitySheet), findsNothing);
    },
  );

  testWidgets(
    'Long city row stays readable and tappable at 320 with enlarged text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final selected = <String>[];
      await openCitySheet(tester, selected, scale: 2);
      await tester.enterText(
        find.byKey(const Key('city-input')),
        'Petropavlovsk-Kamchatsky',
      );
      await tester.pumpAndSettle();
      final row = find.byKey(
        const ValueKey('city-suggestion-Петропавловск-Камчатский'),
      );
      await tester.ensureVisible(row);
      expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
      await tester.tap(row);
      await tester.pumpAndSettle();
      expect(selected, ['Петропавловск-Камчатский']);
    },
  );
}
