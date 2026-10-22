import 'package:petfriendly/features/nearby/city_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/community/data/event_location.dart';
import 'package:petfriendly/features/community/data/form_drafts.dart';
import 'package:petfriendly/features/community/presentation/forms.dart';
import 'package:petfriendly/features/community/presentation/events_screen.dart';
import 'package:petfriendly/features/community/presentation/event_location_widgets.dart';
import 'package:petfriendly/features/nearby/add_place_screen.dart';
import 'package:petfriendly/features/nearby/live_map.dart';
import 'widget_test.dart' show MemoryPreferences;

class EventRepo implements CommunityRepository {
  @override
  String get userId => demoAlex;
  @override
  bool get isDemo => true;
  Json? submitted;
  CommunityData data = {
    'profiles': [],
    'pets': [],
    'events': [],
    'event_members': [],
  };
  @override
  Future<CommunityData> load() async => data;
  @override
  Future<String?> command(String action, Json values) async {
    submitted = values;
    return 'synthetic-event';
  }
}

Future<void> chooseCity(WidgetTester tester, String city) async {
  if (find.byType(EventVenuePicker).evaluate().isEmpty) {
    final opener = find.byKey(const ValueKey('event.choose-location'));
    await tester.scrollUntilVisible(
      opener,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(opener);
    await tester.pumpAndSettle();
  }
  final field = find.byType(TextFormField).first;
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('city-input')), city);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ValueKey('city-suggestion-$city')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Без места'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Long public label remains bounded with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(Brightness.dark),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: EventLocationMapScreen(
            city: 'Минск',
            location: EventLocation(
              53.9,
              27.56,
              label: 'Длинная публичная подпись места встречи ' * 4,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(Card)).height, lessThan(300));
  });
  test('Legacy and invalid locations do not produce map links', () {
    expect(EventLocation.fromRow({}), isNull);
    expect(EventLocation.fromRow({'latitude': 53.9}), isNull);
    for (final lat in [double.nan, double.infinity, 91.0]) {
      expect(
        EventLocation.fromRow({'latitude': lat, 'longitude': 27.5}),
        isNull,
      );
    }
  });

  testWidgets(
    'Selection survives cancellation and draft restore, clears on city change',
    (tester) async {
      final repo = EventRepo();
      final container = ProviderContainer(
        overrides: [
          cityCatalogProvider.overrideWith((ref, city) async => []),
          preferencesProvider.overrideWithValue(MemoryPreferences()),
          communityRepositoryProvider.overrideWithValue(repo),
          eventPointPickerProvider.overrideWithValue((
            context,
            city,
            initial,
          ) async {
            expect(city, 'Минск');
            if (initial != null) {
              expect(initial.latitude, 53.9);
              return null;
            }
            return (53.9, 27.56);
          }),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: studioTheme(Brightness.light),
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditScreen(kind: 'event'),
                    ),
                  ),
                  child: const Text('Открыть'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Открыть'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('event.choose-location')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('event.choose-location')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Выбрать место на карте'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Выбрать место'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Убрать точку встречи'), findsOneWidget);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('event.choose-location')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Выбрать место на карте'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Выбрать место'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Убрать точку встречи'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('field.location_label')),
        'У входа в парк',
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Оставить черновик'));
      await tester.pumpAndSettle();
      expect(
        container
            .read(formDraftsProvider)
            .read('event:new:false')!
            .eventLocation!
            .latitude,
        53.9,
      );
      await tester.tap(find.text('Открыть'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('event.choose-location')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byTooltip('Убрать точку встречи'), findsOneWidget);
      expect(
        tester
            .widget<TextFormField>(
              find.byKey(const ValueKey('field.location_label')),
            )
            .controller!
            .text,
        'У входа в парк',
      );
      await chooseCity(tester, 'Москва');
      await tester.pumpAndSettle();
      expect(find.byTooltip('Убрать точку встречи'), findsNothing);
    },
  );

  testWidgets('Creating event submits selected coordinates and public label', (
    tester,
  ) async {
    final repo = EventRepo();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cityCatalogProvider.overrideWith((ref, city) async => []),
          preferencesProvider.overrideWithValue(MemoryPreferences()),
          communityRepositoryProvider.overrideWithValue(repo),
          eventPointPickerProvider.overrideWithValue(
            (_, _, _) async => (55.75, 37.61),
          ),
        ],
        child: MaterialApp(
          theme: studioTheme(Brightness.light),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const EditScreen(kind: 'event'),
                  ),
                ),
                child: const Text('Открыть'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('field.title')),
      'Встреча у парка',
    );
    await chooseCity(tester, 'Москва');
    await tester.ensureVisible(
      find.byKey(const ValueKey('event.choose-location')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('event.choose-location')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выбрать место на карте'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выбрать место'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('field.location_label')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('field.location_label')),
      'Главный вход',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('field.capacity')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('field.capacity')), '');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('field.duration')),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('field.duration')), '90');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final save = find.widgetWithText(FilledButton, 'Создать встречу');
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(repo.submitted!['capacity_in'], isNull);
    expect(repo.submitted!['duration_in'], 90);
    expect(repo.submitted!['latitude_in'], 55.75);
    expect(repo.submitted!['longitude_in'], 37.61);
    expect(repo.submitted!['location_label_in'], 'Главный вход');
    expect(repo.submitted!['timezone_in'], 'Europe/Moscow');
  });

  for (final brightness in Brightness.values) {
    testWidgets('Meeting map link focuses selected point in $brightness', (
      tester,
    ) async {
      final repo = EventRepo();
      repo.data['events'] = [
        {
          'id': 'synthetic-event',
          'owner_id': demoAlex,
          'title': 'Встреча',
          'city': 'Минск',
          'starts_at': '2027-01-01T10:00:00Z',
          'capacity': 8,
          'latitude': 53.9,
          'longitude': 27.56,
          'location_label': 'У входа',
        },
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cityCatalogProvider.overrideWith((ref, city) async => []),
            communityRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: studioTheme(brightness),
            home: const EventsScreen(focusedEventId: 'synthetic-event'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('meetup-map-synthetic-event')),
      );
      await tester.tap(
        find.byKey(const ValueKey('meetup-map-synthetic-event')),
      );
      await tester.pumpAndSettle();
      final map = tester.widget<LiveMap>(find.byType(LiveMap));
      expect(map.focusPlace!.latitude, 53.9);
      expect(map.focusPlace!.longitude, 27.56);
      expect(map.places.single.category, 'Место встречи');
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Unconfigured map cannot confirm a fabricated meeting point', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PlacePositionPicker(
            city: 'Москва',
            title: 'Место встречи',
            initialPoint: (55.75, 37.61),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Карта не настроена. Выбор точки недоступен.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Выбрать эту точку'),
          )
          .onPressed,
      isNull,
    );
  });
}
