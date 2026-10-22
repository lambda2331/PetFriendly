import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' hide Size;
// The pinned SDK facade does not re-export these platform testing contracts.
// ignore: implementation_imports, depend_on_referenced_packages
import 'package:mapbox_maps_flutter_platform_interface/src/interfaces/mapbox_map_interface.dart'
    show MapboxMapPlatformInterface;
// ignore: implementation_imports, depend_on_referenced_packages
import 'package:mapbox_maps_flutter_platform_interface/src/interfaces/style_interface.dart'
    show StylePlatformInterface;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/ui/components.dart';
import 'package:petfriendly/core/ui/studio_motion.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/nearby/nearby_studio_layout.dart';
import 'package:petfriendly/features/nearby/places_list_screen.dart';
import 'package:petfriendly/features/nearby/fullscreen_map_screen.dart';
import 'package:petfriendly/features/community/presentation/events_screen.dart';
import '../design/nearby-studio-native/fixture.dart';

class FixedReviewCamera implements MapboxMapPlatformInterface {
  FixedReviewCamera(this.camera);
  final CameraState camera;
  @override
  StylePlatformInterface get style => ReviewStyle();
  @override
  Future<CameraState> getCameraState() async => camera;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ReviewStyle implements StylePlatformInterface {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    for (final e in {
      'Manrope': 'assets/fonts/Manrope.ttf',
      'Golos Text': 'assets/fonts/GolosText.ttf',
    }.entries) {
      await (FontLoader(e.key)..addFont(rootBundle.load(e.value))).load();
    }
  });
  for (final locale in ['ru', 'en', 'be', 'pl']) {
    for (final dark in [false, true]) {
      testWidgets('Nearby Studio $locale $dark at 320px / 200%', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final container = nearbyReviewContainer(
          locale: locale,
          dark: dark,
          city: 'San Francisco, California, US',
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const PetFriendlyApp(),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(NearbyStudioLayout), findsOneWidget);
        expect(
          tester.getTopLeft(find.byKey(const Key('nearby-all-meetups'))).dy,
          lessThan(tester.getTopLeft(find.byKey(const Key('choose-city'))).dy),
        );
        expect(find.byKey(const Key('nearby-fullscreen-map')), findsOneWidget);
        expect(
          tester
              .widget<FullscreenMapScreen>(find.byType(FullscreenMapScreen))
              .embeddedHeight,
          180,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('Nearby real routes return to selected city and screen', (
    tester,
  ) async {
    final c = nearbyReviewContainer();
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const PetFriendlyApp()),
    );
    await tester.pumpAndSettle();
    for (final entry in [
      (const Key('nearby-places-list'), PlacesListScreen),
      (const Key('nearby-all-meetups'), EventsScreen),
      (const Key('nearby-fullscreen-map'), FullscreenMapScreen),
    ]) {
      await tester.ensureVisible(find.byKey(entry.$1));
      await tester.tap(find.byKey(entry.$1));
      await tester.pumpAndSettle();
      expect(find.byType(entry.$2), findsOneWidget);
      if (entry.$2 == EventsScreen) {
        // All meetings is a People destination, not a pushed detail route.
        expect(c.read(routerProvider).canPop(), isFalse);
        await tester.tap(find.byKey(const ValueKey('nav-0')));
      } else {
        expect(c.read(routerProvider).canPop(), isTrue);
        c.read(routerProvider).pop();
      }
      await tester.pumpAndSettle();
      expect(find.byType(NearbyStudioLayout), findsOneWidget);
      expect(c.read(prototypeProvider).city, 'Минск');
      expect(c.read(prototypeProvider).manualCity, isTrue);
    }
  });
  testWidgets(
    'External map action retains camera, rejects duplicate opening and detaches',
    (tester) async {
      final c = nearbyReviewContainer();
      addTearDown(c.dispose);
      final actions = EmbeddedMapActions();
      final close = Completer<void>();
      CameraState? received;
      var calls = 0;
      final camera = CameraState(
        center: Point(coordinates: Position(27.542, 53.9285)),
        padding: MbxEdgeInsets(top: 0, left: 0, bottom: 0, right: 0),
        zoom: 14.5,
        bearing: 12,
        pitch: 0,
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(
            home: Scaffold(
              body: FullscreenMapScreen(
                embedded: true,
                showEmbeddedControls: false,
                actions: actions,
                args: const FullscreenMapArgs(places: [], city: 'Минск'),
                onExpand: (value) {
                  calls++;
                  received = value;
                  return close.future;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final mapState =
          tester.state(find.byType(FullscreenMapScreen)) as dynamic;
      // Construct the SDK facade over a fake platform, never a native/private map.
      // ignore: invalid_use_of_internal_member
      mapState.controller = MapboxMap(FixedReviewCamera(camera));
      final first = actions.expand();
      await tester.pump();
      await actions.expand();
      expect(calls, 1);
      expect(received, same(camera));
      expect(received!.zoom, 14.5);
      close.complete();
      await first;
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await actions.expand();
      expect(calls, 1);
    },
  );
  for (final features in [
    const FakeAccessibilityFeatures(disableAnimations: true),
    const FakeAccessibilityFeatures(reduceMotion: true),
  ]) {
    testWidgets('Studio motion honors $features', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue = features;
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      late BuildContext c;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              c = context;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pump();
      expect(StudioMotion.duration(c, StudioMotion.tab), Duration.zero);
      expect(studioSheetAnimation(c).duration, Duration.zero);
    });
  }
}
