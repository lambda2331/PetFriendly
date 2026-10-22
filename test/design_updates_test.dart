import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/community/people_screen.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'widget_test.dart' show MemoryPreferences;

void main() {
  testWidgets('Search offers recovery and retains each segment query', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: studioTheme(Brightness.light),
          home: const Scaffold(body: PeopleScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'нет-такого-питомца');
    await tester.pump();
    expect(find.text('Никого не нашли'), findsOneWidget);
    expect(find.byTooltip('Очистить поиск'), findsOneWidget);
    await tester.tap(find.text('Сообщества'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'соседи');
    await tester.pump();
    expect(find.text('Соседи с питомцами'), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('people-community-segment')),
        matching: find.text('Люди'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'нет-такого-питомца',
    );
    await tester.tap(find.byTooltip('Очистить поиск'));
    await tester.pump();
    expect(find.text('Анна'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Large text keeps Nearby greeting and places controls usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [preferencesProvider.overrideWithValue(MemoryPreferences())],
        child: const PetFriendlyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Хороший день для прогулки.'), findsOneWidget);
    expect(find.byTooltip('На весь экран'), findsNothing);
    expect(find.text('Карта пока недоступна'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('nearby-places-list')));
    await tester.tap(find.byKey(const Key('nearby-places-list')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('place-more-filters')));
    await tester.pumpAndSettle();
    expect(find.text('Категория'), findsOneWidget);
    await tester.ensureVisible(find.text('Показать места'));
    await tester.tap(find.text('Показать места'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  test('Demo helper replies reject an unrelated helper', () async {
    final repository = DemoCommunityRepository();
    repository.data['walk_reviews']!.add({
      'id': 'review',
      'helper_id': demoSasha,
      'published': true,
    });
    expect(
      () => repository.command('reply_walk_review', {
        'review_in': 'review',
        'body_in': 'Спасибо',
      }),
      throwsStateError,
    );
  });
}
