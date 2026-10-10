import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/ui/components.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/nearby/place_repository.dart';
import 'package:petfriendly/features/nearby/place_rating.dart';
import 'package:petfriendly/features/nearby/place_details_sheet.dart';
import 'widget_test.dart' show MemoryPreferences;

void main() {
  testWidgets('Empty metadata consumes no line height', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              Text('Above'),
              MetadataLine(items: ['', '  ']),
              Text('Below'),
            ],
          ),
        ),
      ),
    );
    expect(
      tester.getRect(find.text('Above')).bottom,
      tester.getRect(find.text('Below')).top,
    );
  });

  testWidgets(
    'Missing place data leaves no action row, metadata or empty heading',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      const place = Place(
        'sparse',
        'Место',
        '',
        '',
        null,
        0,
        '',
        '',
        Icons.place_outlined,
        pending: true,
        city: '',
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
      expect(find.byKey(const Key('place-metadata')), findsNothing);
      expect(find.text('Показать на карте'), findsNothing);
      expect(find.text('Уточнить данные'), findsNothing);
      expect(find.text('Отзывы'), findsNothing);
      final frame = tester.getRect(find.byKey(const Key('place-sheet-frame')));
      final last = tester.getRect(
        find.text('Отзывы станут доступны после публикации места.'),
      );
      expect(frame.bottom - last.bottom, closeTo(16, 1));
      expect(frame.height, lessThan(400));
      expect(tester.takeException(), isNull);
    },
  );
}
