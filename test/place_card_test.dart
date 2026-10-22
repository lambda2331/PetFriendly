import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/features/nearby/place_repository.dart';
import 'package:petfriendly/features/nearby/live_map.dart';
import 'package:petfriendly/core/ui/studio_review.dart';
import 'package:petfriendly/features/nearby/fullscreen_map_screen.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/nearby/place_details_sheet.dart';
import 'package:petfriendly/features/nearby/place_rating.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'widget_test.dart' show MemoryPreferences;

class FailingPlaceReviewRepository extends DemoCommunityRepository {
  @override
  Future<String?> command(String action, Json values) async {
    if (action == 'place_review') throw StateError('Synthetic offline failure');
    return super.command(action, values);
  }
}

void main() {
  testWidgets('Inline favorites focus map; marker reviews preserve manual city', (
    tester,
  ) async {
    const place = Place(
      'review-park',
      'Тестовый сквер',
      'Парк',
      'Минск',
      null,
      0,
      'Публичный сквер.',
      'Допуск питомцев не уточнён',
      Icons.park_outlined,
      latitude: 53.9,
      longitude: 27.56,
      sourceId: 'node/test',
    );
    final prefs = MemoryPreferences();
    prefs.values.addAll({
      'favorites': place.id,
      'city': 'Гродно',
      'manualCity': 'true',
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          placesProvider.overrideWithValue(OsmPlaceRepository([place])),
        ],
        child: const PetFriendlyApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-4')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(StudioReviewRow, place.name),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.widgetWithText(StudioReviewRow, place.name), findsOneWidget);
    expect(find.text('Нет оценок'), findsNothing);
    await tester.ensureVisible(find.text(place.name));
    await tester.pumpAndSettle();
    await tester.tap(find.text(place.name));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Показать на карте'));
    await tester.pumpAndSettle();
    final focusedMap = tester.widget<FullscreenMapScreen>(
      find.byWidgetPredicate((w) => w is FullscreenMapScreen && !w.embedded),
    );
    expect(focusedMap.args.focusPlace, place);
    expect(focusedMap.args.city, 'Минск');
    expect(prefs.values['city'], 'Гродно');
    expect(prefs.values['manualCity'], 'true');
    // Simulate the native marker callback; Mapbox is unavailable in widget tests.
    tester.widget<LiveMap>(find.byType(LiveMap).last).onPlace(place);
    await tester.pumpAndSettle();
    expect(find.textContaining('OpenStreetMap'), findsNothing);
    expect(find.byKey(const Key('inline-place-review')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('open-place-review')));
    await tester.tap(find.byKey(const Key('open-place-review')));
    await tester.pumpAndSettle();
    final reviewContext = tester.element(find.byTooltip('4 из 5'));
    expect(
      Navigator.of(reviewContext),
      Navigator.of(reviewContext, rootNavigator: true),
    );
    expect(
      tester.getRect(find.byType(ModalBarrier).last),
      Offset.zero & tester.view.physicalSize / tester.view.devicePixelRatio,
    );
    await tester.ensureVisible(find.byTooltip('4 из 5'));
    await tester.tap(find.byTooltip('4 из 5'));
    await tester.enterText(
      find.byKey(const Key('inline-place-review')),
      'Хорошие дорожки',
    );
    await tester.ensureVisible(find.text('Опубликовать отзыв'));
    await tester.tap(find.text('Опубликовать отзыв'));
    await tester.pumpAndSettle();
    expect(find.text('Хорошие дорожки'), findsOneWidget);
    expect(find.text('4,0'), findsWidgets);
    expect(find.byKey(const Key('inline-place-review')), findsNothing);
    await tester.ensureVisible(find.text('Показать на карте'));
    await tester.tap(find.text('Показать на карте'));
    await tester.pumpAndSettle();
    final screen = tester.widget<FullscreenMapScreen>(
      find.byWidgetPredicate((w) => w is FullscreenMapScreen && !w.embedded),
    );
    expect(screen.args.focusPlace, place);
    expect(screen.args.city, 'Минск');
    expect(prefs.values['city'], 'Гродно');
    expect(prefs.values['manualCity'], 'true');
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Revealed review stays inline and retains draft and rating after failure',
    (tester) async {
      const place = Place(
        'draft-park',
        'Парк',
        'Парк',
        'Минск',
        null,
        0,
        'Публичное место.',
        'Допуск не уточнён',
        Icons.park_outlined,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(MemoryPreferences()),
            communityRepositoryProvider.overrideWithValue(
              FailingPlaceReviewRepository(),
            ),
            placeFeedbackProvider.overrideWith(
              (ref, id) async => const PlaceFeedback([], null),
            ),
          ],
          child: MaterialApp(
            theme: studioTheme(Brightness.light),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showPlace(context, place),
                  child: const Text('Открыть'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Открыть'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('inline-place-review')), findsNothing);
      final barriersBefore = find.byType(ModalBarrier).evaluate().length;
      await tester.tap(find.byKey(const Key('open-place-review')));
      await tester.pumpAndSettle();
      expect(find.byType(PlaceDetailsSheet), findsOneWidget);
      expect(find.byType(ModalBarrier).evaluate().length, barriersBefore);
      await tester.ensureVisible(find.byTooltip('3 из 5'));
      await tester.tap(find.byTooltip('3 из 5'));
      await tester.enterText(
        find.byKey(const Key('inline-place-review')),
        'Черновик отзыва',
      );
      await tester.ensureVisible(find.text('Опубликовать отзыв'));
      await tester.tap(find.text('Опубликовать отзыв'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Не удалось отправить'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('inline-place-review')))
            .controller!
            .text,
        'Черновик отзыва',
      );
      expect(find.text('Оценка: 3 из 5. Можно публиковать.'), findsOneWidget);
      expect(find.byKey(const Key('open-place-review')), findsNothing);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Опубликовать отзыв'),
            )
            .onPressed,
        isNotNull,
      );
    },
  );
}
