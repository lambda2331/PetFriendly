import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/features/nearby/place_filters.dart';
import 'package:petfriendly/features/nearby/place_repository.dart';
import 'package:petfriendly/features/nearby/city_catalog.dart';

void main() {
  test(
    'Catalog evidence survives duplicate contributions; pending places remain',
    () {
      final catalog = catalogPlace({
        'id': 'shared',
        'name': 'Парк',
        'category': 'Парк',
        'latitude': 53.9,
        'longitude': 27.56,
        'pet_access': 'yes',
        'pet_access_evidence': {
          'confirmation': 'community',
          'policy': 'on_leash',
          'basis': 'Public venue sign',
          'observed_at': '2026-01-01T10:00:00Z',
          'verified_at': '2026-01-01T11:00:00Z',
        },
      }, 'Минск');
      const preview = Place(
        'shared',
        'Preview',
        'Парк',
        '',
        null,
        0,
        '',
        'unknown',
        Icons.park,
      );
      const pending = Place(
        'pending',
        'New',
        'Парк',
        '',
        null,
        0,
        '',
        'unknown',
        Icons.park,
        pending: true,
      );
      const other = Place(
        'other',
        'Other city',
        'Парк',
        '',
        null,
        0,
        '',
        'unknown',
        Icons.park,
        city: 'Москва',
      );
      final merged = mergeCityPlaces(
        [catalog],
        [preview, pending, other],
        'Минск',
      );
      expect(merged, hasLength(2));
      expect(merged.first, same(catalog));
      expect(merged.first.accessEvidence, isNotNull);
      expect(merged.last.pending, isTrue);
    },
  );
  final places = [
    const Place(
      'park',
      'Зелёный парк',
      'Парк',
      '',
      null,
      0,
      '',
      'Допуск питомцев не уточнён',
      Icons.park,
    ),
    const Place(
      'cafe',
      'Лапы и кофе',
      'Кафе',
      '',
      null,
      0,
      '',
      'Собаки разрешены · отметка OSM',
      Icons.local_cafe,
    ),
    const Place(
      'no',
      'Ресторан',
      'Ресторан',
      '',
      null,
      0,
      '',
      'Собаки запрещены · отметка OSM',
      Icons.restaurant,
    ),
  ];
  test(
    'Search, category, pet access and favorites combine without treating unknown as allowed',
    () {
      expect(
        filterPlaces(
          places,
          const PlaceFilter(query: 'ЗЕЛЕНЫЙ', category: 'Парк'),
          {},
          null,
        ).single.id,
        'park',
      );
      expect(
        filterPlaces(
          places,
          const PlaceFilter(access: AccessFilter.taggedAllowed),
          {},
          null,
        ).map((p) => p.id),
        ['cafe'],
      );
      expect(
        filterPlaces(
          places,
          const PlaceFilter(access: AccessFilter.unknown, favoritesOnly: true),
          {'cafe'},
          null,
        ),
        hasLength(1), // An OSM allow tag alone is still unconfirmed.
      );
      expect(
        filterPlaces(places, const PlaceFilter(favoritesOnly: true), {
          'park',
        }, null).single.id,
        'park',
      );
    },
  );
}
