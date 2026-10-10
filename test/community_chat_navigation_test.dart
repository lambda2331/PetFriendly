import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/features/chat/chat_repository.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'widget_test.dart' show MemoryPreferences;

void main() {
  testWidgets(
    'Community chat cannot push its community again and back remains predictable',
    (tester) async {
      final repository = DemoCommunityRepository();
      final id = repository.data['groups']!.first['id'];
      await repository.command('join_group', {'group_in': id});
      final chats = DemoChatRepository();
      final chatId = repository.data['conversations']!.first['id'] as String;
      chats.send(chatId, 'petfriendly://group/$id');
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
      final router = container.read(routerProvider);
      router.go('/group/$id');
      await tester.pumpAndSettle();
      for (var attempt = 0; attempt < 3; attempt++) {
        await tester.ensureVisible(find.text('Открыть чат сообщества'));
        await tester.tap(find.text('Открыть чат сообщества'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('message-input')), findsOneWidget);
        expect(find.byKey(const Key('chat-context-link')), findsNothing);
        expect(find.text('Открыть сообщество'), findsNothing);
        expect(find.text('Открыть приглашение'), findsNothing);
        await tester.tap(find.byType(BackButton).hitTestable());
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/group/$id');
      }
      expect(tester.takeException(), isNull);
    },
  );
}
