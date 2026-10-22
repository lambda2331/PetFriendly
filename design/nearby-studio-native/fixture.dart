import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petfriendly/core/backend/backend.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/core/time/display_time.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/nearby/city_catalog.dart';
import 'package:petfriendly/features/nearby/live_map.dart';
import 'package:petfriendly/features/nearby/location_service.dart';
import 'package:petfriendly/features/nearby/nearby_studio_layout.dart';
import 'package:petfriendly/features/nearby/place_repository.dart';
import 'package:petfriendly/features/walks/account_mode.dart';
import 'package:petfriendly/l10n/localization.dart';

/// Public, synthetic and account-free review fixtures. Never cloud credentials.
class NearbyReviewPreferences implements PreferencesRepository {
  NearbyReviewPreferences({
    String locale = 'ru',
    bool dark = false,
    String city = 'Минск',
  }) : values = {
         'locationPrompted': 'yes',
         'manualCity': 'true',
         'city': city,
         'language': locale,
         'theme': dark ? 'dark' : 'light',
       };
  final Map<String, String> values;
  @override
  String? read(String key) => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}

class NearbyReviewCatalog extends CityCatalogService {
  NearbyReviewCatalog() : super(LocationService());
  @override
  Future<List<Place>> load(String city) async => [
    Place(
      'review-public-park',
      'Парк Победы',
      'Парк',
      city,
      null,
      0,
      '',
      'unknown',
      Icons.park_outlined,
      latitude: 53.9285,
      longitude: 27.542,
    ),
  ];
}

Json nearbyReviewEvent(String city) => {
  'id': '00000000-0000-4000-8000-000000000099',
  'title': 'Прогулка в парке',
  'city': city,
  'starts_at': '2026-10-18T08:00:00Z',
  'time_zone': 'Europe/Minsk',
  'location_label': 'Парк Победы',
  'cancelled': false,
  'owner_id': demoAnna,
  'description': 'Синтетическая встреча для проверки интерфейса.',
};

class NearbyReviewRepository extends DemoCommunityRepository {
  NearbyReviewRepository({
    String city = 'Минск',
    bool empty = false,
    this.scenario = 'populated',
  }) : super(seedSamples: false) {
    data['events'] = empty || scenario != 'populated'
        ? []
        : [nearbyReviewEvent(city)];
  }
  final String scenario;
  final pending = Completer<CommunityData>();
  @override
  Future<CommunityData> load() async {
    if (scenario == 'loading') return pending.future;
    if (scenario == 'error') throw StateError('Synthetic meetup failure');
    return super.load();
  }
}

/// Independently assembled reference uses the production presentation widgets.
/// Interactive destinations outside Nearby remain on the earlier prototype.
class NearbyReferenceScreen extends ConsumerWidget {
  const NearbyReferenceScreen({
    this.empty = false,
    this.onCity,
    this.onMode,
    this.onDestination,
    this.scenario = 'populated',
    this.onList,
    this.onMap,
    this.onMeetups,
    super.key,
  });
  final bool empty;
  final String scenario;
  final VoidCallback? onMode;
  final ValueChanged<int>? onDestination;
  final VoidCallback? onCity, onList, onMap, onMeetups;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(prototypeProvider);
    final city = prefs.city;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final event = nearbyReviewEvent(city);
    final noEvent = empty || scenario != 'populated';
    return Scaffold(
      appBar: NearbyStudioHeader(
        dark: dark,
        themeLabel: (dark ? 'Светлая тема' : 'Тёмная тема').tr(context),
        onTheme: () => ref
            .read(prototypeProvider.notifier)
            .setTheme(dark ? ThemeMode.light : ThemeMode.dark),
        stacked:
            MediaQuery.sizeOf(context).width < 360 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.3,
        tall: MediaQuery.textScalerOf(context).scale(1) > 1.3,
        modeControl: TextButton.icon(
          onPressed: onMode,
          icon: const Icon(Icons.expand_more, size: 18),
          label: Text('Владелец'.tr(context)),
        ),
      ),
      body: NearbyStudioLayout(
        greeting: 'Хороший день для прогулки.'.tr(context),
        subtitle: 'И новой компании для вас двоих.'.tr(context),
        meetups: NearbyMeetupPreview(
          title: noEvent ? 'Встречи рядом'.tr(context) : '${event['title']}',
          description: noEvent
              ? scenario == 'loading'
                    ? 'Ищем встречи рядом'.tr(context)
                    : scenario == 'error'
                    ? ''
                    : 'Пока нет предстоящих встреч.'.tr(context)
              : '${venueTime(event['starts_at'], city: city, timeZone: event['time_zone'], locale: context.languageCode)} · ${event['location_label']}',
          allLabel: 'Все встречи'.tr(context),
          onAll: onMeetups ?? () {},
          state: NearbyMeetupFeedback(
            loading: scenario == 'loading',
            loadingLabel: 'Ищем встречи рядом'.tr(context),
            retryLabel: 'Повторить загрузку'.tr(context),
            errorLabel: scenario == 'error'
                ? 'Встречи сейчас недоступны'.tr(context)
                : null,
            onRetry: () {},
          ),
          secondaryAction: empty
              ? Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 18),
                    label: Text('Создать встречу'.tr(context)),
                  ),
                )
              : null,
        ),
        placesTitle: 'Места рядом'.tr(context),
        city: city.split(',').first.trim(),
        cityDetails: city.contains(',')
            ? city.split(',').skip(1).join(',').trim()
            : '',
        listLabel: 'Список мест'.tr(context),
        mapLabel: stringsFor(context.languageCode).nearbyMapView,
        onCity: onCity ?? () {},
        onList: onList ?? () {},
        onMap: onMap ?? () {},
        map: const MapUnavailableState(compact: true),
      ),
      bottomNavigationBar: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: StudioColors.of(context).line)),
        ),
        child: NavigationBar(
          selectedIndex: 0,
          onDestinationSelected: onDestination ?? (_) {},
          destinations: [
            for (final e in [
              (Icons.explore_outlined, 'Рядом'),
              (Icons.people_outline, 'Люди'),
              (Icons.pets_outlined, 'Выгул'),
              (Icons.chat_bubble_outline, 'Чаты'),
              (Icons.person_outline, 'Я'),
            ])
              NavigationDestination(
                icon: Icon(e.$1),
                selectedIcon: Icon(e.$1, color: StudioColors.onLime),
                label: e.$2.tr(context),
              ),
          ],
        ),
      ),
    );
  }
}

ProviderContainer nearbyReviewContainer({
  String locale = 'ru',
  bool dark = false,
  bool empty = false,
  String city = 'Минск',
  String scenario = 'populated',
}) => ProviderContainer(
  overrides: [
    preferencesProvider.overrideWithValue(
      NearbyReviewPreferences(locale: locale, dark: dark, city: city),
    ),
    backendProvider.overrideWithValue(null),
    accountModeRepositoryProvider.overrideWithValue(
      DemoAccountModeRepository()
        ..current = const AccountMode(
          role: 'both',
          mode: 'owner',
          needsRoleSelection: false,
        ),
    ),
    communityRepositoryProvider.overrideWithValue(
      NearbyReviewRepository(city: city, empty: empty, scenario: scenario),
    ),
    cityCatalogServiceProvider.overrideWithValue(NearbyReviewCatalog()),
  ],
);
