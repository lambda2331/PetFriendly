import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/chat/chat_repository.dart';
import 'package:petfriendly/features/chat/conversation_context.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'widget_test.dart' show MemoryPreferences;

Future<GoRouter> mountNavigationApp(
  WidgetTester tester,
  DemoCommunityRepository repository,
  DemoChatRepository chats,
) async {
  final container = ProviderContainer(
    overrides: [
      communityRepositoryProvider.overrideWithValue(repository),
      chatRepositoryProvider.overrideWithValue(chats),
      preferencesProvider.overrideWithValue(MemoryPreferences()),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const PetFriendlyApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container.read(routerProvider);
}

Future<void> expectReadOnlyChat(
  WidgetTester tester, {
  required String title,
  required String kindLabel,
  required GoRouter router,
}) async {
  expect(find.byKey(const Key('message-input')), findsOneWidget);
  expect(
    find.descendant(of: find.byType(AppBar), matching: find.text(title)),
    findsOneWidget,
  );
  expect(find.byTooltip('О переписке'), findsOneWidget);
  expect(find.byKey(const Key('chat-context-link')), findsNothing);
  expect(find.text('Открыть сообщество'), findsNothing);
  expect(find.text('Открыть встречу'), findsNothing);
  expect(find.text('Открыть приглашение'), findsNothing);
  final chatRoute = router.state.uri.path;
  expect(chatRoute, startsWith('/chat/'));
  // Header actions and context never push community/event routes.
  for (var i = 0; i < 3; i++) {
    for (final target in [
      find.descendant(of: find.byType(AppBar), matching: find.text(title)),
      find.byKey(const Key('chat-readonly-context')),
    ]) {
      await tester.tap(target);
      await tester.pumpAndSettle();
      expect(router.state.uri.path, chatRoute);
      if (find.byType(PopupMenuItem<String>).evaluate().isNotEmpty) {
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const Key('message-input')), findsOneWidget);
      expect(router.state.uri.path, chatRoute);
    }
  }
  expect(find.text('Анна'), findsWidgets);
  expect(find.textContaining('Вы ·'), findsWidgets);
  expect(find.textContaining(RegExp(r'\d{1,2}:\d{2}')), findsWidgets);
}

Future<void> back(WidgetTester tester) async {
  await tester.tap(
    find
        .byWidgetPredicate(
          (w) =>
              w is BackButton ||
              w is IconButton &&
                  w.icon is Icon &&
                  (w.icon as Icon).icon == LucideIcons.arrowLeft,
        )
        .hitTestable()
        .first,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'Community → chat → Back restores the same community without cycles',
    (tester) async {
      final repository = DemoCommunityRepository();
      final group = repository.data['groups']!.first;
      final id = group['id'] as String;
      await repository.command('join_group', {'group_in': id});
      final conversation = repository.data['conversations']!.firstWhere(
        (c) => c['kind'] == 'group' && c['context_id'] == id,
      );
      final chats = DemoChatRepository();
      chats.send(conversation['id'] as String, 'petfriendly://group/$id');
      final router = await mountNavigationApp(tester, repository, chats);
      router.go('/people');
      await tester.pumpAndSettle();
      router.push('/group/$id');
      await tester.pumpAndSettle();
      for (var attempt = 0; attempt < 3; attempt++) {
        await tester.ensureVisible(
          find.byKey(const ValueKey('community-chat')),
        );
        await tester.tap(find.byKey(const ValueKey('community-chat')));
        await tester.pumpAndSettle();
        await expectReadOnlyChat(
          tester,
          title: group['title'] as String,
          kindLabel: 'Сообщество',
          router: router,
        );
        await back(tester);
        expect(router.state.uri.path, '/group/$id');
        expect(find.byKey(const Key('message-input')), findsNothing);
      }
      await back(tester);
      expect(router.state.uri.path, '/people');
      expect(router.canPop(), isFalse);
      expect(
        repository.data['group_members']!.where(
          (m) => m['group_id'] == id && m['user_id'] == repository.userId,
        ),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Meetup → chat → Back restores meetup, then original meetup list',
    (tester) async {
      final repository = DemoCommunityRepository();
      final event = repository.data['events']!.first;
      final id = event['id'] as String;
      await repository.command('join_event', {'event_in': id});
      final chatId =
          repository.data['conversations']!.firstWhere(
                (c) => c['kind'] == 'event' && c['context_id'] == id,
              )['id']
              as String;
      final chats = DemoChatRepository();
      final groupId = repository.data['groups']!.first['id'];
      chats.send(chatId, 'petfriendly://group/$groupId');
      chats.send(chatId, 'petfriendly://event/$id');
      final router = await mountNavigationApp(tester, repository, chats);
      router.go('/events');
      await tester.pumpAndSettle();
      router.push('/event/$id');
      await tester.pumpAndSettle();
      for (var attempt = 0; attempt < 3; attempt++) {
        final action = find.byKey(ValueKey('meetup-chat-$id'));
        await tester.ensureVisible(action);
        await tester.tap(action);
        await tester.pumpAndSettle();
        await expectReadOnlyChat(
          tester,
          title: event['title'] as String,
          kindLabel: 'Встреча',
          router: router,
        );
        await back(tester);
        expect(router.state.uri.path, '/event/$id');
      }
      await back(tester);
      expect(router.state.uri.path, '/events');
      expect(router.canPop(), isFalse);
      expect(
        repository.data['event_members']!.where(
          (m) => m['event_id'] == id && m['user_id'] == repository.userId,
        ),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Opening group and meetup chats from Chats returns only to Chats',
    (tester) async {
      final repository = DemoCommunityRepository();
      final group = repository.data['groups']!.first;
      await repository.command('join_group', {'group_in': group['id']});
      final event = repository.data['events']!.first;
      await repository.command('join_event', {'event_in': event['id']});
      final router = await mountNavigationApp(
        tester,
        repository,
        DemoChatRepository(),
      );
      router.go('/chats');
      await tester.pumpAndSettle();
      for (final row in [group, event]) {
        final title = row['title'] as String;
        await tester.ensureVisible(find.text(title));
        await tester.tap(find.text(title));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('message-input')), findsOneWidget);
        expect(find.byKey(const Key('chat-context-link')), findsNothing);
        await back(tester);
        expect(router.state.uri.path, '/chats');
        expect(router.canPop(), isFalse);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Direct-chat invitation has no community route and never joins automatically',
    (tester) async {
      final repository = DemoCommunityRepository();
      final groupId = repository.data['groups']!.first['id'] as String;
      final chatId = await repository.command('direct', {'target': demoAnna});
      final chats = DemoChatRepository();
      chats.send(chatId!, 'petfriendly://group/$groupId');
      final router = await mountNavigationApp(tester, repository, chats);
      router.go('/chats');
      await tester.pumpAndSettle();
      router.push('/chat/$chatId');
      await tester.pumpAndSettle();
      expect(find.text('Открыть сообщество'), findsNothing);
      expect(router.state.uri.path, '/chat/$chatId');
      expect(
        repository.data['group_members']!.any(
          (m) => m['group_id'] == groupId && m['user_id'] == repository.userId,
        ),
        isFalse,
      );
      expect(find.byKey(const Key('message-input')), findsOneWidget);
      await back(tester);
      expect(router.state.uri.path, '/chats');
      expect(router.canPop(), isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  test('Community, meetup and walking chats do not push context routes', () {
    for (final kind in ['group', 'event']) {
      expect(
        ConversationContext.fromConversation({
          'kind': kind,
          'context_id': 'id',
        }),
        isNull,
      );
    }
    final walk = ConversationContext.fromConversation({
      'kind': 'walk',
      'context_id': 'agreement id',
    });
    expect(walk, isNull);
  });
}
