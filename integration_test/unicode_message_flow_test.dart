import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/backend/backend.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/chat/chat_repository.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/nearby/city_catalog.dart';
import 'localization_flow_test.dart' show MemoryPreferences, EmptyCatalog;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
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
      if (Platform.isAndroid) {
        await binding.convertFlutterSurfaceToImage();
        await tester.pumpAndSettle();
      }
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
      final group = repo.data['groups']!.first['id'];
      final invitation = 'petfriendly://group/$group';
      await tester.enterText(
        find.byKey(const Key('message-input')),
        invitation,
      );
      await tester.tap(find.byKey(const Key('send-message')));
      await tester.pumpAndSettle();
      expect(find.text('Открыть сообщество'), findsNothing);
      expect(container.read(routerProvider).state.uri.path, '/chat/$cid');
      expect(chats.messages(cid).any((m) => m.text == invitation), isTrue);
      expect(find.byTooltip('Добавить фото'), findsOneWidget);
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
      await binding.takeScreenshot('qa-unicode-before');
      await tester.tap(find.byKey(const Key('send-message')));
      await tester.pumpAndSettle();
      await binding.takeScreenshot('qa-unicode-after');
      final sent = chats.messages(cid).any((m) => m.text == text);
      final retained = field.controller!.text == text;
      expect(sent, isTrue);
      expect(retained, isFalse);
      final oversized = List.filled(501, '👨‍👩‍👧‍👦').join();
      await tester.enterText(find.byKey(const Key('message-input')), oversized);
      await tester.tap(find.byKey(const Key('send-message')));
      await tester.pumpAndSettle();
      expect(field.controller!.text, oversized);
      expect(chats.messages(cid).any((m) => m.text == oversized), isFalse);
    },
  );
  testWidgets('QA create-meetup labels remain readable at 200% text', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final container = ProviderContainer(
      overrides: [
        backendProvider.overrideWithValue(null),
        preferencesProvider.overrideWithValue(MemoryPreferences()),
        communityRepositoryProvider.overrideWithValue(
          DemoCommunityRepository(),
        ),
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
    container.read(routerProvider).push('/edit/event');
    await tester.pumpAndSettle();
    if (Platform.isAndroid) {
      await binding.convertFlutterSurfaceToImage();
      await tester.pumpAndSettle();
    }
    await binding.takeScreenshot('qa-meetup-labels-200percent');
    final label = find.text('Количество участников');
    expect(label, findsOneWidget);
    final clipped = tester
        .renderObject<RenderParagraph>(label)
        .didExceedMaxLines;
    expect(
      clipped,
      isFalse,
      reason: 'The visible input label must remain complete at enlarged text',
    );
  });
}
