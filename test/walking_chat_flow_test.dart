import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/chat/chat_screen.dart';
import 'package:petfriendly/features/chat/conversation_context.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/walks/walking_repository.dart';
import 'package:petfriendly/features/walks/walking_chat_controller.dart';
import 'package:petfriendly/features/walks/walking_chat_report.dart';
import 'package:petfriendly/l10n/localization.dart';

class ChatWalkFixture implements CommunityRepository {
  ChatWalkFixture({
    this.account = 'helper',
    this.member = true,
    this.instructions = 'SYNTHETIC PRIVATE',
  });
  String account;
  String instructions;
  bool member, fail = false, failLoad = false;
  int transitions = 0, reports = 0;
  Completer<void>? barrier;
  String status = 'assigned';
  Json? reportValues;
  @override
  String get userId => account;
  @override
  bool get isDemo => false;
  @override
  Future<CommunityData> load() async {
    if (failLoad) throw StateError('Synthetic snapshot failure');
    return {
      'conversations': [
        {'id': 'chat', 'kind': 'walk', 'context_id': 'walk'},
      ],
      'conversation_members': [
        if (member) {'conversation_id': 'chat', 'user_id': account},
      ],
      'walk_requests': [
        {'id': 'walk', 'owner_id': 'owner', 'status': status},
      ],
      'walk_agreements': [
        {'request_id': 'walk', 'helper_id': 'helper'},
      ],
      'walk_details': [
        {'request_id': 'walk', 'instructions': instructions},
      ],
    };
  }

  @override
  Future<String?> command(String action, Json values) async {
    if (action == 'report') {
      reports++;
      reportValues = values;
    }
    if (action == 'advance_walk') transitions++;
    await barrier?.future;
    if (fail) throw StateError('Synthetic failure');
    if (action == 'advance_walk') status = '${values['next_status']}';
    return null;
  }
}

class ChatWalkRepository extends WalkingRepository {
  ChatWalkRepository(super.ref, this.fixture);
  final ChatWalkFixture fixture;
  @override
  Future<List<Json>> list({
    String? city,
    String? district,
    String? size,
    DateTime? from,
    DateTime? until,
    String view = 'active',
    int offset = 0,
  }) async => [
    {
      'id': 'walk',
      'owner_id': 'owner',
      'my_role': fixture.account,
      'status': fixture.status,
      'starts_at': '2026-10-12T09:00:00Z',
      'time_zone': 'Europe/Minsk',
      'city': 'Минск',
      'district': 'Public district',
      'duration': 45,
      'pet': {'id': 'pet', 'name': 'Synthetic pet'},
      'owner': {'display_name': 'Synthetic owner'},
      'helper': {'display_name': 'Synthetic helper'},
      'allowed_actions': [
        if (fixture.account == 'helper' && fixture.status == 'assigned')
          'start',
        if (fixture.account == 'helper' && fixture.status == 'in_progress')
          'finish',
        if (fixture.account == 'owner' &&
            fixture.status == 'awaiting_confirmation')
          'confirm',
        if (fixture.status == 'completed')
          fixture.account == 'owner' ? 'review_helper' : 'review_owner',
      ],
    },
  ];
}

ProviderContainer setup(ChatWalkFixture fixture) => ProviderContainer(
  overrides: [
    communityRepositoryProvider.overrideWithValue(fixture),
    walkingRepositoryProvider.overrideWith(
      (ref) => ChatWalkRepository(ref, fixture),
    ),
  ],
);
void main() {
  test('Walk route context no longer pushes a walk detail screen', () {
    expect(
      ConversationContext.fromConversation({
        'kind': 'walk',
        'context_id': 'walk',
      }),
      isNull,
    );
    expect(
      ConversationContext.fromConversation({
        'kind': 'group',
        'context_id': 'group',
      }),
      isNull,
    );
    expect(
      ConversationContext.fromConversation({
        'kind': 'event',
        'context_id': 'event',
      }),
      isNull,
    );
  });
  test(
    'Only member participants receive private details and eligible actions',
    () async {
      for (final fixture in [
        ChatWalkFixture(member: false),
        ChatWalkFixture(account: 'outsider'),
      ]) {
        final container = setup(fixture);
        addTearDown(container.dispose);
        await container.read(walkingChatProvider.notifier).load('chat');
        expect(
          container.read(walkingChatProvider).records['chat']!.item,
          isNull,
        );
        expect(
          container.read(walkingChatProvider).records['chat']!.instructions,
          isNull,
        );
        await container
            .read(walkingChatProvider.notifier)
            .advance('chat', 'start');
        expect(fixture.transitions, 0);
      }
      expect(
        walkingChatNextAction({
          'my_role': 'owner',
          'status': 'assigned',
          'allowed_actions': ['start'],
        }),
        isNull,
      );
      expect(
        walkingChatNextAction({
          'my_role': 'helper',
          'status': 'awaiting_confirmation',
          'allowed_actions': ['confirm'],
        }),
        isNull,
      );
    },
  );
  test(
    'Atomic next actions refresh authoritative status, failed retry and duplicates',
    () async {
      final fixture = ChatWalkFixture();
      final container = setup(fixture);
      addTearDown(container.dispose);
      final controller = container.read(walkingChatProvider.notifier);
      await controller.load('chat');
      expect(
        container.read(walkingChatProvider).records['chat']!.instructions,
        'SYNTHETIC PRIVATE',
      );
      fixture.barrier = Completer<void>();
      final first = controller.advance('chat', 'start');
      await controller.advance('chat', 'start');
      expect(fixture.transitions, 1);
      fixture.barrier!.complete();
      await first;
      fixture.barrier = null;
      expect(
        container.read(walkingChatProvider).records['chat']!.item!['status'],
        'in_progress',
      );
      fixture.fail = true;
      await controller.advance('chat', 'finish');
      expect(
        container.read(walkingChatProvider).records['chat']!.actionError,
        isNotNull,
      );
      fixture.fail = false;
      await controller.advance('chat', 'finish');
      expect(
        container.read(walkingChatProvider).records['chat']!.item!['status'],
        'awaiting_confirmation',
      );
      expect(
        walkingChatNextAction(
          container.read(walkingChatProvider).records['chat']!.item!,
        ),
        isNull,
      );
      fixture.failLoad = true;
      await controller.load('chat');
      expect(
        container.read(walkingChatProvider).records['chat']!.instructions,
        isNull,
      );
      expect(
        container.read(walkingChatProvider).records['chat']!.error,
        isNotNull,
      );
      fixture.failLoad = false;
      fixture.member = false;
      await controller.load('chat');
      expect(
        container.read(walkingChatProvider).records['chat']!.instructions,
        isNull,
      );
    },
  );
  test(
    'Report free-text contract preserves retry draft and prevents duplicate submission',
    () async {
      final fixture = ChatWalkFixture();
      final container = setup(fixture);
      addTearDown(container.dispose);
      final controller = container.read(walkingChatProvider.notifier);
      await controller.load('chat');
      controller.editReport(
        'chat',
        reason: walkingReportReasons.first,
        note: 'Synthetic note',
      );
      fixture.fail = true;
      await controller.report('chat');
      expect(
        container.read(walkingChatProvider).reports['chat']!.note,
        'Synthetic note',
      );
      fixture.fail = false;
      fixture.barrier = Completer<void>();
      final retry = controller.report('chat');
      await controller.report('chat');
      expect(fixture.reports, 2);
      fixture.barrier!.complete();
      await retry;
      await controller.report('chat');
      expect(fixture.reports, 2);
      expect(fixture.reportValues, {
        'target_kind': 'walk',
        'target_id': 'walk',
        'reason': '${walkingReportReasons.first}\n\nSynthetic note',
      });
    },
  );
  test(
    'Account replacement drops report drafts and late command results',
    () async {
      final fixture = ChatWalkFixture();
      final container = setup(fixture);
      addTearDown(container.dispose);
      final controller = container.read(walkingChatProvider.notifier);
      await controller.load('chat');
      controller.editReport(
        'chat',
        reason: walkingReportReasons.first,
        note: 'Old account draft',
      );
      fixture.barrier = Completer<void>();
      final pending = controller.report('chat');
      final replacement = ChatWalkFixture(account: 'owner');
      container.updateOverrides([
        communityRepositoryProvider.overrideWithValue(replacement),
        walkingRepositoryProvider.overrideWith(
          (ref) => ChatWalkRepository(ref, replacement),
        ),
      ]);
      expect(container.read(walkingChatProvider).reports, isEmpty);
      fixture.barrier!.complete();
      await pending;
      expect(container.read(walkingChatProvider).reports, isEmpty);
      expect(container.read(walkingChatProvider).records, isEmpty);
    },
  );
  testWidgets(
    'Compact enlarged chat with keyboard preserves composer and scrolls logistics',
    (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = ChatWalkFixture();
      final container = setup(fixture);
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: studioTheme(Brightness.dark),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(2),
                viewInsets: const EdgeInsets.only(bottom: 220),
              ),
              child: child!,
            ),
            home: const ChatScreen(id: 'chat'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byKey(const Key('walking-chat-context')), findsOneWidget);
    },
  );
  testWidgets(
    'Details header stays fixed while long authorized handover scrolls',
    (tester) async {
      final fixture = ChatWalkFixture(
        instructions: List.filled(
          30,
          'Synthetic authorized instructions for this agreement only.',
        ).join('\n'),
      );
      final container = setup(fixture);
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: studioTheme(Brightness.light),
            home: const ChatScreen(id: 'chat'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('walking-chat-counterpart-avatar')),
        findsOneWidget,
      );
      expect(find.text('Договорённость о выгуле'), findsNothing);
      await tester.tap(find.byKey(const Key('walking-chat-details')));
      await tester.pumpAndSettle();
      final header = find.byKey(const Key('walking-sheet-header'));
      final start = tester.getTopLeft(header);
      await tester.drag(
        find.byKey(const Key('walking-sheet-scroll')),
        const Offset(0, -360),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(header), start);
      expect(find.byTooltip('Закрыть').hitTestable(), findsOneWidget);
      await tester.tap(find.byTooltip('Закрыть'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('walking-chat-status')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Details and report sheets retain chat draft and have no navigation cycle',
    (tester) async {
      final fixture = ChatWalkFixture();
      final container = setup(fixture);
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: studioTheme(Brightness.light),
            home: const ChatScreen(id: 'chat'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).first,
        'Synthetic chat draft',
      );
      await tester.tap(find.byKey(const Key('walking-chat-status')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('walking-chat-action-start')));
      await tester.pumpAndSettle();
      expect(find.text('Synthetic chat draft'), findsOneWidget);
      expect(
        find.byKey(const Key('walking-chat-action-finish')),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Закрыть'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('walking-chat-details')));
      await tester.pumpAndSettle();
      expect(find.text('SYNTHETIC PRIVATE'), findsOneWidget);
      expect(find.text('Europe/Minsk'), findsNothing);
      expect(find.textContaining('Минск, Public district'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('walking-sheet-scroll')),
          matching: find.textContaining('45 минут'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('UTC+3'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('walking-sheet-scroll')),
          matching: find.text('Synthetic owner'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('walking-sheet-scroll')),
          matching: find.text('Synthetic helper'),
        ),
        findsOneWidget,
      );
      expect(find.text('Заметка владельца'), findsNothing);
      await tester.tap(find.byTooltip('Закрыть'));
      await tester.pumpAndSettle();
      expect(find.text('Synthetic chat draft'), findsOneWidget);
      await tester.tap(find.byTooltip('О переписке'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('walking-chat-report')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(walkingReportReasons.last));
      await tester.enterText(
        find.byKey(const Key('walking-report-note')),
        'Synthetic report draft',
      );
      await tester.tap(find.byTooltip('Закрыть'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('О переписке'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('walking-chat-report')));
      await tester.pumpAndSettle();
      expect(find.text('Synthetic report draft'), findsOneWidget);
      await tester.tap(find.byTooltip('Закрыть'));
      await tester.pumpAndSettle();
      expect(find.text('Synthetic chat draft'), findsOneWidget);
      expect(find.byKey(const Key('chat-context-link')), findsNothing);
    },
  );
}
