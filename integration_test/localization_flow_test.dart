import 'package:petfriendly/core/time/display_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/backend/backend.dart';
import 'package:petfriendly/core/location/city_directory.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/nearby/city_catalog.dart';
import 'package:petfriendly/features/nearby/location_service.dart';
import 'package:petfriendly/features/nearby/place_repository.dart';
import 'package:petfriendly/features/nearby/city_sheet.dart';
import 'package:petfriendly/l10n/localization.dart';

class MemoryPreferences implements PreferencesRepository {
  final values = <String, String>{
    'language': 'ru',
    'theme': 'light',
    'city': 'Минск',
    'manualCity': 'true',
    'locationPrompted': 'yes',
  };
  @override
  String? read(String key) => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

class OfflineLocations extends LocationService {
  @override
  Future<bool> hasPermission() async => false;
}

class EmptyCatalog extends CityCatalogService {
  bool fail = false;
  EmptyCatalog() : super(OfflineLocations());
  @override
  Future<List<Place>> load(String city) async {
    if (fail) throw StateError('Synthetic catalog failure');
    return [];
  }
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Four native languages, themes, country-aware picker and Belarusian calendar',
    (tester) async {
      await loadWorldCities();
      if (AppConfig.mapboxToken.isNotEmpty) {
        MapboxOptions.setAccessToken(AppConfig.mapboxToken);
      }
      final prefs = MemoryPreferences();
      final container = ProviderContainer(
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          backendProvider.overrideWithValue(null),
          communityRepositoryProvider.overrideWithValue(
            DemoCommunityRepository(),
          ),
          cityCatalogServiceProvider.overrideWithValue(EmptyCatalog()),
          locationServiceProvider.overrideWithValue(OfflineLocations()),
          placesProvider.overrideWithValue(OsmPlaceRepository([])),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const PetFriendlyApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = container.read(routerProvider);
      for (final lang in appLanguages.keys) {
        await container.read(languageProvider.notifier).select(lang);
        await container
            .read(prototypeProvider.notifier)
            .setTheme(
              lang == 'be' || lang == 'pl' ? ThemeMode.dark : ThemeMode.light,
            );
        router.go('/settings');
        await tester.pumpAndSettle();
        await binding.takeScreenshot('languages-settings-$lang');
        await tester.tap(find.byKey(const Key('settings-language')));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<ListTile>(find.byKey(ValueKey('language-$lang')))
              .selected,
          isTrue,
        );
        await binding.takeScreenshot('language-picker/native-$lang');
        await tester.tap(find.byKey(ValueKey('language-$lang')));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('language-system')), findsNothing);
        expect(router.state.uri.path, '/settings');
        await container
            .read(prototypeProvider.notifier)
            .setCity('San Francisco, California, US');
        router.go('/nearby');
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('choose-city')));
        await tester.pumpAndSettle();
        await binding.takeScreenshot('translated-layout/native-nearby-$lang');
        final catalog =
            container.read(cityCatalogServiceProvider) as EmptyCatalog;
        catalog.fail = true;
        await container
            .read(catalogRefreshProvider.notifier)
            .retry('San Francisco, California, US');
        await tester.pumpAndSettle();
        final retry = find.byKey(const Key('catalog-retry'));
        await tester.ensureVisible(retry);
        await tester.pumpAndSettle();
        expect(retry.hitTestable(), findsOneWidget);
        await binding.takeScreenshot('nearby-sections/native-error-$lang');
        catalog.fail = false;
        await tester.tap(retry.hitTestable());
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('catalog-retry')), findsNothing);
        expect(
          container.read(prototypeProvider).city,
          'San Francisco, California, US',
        );

        router.go('/profile');
        await tester.pumpAndSettle();
        // The approved compact profile has inline pets and favorites, no tabs.
        expect(find.byType(TabBar), findsNothing);
        await tester.pumpAndSettle();
        await binding.takeScreenshot('translated-layout/native-profile-$lang');
        expect(tester.takeException(), isNull);
        await container.read(prototypeProvider.notifier).setCity('Минск');
        router.go('/login');
        await tester.pumpAndSettle();
        await binding.takeScreenshot('languages-login-$lang');
        expect(
          find.byTooltip(
            'Язык приложения'.tr(tester.element(find.byType(Scaffold).first)),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      }
      await container.read(languageProvider.notifier).select('pl');
      for (final theme in [ThemeMode.light, ThemeMode.dark]) {
        await container.read(prototypeProvider.notifier).setTheme(theme);
        router.go('/nearby');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Минск').first);
        await tester.pumpAndSettle();
        expect(find.byType(CitySheet), findsOneWidget);
        await tester.enterText(find.byKey(const Key('city-input')), 'Warszawa');
        await tester.pumpAndSettle();
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await binding.takeScreenshot('languages-city-pl-${theme.name}');
        final warsaw = suggestCities('Warszawa', countryCode: 'PL').first;
        await tester.tap(
          find.byKey(ValueKey('city-suggestion-${warsaw.name}')),
        );
        await tester.pumpAndSettle();
        expect(container.read(prototypeProvider).city, warsaw.name);
        expect(container.read(prototypeProvider).manualCity, isTrue);
        expect(cityTimeZone(warsaw.name), 'Europe/Warsaw');
        // Reset just this in-memory fixture for the next themed picker.
        await container.read(prototypeProvider.notifier).setCity('Минск');
      }
      await container.read(languageProvider.notifier).select('be');
      router.go('/edit/walk');
      await tester.pumpAndSettle();
      final date = find.byKey(const ValueKey('walking-date-trigger'));
      await tester.ensureVisible(date);
      await tester.tap(date);
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(CalendarDatePicker));
      expect(MaterialLocalizations.of(context).firstDayOfWeekIndex, 1);
      expect(find.byType(CalendarDatePicker), findsOneWidget);
      await binding.takeScreenshot('languages-calendar-be-dark');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
    },
  );
}
