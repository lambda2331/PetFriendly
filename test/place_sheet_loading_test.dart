import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/nearby/place_repository.dart';
import 'package:petfriendly/features/nearby/place_rating.dart';
import 'package:petfriendly/features/nearby/place_details_sheet.dart';
import 'widget_test.dart' show MemoryPreferences;

void main() {
  testWidgets(
    'Reviews resolve before the fitted sheet opens without a loading jump',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const place = Place(
        'loading-park',
        'Тестовый парк',
        'Парк',
        'Минск',
        null,
        0,
        'Публичное место.',
        'Допуск питомцев не уточнён',
        Icons.park_outlined,
        latitude: 53.9,
        longitude: 27.56,
      );
      final feedback = Completer<PlaceFeedback>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(MemoryPreferences()),
            placeFeedbackProvider.overrideWith((ref, id) => feedback.future),
            placeRatingProvider.overrideWith(
              (ref, place) =>
                  ref.watch(placeFeedbackProvider(place.id)).hasValue
                  ? const PlaceRating(4, 1)
                  : null,
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
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      expect(find.byKey(const Key('place-sheet-frame')), findsNothing);
      expect(find.text('Открываем место…'), findsOneWidget);
      // Repeated taps while preparing must not stack duplicate sheets.
      await tester.tap(find.text('Открыть'));
      feedback.complete(
        PlaceFeedback([
          {
            'id': 'review',
            'author_id': 'synthetic',
            'rating': 4,
            'body': 'Синтетический отзыв для проверки поздней загрузки.',
            'created_at': '2026-10-10T10:00:00Z',
          },
        ], null),
      );
      await tester.pumpAndSettle();
      final frame = tester.getRect(find.byKey(const Key('place-sheet-frame')));
      final action = tester.getRect(find.text('Показать на карте'));
      expect(find.byType(PlaceDetailsSheet), findsOneWidget);
      expect(frame.height, lessThanOrEqualTo(844 * .86));
      expect(find.text('Загружаем отзывы…'), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.getRect(find.byKey(const Key('place-sheet-frame'))), frame);
      expect(tester.getRect(find.text('Показать на карте')), action);
      expect(find.text('4,0'), findsOneWidget);
      expect(find.byKey(const Key('inline-place-review')), findsNothing);
      expect(
        tester
            .getTopLeft(
              find.text('Синтетический отзыв для проверки поздней загрузки.'),
            )
            .dy,
        lessThan(
          tester.getTopLeft(find.byKey(const Key('open-place-review'))).dy,
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Синтетический отзыв для проверки поздней загрузки.'),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Short place sheet ends after content, retaining the safe inset',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.viewPadding = const FakeViewPadding(bottom: 34);
      addTearDown(tester.view.reset);
      const place = Place(
        'short',
        'Парк',
        'Парк',
        'Минск',
        null,
        0,
        'Публичное место.',
        'Допуск питомцев не уточнён',
        Icons.park_outlined,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(MemoryPreferences()),
            placeFeedbackProvider.overrideWith(
              (ref, id) async => const PlaceFeedback([], {
                'id': 'own-review',
                'rating': 4,
                'body': 'Хороший парк.',
              }),
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
      final frame = tester.getRect(find.byKey(const Key('place-sheet-frame')));
      final lastText = tester.getRect(find.text('Хороший парк.'));
      expect(find.byKey(const Key('open-place-review')), findsNothing);
      expect(find.byKey(const Key('inline-place-review')), findsNothing);
      expect(frame.height, lessThan(844 * .88));
      // Shared sheet: 34px safe inset and 20px body/footer padding.
      expect(frame.bottom - lastText.bottom, closeTo(54, 1));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Cancelling a slow open releases it and ignores late reviews', (
    tester,
  ) async {
    final feedback = Completer<PlaceFeedback>();
    const place = Place(
      'cancel',
      'Парк',
      'Парк',
      'Минск',
      null,
      0,
      'Публичное место.',
      'Допуск питомцев не уточнён',
      Icons.park_outlined,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(MemoryPreferences()),
          placeFeedbackProvider.overrideWith((ref, id) => feedback.future),
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
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();
    feedback.complete(const PlaceFeedback([], null));
    await tester.pumpAndSettle();
    expect(find.byType(PlaceDetailsSheet), findsNothing);
    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();
    expect(find.byType(PlaceDetailsSheet), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final brightness in Brightness.values) {
    testWidgets(
      'Place actions and review remain usable at large text: $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        const place = Place(
          'accessible',
          'Тестовый парк',
          'Парк',
          'Минск',
          null,
          0,
          'Публичное место.',
          'Допуск питомцев не уточнён',
          Icons.park_outlined,
          latitude: 53.9,
          longitude: 27.56,
          sourceId: 'node/test',
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              preferencesProvider.overrideWithValue(MemoryPreferences()),
              placeFeedbackProvider.overrideWith(
                (ref, id) async => const PlaceFeedback([], null),
              ),
            ],
            child: MaterialApp(
              theme: studioTheme(brightness),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
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
        final map = tester.getRect(find.text('Показать на карте'));
        final correction = tester.getRect(find.text('Уточнить данные'));
        expect(correction.top, greaterThan(map.bottom));
        expect(find.byKey(const Key('inline-place-review')), findsNothing);
        await tester.scrollUntilVisible(
          find.byKey(const Key('open-place-review')),
          160,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(find.byKey(const Key('open-place-review')));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byTooltip('4 из 5'));
        await tester.tap(find.byTooltip('4 из 5'));
        await tester.pumpAndSettle();
        expect(find.text('Оценка: 4 из 5. Можно публиковать.'), findsOneWidget);
        final publish = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Опубликовать отзыв'),
        );
        expect(publish.onPressed, isNotNull);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
