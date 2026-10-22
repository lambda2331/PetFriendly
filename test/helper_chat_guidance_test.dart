import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/features/chat/new_chat_screen.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/nearby/city_catalog.dart';
import 'package:petfriendly/features/walks/account_mode.dart';
import 'package:petfriendly/features/walks/helper_requests_screen.dart';
import 'widget_test.dart' show EmptyCatalog, MemoryPreferences;

void main() {
  testWidgets(
    'Empty chats open an explicit conversation picker in both account modes',
    (tester) async {
      final account = DemoAccountModeRepository();
      await account.chooseRole('both', mode: 'helper');
      final prefs = MemoryPreferences()..values['language'] = 'ru';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountModeRepositoryProvider.overrideWithValue(account),
            communityRepositoryProvider.overrideWithValue(
              DemoCommunityRepository(seedSamples: false),
            ),
            preferencesProvider.overrideWithValue(prefs),
            cityCatalogServiceProvider.overrideWithValue(EmptyCatalog()),
          ],
          child: const PetFriendlyApp(),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(StudioShell)),
      );
      final router = container.read(routerProvider);
      router.go('/chats');
      await tester.pumpAndSettle();
      expect(find.text('Пока нет переписок'), findsOneWidget);
      expect(find.text('Найдите человека и начните разговор.'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Новая переписка'));
      await tester.pumpAndSettle();
      expect(find.byType(NewChatScreen), findsOneWidget);
      expect(find.byKey(const Key('message-input')), findsNothing);
      expect(
        container.read(communityProvider).value!['conversations'],
        isEmpty,
      );
      Navigator.of(tester.element(find.byType(NewChatScreen))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('nav-5')));
      await tester.pumpAndSettle();
      expect(find.byType(RequestsScreen), findsOneWidget);
      await container.read(accountModeProvider.notifier).switchMode('owner');
      router.go('/chats');
      await tester.pumpAndSettle();
      expect(find.text('Пока нет переписок'), findsOneWidget);
      await tester.tap(find.widgetWithText(OutlinedButton, 'Новая переписка'));
      await tester.pumpAndSettle();
      expect(find.byType(NewChatScreen), findsOneWidget);
      expect(
        container.read(communityProvider).value!['conversations'],
        isEmpty,
      );
      Navigator.of(tester.element(find.byType(NewChatScreen))).pop();
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('nav-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav-5')), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
