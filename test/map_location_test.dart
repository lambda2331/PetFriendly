import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:petfriendly/features/nearby/fullscreen_map_screen.dart';
import 'package:petfriendly/features/nearby/location_service.dart';
import 'package:petfriendly/features/nearby/live_map.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'widget_test.dart' show MemoryPreferences;

class FakeLocation extends LocationService {
  FakeLocation({this.denied = false}) {
    updates = StreamController<Position>.broadcast(
      onListen: () => active = true,
      onCancel: () => active = false,
    );
  }
  final bool denied;
  bool active = false, permissionGranted = false;
  late final StreamController<Position> updates;
  @override
  Future<bool> hasPermission() async => permissionGranted && !denied;
  @override
  Future<Position> currentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    if (denied) throw const LocationIssue('Доступ к геолокации не разрешён.');
    permissionGranted = true;
    return sample;
  }

  @override
  Stream<Position> positions() => updates.stream;
}

final sample = Position(
  latitude: 53.9,
  longitude: 27.56,
  timestamp: DateTime(2026),
  accuracy: 15,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);
void main() {
  testWidgets(
    'Main map resumes already permitted location without changing manual city',
    (tester) async {
      final service = FakeLocation()..permissionGranted = true;
      final prefs = MemoryPreferences()
        ..values['city'] = 'Москва'
        ..values['manualCity'] = 'true';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            locationServiceProvider.overrideWithValue(service),
            preferencesProvider.overrideWithValue(prefs),
          ],
          child: MaterialApp(
            theme: studioTheme(Brightness.light),
            home: const FullscreenMapScreen(
              embedded: true,
              args: FullscreenMapArgs(places: [], city: 'Москва'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(service.active, isTrue);
      // Unconfigured maps show the compact fallback while permitted location
      // and the user's manual city remain unchanged.
      expect(find.byType(MapUnavailableState), findsOneWidget);
      expect(find.byType(LiveMap), findsNothing);
      expect(prefs.values['city'], 'Москва');
      expect(prefs.values['manualCity'], 'true');
      expect(find.byTooltip('Моё местоположение'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(service.active, isFalse);
      await service.updates.close();
    },
  );
  for (final denied in [false, true]) {
    testWidgets(
      'Fullscreen location respects denial=$denied and stops when hidden',
      (tester) async {
        final service = FakeLocation(denied: denied);
        Widget screen(bool active) => ProviderScope(
          overrides: [locationServiceProvider.overrideWithValue(service)],
          child: MaterialApp(
            theme: studioTheme(Brightness.light),
            home: TickerMode(
              enabled: active,
              child: const FullscreenMapScreen(
                args: FullscreenMapArgs(places: [], city: 'Минск'),
              ),
            ),
          ),
        );
        await tester.pumpWidget(screen(true));
        await tester.pumpAndSettle();
        expect(service.active, isFalse);
        await tester.tap(find.byTooltip('Моё местоположение'));
        await tester.pumpAndSettle();
        expect(service.active, !denied);
        final map = tester.widget<LiveMap>(find.byType(LiveMap));
        expect(map.userPosition, denied ? isNull : sample);
        if (denied) {
          expect(find.text('Доступ к геолокации не разрешён.'), findsOneWidget);
        } else {
          await tester.pumpWidget(screen(false));
          await tester.pumpAndSettle();
          expect(service.active, isFalse);
          await tester.pumpWidget(screen(true));
          await tester.pumpAndSettle();
          expect(service.active, isTrue);
          final observer =
              tester.state(find.byType(FullscreenMapScreen))
                  as WidgetsBindingObserver;
          observer.didChangeAppLifecycleState(AppLifecycleState.hidden);
          await tester.pumpAndSettle();
          expect(service.active, isFalse);
          observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
          await tester.pumpAndSettle();
          expect(service.active, isTrue);
        }
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        expect(service.active, isFalse);
        await service.updates.close();
      },
    );
  }
}
