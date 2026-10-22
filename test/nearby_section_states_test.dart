import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/backend/backend.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/nearby/city_catalog.dart';
import 'package:petfriendly/features/nearby/place_repository.dart';
import 'package:petfriendly/l10n/localization.dart';
import 'widget_test.dart' show MemoryPreferences, EmptyCatalog;

class DelayedCatalog extends EmptyCatalog {
  Completer<List<Place>>? pending;
  bool fail = false;
  int loads = 0;
  @override
  Future<List<Place>> load(String city) async {
    loads++;
    if (pending != null) return pending!.future;
    if (fail) throw StateError('Synthetic catalog failure');
    return [
      Place(
        'public-test',
        'Public park',
        'Парк',
        '',
        null,
        0,
        '',
        'unknown',
        Icons.park_outlined,
        city: city,
        latitude: 53.9,
        longitude: 27.5,
      ),
    ];
  }
}

void main() {
  setUpAll(() async {
    for (final font in {
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'Manrope': 'assets/fonts/Manrope.ttf',
      'Golos Text': 'assets/fonts/GolosText.ttf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
  });
  test(
    'catalog refresh retains previous public places on failure and ignores duplicate retry',
    () async {
      const city = 'San Francisco, California, US';
      final catalog = DelayedCatalog();
      final prefs = MemoryPreferences()..values['city'] = city;
      final container = ProviderContainer(
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          cityCatalogServiceProvider.overrideWithValue(catalog),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        selectedCityCatalogProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      await container.read(authStateProvider.future);
      final first = await container.read(cityCatalogProvider(city).future);
      final loadsBefore = catalog.loads;
      catalog.pending = Completer<List<Place>>();
      final refresh = container
          .read(catalogRefreshProvider.notifier)
          .retry(city);
      await container.read(catalogRefreshProvider.notifier).retry(city);
      expect(container.read(catalogRefreshProvider), contains(city));
      await Future<void>.delayed(Duration.zero);
      expect(catalog.loads, loadsBefore + 1);
      catalog.pending!.completeError(StateError('Synthetic refresh failure'));
      await refresh;
      final state = container.read(selectedCityCatalogProvider);
      expect(state.hasError, isTrue);
      expect(state.value, first);
      expect(container.read(catalogRefreshProvider), isEmpty);
      expect(container.read(prototypeProvider).city, city);
    },
  );

  for (final locale in ['ru', 'en', 'be', 'pl']) {
    for (final dark in [false, true]) {
      testWidgets('grouped nearby states $locale dark=$dark', (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final catalog = DelayedCatalog()..fail = true;
        final prefs = MemoryPreferences()
          ..values.addAll({
            'city': 'San Francisco, California, US',
            'manualCity': 'true',
            'language': locale,
            'theme': dark ? 'dark' : 'light',
          });
        final container = ProviderContainer(
          overrides: [
            preferencesProvider.overrideWithValue(prefs),
            cityCatalogServiceProvider.overrideWithValue(catalog),
            communityRepositoryProvider.overrideWithValue(
              DemoCommunityRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);
        const capture = Key('nearby-state-capture');
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const RepaintBoundary(key: capture, child: PetFriendlyApp()),
          ),
        );
        await tester.pumpAndSettle();
        final context = tester.element(find.byKey(const Key('choose-city')));
        expect(
          tester.getTopLeft(find.byKey(const Key('nearby-all-meetups'))).dy,
          lessThan(tester.getTopLeft(find.byKey(const Key('choose-city'))).dy),
        );
        final retry = find.byKey(const Key('catalog-retry'));
        await tester.scrollUntilVisible(
          retry,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(
          find.text('Не удалось загрузить места.'.tr(context)),
          findsOneWidget,
        );
        expect(find.byKey(const Key('nearby-places-list')), findsOneWidget);
        expect(
          tester.getTopLeft(find.byKey(const Key('nearby-places-list'))).dy,
          lessThan(tester.getTopLeft(retry).dy),
        );
        expect(tester.takeException(), isNull);
        if (const bool.fromEnvironment('CAPTURE_NEARBY_STATES')) {
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(capture),
          );
          await tester.runAsync(() async {
            final pixels = await boundary.toImage(pixelRatio: 2);
            final bytes = await pixels.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final file = File(
              'docs/screenshots/nearby-sections/$locale-${dark ? 'dark' : 'light'}-error-large.png',
            );
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            pixels.dispose();
          });
        }
        catalog.pending = Completer<List<Place>>();
        await tester.tap(retry.hitTestable());
        await tester.pump();
        expect(container.read(catalogRefreshProvider), isNotEmpty);
        expect(find.byKey(const Key('catalog-retry')), findsNothing);
        expect(
          find.text('Загружаем места города…'.tr(context)),
          findsOneWidget,
        );
        catalog.pending!.complete([]);
        await tester.pumpAndSettle();
        expect(
          find.text('Не удалось загрузить места.'.tr(context)),
          findsNothing,
        );
        expect(container.read(prototypeProvider).manualCity, isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
