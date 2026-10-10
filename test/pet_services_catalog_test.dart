import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/features/nearby/city_catalog.dart';
import 'package:petfriendly/features/nearby/city_search.dart';
import 'package:petfriendly/core/time/display_time.dart';

void main() {
  test(
    'Pet services import once with stable source IDs; human clinics/eateries excluded',
    () {
      Map<String, dynamic> venue(int id, Map<String, String> tags) => {
        'type': 'node',
        'id': id,
        'lat': 55.75,
        'lon': 37.6,
        'tags': {'name': 'Место $id', ...tags},
      };
      final shop = venue(1, {'shop': 'pet'});
      final vet = venue(2, {'amenity': 'veterinary'});
      final raw = {
        'elements': [
          shop,
          shop,
          vet,
          venue(3, {'amenity': 'clinic'}),
          venue(4, {'amenity': 'cafe'}),
          venue(5, {'amenity': 'restaurant'}),
          venue(6, {'shop': 'supermarket'}),
        ],
      };
      final result = parseCityOsm(raw, 'Москва');
      expect(result, hasLength(2));
      expect(result.map((p) => p.category), ['Зоомагазин', 'Ветклиника']);
      expect(result.first.icon, Icons.storefront_outlined);
      expect(result.last.icon, Icons.local_hospital_outlined);
      expect(
        result.every((p) => p.rating == null && p.reviewCount == 0),
        isTrue,
      );
      expect(
        result.every((p) => p.petAccess == 'Допуск питомцев не уточнён'),
        isTrue,
      );
      expect(parseCityOsm(raw, 'Москва').first.id, result.first.id);
      expect(automaticPlace('Ветклиника'), isTrue);
      expect(automaticPlace('Кафе'), isFalse);
    },
  );
  test('Russian aliases resolve with correct country and venue timezone', () {
    expect(canonicalCity('Moscow'), 'Москва');
    expect(canonicalCity('СПб'), 'Санкт-Петербург');
    expect(suggestCities('Екатерин').single.country, 'Россия');
    expect(cityGeocodingQuery('Moscow'), 'Москва, Россия');
    expect(cityGeocodingQuery('Гродно'), 'Гродно, Беларусь');
    expect(cityGeocodingQuery('Тверь, Россия'), 'Тверь, Россия');
    expect(cityTimeZone('Москва'), 'Europe/Moscow');
    expect(cityTimeZone('Новосибирск'), 'Asia/Novosibirsk');
    expect(cityTimeZone('Владивосток'), 'Asia/Vladivostok');
    for (final city in launchCities) {
      expect(validTimeZone(city.timeZone), isTrue, reason: city.name);
    }
  });
}
