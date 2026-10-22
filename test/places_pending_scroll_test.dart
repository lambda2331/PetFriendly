import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petfriendly/core/backend/backend.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/nearby/city_catalog.dart';
import 'package:petfriendly/features/nearby/pet_access_repository.dart';
import 'package:petfriendly/features/nearby/place_contributions.dart';
import 'package:petfriendly/features/nearby/place_filters.dart';
import 'package:petfriendly/features/nearby/place_pages.dart';
import 'package:petfriendly/features/nearby/place_repository.dart';
import 'package:petfriendly/features/nearby/place_row.dart';
import 'package:petfriendly/features/nearby/places_list_screen.dart';
import 'widget_test.dart' show MemoryPreferences;

Place venue(String id, String name, {bool pending = false}) => Place(
  id,
  name,
  'Парк',
  'Минск',
  null,
  0,
  '',
  'unknown',
  Icons.park,
  pending: pending,
);

class TestPages extends PlacePages {
  @override
  Future<PlacePage> build() async {
    final query = ref.watch(placeFiltersProvider).query;
    final places = List.generate(
      40,
      (i) => venue('p$i', 'Б парк $i'),
    ).where((p) => p.name.contains(query)).toList();
    return PlacePage(places, places.length);
  }
}

class TestContributions extends PlaceContributions {
  @override
  Future<List<Place>> build() async => [
    venue('pending', 'А новый парк', pending: true),
  ];
}

void main() {
  testWidgets('Pending place scrolls with catalog and respects search', (
    tester,
  ) async {
    final client = (await tester.runAsync(
      () async => SupabaseClient('https://unused.invalid', 'test-public-key'),
    ))!;
    final container = ProviderContainer(
      overrides: [
        backendProvider.overrideWithValue(client),
        authStateProvider.overrideWith((ref) => Stream.value(null)),
        preferencesProvider.overrideWithValue(MemoryPreferences()),
        communityRepositoryProvider.overrideWithValue(
          DemoCommunityRepository(),
        ),
        placePagesProvider.overrideWith(TestPages.new),
        placeContributionsProvider.overrideWith(TestContributions.new),
        cityCatalogProvider('Минск').overrideWith((ref) async => []),
        petAccessByCityProvider('Минск').overrideWith((ref) async => {}),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: studioTheme(Brightness.light),
          home: const PlacesListScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final list = find.byKey(const Key('places-paged-list'));
    expect(
      find.ancestor(of: find.text('А новый парк'), matching: list),
      findsOneWidget,
    );
    expect(find.text('41 мест'), findsOneWidget);
    await tester.drag(list, const Offset(0, -600));
    await tester.pumpAndSettle();
    expect(find.text('А новый парк').hitTestable(), findsNothing);
    await tester.enterText(find.byKey(const Key('places-search')), 'Б парк');
    await tester.pumpAndSettle();
    expect(find.text('А новый парк'), findsNothing);
    expect(
      tester
          .widgetList<PlaceRow>(find.byType(PlaceRow))
          .any((row) => row.place.pending),
      isFalse,
    );
    await tester.enterText(find.byKey(const Key('places-search')), 'А новый');
    await tester.pumpAndSettle();
    expect(find.text('А новый парк'), findsOneWidget);
    expect(find.text('1 мест'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.runAsync(client.dispose);
  });
}
