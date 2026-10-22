import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/community/data/community_browse.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/community/presentation/community_browser.dart';
import 'package:petfriendly/features/nearby/city_catalog.dart';
import 'widget_test.dart' show EmptyCatalog, MemoryPreferences;

class PendingMembershipRepository implements CommunityRepository {
  @override
  String get userId => demoAlex;
  @override
  bool get isDemo => true;
  final completion = Completer<String?>();
  int commands = 0;
  @override
  Future<CommunityData> load() async => {
    'groups': [
      {'id': 'a', 'title': 'Соседи', 'description': 'Прогулки'},
    ],
    'group_members': [],
  };
  @override
  Future<String?> command(String action, Json values) {
    commands++;
    return completion.future;
  }
}

void main() {
  final data = <String, List<Json>>{
    'groups': [
      {'id': 'a', 'title': 'Соседи', 'description': 'Спокойные прогулки'},
      {'id': 'b', 'title': 'Походы', 'description': 'Лес и тропы'},
    ],
    'group_members': [
      {'group_id': 'a', 'user_id': demoAlex},
    ],
  };
  test(
    'Membership and search filters compose without fabricating area data',
    () {
      expect(
        browseCommunities(
          data,
          demoAlex,
          participation: CommunityParticipation.joined,
        ).single['id'],
        'a',
      );
      expect(
        browseCommunities(
          data,
          demoAlex,
          participation: CommunityParticipation.discover,
        ).single['id'],
        'b',
      );
      expect(
        browseCommunities(data, demoAlex, query: ' СПОКОЙНЫЕ ').single['id'],
        'a',
      );
      expect(
        browseCommunities(
          data,
          demoAlex,
          query: 'лес',
          participation: CommunityParticipation.joined,
        ),
        isEmpty,
      );
    },
  );
  test(
    'Repeated joins are serialized and recoverable errors retain snapshot',
    () async {
      final repo = PendingMembershipRepository();
      final container = ProviderContainer(
        overrides: [communityRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      await container.read(communityProvider.future);
      final controller = container.read(communityMembershipProvider.notifier);
      final pending = controller.change('a', joined: false);
      await controller.change('a', joined: false);
      expect(repo.commands, 1);
      expect(container.read(communityMembershipProvider), {'a'});
      final failure = expectLater(pending, throwsStateError);
      repo.completion.completeError(StateError('offline'));
      await failure;
      expect(container.read(communityMembershipProvider), isEmpty);
      expect(container.read(communityProvider).value!['groups'], isNotEmpty);
    },
  );
  testWidgets(
    'Communities show separate joined/discovery and survive enlarged text',
    (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.binding.setSurfaceSize(const Size(320, 740));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = DemoCommunityRepository();
      repo.data['groups'] = [
        {
          'id': 'a',
          'title': 'Длинное название сообщества соседей с питомцами',
          'description': 'Длинное описание прогулок и общения с соседями.',
          'owner_id': demoAnna,
        },
        {
          'id': 'b',
          'title': 'Новые знакомства',
          'description': 'Спокойные прогулки',
          'owner_id': demoAnna,
        },
      ];
      repo.data['group_members'] = [
        {'group_id': 'a', 'user_id': demoAlex},
      ];
      final prefs = MemoryPreferences()..values['language'] = 'ru';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communityRepositoryProvider.overrideWithValue(repo),
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
      container.read(routerProvider).go('/people');
      await tester.pumpAndSettle();
      final communityTab = find.descendant(
        of: find.byKey(const ValueKey('people-community-segment')),
        matching: find.text('Сообщества'),
      );
      await tester.ensureVisible(communityTab);
      await tester.pumpAndSettle();
      expect(communityTab.hitTestable(), findsOneWidget);
      await tester.tap(communityTab);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(CommunityBrowser),
        180,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('people-list')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CommunityBrowser), findsOneWidget);
      expect(find.textContaining('Вы участвуете'), findsOneWidget);
      container
          .read(communityBrowseProvider.notifier)
          .select(CommunityParticipation.joined);
      await tester.pumpAndSettle();
      expect(find.text('Новые знакомства'), findsNothing);
      container
          .read(communityBrowseProvider.notifier)
          .select(CommunityParticipation.discover);
      await tester.pumpAndSettle();
      expect(find.text('Новые знакомства'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('social-filter')),
        -180,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('people-list')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('social-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Все').last);
      await tester.pumpAndSettle();
      expect(
        container.read(communityBrowseProvider).participation,
        CommunityParticipation.all,
      );
      final search = find.byKey(const ValueKey('community-search-1'));
      await tester.scrollUntilVisible(
        search,
        -180,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('people-list')),
          matching: find.byType(Scrollable),
        ),
      );
      await tester.enterText(search, 'Нет такого названия');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      expect(find.text('Сообщества не найдены'), findsOneWidget);
      expect(find.text('Сбросить'), findsOneWidget);
      await tester.ensureVisible(find.text('Сбросить'));
      await tester.pumpAndSettle();
      expect(find.text('Сбросить').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Сбросить').hitTestable());
      await tester.pumpAndSettle();
      expect(
        container.read(communityBrowseProvider).participation,
        CommunityParticipation.all,
      );
      await tester.scrollUntilVisible(
        search,
        -180,
        scrollable: find.descendant(
          of: find.byKey(const ValueKey('people-list')),
          matching: find.byType(Scrollable),
        ),
      );
      expect(tester.widget<TextField>(search).controller!.text, isEmpty);
      repo.data['groups'] = [];
      await container.read(communityProvider.notifier).refresh();
      await tester.pumpAndSettle();
      expect(find.text('Пока нет сообществ'), findsOneWidget);
      expect(find.text('Сбросить'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
