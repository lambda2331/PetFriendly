import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/walks/helper_reputation.dart';
import 'package:petfriendly/features/walks/walking_profile_components.dart';

void main() {
  testWidgets('Rating announces its scale rather than a bare number', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(Brightness.light),
        home: const Scaffold(
          body: WalkingExperienceSummary(
            reputation: HelperReputation(4.8, 12, 18),
          ),
        ),
      ),
    );
    expect(find.bySemanticsLabel('Средняя оценка 4,8 из 5'), findsOneWidget);
    semantics.dispose();
  });
  testWidgets(
    'Missing average with published reviews does not claim no reviews',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(Brightness.light),
          home: const Scaffold(
            body: WalkingExperienceSummary(
              reputation: HelperReputation(null, 2, 3),
            ),
          ),
        ),
      );
      expect(find.text('Оценка недоступна'), findsOneWidget);
      expect(find.text('2 отзыва · опубликовано'), findsOneWidget);
      expect(find.text('Пока нет отзывов'), findsNothing);
    },
  );
  for (final brightness in Brightness.values) {
    testWidgets(
      'Unavailable facts stay distinct from new helper: $brightness',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(brightness),
            home: const Scaffold(
              body: WalkingExperienceSummary(
                reputation: HelperReputation(null, null, null),
              ),
            ),
          ),
        );
        expect(find.text('Отзывы недоступны'), findsOneWidget);
        expect(find.text('Опыт недоступен'), findsOneWidget);
        expect(find.text('Пока нет отзывов'), findsNothing);
        expect(find.text('0'), findsNothing);
      },
    );
    testWidgets(
      'Short but wrapped review remains expandable at 320px/2x: $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(320, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: studioTheme(brightness),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: const Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: WalkingReviewTile(
                      preview: true,
                      review: {
                        'id': 'r',
                        'author_id': 'a',
                        'rating': 5,
                        'created_at': '2026-10-10T10:00:00Z',
                        'body':
                            'Спасибо за спокойную прогулку. Луна вернулась довольной. Всё прошло хорошо.',
                      },
                      author: {
                        'display_name': 'Александра Константинопольская',
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final body = tester.widget<Text>(
          find.textContaining('Спасибо за спокойную'),
        );
        expect(body.maxLines, 3);
        expect(find.text('Читать полностью'), findsOneWidget);
        await tester.ensureVisible(find.text('Читать полностью'));
        await tester.tap(find.text('Читать полностью'));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<Text>(find.textContaining('Спасибо за спокойную'))
              .maxLines,
          isNull,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
