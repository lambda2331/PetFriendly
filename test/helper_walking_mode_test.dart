import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/walks/walking_repository.dart';
import 'package:petfriendly/features/walks/helper_requests_screen.dart';

void main() {
  test(
    'discovery omits own requests and private instructions; filters unknown size',
    () async {
      final repo = DemoCommunityRepository(seedSamples: false);
      final future = DateTime.now()
          .add(const Duration(days: 2))
          .toIso8601String();
      repo.data['walk_requests'] = [
        {
          'id': 'other',
          'owner_id': demoAnna,
          'pet_id': 'pet',
          'status': 'open',
          'city': 'Минск',
          'starts_at': future,
          'instructions': 'private',
        },
        {
          'id': 'mine',
          'owner_id': demoAlex,
          'pet_id': 'pet',
          'status': 'open',
          'city': 'Минск',
          'starts_at': future,
        },
      ];
      repo.data['pets'] = [
        {'id': 'pet', 'name': 'Луна'},
      ];
      final scope = ProviderContainer(
        overrides: [communityRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(scope.dispose);
      final repository = scope.read(walkingRepositoryProvider);
      final found = await repository.list(city: 'Минск');
      expect(found.map((w) => w['id']), ['other']);
      expect(found.single.containsKey('instructions'), false);
      expect(found.single['my_role'], 'viewer');
      expect(await repository.list(city: 'Минск', size: 'small'), isEmpty);
    },
  );
  test(
    'applications do not become assigned agreements; roles and history survive',
    () async {
      final repo = DemoCommunityRepository(seedSamples: false);
      repo.data['walk_requests'] = [
        {'id': 'pending', 'owner_id': demoAnna, 'status': 'open'},
        {'id': 'selected', 'owner_id': demoAnna, 'status': 'assigned'},
        {'id': 'done', 'owner_id': demoAnna, 'status': 'completed'},
      ];
      repo.data['walk_applications'] = [
        {'request_id': 'pending', 'helper_id': demoAlex},
      ];
      repo.data['walk_agreements'] = [
        {'request_id': 'selected', 'helper_id': demoAlex},
        {'request_id': 'done', 'helper_id': demoAlex},
      ];
      final scope = ProviderContainer(
        overrides: [communityRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(scope.dispose);
      final repository = scope.read(walkingRepositoryProvider);
      expect((await repository.list()).map((w) => w['id']), ['selected']);
      expect(
        (await repository.list(view: 'applications')).single['my_role'],
        'applicant',
      );
      expect((await repository.list(view: 'history')).single['id'], 'done');
    },
  );
  test(
    'owner profile filters received reviews and never merges reputations',
    () async {
      final repo = DemoCommunityRepository(seedSamples: false);
      repo.data['walk_owner_reviews'] = [
        {'id': 'mine', 'owner_id': demoAlex, 'published': true, 'rating': 5},
        {'id': 'other', 'owner_id': demoAnna, 'published': true, 'rating': 1},
        {'id': 'hidden', 'owner_id': demoAlex, 'published': false, 'rating': 1},
      ];
      final scope = ProviderContainer(
        overrides: [communityRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(scope.dispose);
      final data = await scope
          .read(walkingRepositoryProvider)
          .ownerProfile(demoAlex);
      expect(rows(data, 'walk_owner_reviews').map((r) => r['id']), ['mine']);
      expect(rows(data, 'owner_ratings').single['rating'], 5.0);
    },
  );
  test(
    'demo owner review requires confirmed assigned agreement and remains unique',
    () async {
      final repo = DemoCommunityRepository(seedSamples: false);
      repo.data['walk_requests'] = [
        {'id': 'walk', 'owner_id': demoAnna, 'status': 'awaiting_confirmation'},
      ];
      repo.data['walk_agreements'] = [
        {'request_id': 'walk', 'helper_id': demoAlex},
      ];
      final args = {
        'request_in': 'walk',
        'rating_in': 5,
        'body_in': 'Спасибо за понятные инструкции.',
      };
      await expectLater(
        repo.command('review_walk_owner', args),
        throwsStateError,
      );
      repo.data['walk_requests']!.single['status'] = 'completed';
      expect(
        canReviewAgreement(repo.data, 'walk', demoAlex, owner: true),
        true,
      );
      await repo.command('review_walk_owner', args);
      expect(
        canReviewAgreement(repo.data, 'walk', demoAlex, owner: true),
        false,
      );
      await expectLater(
        repo.command('review_walk_owner', args),
        throwsStateError,
      );
      expect(
        rows(repo.data, 'walk_owner_reviews').single['owner_id'],
        demoAnna,
      );
      expect(rows(repo.data, 'walk_reviews'), isEmpty);
    },
  );
  for (final brightness in Brightness.values) {
    testWidgets('long Cyrillic request at 320px / 200% $brightness', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: studioTheme(brightness),
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(320, 900),
                textScaler: TextScaler.linear(2),
              ),
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: WalkingRequestRow(
                      item: {
                        'id': 'test',
                        'city': 'Минск',
                        'district': 'Центральный район',
                        'starts_at': '2026-10-11T15:30:00Z',
                        'status': 'open',
                        'my_role': 'applicant',
                        'applied': true,
                        'pet': {
                          'name': 'Александровский очень длинный питомец',
                        },
                        'owner': {
                          'id': 'owner',
                          'display_name': 'Александра Константиновна Дудинская',
                          'review_count': 0,
                        },
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        find.text('Владелец · Александра Константиновна Дудинская'),
        findsOneWidget,
      );
      expect(find.text('0'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, 'Детали'), findsOneWidget);
      expect(find.text('Отклик отправлен · ждём решения'), findsOneWidget);
    });
  }
}
