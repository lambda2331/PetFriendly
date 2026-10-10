import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:petfriendly/core/backend/backend.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/nearby/city_catalog.dart';
import 'package:petfriendly/features/nearby/location_service.dart';
import 'package:petfriendly/features/nearby/place_filters.dart';
import 'package:petfriendly/features/nearby/place_repository.dart';
import 'widget_test.dart' show MemoryPreferences;

class DelayedCatalog extends CityCatalogService {
  DelayedCatalog() : super(LocationService());
  final calls = <String, Completer<List<Place>>>{};
  @override
  Future<List<Place>> load(String city) =>
      (calls[city] ??= Completer<List<Place>>()).future;
}

void main() {
  test(
    'Busy import serves existing city places through bounded RPC pages',
    () async {
      var pages = 0;
      final client = SupabaseClient(
        'https://fixture.example',
        'fixture-key',
        httpClient: MockClient((request) async {
          final isImport = request.url.path.endsWith('city-catalog');
          if (isImport) {
            return http.Response(
              '{"status":"busy"}',
              202,
              headers: {'content-type': 'application/json'},
            );
          }
          final input = jsonDecode(request.body);
          expect(input['city_in'], 'Минск');
          pages++;
          return http.Response(
            jsonEncode({
              'total': 1,
              'items': [
                {
                  'id': 'seeded',
                  'name': 'Парк',
                  'category': 'Парк',
                  'latitude': 53.9,
                  'longitude': 27.5,
                },
              ],
            }),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [backendProvider.overrideWithValue(client)],
      );
      addTearDown(() async {
        container.dispose();
        await client.dispose();
      });
      final places = await container.read(cityCatalogProvider('Минск').future);
      expect(places.single.id, 'seeded');
      expect(pages, 2); // Availability check, then map page.
    },
  );
  test(
    'Rejected import authentication never falls back to public catalog',
    () async {
      var searches = 0;
      final client = SupabaseClient(
        'https://fixture.example',
        'fixture-key',
        httpClient: MockClient((request) async {
          if (!request.url.path.endsWith('city-catalog')) searches++;
          return http.Response(
            '{"error":"Authentication required"}',
            401,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final container = ProviderContainer(
        retry: (_, _) => null,
        overrides: [backendProvider.overrideWithValue(client)],
      );
      addTearDown(() async {
        container.dispose();
        await client.dispose();
      });
      await expectLater(
        container.read(cityCatalogProvider('Минск').future),
        throwsA(isA<FunctionException>()),
      );
      expect(searches, 0);
    },
  );
  testWidgets('Retry reruns a failed server catalog preparation', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(MemoryPreferences()),
          catalogReadyProvider.overrideWith((ref, city) async {
            if (++attempts == 1) throw StateError('Temporary failure');
          }),
          cityCatalogProvider.overrideWith((ref, city) async {
            await ref.watch(catalogReadyProvider(city).future);
            return <Place>[];
          }),
        ],
        child: const MaterialApp(home: Scaffold(body: CityCatalogStatus())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Места временно недоступны'), findsOneWidget);
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
    expect(find.text('Места временно недоступны'), findsNothing);
  });
  test(
    'Late city response cannot replace the selected city; previous results are reused',
    () async {
      final service = DelayedCatalog();
      final prefs = MemoryPreferences()..values['city'] = 'Warszawa';
      final container = ProviderContainer(
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          cityCatalogServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);
      final listener = container.listen(selectedCityCatalogProvider, (_, _) {});
      addTearDown(listener.close);
      expect(container.read(selectedCityCatalogProvider).isLoading, isTrue);
      await Future<void>.delayed(Duration.zero);
      await container.read(prototypeProvider.notifier).setCity('Vilnius');
      await Future<void>.delayed(Duration.zero);
      service.calls['Vilnius']!.complete([
        const Place(
          'v',
          'Park',
          'Парк',
          'Vilnius',
          null,
          0,
          '',
          'Допуск питомцев не уточнён',
          Icons.park_outlined,
          city: 'Vilnius',
        ),
      ]);
      await container.read(cityCatalogProvider('Vilnius').future);
      expect(container.read(filteredPlacesProvider).single.id, 'v');
      service.calls['Warszawa']!.complete([
        const Place(
          'w',
          'Park',
          'Парк',
          'Warszawa',
          null,
          0,
          '',
          'Допуск питомцев не уточнён',
          Icons.park_outlined,
          city: 'Warszawa',
        ),
      ]);
      await container.read(cityCatalogProvider('Warszawa').future);
      expect(container.read(filteredPlacesProvider).single.id, 'v');
      await container.read(prototypeProvider.notifier).setCity('Warszawa');
      expect(container.read(filteredPlacesProvider).single.id, 'w');
      expect(service.calls.length, 2);
    },
  );
  test(
    'Only parks/dog parks import; duplicate sources collapse; missing dog access stays unknown',
    () {
      final park = {
        'type': 'way',
        'id': 1,
        'center': {'lat': 54.0, 'lon': 25.0},
        'tags': {'leisure': 'park', 'name': 'Park'},
      };
      final result = parseCityOsm({
        'elements': [
          park,
          park,
          {
            'type': 'node',
            'id': 2,
            'lat': 54.0,
            'lon': 25.0,
            'tags': {'amenity': 'cafe', 'name': 'Cafe'},
          },
        ],
      }, 'Vilnius');
      expect(result.length, 1);
      expect(result.single.city, 'Vilnius');
      expect(result.single.petAccess, 'Допуск питомцев не уточнён');
      expect(
        () => parseCityOsm({'remark': 'timed out', 'elements': []}, 'Vilnius'),
        throwsStateError,
      );
    },
  );
}
