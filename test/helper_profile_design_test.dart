import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/walks/walks_screen.dart';
import 'package:petfriendly/features/walks/reply_drafts.dart';

class ProfileFixture implements CommunityRepository {
  ProfileFixture(
    this.helper, {
    this.account = 'self',
    bool stats = true,
    bool present = true,
  }) {
    data = {
      'profiles': [
        if (present)
          {
            'id': helper,
            'display_name': 'Синтетический помощник с длинным именем',
            'district': 'Тестовый район',
            'about': 'Синтетическое описание опыта прогулок.',
          },
        {'id': 'author', 'display_name': 'Автор синтетического отзыва'},
      ],
      'helper_ratings': [
        if (stats)
          {'id': helper, 'rating': 4.5, 'review_count': 2, 'completed': 7},
      ],
      'walk_reviews': [
        {
          'id': 'old',
          'helper_id': helper,
          'author_id': 'author',
          'published': true,
          'rating': 4,
          'body': 'Первый синтетический отзыв.',
          'created_at': '2026-01-01T12:00:00Z',
        },
        {
          'id': 'recent',
          'helper_id': helper,
          'author_id': 'author',
          'published': true,
          'rating': 5,
          'body': 'Последний синтетический отзыв.',
          'created_at': '2026-02-01T12:00:00Z',
        },
        {
          'id': 'hidden',
          'helper_id': helper,
          'author_id': 'author',
          'published': false,
          'rating': 5,
          'body': 'Скрытый отзыв.',
          'created_at': '2026-03-01T12:00:00Z',
        },
      ],
    };
  }
  final String helper, account;
  late CommunityData data;
  Completer<String?>? replyGate, chatGate;
  bool failReply = false, failBlock = false;
  int replyCalls = 0, chatCalls = 0, blockCalls = 0;
  @override
  String get userId => account;
  @override
  bool get isDemo => false;
  @override
  Future<CommunityData> load() async => {
    for (final entry in data.entries)
      entry.key: [
        for (final row in entry.value) {...row},
      ],
  };
  @override
  Future<String?> command(String action, Json values) async {
    if (action == 'reply_walk_review') {
      replyCalls++;
      if (failReply) throw StateError('synthetic offline');
      if (replyGate != null) await replyGate!.future;
      final review = data['walk_reviews']!.firstWhere(
        (r) => r['id'] == values['review_in'],
      );
      review['helper_reply'] = values['body_in'];
      review['replied_at'] = '2026-02-02T12:00:00Z';
      return null;
    }
    if (action == 'direct') {
      chatCalls++;
      return chatGate == null
          ? 'synthetic-conversation'
          : await chatGate!.future;
    }
    if (action == 'block') {
      blockCalls++;
      if (failBlock) throw StateError('synthetic offline');
      return null;
    }
    throw StateError('unexpected fixture action');
  }
}

Future<void> mountProfile(
  WidgetTester tester,
  ProfileFixture fixture, {
  Brightness brightness = Brightness.light,
  double scale = 1,
}) async {
  if (scale == 1) {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }
  final router = GoRouter(
    initialLocation: '/walks',
    routes: [
      GoRoute(
        path: '/helper',
        builder: (_, _) => HelperScreen(id: fixture.helper),
      ),
      GoRoute(
        path: '/helper/preferences',
        builder: (_, _) => const Scaffold(body: Text('Редактор помощника')),
      ),
      GoRoute(
        path: '/walks',
        builder: (context, _) => Scaffold(
          body: Column(
            children: [
              const Text('Запросы на выгул'),
              TextButton(
                onPressed: () => context.push('/helper'),
                child: const Text('Открыть профиль'),
              ),
            ],
          ),
        ),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (_, state) =>
            Scaffold(body: Text('Чат ${state.pathParameters['id']}')),
      ),
      GoRoute(
        path: '/report/:kind/:id',
        builder: (_, state) =>
            Scaffold(body: Text('Жалоба ${state.pathParameters['kind']}')),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [communityRepositoryProvider.overrideWithValue(fixture)],
      child: MaterialApp.router(
        theme: studioTheme(brightness),
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Открыть профиль'));
  await tester.pumpAndSettle();
}

void main() {
  test('Reply drafts reset when the internal account changes', () async {
    final container = ProviderContainer(
      overrides: [
        communityRepositoryProvider.overrideWithValue(ProfileFixture('self')),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(reviewReplyDraftsProvider.notifier)
        .keep('recent', 'Черновик первого аккаунта');
    expect(
      container.read(reviewReplyDraftsProvider)['recent']!.text,
      'Черновик первого аккаунта',
    );
    container.updateOverrides([
      communityRepositoryProvider.overrideWithValue(
        ProfileFixture('other', account: 'another-account'),
      ),
    ]);
    await container.pump();
    expect(container.read(reviewReplyDraftsProvider), isEmpty);
  });

  testWidgets(
    'Back and reopen preserve an unpublished reply in the same session',
    (tester) async {
      await mountProfile(tester, ProfileFixture('self'));
      await tester.ensureVisible(find.text('Ответить').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ответить').first);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('reply-input-recent')),
        'Черновик после возврата',
      );
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Открыть профиль'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ответить').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ответить').first);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('reply-input-recent')))
            .controller!
            .text,
        'Черновик после возврата',
      );
    },
  );

  testWidgets('Back and reopen cannot duplicate a pending reply publication', (
    tester,
  ) async {
    final fixture = ProfileFixture('self')..replyGate = Completer<String?>();
    await mountProfile(tester, fixture);
    await tester.ensureVisible(find.text('Ответить').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ответить').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('reply-input-recent')),
      'Ответ ожидает публикации',
    );
    await tester.ensureVisible(find.text('Опубликовать ответ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Опубликовать ответ'));
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Открыть профиль'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Публикуем…'));
    await tester.pumpAndSettle();
    final pending = find.ancestor(
      of: find.text('Публикуем…'),
      matching: find.byType(OutlinedButton),
    );
    expect(tester.widget<OutlinedButton>(pending).onPressed, isNull);
    await tester.tap(pending);
    expect(fixture.replyCalls, 1);
    fixture.replyGate!.complete(null);
    await tester.pumpAndSettle();
    expect(find.text('Ответ ожидает публикации'), findsOneWidget);
    expect(find.text('Публикуем…'), findsNothing);
  });
  testWidgets(
    'Own helper profile offers editing and replies without self contact or profile menu',
    (tester) async {
      await mountProfile(tester, ProfileFixture('self'));
      expect(find.text('Ваш профиль помощника'), findsOneWidget);
      expect(find.text('Обсудить прогулку'), findsNothing);
      expect(find.byTooltip('Действия с профилем'), findsNothing);
      expect(find.text('Ответить'), findsNWidgets(2));
      expect(find.text('Скрытый отзыв.'), findsNothing);
      await tester.ensureVisible(find.text('Редактировать профиль'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Редактировать профиль'));
      await tester.pumpAndSettle();
      expect(find.text('Редактор помощника'), findsOneWidget);
    },
  );

  testWidgets(
    'Other helper has contact and labelled actions, never reply editor',
    (tester) async {
      await mountProfile(tester, ProfileFixture('other'));
      expect(find.text('Профиль помощника'), findsOneWidget);
      expect(find.text('Обсудить прогулку'), findsOneWidget);
      expect(find.byTooltip('Действия с профилем'), findsOneWidget);
      expect(find.text('Ответить'), findsNothing);
      expect(find.text('Найти запрос на выгул'), findsNothing);
    },
  );

  testWidgets(
    'Missing profile offers a useful return without fabricated identity/contact',
    (tester) async {
      await mountProfile(tester, ProfileFixture('absent', present: false));
      expect(find.text('Профиль недоступен'), findsOneWidget);
      expect(find.text('Обсудить прогулку'), findsNothing);
      expect(
        find.text('Синтетический помощник с длинным именем'),
        findsNothing,
      );
      await tester.tap(find.text('Назад'));
      await tester.pumpAndSettle();
      expect(find.text('Запросы на выгул'), findsOneWidget);
    },
  );

  testWidgets(
    'Missing production aggregates preserve known identity without zero totals',
    (tester) async {
      await mountProfile(tester, ProfileFixture('other', stats: false));
      expect(
        find.text('Синтетический помощник с длинным именем'),
        findsOneWidget,
      );
      expect(find.text('Отзывы недоступны'), findsOneWidget);
      expect(find.text('Опыт недоступен'), findsOneWidget);
      expect(find.text('Повторить загрузку опыта'), findsOneWidget);
      expect(find.text('0 завершённых выгулов'), findsNothing);
      expect(find.text('Пока нет отзывов'), findsNothing);
    },
  );

  testWidgets(
    'Reply failure retains draft; pending disables field and guards duplicate publication',
    (tester) async {
      final fixture = ProfileFixture('self')..failReply = true;
      await mountProfile(tester, fixture);
      await tester.ensureVisible(find.text('Ответить').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ответить').first);
      await tester.pumpAndSettle();
      final input = find.byKey(const ValueKey('reply-input-recent'));
      await tester.enterText(
        input,
        'Синтетический ответ с сохранённым черновиком',
      );
      await tester.ensureVisible(find.text('Опубликовать ответ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Опубликовать ответ'));
      await tester.pumpAndSettle();
      expect(
        find.text('Не удалось опубликовать. Проверьте соединение и повторите.'),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(input).controller!.text,
        'Синтетический ответ с сохранённым черновиком',
      );
      fixture.failReply = false;
      fixture.replyGate = Completer<String?>();
      await tester.ensureVisible(find.text('Опубликовать ответ'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Опубликовать ответ'));
      await tester.pump();
      expect(tester.widget<TextField>(input).enabled, false);
      expect(find.text('Публикуем…'), findsOneWidget);
      final pendingButton = find.ancestor(
        of: find.text('Публикуем…'),
        matching: find.byType(FilledButton),
      );
      await tester.tap(pendingButton);
      await tester.pump();
      expect(fixture.replyCalls, 2);
      fixture.replyGate!.complete(null);
      await tester.pumpAndSettle();
      expect(find.text('Ответ опубликован'), findsOneWidget);
      expect(
        find.text('Синтетический ответ с сохранённым черновиком'),
        findsOneWidget,
      );
      expect(find.text('Изменить ответ'), findsOneWidget);
    },
  );

  testWidgets('Contact pending is guarded and failed creation can retry', (
    tester,
  ) async {
    final fixture = ProfileFixture('other')..chatGate = Completer<String?>();
    await mountProfile(tester, fixture);
    await tester.ensureVisible(find.text('Обсудить прогулку'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Обсудить прогулку'));
    await tester.pump();
    await tester.tap(
      find.ancestor(
        of: find.text('Открываем чат…'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(fixture.chatCalls, 1);
    fixture.chatGate!.completeError(StateError('synthetic offline'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        'Не удалось открыть переписку. Проверьте соединение и попробуйте снова.',
      ),
      findsOneWidget,
    );
    fixture.chatGate = null;
    await tester.ensureVisible(find.text('Обсудить прогулку'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Обсудить прогулку'));
    await tester.pumpAndSettle();
    expect(fixture.chatCalls, 2);
    expect(find.text('Чат synthetic-conversation'), findsOneWidget);
  });

  testWidgets(
    'Blocking requires confirmation and a failure remains recoverable',
    (tester) async {
      final fixture = ProfileFixture('other')..failBlock = true;
      await mountProfile(tester, fixture);
      await tester.ensureVisible(find.byTooltip('Действия с профилем'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Действия с профилем'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Заблокировать'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Отмена'));
      await tester.pumpAndSettle();
      expect(fixture.blockCalls, 0);
      await tester.tap(find.byTooltip('Действия с профилем'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Заблокировать'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Заблокировать'));
      await tester.pumpAndSettle();
      expect(fixture.blockCalls, 1);
      expect(find.text('Повторить блокировку'), findsOneWidget);
      expect(
        find.text(
          'Не удалось заблокировать пользователя. Проверьте соединение и попробуйте снова.',
        ),
        findsOneWidget,
      );
    },
  );

  for (final brightness in Brightness.values) {
    for (final helper in ['self', 'other']) {
      testWidgets(
        'Helper $helper reflows at 320 and 2x in ${brightness.name}',
        (tester) async {
          tester.view.physicalSize = const Size(320, 850);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await mountProfile(
            tester,
            ProfileFixture(helper),
            brightness: brightness,
            scale: 2,
          );
          await tester.scrollUntilVisible(
            find.byKey(const ValueKey('walking-review-recent')),
            300,
            scrollable: find.byType(Scrollable).first,
          );
          await tester.pumpAndSettle();
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          if (helper == 'self') {
            expect(find.text('Обсудить прогулку'), findsNothing);
          } else {
            expect(find.text('Ответить'), findsNothing);
          }
        },
      );
    }
  }
}
