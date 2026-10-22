import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:integration_test/integration_test.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:petfriendly/core/backend/backend.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/nearby/fullscreen_map_screen.dart';
import 'package:petfriendly/features/nearby/live_map.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/nearby/city_catalog.dart';
import 'package:petfriendly/features/nearby/location_service.dart';
import 'package:petfriendly/features/nearby/place_repository.dart';
import '../test/widget_test.dart' show MemoryPreferences;

geo.Position syntheticPosition(double latitude, double longitude) =>
    geo.Position(
      latitude: latitude,
      longitude: longitude,
      timestamp: DateTime.now(),
      accuracy: 10,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

class SyntheticLocation extends LocationService {
  bool slow = false;
  final updates = StreamController<geo.Position>.broadcast();
  final sample = syntheticPosition(53.928, 27.61);
  @override
  Future<bool> hasPermission() async => true;
  @override
  Future<geo.Position> currentPosition({
    geo.LocationAccuracy accuracy = geo.LocationAccuracy.high,
  }) async {
    if (slow) throw TimeoutException('Synthetic slow first fix');
    return lastPosition = sample;
  }

  @override
  Stream<geo.Position> positions() => updates.stream;
  @override
  Future<({double latitude, double longitude})> cityCenter(String city) async =>
      (latitude: 53.9023, longitude: 27.5619);
}

class FirstLaunchLocation extends SyntheticLocation {
  final grantPermission = Completer<void>();
  final resolveCity = Completer<String>();
  bool allowed = false;
  @override
  Future<bool> hasPermission() async => allowed;
  @override
  Future<String> nearbyCity() async {
    await grantPermission.future;
    allowed = true;
    lastPosition = sample;
    return resolveCity.future;
  }
}

class EmptyCatalog extends CityCatalogService {
  EmptyCatalog(super.location);
  @override
  Future<List<Place>> load(String city) async => [];
}

Future<void> ready(WidgetTester tester, Brightness theme) async {
  final loaded = find.byWidgetPredicate(
    (w) =>
        w is Semantics && w.properties.identifier == 'map-ready-${theme.name}',
  );
  for (var i = 0; i < 100 && loaded.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
  expect(loaded, findsOneWidget);
  await tester.pump(const Duration(seconds: 1));
}

Future<void> expectMarker(WidgetTester tester, geo.Position position) async {
  final state = tester.state(find.byType(LiveMap)) as dynamic;
  List<PointAnnotation> annotations = [];
  for (var i = 0; i < 40; i++) {
    final manager = state.userManager as PointAnnotationManager?;
    annotations = manager == null ? [] : await manager.getAnnotations();
    if (annotations.length == 1 &&
        (annotations.single.geometry.coordinates.lat.toDouble() -
                    position.latitude)
                .abs() <
            .00001 &&
        (annotations.single.geometry.coordinates.lng.toDouble() -
                    position.longitude)
                .abs() <
            .00001) {
      break;
    }
    await tester.pump(const Duration(milliseconds: 250));
  }
  expect(annotations, hasLength(1));
  expect(
    annotations.single.geometry.coordinates.lat.toDouble(),
    closeTo(position.latitude, .00001),
  );
  expect(
    annotations.single.geometry.coordinates.lng.toDouble(),
    closeTo(position.longitude, .00001),
  );
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Nearby shows the first fix before city lookup completes', (
    tester,
  ) async {
    MapboxOptions.setAccessToken(AppConfig.mapboxToken);
    final service = FirstLaunchLocation();
    final preferences = MemoryPreferences()
      ..values.remove('locationPrompted')
      ..values['language'] = 'ru'
      ..values['theme'] = 'light';
    final container = ProviderContainer(
      overrides: [
        preferencesProvider.overrideWithValue(preferences),
        backendProvider.overrideWithValue(null),
        communityRepositoryProvider.overrideWithValue(
          DemoCommunityRepository(),
        ),
        cityCatalogServiceProvider.overrideWithValue(EmptyCatalog(service)),
        placesProvider.overrideWithValue(OsmPlaceRepository([])),
        locationServiceProvider.overrideWithValue(service),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const PetFriendlyApp(),
      ),
    );
    await ready(tester, Brightness.light);
    expect(tester.widget<LiveMap>(find.byType(LiveMap)).userPosition, isNull);
    service.grantPermission.complete();
    await expectMarker(tester, service.sample);
    final state = tester.state(find.byType(LiveMap)) as dynamic;
    final camera = await (state.map as MapboxMap).getCameraState();
    expect(camera.zoom, closeTo(15, .1));
    expect(
      camera.center.coordinates.lat.toDouble(),
      closeTo(service.sample.latitude, .00001),
    );
    expect(
      camera.center.coordinates.lng.toDouble(),
      closeTo(service.sample.longitude, .00001),
    );
    expect(service.resolveCity.isCompleted, isFalse);
    expect(find.byTooltip('Моё местоположение'), findsNothing);
    await binding.takeScreenshot('nearby-first-fix-light-ios');
    await container.read(prototypeProvider.notifier).setTheme(ThemeMode.dark);
    await ready(tester, Brightness.dark);
    await expectMarker(tester, service.sample);
    await binding.takeScreenshot('nearby-first-fix-dark-ios');
    service.resolveCity.complete('Минск');
    await tester.pump(const Duration(seconds: 1));
    await expectMarker(tester, service.sample);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    container.dispose();
    await service.updates.close();
    service.dispose();
  });
  testWidgets(
    'Embedded GPS before map readiness, theme recreation, and explicit focus',
    (tester) async {
      MapboxOptions.setAccessToken(AppConfig.mapboxToken);
      final service = SyntheticLocation();
      final preferences = MemoryPreferences()
        ..values['locationPrompted'] = 'yes';
      final container = ProviderContainer(
        overrides: [
          preferencesProvider.overrideWithValue(preferences),
          locationServiceProvider.overrideWithValue(service),
        ],
      );
      const place = Place(
        'test-public-park',
        'Тестовый парк',
        'Парк',
        'Минск',
        null,
        0,
        '',
        'unknown',
        Icons.park,
        latitude: 53.927,
        longitude: 27.613,
      );
      Widget screen(Brightness theme, {bool embedded = true, Place? focus}) =>
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: studioTheme(theme),
              home: Scaffold(
                body: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(embedded ? 24 : 0),
                    child: FullscreenMapScreen(
                      embedded: embedded,
                      args: FullscreenMapArgs(
                        places: [place],
                        city: 'Минск',
                        focusPlace: focus,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
      for (final theme in [Brightness.light, Brightness.dark]) {
        await tester.pumpWidget(screen(theme));
        await ready(tester, theme);
        await expectMarker(tester, service.sample);
        final state = tester.state(find.byType(LiveMap)) as dynamic;
        final native = state.map as MapboxMap;
        final camera = await native.getCameraState();
        expect(camera.zoom, closeTo(15, .1));
        expect(
          camera.center.coordinates.lat.toDouble(),
          closeTo(service.sample.latitude, .00001),
        );
        expect(
          camera.center.coordinates.lng.toDouble(),
          closeTo(service.sample.longitude, .00001),
        );
        expect(find.byTooltip('Моё местоположение'), findsNothing);
        await binding.takeScreenshot('nearby-location-${theme.name}-ios');
      }
      final next = syntheticPosition(53.9282, 27.6103);
      service.updates.add(next);
      await tester.pumpWidget(screen(Brightness.dark));
      await expectMarker(tester, next);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 500));
      await container
          .read(prototypeProvider.notifier)
          .setCity('Минск', manual: true);
      await tester.pumpWidget(
        screen(Brightness.light, embedded: false, focus: place),
      );
      await ready(tester, Brightness.light);
      await expectMarker(tester, service.sample);
      final state = tester.state(find.byType(LiveMap)) as dynamic;
      final camera = await (state.map as MapboxMap).getCameraState();
      expect(camera.zoom, closeTo(16, .1));
      expect(
        camera.center.coordinates.lat.toDouble(),
        closeTo(place.latitude!, .00001),
      );
      expect(
        camera.center.coordinates.lng.toDouble(),
        closeTo(place.longitude!, .00001),
      );
      expect(container.read(prototypeProvider).manualCity, isTrue);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 500));
      await container
          .read(prototypeProvider.notifier)
          .setCity('Минск', manual: false);
      service.slow = true;
      service.lastPosition = null;
      await tester.pumpWidget(screen(Brightness.light));
      await tester.pump(const Duration(milliseconds: 500));
      service.updates.add(service.sample);
      await ready(tester, Brightness.light);
      await expectMarker(tester, service.sample);
      final delayedState = tester.state(find.byType(LiveMap)) as dynamic;
      // Flutter's pump clock does not advance the native Mapbox animation
      // clock. Wait in wall time for the 220 ms camera animation to finish.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 400)),
      );
      await tester.pump();
      final delayedCamera = await (delayedState.map as MapboxMap)
          .getCameraState();
      expect(delayedCamera.zoom, closeTo(15, .1));
      expect(
        delayedCamera.center.coordinates.lat.toDouble(),
        closeTo(service.sample.latitude, .00001),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      container.dispose();
      await service.updates.close();
    },
  );
}
