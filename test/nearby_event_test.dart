import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/nearby/nearby_event_banner.dart';

class EventFixtures extends DemoCommunityRepository {
  @override
  Future<CommunityData> load() async {
    final now = DateTime.now().toUtc();
    Json event(
      String id,
      int hours, {
      String city = 'Минск',
      bool cancelled = false,
    }) => {
      'id': id,
      'city': city,
      'starts_at': now.add(Duration(hours: hours)).toIso8601String(),
      'cancelled': cancelled,
    };
    return {
      'events': [
        event('other-city', 1, city: 'Гродно'),
        event('past', -1),
        event('cancelled', 1, cancelled: true),
        event('later', 3),
        event('next', 2),
      ],
    };
  }
}

void main() {
  test(
    'Nearby banner picks a future active event in the selected city',
    () async {
      final container = ProviderContainer(
        overrides: [
          communityRepositoryProvider.overrideWithValue(EventFixtures()),
        ],
      );
      addTearDown(container.dispose);
      await container.read(communityProvider.future);
      expect(container.read(nextCityEventProvider('Минск'))?['id'], 'next');
      expect(container.read(nextCityEventProvider('Брест')), isNull);
    },
  );
}
