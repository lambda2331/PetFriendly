import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/chat/chat_repository.dart';
import 'package:petfriendly/features/chat/chat_screen.dart';
import 'package:petfriendly/features/chat/conversation_context.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/walks/walk_progress.dart';

void main() {
  test('Every server workflow stage has a role-specific next step', () {
    final stages = [
      'open',
      'assigned',
      'in_progress',
      'awaiting_confirmation',
      'completed',
    ];
    for (var i = 0; i < stages.length; i++) {
      final owner = WalkProgress.forRequest(
        status: stages[i],
        owner: true,
        helper: false,
      );
      final helper = WalkProgress.forRequest(
        status: stages[i],
        owner: false,
        helper: true,
      );
      expect(owner.stage, i);
      expect(helper.stage, i);
      expect(owner.instruction, isNot(helper.instruction));
    }
    expect(
      WalkProgress.forRequest(
        status: 'assigned',
        owner: true,
        helper: false,
      ).instruction,
      contains('отмечает выбранный помощник'),
    );
    expect(
      WalkProgress.forRequest(
        status: 'awaiting_confirmation',
        owner: false,
        helper: true,
      ).instruction,
      contains('Дождитесь подтверждения владельца'),
    );
    expect(
      WalkProgress.forRequest(
        status: 'open',
        owner: false,
        helper: false,
        applied: true,
      ).instruction,
      contains('отклик отправлен'),
    );
    expect(
      WalkProgress.forRequest(
        status: 'completed',
        owner: true,
        helper: false,
        reviewed: true,
      ).instruction,
      contains('уже сохранён'),
    );
    expect(
      WalkProgress.forRequest(
        status: 'cancelled',
        owner: true,
        helper: false,
      ).stage,
      isNull,
    );
  });
  test(
    'Unrelated viewer receives status context without participant instruction',
    () {
      final value = WalkProgress.forRequest(
        status: 'assigned',
        owner: false,
        helper: false,
      );
      expect(value.instruction, contains('только её участники'));
    },
  );
  test(
    'Community chats omit return links; events and walks retain context',
    () {
      expect(
        ConversationContext.fromConversation({
          'kind': 'group',
          'context_id': 'group-id',
        }),
        isNull,
      );
      expect(
        ConversationContext.fromConversation({
          'kind': 'event',
          'context_id': 'event-id',
        })?.route,
        '/event/event-id',
      );
      expect(
        ConversationContext.fromConversation({
          'kind': 'walk',
          'context_id': 'request-id',
        })?.route,
        '/walk/request-id',
      );
      expect(
        ConversationContext.fromConversation({
          'kind': 'direct',
          'context_id': 'person',
        }),
        isNull,
      );
      expect(
        ConversationContext.fromConversation({
          'kind': 'walk',
          'context_id': '',
        }),
        isNull,
      );
      expect(ConversationContext.fromConversation(null), isNull);
    },
  );
  test('Walk chat is exposed only to owner or assigned helper', () {
    final data = {
      'walk_requests': [
        {'id': 'request', 'owner_id': 'owner'},
      ],
      'walk_agreements': [
        {'request_id': 'request', 'helper_id': 'helper'},
      ],
      'conversations': [
        {'id': 'chat', 'kind': 'walk', 'context_id': 'request'},
      ],
    };
    expect(walkConversationId(data, 'request', 'owner'), 'chat');
    expect(walkConversationId(data, 'request', 'helper'), 'chat');
    expect(walkConversationId(data, 'request', 'stranger'), isNull);
    expect(walkConversationId(data, 'request', null), isNull);
  });
  test(
    'Demo assignment creates contextual conversation like server assignment',
    () async {
      final repo = DemoCommunityRepository();
      final request = repo.data['walk_requests']!.first;
      request['owner_id'] = repo.userId;
      await repo.command('demo_application', {'request_in': request['id']});
      await repo.command('assign_walk', {
        'request_in': request['id'],
        'helper_in': demoSasha,
      });
      expect(
        walkConversationId(await repo.load(), request['id'], repo.userId),
        isNotNull,
      );
    },
  );
  testWidgets(
    'Opening context preserves chat draft and scroll when returning',
    (tester) async {
      final repository = DemoCommunityRepository();
      repository.data['conversations']!.add({
        'id': 'context-chat',
        'kind': 'walk',
        'context_id': 'request',
      });
      final messages = DemoChatRepository();
      for (var i = 0; i < 35; i++) {
        messages.send('context-chat', 'Сообщение $i');
      }
      final router = GoRouter(
        initialLocation: '/chat/context-chat',
        routes: [
          GoRoute(
            path: '/chat/:id',
            builder: (_, state) => ChatScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/walk/:id',
            builder: (_, _) => Scaffold(
              appBar: AppBar(title: const Text('Контекст прогулки')),
              body: const Text('Договорённость'),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communityRepositoryProvider.overrideWithValue(repository),
            chatRepositoryProvider.overrideWithValue(messages),
          ],
          child: MaterialApp.router(
            theme: studioTheme(Brightness.light),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('message-input')),
        'Черновик',
      );
      await tester.drag(find.byType(ListView), const Offset(0, -700));
      await tester.pumpAndSettle();
      final list = tester.widget<ListView>(find.byType(ListView));
      final before = list.controller!.offset;
      expect(before, greaterThan(0));
      await tester.tap(find.byKey(const Key('chat-context-link')));
      await tester.pumpAndSettle();
      expect(find.text('Контекст прогулки'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('message-input')))
            .controller!
            .text,
        'Черновик',
      );
      expect(
        tester.widget<ListView>(find.byType(ListView)).controller!.offset,
        before,
      );
    },
  );
}
