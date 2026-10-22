import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/backend/backend.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/chat/chat_repository.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/nearby/city_catalog.dart';
import 'widget_test.dart' show MemoryPreferences, EmptyCatalog;

void main() {
  testWidgets(
    'QA chat accepted Unicode input must send or remain recoverable',
    (tester) async {
      final repo = DemoCommunityRepository();
      final cid = await repo.command('direct', {'target': demoAnna});
      final chats = DemoChatRepository(seedMessages: false);
      final container = ProviderContainer(
        overrides: [
          backendProvider.overrideWithValue(null),
          preferencesProvider.overrideWithValue(MemoryPreferences()),
          communityRepositoryProvider.overrideWithValue(repo),
          chatRepositoryProvider.overrideWithValue(chats),
          cityCatalogServiceProvider.overrideWithValue(EmptyCatalog()),
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
      container.read(routerProvider).push('/chat/$cid');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('message-input')),
        'QA ASCII control',
      );
      await tester.tap(find.byKey(const Key('send-message')));
      await tester.pumpAndSettle();
      expect(
        chats.messages(cid!).any((m) => m.text == 'QA ASCII control'),
        isTrue,
      );
      final text = List.filled(501, '🐕').join();
      await tester.enterText(find.byKey(const Key('message-input')), text);
      await tester.pumpAndSettle();
      final field = tester.widget<TextField>(
        find.byKey(const Key('message-input')),
      );
      expect(
        field.controller!.text,
        text,
        reason: 'accepted 501 visible characters',
      );

      await tester.tap(find.byKey(const Key('send-message')));
      await tester.pumpAndSettle();

      final sent = chats.messages(cid).any((m) => m.text == text);
      final retained = field.controller!.text == text;

      expect(sent, isTrue, reason: '501 emoji are 501 server characters');
      expect(retained, isFalse);
      final oversized = List.filled(501, '👨‍👩‍👧‍👦').join();
      await tester.enterText(find.byKey(const Key('message-input')), oversized);
      await tester.tap(find.byKey(const Key('send-message')));
      await tester.pumpAndSettle();
      expect(
        field.controller!.text,
        oversized,
        reason: 'Rejected draft stays recoverable',
      );
      expect(chats.messages(cid).any((m) => m.text == oversized), isFalse);
      expect(
        find.text('Сообщение должно быть не длиннее 1000 символов'),
        findsOneWidget,
      );
      expect(find.byTooltip('Добавить фото'), findsOneWidget);
    },
  );
}
