import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/nearby/places_list_screen.dart';
import 'package:petfriendly/features/nearby/place_repository.dart';
import 'package:petfriendly/features/nearby/place_contributions.dart';
import 'package:petfriendly/features/nearby/place_filters.dart';
import 'widget_test.dart' show MemoryPreferences;

void main() {
  testWidgets('Walking calendar uses Russian labels and Monday first', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [preferencesProvider.overrideWithValue(MemoryPreferences())],
        child: const PetFriendlyApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Попросить о выгуле'));
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('walking-date-trigger'));
    await tester.scrollUntilVisible(
      field,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(field);
    await tester.pumpAndSettle();
    final ctx = tester.element(find.byType(CalendarDatePicker));
    expect(MaterialLocalizations.of(ctx).firstDayOfWeekIndex, 1);
    expect(find.text('Готово'), findsOneWidget);
    expect(find.text('Select date'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Places load additional batches and reset pagination after search',
    (tester) async {
      final places = List.generate(
        120,
        (i) => Place(
          'p$i',
          'Place ${i.toString().padLeft(3, '0')}',
          'Парк',
          'Минск',
          null,
          0,
          '',
          'Допуск питомцев не уточнён',
          Icons.park_outlined,
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(MemoryPreferences()),
            placesProvider.overrideWithValue(OsmPlaceRepository(places)),
          ],
          child: MaterialApp(
            theme: studioTheme(Brightness.light),
            home: const PlacesListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      int count() =>
          (tester
                      .widget<ListView>(
                        find.byKey(const Key('places-paged-list')),
                      )
                      .childrenDelegate
                  as SliverChildBuilderDelegate)
              .childCount!;
      expect(count(), 41);
      await tester.drag(
        find.byKey(const Key('places-paged-list')),
        const Offset(0, -4000),
      );
      await tester.pumpAndSettle();
      expect(count(), greaterThan(41));
      expect(count(), lessThanOrEqualTo(121));
      await tester.enterText(
        find.byKey(const Key('places-search')),
        'Place 003',
      );
      await tester.pumpAndSettle();
      expect(count(), 2);
      expect(
        find.descendant(
          of: find.byKey(const Key('places-paged-list')),
          matching: find.text('Place 003'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'Own demo proposal appears on the city map without invented pet access or ratings',
    () async {
      final container = ProviderContainer(
        overrides: [preferencesProvider.overrideWithValue(MemoryPreferences())],
      );
      addTearDown(container.dispose);
      await container.read(placeContributionsProvider.future);
      final id = newPlaceId();
      final controller = container.read(placeContributionsProvider.notifier);
      await controller.submit(
        id: id,
        name: 'Новый парк',
        category: 'Парк',
        city: 'Минск',
        description: 'Публичное место',
        latitude: 53.9,
        longitude: 27.56,
      );
      await controller.submit(
        id: id,
        name: 'Новый парк',
        category: 'Парк',
        city: 'Минск',
        description: 'Публичное место',
        latitude: 53.9,
        longitude: 27.56,
      );
      final own = container
          .read(filteredPlacesProvider)
          .where((p) => p.id == id)
          .single;
      expect(own.pending, isTrue);
      expect(own.petAccess, 'Допуск питомцев не уточнён');
      expect(own.rating, isNull);
    },
  );
}
