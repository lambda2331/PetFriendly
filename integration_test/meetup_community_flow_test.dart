import 'support/native_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/chat/chat_repository.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/nearby/city_catalog.dart';
import '../test/widget_test.dart' show MemoryPreferences, EmptyCatalog;

Future<void> press(WidgetTester tester, Finder target) async {
  await tapNativeReady(tester, target);
}

Future<void> nativeBack(WidgetTester tester) async {
  await press(tester, find.byType(BackButton).hitTestable().first);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Native meetup and community joining and predictable chat Back in both themes',
    (tester) async {
      for (final theme in [ThemeMode.light, ThemeMode.dark]) {
        final repo = DemoCommunityRepository();
        final group = repo.data['groups']!.first;
        final groupId = group['id'] as String;
        // These are public fixture venues, never a user's live location.
        final event = repo.data['events']!.first;
        event.addAll({
          'latitude': 53.901,
          'longitude': 27.56,
          'location_label': 'У центрального входа в сквер',
        });
        final eventId = event['id'] as String;
        const eventChatId = '00000000-0000-4000-8000-000000000091';
        repo.data['conversations']!.add({
          'id': eventChatId,
          'kind': 'event',
          'context_id': eventId,
        });
        final chats = DemoChatRepository();
        chats.send(eventChatId, 'petfriendly://group/$groupId');
        final prefs = MemoryPreferences()
          ..values.addAll({
            'theme': theme.name,
            'language': 'ru',
            'city': 'Минск',
            'manualCity': 'true',
          });
        final container = ProviderContainer(
          overrides: [
            preferencesProvider.overrideWithValue(prefs),
            communityRepositoryProvider.overrideWithValue(repo),
            chatRepositoryProvider.overrideWithValue(chats),
            cityCatalogServiceProvider.overrideWithValue(EmptyCatalog()),
          ],
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const PetFriendlyApp(),
          ),
        );
        await tester.pumpAndSettle();
        final router = container.read(routerProvider);
        final prefix = 'native-${theme.name}';
        // Discover the complete meetup list from Nearby, rather than its banner.
        await press(tester, find.byKey(const Key('nearby-all-meetups')));
        expect(router.state.uri.path, '/events');
        await binding.takeScreenshot('$prefix-meetups-ios');
        await press(tester, find.byKey(ValueKey('meetup-$eventId')));
        expect(router.state.uri.path, '/event/$eventId');
        expect(find.byKey(ValueKey('meetup-map-$eventId')), findsOneWidget);
        await press(
          tester,
          find.widgetWithText(FilledButton, 'Присоединиться'),
        );
        expect(
          repo.data['event_members']!.where(
            (m) => m['event_id'] == eventId && m['user_id'] == repo.userId,
          ),
          hasLength(1),
        );
        await binding.takeScreenshot('$prefix-meetup-joined-ios');
        for (var repeat = 0; repeat < 2; repeat++) {
          await press(tester, find.byKey(ValueKey('meetup-chat-$eventId')));
          expect(find.byKey(const Key('message-input')), findsOneWidget);
          expect(find.byKey(const Key('chat-context-link')), findsNothing);
          expect(find.text('Открыть сообщество'), findsNothing);
          final chatPath = router.state.uri.path;
          await press(tester, find.byTooltip('О переписке'));
          expect(router.state.uri.path, chatPath);
          await press(
            tester,
            find.widgetWithText(PopupMenuItem<String>, 'О переписке'),
          );
          expect(router.state.uri.path, chatPath);
          if (repeat == 0) {
            await binding.takeScreenshot('$prefix-meetup-chat-ios');
          }
          // Read-only chat context is a sheet, never another event/group route.
          await press(tester, find.byTooltip('Закрыть').hitTestable().last);
          await nativeBack(tester);
          expect(router.state.uri.path, '/event/$eventId');
        }
        await nativeBack(tester);
        expect(router.state.uri.path, '/events');
        await press(tester, find.byKey(const ValueKey('nav-0')));
        expect(router.state.uri.path, '/nearby');
        expect(container.read(prototypeProvider).city, 'Минск');
        expect(container.read(prototypeProvider).manualCity, isTrue);
        // Separate People / Communities segments remain the existing navigation.
        await press(tester, find.byKey(const ValueKey('nav-1')));
        await press(tester, find.text('Сообщества'));
        await binding.takeScreenshot('$prefix-communities-ios');
        await press(tester, find.byKey(ValueKey('community-$groupId')));
        await press(tester, find.byKey(const Key('community-membership')));
        expect(
          repo.data['group_members']!.where(
            (m) => m['group_id'] == groupId && m['user_id'] == repo.userId,
          ),
          hasLength(1),
        );
        await binding.takeScreenshot('$prefix-community-joined-ios');
        final groupChat = repo.data['conversations']!.firstWhere(
          (c) => c['kind'] == 'group' && c['context_id'] == groupId,
        );
        chats.send(groupChat['id'] as String, 'petfriendly://group/$groupId');
        for (var repeat = 0; repeat < 2; repeat++) {
          await press(tester, find.byKey(const Key('community-chat')));
          expect(find.byKey(const Key('message-input')), findsOneWidget);
          expect(find.byKey(const Key('chat-context-link')), findsNothing);
          expect(find.text('Открыть сообщество'), findsNothing);
          final chatPath = router.state.uri.path;
          await press(tester, find.byTooltip('О переписке'));
          expect(router.state.uri.path, chatPath);
          await press(
            tester,
            find.widgetWithText(PopupMenuItem<String>, 'О переписке'),
          );
          expect(router.state.uri.path, chatPath);
          if (repeat == 0) {
            await binding.takeScreenshot('$prefix-community-chat-ios');
          }
          await press(tester, find.byTooltip('Закрыть').hitTestable().last);
          await nativeBack(tester);
          expect(router.state.uri.path, '/people');
          expect(find.byKey(const Key('community-chat')), findsOneWidget);
        }
        await press(tester, find.byTooltip('Закрыть').hitTestable().last);
        expect(router.state.uri.path, '/people');
        await press(tester, find.byKey(const ValueKey('nav-3')));
        for (final row in [group, event]) {
          await press(tester, find.text(row['title'] as String));
          expect(find.byKey(const Key('message-input')), findsOneWidget);
          await nativeBack(tester);
          expect(router.state.uri.path, '/chats');
          expect(router.canPop(), isFalse);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        container.dispose();
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
