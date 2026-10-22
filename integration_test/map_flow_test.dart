import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:petfriendly/main.dart' as app;
import 'package:petfriendly/core/backend/backend.dart';
import 'package:petfriendly/features/nearby/fullscreen_map_screen.dart';
import 'package:petfriendly/features/nearby/live_map.dart';
import 'package:petfriendly/features/nearby/add_place_screen.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Mapbox loads real map and OSM annotations in both themes', (
    tester,
  ) async {
    expect(AppConfig.mapboxToken.isNotEmpty, isTrue);
    SharedPreferences.setMockInitialValues({
      'language': 'ru',
      'locationPrompted': 'yes',
      'manualCity': 'true',
      'city': 'Минск',
      'theme': 'light',
    });
    await app.main();
    await tester.pumpAndSettle();
    await waitFor(
      tester,
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.identifier == 'map-ready-light',
      ),
    );
    expect(find.text('Карта пока недоступна'), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(PetFriendlyApp)),
    );
    await container.read(prototypeProvider.notifier).setTheme(ThemeMode.dark);
    await waitFor(
      tester,
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.identifier == 'map-ready-dark',
      ),
    );
    expect(find.text('Карта пока недоступна'), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('nearby-fullscreen-map')));
    await tester.tap(find.byKey(const Key('nearby-fullscreen-map')));
    await waitFor(tester, find.byTooltip('Закрыть карту'));
    final fullMap = find.descendant(
      of: find.byWidgetPredicate(
        (w) => w is FullscreenMapScreen && !w.embedded,
      ),
      matching: find.byKey(const ValueKey('live-map')),
    );
    await waitFor(
      tester,
      find.descendant(
        of: find.byWidgetPredicate(
          (w) => w is FullscreenMapScreen && !w.embedded,
        ),
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.identifier == 'map-ready-dark',
        ),
      ),
    );
    await tester.drag(fullMap, const Offset(100, 60));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byTooltip('Приблизить').hitTestable());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byTooltip('Отдалить').hitTestable());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.byTooltip('Закрыть карту'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('nearby-fullscreen-map')), findsOneWidget);
    await tester.tap(find.byKey(const Key('nearby-places-list')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('places-search')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('places-search')),
      'Александровский',
    );
    await tester.pumpAndSettle();
    expect(find.text('Александровский сквер'), findsOneWidget);
    await tester.tap(find.text('Александровский сквер'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Показать на карте'));
    final full = find.byWidgetPredicate(
      (w) => w is FullscreenMapScreen && !w.embedded,
    );
    await waitFor(
      tester,
      find.descendant(
        of: full,
        matching: find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.identifier == 'map-ready-dark',
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    final selected = tester.widget<FullscreenMapScreen>(full).args.focusPlace!;
    final state =
        tester.state(find.descendant(of: full, matching: find.byType(LiveMap)))
            as dynamic;
    final native = state.map as MapboxMap;
    final camera = await native.getCameraState();
    expect(camera.zoom, closeTo(16, .2));
    expect(
      camera.center.coordinates.lat.toDouble(),
      closeTo(selected.latitude!, .0001),
    );
    expect(
      camera.center.coordinates.lng.toDouble(),
      closeTo(selected.longitude!, .0001),
    );
    await tester.tap(find.byTooltip('Приблизить').hitTestable());
    await tester.pump(const Duration(seconds: 1));
    expect((await native.getCameraState()).zoom, greaterThan(16.5));
    await tester.tap(find.byTooltip('Закрыть карту'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Добавить место'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отметить на карте'));
    await waitFor(
      tester,
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.identifier == 'map-ready-dark',
      ),
    );
    expect(find.byType(SelectedPlacePin), findsOneWidget);
    await tester.tap(find.text('Выбрать эту точку'));
    await tester.pumpAndSettle();
    expect(find.text('Точка выбрана'), findsOneWidget);
    await tester.tap(find.byType(BackButton).hitTestable());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton).hitTestable());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('nearby-places-list')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> waitFor(WidgetTester tester, Finder finder) async {
  final end = DateTime.now().add(const Duration(seconds: 60));
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  expect(finder, findsOneWidget);
}
