import 'package:go_router/go_router.dart';
import 'package:petfriendly/features/chat/chat_screen.dart';
import 'package:petfriendly/features/chat/new_chat_screen.dart';
import 'package:petfriendly/features/walks/walking_chat_widgets.dart';
import 'package:petfriendly/features/walks/walking_chat_controller.dart';
import 'package:petfriendly/l10n/localization.dart';
import 'walking_chat_flow_test.dart' as walking_fixture;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/core/ui/studio_pickers.dart';
import 'package:petfriendly/features/chat/chat_composer_draft.dart';
import 'package:petfriendly/features/chat/chat_repository.dart';
import 'package:petfriendly/features/chat/shared_content.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/community/presentation/meetup_controller.dart';
import 'widget_test.dart' show MemoryPreferences;

void main() {
  test(
    'Full meetings leave discovery, joined/owner details and unlimited remain',
    () async {
      final repo = DemoCommunityRepository();
      final id = await repo.command('event', {
        'title_in': 'Public event',
        'city_in': 'Минск',
        'starts_in': DateTime.now()
            .add(const Duration(days: 2))
            .toIso8601String(),
        'capacity_in': null,
        'duration_in': 90,
        'timezone_in': 'Europe/Minsk',
      });
      expect(findRow(repo.data, 'events', id)?['duration'], 90);
      expect(
        repo.data['conversations']!.where((c) => c['context_id'] == id),
        hasLength(1),
      );
      final item = findRow(repo.data, 'events', id)!;
      item['capacity'] = 1;
      final outsider = selectMeetups(
        repo.data,
        city: 'Минск',
        uid: demoAnna,
        filters: const MeetupFilters(),
        now: DateTime.now(),
      );
      expect(outsider.any((e) => e['id'] == id), false);
      expect(findRow(repo.data, 'events', id), isNotNull);
      expect(
        selectMeetups(
          repo.data,
          city: 'Минск',
          uid: repo.userId,
          filters: const MeetupFilters(),
          now: DateTime.now(),
        ).any((e) => e['id'] == id),
        true,
      );
      item['capacity'] = null;
      expect(
        selectMeetups(
          repo.data,
          city: 'Минск',
          uid: demoAnna,
          filters: const MeetupFilters(),
          now: DateTime.now(),
        ).any((e) => e['id'] == id),
        true,
      );
      expect(sharedRecord('note\npetfriendly://event/$id')?.id, id);
      expect(sharedRecord('https://untrusted.example/event/$id'), isNull);
    },
  );

  testWidgets(
    'Share preserves existing draft, sends explicitly and reopens exact event',
    (tester) async {
      final repo = DemoCommunityRepository();
      final chats = DemoChatRepository(seedMessages: false);
      await repo.command('direct', {'target': demoAnna});
      final container = ProviderContainer(
        overrides: [
          communityRepositoryProvider.overrideWithValue(repo),
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
      final event = repo.data['events']!.first,
          id = '${repo.data['events']!.first['id']}';
      final target =
          repo.data['conversations']!.firstWhere(
                (c) => c['kind'] == 'direct',
              )['id']
              as String;
      final router = container.read(routerProvider);
      container
          .read(chatComposerDraftsProvider)
          .keep(
            target,
            const ChatComposerDraft(text: 'Existing private draft'),
          );
      final before = repo.data['event_members']!.length;
      router.go('/events');
      await tester.pumpAndSettle();
      router.push('/event/$id');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Поделиться'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ValueKey('share-chat-$target')));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/chat/$target');
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('message-input')))
            .controller!
            .text,
        'Existing private draft',
      );
      expect(chats.messages(target), isEmpty);
      expect(
        container.read(chatComposerDraftsProvider).read(target)?.eventId,
        id,
      );
      await tester.tap(find.byKey(const Key('send-message')));
      await tester.pumpAndSettle();
      expect(sharedRecord(chats.messages(target).single.text)?.id, id);
      expect(container.read(chatComposerDraftsProvider).read(target), isNull);
      expect(repo.data['event_members']!.length, before);
      await tester.tap(
        find.widgetWithText(OutlinedButton, '${event['title']}'),
      );
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/event/$id');
      router.pop();
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/event/$id');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Filter dismissal cancels, Reset waits for Apply', (
    tester,
  ) async {
    int selected = 1;
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(Brightness.light),
        home: Builder(
          builder: (ctx) => Scaffold(
            body: TextButton(
              onPressed: () async {
                final result = await showStudioChoice<int>(
                  context: ctx,
                  title: 'Фильтры',
                  value: selected,
                  resetValue: 1,
                  options: [
                    (value: 1, label: 'Все'),
                    (value: 2, label: 'Сегодня'),
                  ],
                );
                if (result != null) selected = result;
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сегодня'));
    await tester.tap(find.byTooltip('Закрыть'));
    await tester.pumpAndSettle();
    expect(selected, 1);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сегодня'));
    await tester.tap(find.text('Применить'));
    await tester.pumpAndSettle();
    expect(selected, 2);
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сбросить'));
    expect(selected, 2);
    await tester.tap(find.text('Применить'));
    await tester.pumpAndSettle();
    expect(selected, 1);
  });

  testWidgets(
    '24-hour sheet cancel retains value and Done commits valid fields',
    (tester) async {
      var selected = const TimeOfDay(hour: 9, minute: 30);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(Brightness.dark),
          home: Builder(
            builder: (ctx) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  final result = await showStudioTimePicker(
                    context: ctx,
                    timeZone: 'Europe/Warsaw',
                    initialTime: selected,
                  );
                  if (result != null) selected = result;
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '23');
      await tester.tap(find.byTooltip('Закрыть'));
      await tester.pumpAndSettle();
      expect(selected.hour, 9);
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('09'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField).first, '24');
      await tester.tap(find.text('Готово'));
      await tester.pumpAndSettle();
      expect(selected.hour, 9);
      await tester.enterText(find.byType(TextFormField).first, '23');
      await tester.enterText(find.byType(TextFormField).last, '59');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Готово'));
      await tester.pumpAndSettle();
      expect(selected, const TimeOfDay(hour: 23, minute: 59));
    },
  );
  testWidgets(
    'New chat returns to the original person search and reuses stable conversation',
    (tester) async {
      final repo = DemoCommunityRepository();
      final c = ProviderContainer(
        overrides: [
          communityRepositoryProvider.overrideWithValue(repo),
          preferencesProvider.overrideWithValue(MemoryPreferences()),
        ],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const PetFriendlyApp()),
      );
      await tester.pumpAndSettle();
      final router = c.read(routerProvider);
      router.go('/chats');
      router.push('/new-chat');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Анна');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('new-chat-$demoAnna')));
      await tester.pumpAndSettle();
      final route = router.state.uri.path;
      expect(route, startsWith('/chat/'));
      await tester.enterText(
        find.byKey(const Key('message-input')),
        'Retained draft',
      );
      router.pop();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/new-chat');
      expect(find.text('Анна'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('new-chat-$demoAnna')));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, route);
      expect(find.text('Retained draft'), findsOneWidget);
    },
  );
  testWidgets(
    'New chat sheet restores search and draft after conversation Back',
    (tester) async {
      final repo = DemoCommunityRepository();
      final c = ProviderContainer(
        overrides: [
          communityRepositoryProvider.overrideWithValue(repo),
          preferencesProvider.overrideWithValue(MemoryPreferences()),
        ],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const PetFriendlyApp()),
      );
      await tester.pumpAndSettle();
      final router = c.read(routerProvider);
      router.go('/chats');
      await tester.pumpAndSettle();
      showNewChatSheet(tester.element(find.text('Чаты').first));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Анна');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('new-chat-$demoAnna')));
      await tester.pumpAndSettle();
      final route = router.state.uri.path;
      await tester.enterText(
        find.byKey(const Key('message-input')),
        'Sheet draft',
      );
      router.pop();
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Анна'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('new-chat-$demoAnna')));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, route);
      expect(find.text('Sheet draft'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(NewChatScreen))).pop();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/chats');
    },
  );
  testWidgets('Unknown shared conversation never substitutes demo messages', (
    tester,
  ) async {
    final c = ProviderContainer(
      overrides: [preferencesProvider.overrideWithValue(MemoryPreferences())],
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const PetFriendlyApp()),
    );
    await tester.pumpAndSettle();
    c.read(routerProvider).go('/chat/missing-record');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('message-input')), findsNothing);
    expect(find.text('Переписка недоступна'), findsOneWidget);
  });
  testWidgets(
    'Agreement chat Back restores details before originating history',
    (tester) async {
      final c = walking_fixture.setup(walking_fixture.ChatWalkFixture());
      addTearDown(c.dispose);
      await c.read(communityProvider.future);
      await c.read(walkingChatProvider.notifier).load('chat');
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (ctx, state) => Scaffold(
              body: FilledButton(
                onPressed: () =>
                    showWalkingChatDetails(ctx, 'chat', chatEntry: true),
                child: const Text('History details'),
              ),
            ),
          ),
          GoRoute(
            path: '/chat/:id',
            builder: (ctx, state) =>
                ChatScreen(id: state.pathParameters['id']!),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp.router(
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: studioTheme(Brightness.light),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('History details'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('agreement-details-chat')));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/chat/chat');
      await tester.enterText(
        find.byKey(const Key('message-input')),
        'Agreement draft',
      );
      router.pop();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/');
      expect(find.byKey(const Key('agreement-details-chat')), findsOneWidget);
      await tester.tap(find.byKey(const Key('agreement-details-chat')));
      await tester.pumpAndSettle();
      expect(find.text('Agreement draft'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Закрыть'));
      await tester.pumpAndSettle();
      expect(find.text('History details'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Nearby All meetings keeps People shell and returns to Nearby city context',
    (tester) async {
      final prefs = MemoryPreferences()
        ..values.addAll({'city': 'Минск', 'manualCity': 'true'});
      final c = ProviderContainer(
        overrides: [preferencesProvider.overrideWithValue(prefs)],
      );
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const PetFriendlyApp()),
      );
      await tester.pumpAndSettle();
      final router = c.read(routerProvider);
      router.go('/nearby');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Все встречи'));
      await tester.tap(find.text('Все встречи'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<StatefulNavigationShell>(
              find.byType(StatefulNavigationShell),
            )
            .currentIndex,
        1,
      );
      expect(
        find.byKey(const ValueKey('people-community-segment')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('nav-0')));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/nearby');
      expect(c.read(prototypeProvider).city, 'Минск');
      expect(c.read(prototypeProvider).manualCity, true);
    },
  );
}
