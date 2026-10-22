import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/walks/walks_screen.dart';
import 'package:petfriendly/features/walks/owner_profile_screen.dart';
import 'package:petfriendly/features/walks/walking_form_drafts.dart';
import 'helper_profile_design_test.dart' show ProfileFixture;

class WalkingFixture extends ProfileFixture {
  WalkingFixture({super.account = 'self', String status = 'completed'})
    : super('helper') {
    data['walk_requests'] = [
      {
        'id': 'walk',
        'owner_id': 'self',
        'pet_id': 'pet',
        'status': status,
        'starts_at': '2026-10-12T09:00:00Z',
        'city': 'Минск',
        'time_zone': 'Europe/Minsk',
        'district': 'Публичный район',
        'duration': 30,
      },
    ];
    data['pets'] = [
      {'id': 'pet', 'name': 'Луна'},
    ];
    data['walk_agreements'] = [
      {'request_id': 'walk', 'helper_id': 'helper'},
    ];
    data['walk_details'] = [
      {
        'request_id': 'walk',
        'instructions': 'Синтетические приватные инструкции',
      },
    ];
    data['walk_reviews'] = [];
  }
  int reviews = 0;
  bool failReview = true;
  @override
  Future<String?> command(String action, Json values) async {
    if (action == 'review_walk' || action == 'reply_walk_owner_review') {
      reviews++;
      if (failReview) throw StateError('synthetic offline');
      data['walk_reviews']!.add({
        'id': 'saved-review',
        'request_id': 'walk',
        'author_id': 'self',
        'helper_id': 'helper',
        'published': true,
        'rating': values['rating_in'],
        'body': values['body_in'],
      });
      return null;
    }
    return super.command(action, values);
  }
}

Future<void> mount(
  WidgetTester tester,
  WalkingFixture fixture, {
  bool detail = false,
}) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => detail
            ? const WalkDetailScreen(id: 'walk')
            : Scaffold(
                body: TextButton(
                  onPressed: () => showWalkingReviewSheet(context, id: 'walk'),
                  child: const Text('Открыть отзыв'),
                ),
              ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [communityRepositoryProvider.overrideWithValue(fixture)],
      child: MaterialApp.router(
        theme: studioTheme(Brightness.light),
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final account in ['self', 'helper', 'stranger']) {
    testWidgets('Static private instructions only for participant $account', (
      tester,
    ) async {
      await mount(
        tester,
        WalkingFixture(account: account, status: 'assigned'),
        detail: true,
      );
      expect(
        find.text('Синтетические приватные инструкции'),
        account == 'stranger' ? findsNothing : findsOneWidget,
      );
      expect(find.byType(ExpansionTile), findsNothing);
      expect(find.text('Публичный район'), findsOneWidget);
      expect(find.textContaining('Europe/Minsk'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'Successful eligible review closes one sheet and clears its draft',
    (tester) async {
      final fixture = WalkingFixture()..failReview = false;
      await mount(tester, fixture);
      await tester.tap(find.text('Открыть отзыв'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('walking-review-star-5')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        'Опубликованный синтетический отзыв',
      );
      await tester.ensureVisible(find.text('Опубликовать'));
      await tester.tap(find.text('Опубликовать'));
      await tester.pumpAndSettle();
      expect(fixture.reviews, 1);
      expect(find.byType(ReviewScreen), findsNothing);
      expect(find.text('Открыть отзыв'), findsOneWidget);
      final context = tester.element(find.text('Открыть отзыв'));
      expect(
        ProviderScope.containerOf(context).read(walkingFormDraftsProvider),
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Review sheet retains eligible draft after failed publication and reopening',
    (tester) async {
      final fixture = WalkingFixture();
      await mount(tester, fixture);
      await tester.tap(find.text('Открыть отзыв'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('walking-review-star-5')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Синтетический черновик');
      await tester.ensureVisible(find.text('Опубликовать'));
      await tester.tap(find.text('Опубликовать'));
      await tester.pumpAndSettle();
      expect(fixture.reviews, 1);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Синтетический черновик',
      );
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Открыть отзыв'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Синтетический черновик',
      );
      expect(
        tester
            .widget<IconButton>(
              find.byKey(const ValueKey('walking-review-star-5')),
            )
            .isSelected,
        true,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Unconfirmed agreement keeps review submission disabled', (
    tester,
  ) async {
    final fixture = WalkingFixture(status: 'awaiting_confirmation');
    await mount(tester, fixture);
    await tester.tap(find.text('Открыть отзыв'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, false);
    final submit = find.ancestor(
      of: find.text('Опубликовать'),
      matching: find.byType(FilledButton),
    );
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    expect(fixture.reviews, 0);
  });
  testWidgets(
    'Owner reply starts with existing text and retains edits after failure',
    (tester) async {
      final fixture = WalkingFixture();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [communityRepositoryProvider.overrideWithValue(fixture)],
          child: MaterialApp(
            theme: studioTheme(Brightness.light),
            home: Scaffold(
              body: OwnerReviewReply(
                review: const {
                  'id': 'owner-review',
                  'owner_reply': 'Существующий ответ',
                },
                onSaved: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ответить'), findsNothing);
      await tester.tap(find.text('Изменить ответ'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Существующий ответ',
      );
      await tester.enterText(find.byType(TextField), 'Исправленный ответ');
      await tester.tap(find.text('Опубликовать ответ'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Исправленный ответ',
      );
      expect(fixture.reviews, 1);
    },
  );
  for (final brightness in Brightness.values) {
    testWidgets('Review form reflows at 320 and 200 percent: $brightness', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communityRepositoryProvider.overrideWithValue(WalkingFixture()),
          ],
          child: MaterialApp(
            theme: studioTheme(brightness),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const ReviewScreen(id: 'walk', embedded: true),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Опубликовать'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  test(
    'Walking form drafts reset on internal account change and separate recipients',
    () {
      final container = ProviderContainer(
        overrides: [
          communityRepositoryProvider.overrideWithValue(WalkingFixture()),
        ],
      );
      addTearDown(container.dispose);
      container
          .read(walkingFormDraftsProvider.notifier)
          .keep('review:helper:one', text: 'Первый', rating: 5);
      container
          .read(walkingFormDraftsProvider.notifier)
          .keep('review:owner:one', text: 'Другой участник', rating: 4);
      expect(container.read(walkingFormDraftsProvider).length, 2);
      container.updateOverrides([
        communityRepositoryProvider.overrideWithValue(
          WalkingFixture(account: 'another'),
        ),
      ]);
      expect(container.read(walkingFormDraftsProvider), isEmpty);
    },
  );
}
