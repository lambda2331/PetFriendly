import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/community/presentation/meetup_controller.dart';

void main() {
  final now = DateTime.utc(2026, 10, 10, 20, 30);
  Json event(
    String id, {
    String city = 'Минск',
    String owner = 'anna',
    String? starts,
    String zone = 'Europe/Minsk',
    bool cancelled = false,
  }) => {
    'id': id,
    'city': city,
    'owner_id': owner,
    'title': 'Вечерняя прогулка $id',
    'starts_at': starts ?? now.add(const Duration(hours: 1)).toIso8601String(),
    'time_zone': zone,
    'cancelled': cancelled,
  };
  CommunityData fixture() => {
    'events': [
      event('future'),
      event('joined'),
      event('own', owner: 'alex'),
      event('other-city', city: 'Варшава'),
      event(
        'past',
        starts: now.subtract(const Duration(days: 1)).toIso8601String(),
      ),
      event('cancelled', cancelled: true),
    ],
    'event_members': [
      {'event_id': 'joined', 'user_id': 'alex'},
    ],
  };
  List<String> ids(MeetupFilters filters) => selectMeetups(
    fixture(),
    city: 'Минск',
    uid: 'alex',
    filters: filters,
    now: now,
  ).map((row) => row['id'] as String).toList();
  test('Upcoming scopes city and omits cancelled and elapsed events', () {
    expect(ids(const MeetupFilters()), ['future', 'joined', 'own']);
  });
  test('Joined and organizing are distinct actual participation views', () {
    expect(
      ids(const MeetupFilters(participation: MeetupParticipation.joined)),
      ['joined'],
    );
    expect(
      ids(const MeetupFilters(participation: MeetupParticipation.organizing)),
      ['own'],
    );
  });
  test('History retains cancelled and elapsed events honestly', () {
    expect(
      ids(const MeetupFilters(history: true)),
      containsAll(['past', 'cancelled']),
    );
    expect(ids(const MeetupFilters(history: true)), isNot(contains('future')));
  });
  test('Search preserves filters and matches public title', () {
    expect(
      ids(
        const MeetupFilters(
          query: 'own',
          participation: MeetupParticipation.organizing,
        ),
      ),
      ['own'],
    );
    expect(ids(const MeetupFilters(query: 'несуществующее')), isEmpty);
  });
  test('Today is evaluated in each venue zone, not device time', () {
    final data = {
      'events': [event('minsk'), event('new-york', zone: 'America/New_York')],
    };
    expect(
      selectMeetups(
        data,
        city: 'Минск',
        uid: 'alex',
        filters: const MeetupFilters(date: MeetupDate.today),
        now: now,
      ).map((e) => e['id']),
      ['new-york'],
    );
  });
  test('Weekend respects venue calendar across device UTC boundary', () {
    final fridayUtc = DateTime.utc(2026, 10, 16, 22, 30);
    final data = {
      'events': [
        event('minsk-saturday', starts: '2026-10-17T08:00:00Z'),
        event('minsk-sunday', starts: '2026-10-18T08:00:00Z'),
        event('minsk-monday', starts: '2026-10-19T08:00:00Z'),
        event(
          'new-york-saturday',
          starts: '2026-10-18T02:00:00Z',
          zone: 'America/New_York',
        ),
      ],
    };
    final result = selectMeetups(
      data,
      city: 'Минск',
      uid: 'alex',
      filters: const MeetupFilters(date: MeetupDate.weekend),
      now: fridayUtc,
    );
    expect(
      result.map((e) => e['id']),
      containsAll(['minsk-saturday', 'minsk-sunday', 'new-york-saturday']),
    );
    expect(result.map((e) => e['id']), isNot(contains('minsk-monday')));
    expect(meetupVenueDate(data['events']!.last)?.day, 17);
  });
  test('Unknown venue zones cannot satisfy date filters', () {
    expect(
      selectMeetups(
        {
          'events': [event('unknown', zone: 'Bad/Zone')],
        },
        city: 'Минск',
        uid: 'alex',
        filters: const MeetupFilters(date: MeetupDate.today),
        now: now,
      ),
      isEmpty,
    );
  });
  test('Member count deduplicates memberships', () {
    expect(
      meetupMembers({
        'event_members': [
          {'event_id': 'a', 'user_id': 'x'},
          {'event_id': 'a', 'user_id': 'x'},
        ],
      }, 'a'),
      1,
    );
  });
  test(
    'Participation locks duplicate requests and preserves snapshot after error',
    () async {
      final repository = _DelayedRepository();
      final container = ProviderContainer(
        overrides: [communityRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      await container.read(communityProvider.future);
      final action = container.read(meetupActionsProvider.notifier);
      final first = action.participation('future', joined: false);
      expect(container.read(meetupActionsProvider), contains('future'));
      expect(await action.participation('future', joined: false), false);
      repository.result.completeError(StateError('offline'));
      await expectLater(first, throwsStateError);
      expect(container.read(meetupActionsProvider), isEmpty);
      expect(container.read(communityProvider).value?['events'], isNotEmpty);
      expect(repository.commands, 1);
    },
  );
}

class _DelayedRepository implements CommunityRepository {
  final result = Completer<String?>();
  int commands = 0;
  @override
  String get userId => 'alex';
  @override
  bool get isDemo => true;
  @override
  Future<CommunityData> load() async => {
    'events': [
      {
        'id': 'future',
        'owner_id': 'anna',
        'starts_at': DateTime.now()
            .add(const Duration(days: 1))
            .toIso8601String(),
        'city': 'Минск',
        'cancelled': false,
      },
    ],
    'event_members': [],
  };
  @override
  Future<String?> command(String action, Json values) {
    commands++;
    return result.future;
  }
}
