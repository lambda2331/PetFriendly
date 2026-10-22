import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/nearby/city_catalog.dart';
import 'widget_test.dart' show MemoryPreferences, EmptyCatalog;

class RecoverableSocialRepository extends DemoCommunityRepository {
  bool failNext = false;
  @override
  Future<CommunityData> load() async {
    if (failNext) {
      failNext = false;
      throw StateError('Synthetic network failure');
    }
    return super.load();
  }
}

class PendingSocialRepository extends DemoCommunityRepository {
  Completer<CommunityData>? pending;
  int loads = 0;

  @override
  Future<CommunityData> load() {
    loads++;
    return pending?.future ?? super.load();
  }
}

void main() {
  test(
    'refresh gives pending feedback and ignores duplicate retries',
    () async {
      final repo = PendingSocialRepository();
      final container = ProviderContainer(
        overrides: [communityRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      final initial = await container.read(communityProvider.future);
      repo.pending = Completer<CommunityData>();
      final controller = container.read(communityProvider.notifier);
      final refresh = controller.refresh();
      await controller.refresh();
      expect(repo.loads, 2);
      expect(container.read(communityProvider).isLoading, isTrue);
      expect(container.read(communityProvider).value, initial);
      repo.pending!.completeError(StateError('Synthetic network failure'));
      await refresh;
      expect(container.read(communityProvider).hasError, isTrue);
      expect(container.read(communityProvider).isLoading, isFalse);
      repo.pending = null;
      await controller.refresh();
      expect(repo.loads, 3);
      expect(container.read(communityProvider).hasError, isFalse);
    },
  );

  for (final meetups in [true, false]) {
    testWidgets(
      '${meetups ? 'Meetup' : 'Community'} search survives failed refresh and retry',
      (tester) async {
        final repo = RecoverableSocialRepository();
        final prefs = MemoryPreferences()
          ..values.addAll({
            'manualCity': 'true',
            'city': 'Минск',
            'language': 'ru',
          });
        final container = ProviderContainer(
          overrides: [
            preferencesProvider.overrideWithValue(prefs),
            communityRepositoryProvider.overrideWithValue(repo),
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
        container.read(routerProvider).go(meetups ? '/events' : '/people');
        await tester.pumpAndSettle();
        if (!meetups) {
          await tester.tap(
            find.descendant(
              of: find.byKey(const ValueKey('people-community-segment')),
              matching: find.text('Сообщества'),
            ),
          );
          await tester.pumpAndSettle();
        }
        final search = meetups
            ? find.byKey(const ValueKey('meetup-search'))
            : find.byKey(const ValueKey('community-search-1'));
        final query = meetups ? 'Вечерняя' : 'Соседи';
        await tester.enterText(search, query);
        tester.testTextInput.hide();
        await tester.pumpAndSettle();
        repo.failNext = true;
        await container.read(communityProvider.notifier).refresh();
        await tester.pumpAndSettle();
        expect(find.text('Повторить загрузку'), findsOneWidget);
        await tester.ensureVisible(find.text('Повторить загрузку'));
        await tester.tap(find.text('Повторить загрузку'));
        await tester.pumpAndSettle();
        expect(tester.widget<TextField>(search).controller!.text, query);
        expect(container.read(prototypeProvider).city, 'Минск');
        expect(container.read(prototypeProvider).manualCity, isTrue);
        expect(container.read(communityProvider).hasError, isFalse);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
