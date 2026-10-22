import '../../l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'nearby_studio_layout.dart';
import '../community/data/community_repository.dart';
import '../../core/time/display_time.dart';

final nextCityEventProvider = Provider.family<Json?, String>((ref, city) {
  final data = ref.watch(communityProvider).value ?? {};
  final now = DateTime.now();
  final events =
      rows(data, 'events').where((event) {
          final starts = DateTime.tryParse('${event['starts_at']}');
          return event['city'] == city &&
              event['cancelled'] != true &&
              starts != null &&
              starts.isAfter(now);
        }).toList()
        ..sort((a, b) => '${a['starts_at']}'.compareTo('${b['starts_at']}'));
  return events.firstOrNull;
});

class NearbyEventBanner extends ConsumerStatefulWidget {
  const NearbyEventBanner({required this.city, super.key});
  final String city;

  @override
  ConsumerState<NearbyEventBanner> createState() => _NearbyEventBannerState();
}

class _NearbyEventBannerState extends ConsumerState<NearbyEventBanner> {
  Json? lastEvent;
  Object? snapshotRepository;
  String? snapshotCity, snapshotAccount;

  @override
  Widget build(BuildContext context) {
    final repository = ref.watch(communityRepositoryProvider);
    if (snapshotRepository != repository ||
        snapshotCity != widget.city ||
        snapshotAccount != repository.userId) {
      lastEvent = null;
      snapshotRepository = repository;
      snapshotCity = widget.city;
      snapshotAccount = repository.userId;
    }
    final state = ref.watch(communityProvider);
    final currentEvent = ref.watch(nextCityEventProvider(widget.city));
    if (!state.isLoading && !state.hasError) lastEvent = currentEvent;
    final event = currentEvent ?? lastEvent;

    final loading = state.isLoading;
    final failed = state.hasError;
    final locationLabel = '${event?['location_label'] ?? ''}'.trim();
    return NearbyMeetupPreview(
      title: event == null ? 'Встречи рядом'.tr(context) : '${event['title']}',
      description: event != null
          ? [
              venueTime(
                event['starts_at'],
                city: widget.city,
                timeZone: event['time_zone'],
                locale: context.languageCode,
              ),
              if (locationLabel.isNotEmpty) locationLabel,
            ].join(' · ')
          : loading
          ? 'Ищем встречи рядом'.tr(context)
          : failed
          ? ''
          : 'Пока нет предстоящих встреч.'.tr(context),
      allLabel: 'Все встречи'.tr(context),
      onAll: () => context.go('/events'),
      state: NearbyMeetupFeedback(
        loading: loading,
        loadingLabel: 'Ищем встречи рядом'.tr(context),
        errorLabel: failed ? 'Встречи сейчас недоступны'.tr(context) : null,
        retryLabel: 'Повторить загрузку'.tr(context),
        onRetry: loading
            ? null
            : () => ref.read(communityProvider.notifier).refresh(),
      ),
    );
  }
}
