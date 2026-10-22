import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:petfriendly/core/backend/backend.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/community/data/event_location.dart';
import 'package:petfriendly/features/community/data/form_drafts.dart';
import 'package:petfriendly/features/nearby/live_map.dart';
import '../test/widget_test.dart' show MemoryPreferences;

Future<void> ready(WidgetTester tester, Brightness theme) async {
  final marker = find.byWidgetPredicate(
    (w) =>
        w is Semantics &&
        w.properties.identifier ==
            (theme == Brightness.dark ? 'map-ready-dark' : 'map-ready-light'),
  );
  for (var i = 0; i < 40 && marker.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
  expect(marker, findsOneWidget);
  await tester.pump(const Duration(milliseconds: 300));
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Real meeting point picker, creation and focus in both themes', (
    tester,
  ) async {
    MapboxOptions.setAccessToken(AppConfig.mapboxToken);
    for (final theme in [Brightness.light, Brightness.dark]) {
      final repo = DemoCommunityRepository();
      repo.data['events']!.clear();
      final container = ProviderContainer(
        overrides: [
          preferencesProvider.overrideWithValue(
            MemoryPreferences()
              ..values.addAll({'language': 'ru', 'theme': theme.name}),
          ),
          communityRepositoryProvider.overrideWithValue(repo),
        ],
      );
      container
          .read(formDraftsProvider)
          .keep(
            'event:new:false',
            FormDraft(
              {
                'title': 'Встреча в сквере',
                'city': 'Минск',
                'location_label': 'У входа в сквер',
              },
              DateTime.now().add(const Duration(days: 2)),
              'Europe/Minsk',
              null,
              null,
              eventLocation: const EventLocation(53.901, 27.56),
            ),
          );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const PetFriendlyApp(),
        ),
      );
      await tester.pumpAndSettle();
      container.read(routerProvider).go('/events');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('meetup-create')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('event.choose-location')),
      );
      await tester.tap(find.byKey(const ValueKey('event.choose-location')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Выбрать место на карте'));
      await ready(tester, theme);
      final mapbox =
          (tester.state(find.byType(LiveMap)) as dynamic).map as MapboxMap;
      final initial = await mapbox.getCameraState();
      expect(
        initial.center.coordinates.lat.toDouble(),
        closeTo(53.901, 0.0001),
      );
      expect(initial.zoom, closeTo(16, 0.1));
      await tester.drag(find.byType(MapWidget), const Offset(70, 45));
      await tester.pump(const Duration(milliseconds: 600));
      final moved = await mapbox.getCameraState();
      await binding.takeScreenshot('event-point-picker-${theme.name}-ios');
      await tester.tap(find.widgetWithText(FilledButton, 'Выбрать эту точку'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Выбрать место'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('event.choose-location')),
        findsOneWidget,
      );
      final label = find.byKey(const ValueKey('field.location_label'));
      await tester.ensureVisible(label);
      expect(tester.widget<TextFormField>(label).controller!.text, isEmpty);
      await tester.enterText(label, 'У входа в сквер');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await binding.takeScreenshot('event-point-form-${theme.name}-ios');
      final save = find.byKey(const ValueKey('form-save'));
      await tester.scrollUntilVisible(
        save,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(save);
      await tester.pumpAndSettle();
      final created = repo.data['events']!.single;
      expect(
        created['latitude'],
        closeTo(moved.center.coordinates.lat.toDouble(), 0.000001),
      );
      expect(
        created['longitude'],
        closeTo(moved.center.coordinates.lng.toDouble(), 0.000001),
      );
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(container.read(routerProvider).state.uri.path, '/event/${created['id']}');
      final pointRow = find.byKey(ValueKey('meetup-map-${created['id']}'));
      await tester.ensureVisible(pointRow);
      await tester.tap(pointRow);
      await ready(tester, theme);
      final eventMap =
          (tester.state(find.byType(LiveMap)) as dynamic).map as MapboxMap;
      final focus = await eventMap.getCameraState();
      expect(
        focus.center.coordinates.lat.toDouble(),
        closeTo(created['latitude'], 0.000001),
      );
      expect(focus.zoom, greaterThanOrEqualTo(15));
      await binding.takeScreenshot('event-point-view-${theme.name}-ios');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      container.dispose();
    }
  });
}
