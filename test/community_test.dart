import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';

void main() {
  test(
    'Created pet and walk support helper assignment, completion and one review',
    () async {
      final repo = DemoCommunityRepository();
      await repo.command('pet', {
        'name': 'Мия',
        'kind': 'Кошка',
        'age': 4,
        'temperament': 'Осторожная',
      });
      var snapshot = await repo.load();
      final pet = rows(snapshot, 'pets').firstWhere((p) => p['name'] == 'Мия');
      final request = await repo.command('walk', {
        'pet_in': pet['id'],
        'city_in': 'Минск',
        'starts_in': DateTime.now()
            .add(const Duration(days: 1))
            .toUtc()
            .toIso8601String(),
        'duration_in': 30,
        'description_in': 'Помочь с прогулкой',
        'instructions_in': 'Не отпускать поводок',
      });
      await expectLater(
        repo.command('review_walk', {
          'request_in': request,
          'rating_in': 5,
          'body_in': '',
        }),
        throwsStateError,
      );
      await repo.command('demo_application', {'request_in': request});
      await repo.command('assign_walk', {
        'request_in': request,
        'helper_in': demoSasha,
      });
      for (final status in [
        'in_progress',
        'awaiting_confirmation',
        'completed',
      ]) {
        await repo.command('advance_walk', {
          'request_in': request,
          'next_status': status,
        });
      }
      await repo.command('review_walk', {
        'request_in': request,
        'rating_in': 5,
        'body_in': 'Всё отлично',
      });
      await expectLater(
        repo.command('review_walk', {
          'request_in': request,
          'rating_in': 1,
          'body_in': '',
        }),
        throwsStateError,
      );
      snapshot = await repo.load();
      expect(
        findRow(snapshot, 'walk_requests', request)?['status'],
        'completed',
      );
      expect(rows(snapshot, 'walk_reviews').single['helper_id'], demoSasha);
    },
  );
  test('Event joining is idempotent', () async {
    final repo = DemoCommunityRepository();
    final snapshot = await repo.load();
    final event = rows(snapshot, 'events').first['id'];
    await repo.command('join_event', {'event_in': event});
    await repo.command('join_event', {'event_in': event});
    expect(
      rows(
        await repo.load(),
        'event_members',
      ).where((m) => m['event_id'] == event && m['user_id'] == demoAlex).length,
      1,
    );
  });
}
