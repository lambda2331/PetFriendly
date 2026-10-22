import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/location/city_directory.dart';
import 'package:petfriendly/core/time/display_time.dart';
import 'package:petfriendly/features/nearby/location_service.dart';
import 'package:petfriendly/features/nearby/city_sheet.dart';
import 'package:petfriendly/l10n/localization.dart';

void main() {
  test(
    'Worldwide cities include countries, accent-insensitive aliases and valid public centres',
    () {
      expect(availableCities.length, greaterThan(34000));
      expect(availableCountries.length, greaterThan(240));
      for (final code in ['PL', 'FR', 'US', 'JP', 'BY', 'RU']) {
        expect(availableCountries, contains(code));
      }
      final warsaw = suggestCities('Warszawa', countryCode: 'PL').first;
      expect(warsaw.isoCountry, 'PL');
      expect(warsaw.timeZone, 'Europe/Warsaw');
      expect(cityTimeZone(warsaw.name), 'Europe/Warsaw');
      final lodz = suggestCities('Lodz', countryCode: 'PL').first;
      expect(lodz.displayName, 'Łódź');
      expect(countryName('PL', 'be'), 'Польшча');
      expect(countryName('BY', 'pl'), 'Białoruś');
      expect(
        suggestCities('Польша').every((c) => c.isoCountry == 'PL'),
        isTrue,
      );
    },
  );
  test('Homonyms retain separate canonical keys, countries and time zones', () {
    final french = suggestCities('Brest', countryCode: 'FR').first;
    final belarus = suggestCities('Brest', countryCode: 'BY').first;
    expect(belarus.name, 'Брест');
    expect(french.name, isNot(belarus.name));
    expect(french.timeZone, 'Europe/Paris');
    expect(belarus.timeZone, 'Europe/Minsk');
    final springfields = suggestCities(
      'Springfield',
      countryCode: 'US',
      limit: 40,
    ).where((c) => c.displayName == 'Springfield').toList();
    expect(springfields.length, greaterThan(2));
    expect(springfields.map((c) => c.name).toSet().length, springfields.length);
    expect(knownCity('Springfield'), isNull);
    expect(
      detectedCity('Brest', 'FR', french.latitude!, french.longitude!),
      french.name,
    );
    expect(
      detectedCity('Brest', 'BY', belarus.latitude!, belarus.longitude!),
      belarus.name,
    );
    expect(canonicalCity('Moscow'), 'Москва');
  });
  test(
    'Chosen city centre is offline and is not a live user position',
    () async {
      final paris = suggestCities('Paris', countryCode: 'FR').first;
      final service = LocationService();
      final centre = await service.cityCenter(paris.name);
      expect(centre.latitude, paris.latitude);
      expect(centre.longitude, paris.longitude);
      expect(service.lastPosition, isNull);
    },
  );
  test('Typeahead is bounded and uses a prebuilt local search index', () {
    final watch = Stopwatch()..start();
    for (final text in [
      'W',
      'Wa',
      'War',
      'Wars',
      'Warsz',
      'Warsza',
      'Warszaw',
      'Warszawa',
    ]) {
      expect(suggestCities(text).length, lessThanOrEqualTo(6));
    }
    watch.stop();
    expect(watch.elapsedMilliseconds, lessThan(500));
  });
  testWidgets(
    'Picker displays country and region and returns the stable city key in Polish',
    (tester) async {
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('pl'),
          theme: studioTheme(Brightness.light),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: CitySheet(
              city: 'Минск',
              onSelected: (c) => selected = c,
              onLocate: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('city-input')), 'Warszawa');
      await tester.pumpAndSettle();
      final city = suggestCities('Warszawa', countryCode: 'PL').first;
      expect(find.textContaining('Polska'), findsWidgets);
      final row = find.byKey(ValueKey('city-suggestion-${city.name}'));
      await tester.ensureVisible(row);
      await tester.tap(row);
      expect(selected, city.name);
      expect(find.text('Wybierz miasto'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
