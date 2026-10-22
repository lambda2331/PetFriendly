import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/chat/chat_repository.dart';
import 'package:petfriendly/features/chat/chat_screen.dart';
import 'package:petfriendly/features/chat/inbox_repository.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';

class ControlledCommunity extends CommunityController {
  ControlledCommunity(this.result);
  final Future<CommunityData> result;
  @override
  Future<CommunityData> build() => result;
}

void main() {
  test(
    'Unread counts exclude own messages and preserve incoming after cursor',
    () {
      final before = DateTime.utc(2026, 10, 9, 10);
      final after = before.add(const Duration(minutes: 1));
      final messages = [
        ChatMessage('Прочитано', sentAt: before),
        ChatMessage('Мой ответ', mine: true, sentAt: after),
        ChatMessage('Новое сообщение', sentAt: after),
      ];
      final entry = demoInboxEntry('a', messages, before);
      expect(entry.unread, 1);
      expect(entry.preview, 'Новое сообщение');
      expect(demoInboxEntry('a', messages, null).unread, 2);
      expect(demoInboxEntry('a', messages, after).unread, 0);
    },
  );

  test(
    'Inbox sorts by actual last activity with stable empty-thread order',
    () {
      final newer = DateTime.utc(2026, 10, 9);
      final entries = sortInbox([
        const InboxEntry(id: 'z'),
        InboxEntry(
          id: 'old',
          lastActivity: newer.subtract(const Duration(days: 1)),
        ),
        const InboxEntry(id: 'a'),
        InboxEntry(id: 'new', lastActivity: newer),
      ]);
      expect(entries.map((e) => e.id), ['new', 'old', 'a', 'z']);
    },
  );

  testWidgets('Loading and failure never announce an empty inbox', (
    tester,
  ) async {
    final community = Completer<CommunityData>();
    final inbox = StreamController<List<InboxEntry>>();
    addTearDown(inbox.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityProvider.overrideWith(
            () => ControlledCommunity(community.future),
          ),
          chatInboxProvider.overrideWith((ref) => inbox.stream),
        ],
        child: MaterialApp(
          theme: studioTheme(Brightness.light),
          home: const Scaffold(body: ChatsScreen()),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Пока нет переписок'), findsNothing);
    community.complete({});
    inbox.addError(StateError('offline'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Повторить'), findsOneWidget);
    expect(find.text('Пока нет переписок'), findsNothing);
    inbox.add([]);
    await tester.pumpAndSettle();
    expect(find.text('Пока нет переписок'), findsOneWidget);
    expect(find.text('Новая переписка'), findsOneWidget);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'Empty inbox scrolls at 320px with enlarged text: $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(320, 520);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              communityProvider.overrideWith(
                () => ControlledCommunity(Future.value({})),
              ),
              chatInboxProvider.overrideWith(
                (ref) => Stream.value(<InboxEntry>[]),
              ),
            ],
            child: MaterialApp(
              theme: studioTheme(brightness),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: const Scaffold(body: ChatsScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byTooltip('Новая переписка'), findsOneWidget);
        await tester.ensureVisible(find.text('Новая переписка'));
        await tester.pumpAndSettle();
        expect(find.text('Пока нет переписок'), findsOneWidget);
        expect(
          tester.getRect(find.text('Новая переписка')).bottom,
          lessThanOrEqualTo(520),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Fetch failure keeps available preview and unread evidence', (
    tester,
  ) async {
    final inbox = StreamController<List<InboxEntry>>();
    addTearDown(inbox.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          communityProvider.overrideWith(
            () => ControlledCommunity(Future.value({})),
          ),
          chatInboxProvider.overrideWith((ref) => inbox.stream),
        ],
        child: MaterialApp(
          theme: studioTheme(Brightness.dark),
          home: const Scaffold(body: ChatsScreen()),
        ),
      ),
    );
    inbox.add([
      InboxEntry(
        id: 'anna',
        preview: 'Встретимся у парка?',
        unread: 2,
        lastActivity: DateTime.utc(2026, 10, 9),
      ),
    ]);
    await tester.pumpAndSettle();
    inbox.addError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(find.text('Встретимся у парка?'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
    expect(find.text('Пока нет переписок'), findsNothing);
  });

  testWidgets('Long preview and unread label reflow at 320 with enlarged text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(Brightness.light),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: ListView(
              children: [
                InboxRow(
                  entry: InboxEntry(
                    id: 'a',
                    unread: 120,
                    preview:
                        'Очень длинное сообщение о прогулке и встрече у входа в парк',
                    lastActivity: DateTime.utc(2026, 10, 9),
                  ),
                  title: 'Соседи с питомцами и совместные прогулки',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
