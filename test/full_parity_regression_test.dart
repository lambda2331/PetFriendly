import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/chat/new_chat_screen.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/walks/personal_walking_hub.dart';
import 'package:petfriendly/features/walks/walking_repository.dart';
import 'personal_walking_hub_test.dart'
    show PagedWalkingFixture, HubCommunityFixture, EmptyCommunityController;
import 'widget_test.dart' show MemoryPreferences;

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'Real New Chat sheet keeps search fixed and filters after scroll $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(402, 874);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final repo = DemoCommunityRepository(seedSamples: false);
        repo.data['profiles'] = [
          for (var i = 0; i < 60; i++)
            {
              'id': 'person-$i',
              'display_name': 'Person $i',
              'district': 'Public district',
            },
        ];
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (context, _) => Scaffold(
                body: TextButton(
                  onPressed: () => showNewChatSheet(context),
                  child: const Text('Open picker'),
                ),
              ),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              preferencesProvider.overrideWithValue(MemoryPreferences()),
              communityRepositoryProvider.overrideWithValue(repo),
            ],
            child: MaterialApp.router(
              theme: studioTheme(brightness),
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Open picker'));
        await tester.pumpAndSettle();
        final search = find.byKey(const Key('new-chat-search'));
        final before = tester.getRect(search);
        final body = find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(SingleChildScrollView),
        );
        await tester.drag(body, const Offset(0, -420));
        await tester.pumpAndSettle();
        expect(tester.getRect(search), before);
        expect(search.hitTestable(), findsOneWidget);
        await tester.enterText(search, 'Person 59');
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('new-chat-person-59')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('new-chat-person-0')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final tab in [PersonalWalkingTab.current, PersonalWalkingTab.history]) {
    testWidgets(
      'Walking $tab keeps search and filters fixed while results scroll',
      (tester) async {
        tester.view.physicalSize = const Size(402, 874);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              walkingRepositoryProvider.overrideWith(
                (ref) => PagedWalkingFixture(ref, active: true),
              ),
              communityRepositoryProvider.overrideWithValue(
                HubCommunityFixture(),
              ),
              communityProvider.overrideWith(EmptyCommunityController.new),
            ],
            child: MaterialApp(
              theme: studioTheme(Brightness.light),
              home: Scaffold(body: PersonalWalkingHub(initialTab: tab)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final search = find.byKey(
          ValueKey(
            tab == PersonalWalkingTab.current
                ? 'walking-current-search'
                : 'walking-history-search',
          ),
        );
        final before = tester.getRect(search);
        final filterBefore = tester.getRect(find.byTooltip('Фильтры'));
        await tester.drag(find.byType(ListView), const Offset(0, -420));
        await tester.pumpAndSettle();
        final scrollable = tester.state<ScrollableState>(
          find.descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          ),
        );
        expect(scrollable.position.pixels, greaterThan(300));
        expect(tester.getRect(search), before);
        expect(tester.getRect(find.byTooltip('Фильтры')), filterBefore);
        expect(search.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
