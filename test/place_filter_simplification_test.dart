import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/nearby/place_filters.dart';
import 'package:petfriendly/features/nearby/places_list_screen.dart';
import 'widget_test.dart' show MemoryPreferences;

void main() {
  test(
    'Filter count includes nondefault sorting and excludes visible search query',
    () {
      expect(activePlaceFilterCount(const PlaceFilter(query: 'Парк')), 0);
      expect(
        activePlaceFilterCount(
          const PlaceFilter(
            category: 'Парк',
            access: AccessFilter.unknown,
            favoritesOnly: true,
            sort: PlaceSort.nearby,
          ),
        ),
        4,
      );
    },
  );

  testWidgets('Only category is visible; other choices open in filter sheet', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [preferencesProvider.overrideWithValue(MemoryPreferences())],
        child: MaterialApp(
          theme: studioTheme(Brightness.light),
          home: const PlacesListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Категория'), findsOneWidget);
    expect(find.text('С питомцем'), findsNothing);
    expect(find.text('Подборка'), findsNothing);
    await tester.tap(find.byKey(const Key('place-more-filters')));
    await tester.pumpAndSettle();
    expect(find.text('С питомцем'), findsOneWidget);
    expect(find.text('Подборка'), findsOneWidget);
    expect(find.text('Сортировка'), findsOneWidget);
    final panel = tester.getRect(
      find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Material),
          )
          .first,
    );
    final action = tester.getRect(
      find.widgetWithText(FilledButton, 'Показать места'),
    );
    expect(panel.bottom - action.bottom, lessThanOrEqualTo(32));
    await tester.ensureVisible(find.text('Показать места'));
    await tester.tap(find.text('Показать места'));
    await tester.pumpAndSettle();
    expect(find.text('С питомцем'), findsNothing);
  });

  testWidgets(
    'Clearing an active chip preserves query and category with enlarged text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final container = ProviderContainer(
        overrides: [preferencesProvider.overrideWithValue(MemoryPreferences())],
      );
      addTearDown(container.dispose);
      container
          .read(placeFiltersProvider.notifier)
          .update(
            const PlaceFilter(
              query: 'Зелёный',
              category: 'Парк',
              access: AccessFilter.unknown,
            ),
          );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: studioTheme(Brightness.dark),
            home: const MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2)),
              child: PlacesListScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('place-more-filters')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Убрать фильтр допуска'));
      await tester.pumpAndSettle();
      final filter = container.read(placeFiltersProvider);
      expect(filter.access, AccessFilter.all);
      expect(filter.query, 'Зелёный');
      expect(filter.category, 'Парк');
      expect(find.byKey(const Key('place-more-filters')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final brightness in Brightness.values) {
    testWidgets('Filters scroll on short screens at 2x text: $brightness', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(MemoryPreferences()),
          ],
          child: MaterialApp(
            theme: studioTheme(brightness),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const PlacesListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: 'Catalog before opening filters',
      );
      await tester.tap(find.byKey(const Key('place-more-filters')));
      await tester.pumpAndSettle();
      final scrolling = find
          .descendant(
            of: find.byType(BottomSheet),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Показать места'),
        160,
        scrollable: scrolling,
      );
      await tester.tap(find.text('Показать места'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
