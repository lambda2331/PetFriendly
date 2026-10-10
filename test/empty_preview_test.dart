import 'package:flutter/material.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/walks/walks_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/chat/chat_repository.dart';
import 'package:petfriendly/features/chat/inbox_repository.dart';

void main() {
  testWidgets('Empty walking preview has one message and no orphan headings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityRepositoryProvider.overrideWithValue(
            DemoCommunityRepository(seedSamples: false),
          ),
        ],
        child: MaterialApp(
          theme: studioTheme(Brightness.light),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const Scaffold(body: WalksScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Помощники'), findsNothing);
    expect(find.text('Запросы на прогулку'), findsNothing);
    expect(find.text('Пока нет запросов на прогулку.'), findsOneWidget);
    expect(
      find.text('Демонстрационные данные · PetFriendly 0.1'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
  test(
    'Unseeded preview starts without pretend social activity and accepts own groups',
    () async {
      final repo = DemoCommunityRepository(seedSamples: false);
      final data = await repo.load();
      for (final key in [
        'pets',
        'groups',
        'events',
        'walk_requests',
        'conversations',
      ]) {
        expect(rows(data, key), isEmpty);
      }
      expect(
        rows(data, 'profiles').single['display_name'],
        'Новый пользователь',
      );
      final container = ProviderContainer(
        overrides: [communityRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      container.listen(chatInboxProvider, (_, _) {});
      expect(await container.read(chatInboxProvider.future), isEmpty);
      expect(
        container.read(chatRepositoryProvider).messages('unknown'),
        isEmpty,
      );
      final group = await container.read(communityProvider.notifier).command(
        'group',
        {'title_in': 'Моя группа'},
      );
      final chats = await container.read(chatInboxProvider.future);
      expect(chats, hasLength(1));
      expect(
        container.read(chatRepositoryProvider).messages(chats.single.id),
        isEmpty,
      );
      expect(group, isNotNull);
    },
  );
}
