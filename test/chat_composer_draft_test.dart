import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/chat/chat_composer_draft.dart';
import 'package:petfriendly/features/chat/chat_media.dart';
import 'package:petfriendly/features/chat/chat_screen.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/walks/walking_repository.dart';
import 'package:petfriendly/l10n/localization.dart';
import 'walking_chat_flow_test.dart' show ChatWalkFixture, ChatWalkRepository;

MediaDraft photo() => MediaDraft(
  bytes: base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
  ),
  kind: 'image',
  mime: 'image/png',
);

class DeferredPicker extends ChatMediaService {
  final result = Completer<MediaDraft?>();
  @override
  Future<MediaDraft?> pickImage() => result.future;
}

Future<void> open(
  WidgetTester tester,
  ProviderContainer container, {
  bool chat = true,
}) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: studioTheme(Brightness.light),
        home: chat
            ? const ChatScreen(id: 'chat')
            : const Scaffold(body: Text('Entry point')),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('Account replacement retires text/photos and rejects late writes', () {
    final fixture = ChatWalkFixture();
    final container = ProviderContainer(
      overrides: [communityRepositoryProvider.overrideWithValue(fixture)],
    );
    addTearDown(container.dispose);
    final old = container.read(chatComposerDraftsProvider);
    old.keep('chat', ChatComposerDraft(text: 'Old account', media: photo()));
    container.updateOverrides([
      communityRepositoryProvider.overrideWithValue(
        ChatWalkFixture(account: 'owner'),
      ),
    ]);
    final current = container.read(chatComposerDraftsProvider);
    expect(current.read('chat'), isNull);
    expect(old.active, isFalse);
    old.keep(
      'chat',
      ChatComposerDraft(text: 'Late old account', media: photo()),
    );
    expect(old.read('chat'), isNull);
    expect(current.read('chat'), isNull);
  });
  testWidgets(
    'Text and selected photo survive route exit/reentry; sending clears draft',
    (tester) async {
      final fixture = ChatWalkFixture();
      final picker = DeferredPicker();
      final container = ProviderContainer(
        overrides: [
          communityRepositoryProvider.overrideWithValue(fixture),
          walkingRepositoryProvider.overrideWith(
            (ref) => ChatWalkRepository(ref, fixture),
          ),
          chatMediaServiceProvider.overrideWithValue(picker),
        ],
      );
      addTearDown(container.dispose);
      await open(tester, container);
      await tester.enterText(
        find.byKey(const Key('message-input')),
        'Unsent synthetic text',
      );
      await tester.tap(find.byKey(const Key('attach-media')));
      await tester.pump();
      picker.result.complete(photo());
      await tester.pumpAndSettle();
      expect(
        container.read(chatComposerDraftsProvider).read('chat')!.media,
        isNotNull,
      );
      await open(tester, container, chat: false);
      await open(tester, container);
      expect(find.text('Unsent synthetic text'), findsOneWidget);
      expect(find.byTooltip('Убрать вложение'), findsOneWidget);
      await tester.tap(find.byTooltip('Убрать вложение'));
      await tester.pumpAndSettle();
      expect(
        container.read(chatComposerDraftsProvider).read('chat')!.media,
        isNull,
      );
      await tester.tap(find.byKey(const Key('send-message')));
      await tester.pumpAndSettle();
      expect(container.read(chatComposerDraftsProvider).read('chat'), isNull);
      // A photo-only send must clear memory even when text was already empty.
      await tester.tap(find.byKey(const Key('attach-media')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('send-message')));
      await tester.pumpAndSettle();
      expect(container.read(chatComposerDraftsProvider).read('chat'), isNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Late photo picker from old account cannot populate new composer',
    (tester) async {
      final fixture = ChatWalkFixture();
      final picker = DeferredPicker();
      final container = ProviderContainer(
        overrides: [
          communityRepositoryProvider.overrideWithValue(fixture),
          walkingRepositoryProvider.overrideWith(
            (ref) => ChatWalkRepository(ref, fixture),
          ),
          chatMediaServiceProvider.overrideWithValue(picker),
        ],
      );
      addTearDown(container.dispose);
      await open(tester, container);
      await tester.enterText(
        find.byKey(const Key('message-input')),
        'Old account text',
      );
      await tester.tap(find.byKey(const Key('attach-media')));
      await tester.pump();
      final replacement = ChatWalkFixture(account: 'owner');
      container.updateOverrides([
        communityRepositoryProvider.overrideWithValue(replacement),
        walkingRepositoryProvider.overrideWith(
          (ref) => ChatWalkRepository(ref, replacement),
        ),
        chatMediaServiceProvider.overrideWithValue(picker),
      ]);
      await tester.pump();
      await tester.pump();
      picker.result.complete(photo());
      await tester.pumpAndSettle();
      expect(find.text('Old account text'), findsNothing);
      expect(find.byTooltip('Убрать вложение'), findsNothing);
      expect(container.read(chatComposerDraftsProvider).read('chat'), isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
