import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petfriendly/core/backend/backend.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/chat/chat_repository.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/nearby/city_catalog.dart';
import 'package:petfriendly/features/walks/account_mode.dart';
import '../../design/nearby-studio-native/fixture.dart';

const meetupFixtureId = '00000000-0000-4000-8000-000000000099';
const meetupChatFixtureId = '00000000-0000-4000-8000-000000000091';

class MeetupStudioRepository extends DemoCommunityRepository {
  MeetupStudioRepository({this.scenario = 'populated'})
    : super(seedSamples: false) {
    data['events'] = scenario == 'empty'
        ? []
        : [
            {
              ...nearbyReviewEvent('Минск'),
              'capacity': 12,
              'description':
                  'Спокойная прогулка и знакомство с другими владельцами питомцев. Встречаемся у главного входа в парк.',
              'latitude': 53.9285,
              'longitude': 27.542,
            },
            {
              ...nearbyReviewEvent('Минск'),
              'id': '00000000-0000-4000-8000-000000000098',
              'owner_id': userId,
              'title': 'Знакомство с соседями',
              'starts_at': '2026-10-19T15:00:00Z',
              'capacity': 8,
            },
          ];
    data['event_members'] = [
      {'event_id': meetupFixtureId, 'user_id': userId},
    ];
    data['profiles']!.add({'id': demoAnna, 'display_name': 'Анна'});
    data['conversations']!.add({
      'id': meetupChatFixtureId,
      'kind': 'event',
      'context_id': meetupFixtureId,
    });
  }
  String scenario;
  final pending = Completer<CommunityData>();
  @override
  Future<CommunityData> load() async {
    if (scenario == 'loading') return pending.future;
    if (scenario == 'error') throw StateError('Synthetic unavailable data');
    return super.load();
  }
}

ProviderContainer meetupStudioContainer({
  String locale = 'ru',
  bool dark = false,
  MeetupStudioRepository? repository,
  bool helperOnly = false,
}) => ProviderContainer(
  overrides: [
    backendProvider.overrideWithValue(null),
    preferencesProvider.overrideWithValue(
      NearbyReviewPreferences(locale: locale, dark: dark),
    ),
    communityRepositoryProvider.overrideWithValue(
      repository ?? MeetupStudioRepository(),
    ),
    chatRepositoryProvider.overrideWithValue(DemoChatRepository()),
    cityCatalogServiceProvider.overrideWithValue(NearbyReviewCatalog()),
    accountModeRepositoryProvider.overrideWithValue(
      DemoAccountModeRepository()
        ..current = AccountMode(
          role: helperOnly ? 'helper' : 'both',
          mode: helperOnly ? 'helper' : 'owner',
          needsRoleSelection: false,
        ),
    ),
  ],
);
