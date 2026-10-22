import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/location/city_directory.dart';
import 'package:petfriendly/core/time/display_time.dart';
import 'package:petfriendly/features/nearby/location_service.dart';

void main() {
  test(
    'Every bundled runtime city has a unique key, valid zone and public centre',
    () async {
      final keys = <String>{};
      final zones = <String>{};
      final service = LocationService();
      addTearDown(service.dispose);
      for (final city in availableCities) {
        expect(keys.add(city.name), isTrue, reason: city.name);
        expect(city.name.length, lessThanOrEqualTo(120), reason: city.name);
        expect(knownCity(city.name), same(city), reason: city.name);
        expect(city.latitude, inInclusiveRange(-90, 90), reason: city.name);
        expect(city.longitude, inInclusiveRange(-180, 180), reason: city.name);
        zones.add(city.timeZone);
        final point = await service.cityCenter(city.name);
        expect(point.latitude, city.latitude, reason: city.name);
        expect(point.longitude, city.longitude, reason: city.name);
      }
      for (final zone in zones) {
        expect(validTimeZone(zone), isTrue, reason: zone);
      }
      expect(service.lastPosition, isNull);
      expect(keys.length, greaterThanOrEqualTo(34156));
    },
  );

  test('Search reaches at least one known centre in each bundled country', () {
    for (final code in availableCountries) {
      final expected = availableCities.firstWhere((c) => c.isoCountry == code);
      final results = suggestCities(expected.displayName, countryCode: code);
      expect(results.map((c) => c.name), contains(expected.name), reason: code);
      expect(results.every((c) => c.isoCountry == code), isTrue, reason: code);
      for (final lang in ['ru', 'en', 'be', 'pl']) {
        expect(countryName(code, lang), isNot(code), reason: '$code/$lang');
      }
    }
  });

  test(
    'Representative continents and scripts retain country and venue zone',
    () {
      const cases = {
        'PL': 'Warszawa',
        'JP': '東京',
        'CN': '北京',
        'IN': 'Mumbai',
        'AE': 'Dubai',
        'EG': 'القاهرة',
        'ZA': 'Cape Town',
        'US': 'New York',
        'CA': 'Toronto',
        'BR': 'São Paulo',
        'AR': 'Buenos Aires',
        'AU': 'Sydney',
        'NZ': 'Auckland',
        'FJ': 'Suva',
        'CL': 'Santiago',
        'GB': 'London',
        'FR': 'Paris',
        'BY': 'Мінск',
        'RU': 'Москва',
      };
      for (final entry in cases.entries) {
        final matches = suggestCities(entry.value, countryCode: entry.key);
        expect(matches, isNotEmpty, reason: '${entry.key}/${entry.value}');
        expect(
          validTimeZone(matches.first.timeZone),
          isTrue,
          reason: entry.key,
        );
      }
      for (final legacy in launchCities) {
        final resolved = knownCity(legacy.name)!;
        expect(resolved.name, legacy.name);
        expect(resolved.isoCountry, legacy.isoCountry);
        expect(resolved.latitude, isNotNull, reason: legacy.name);
        expect(validTimeZone(resolved.timeZone), isTrue);
      }
      expect(knownCity('Springfield'), isNull);
      expect(cityTimeZone('Small settlement, PL'), isNull);
      expect(
        cityGeocodingQuery('Small settlement, PL'),
        'Small settlement, PL',
      );
    },
  );
}
