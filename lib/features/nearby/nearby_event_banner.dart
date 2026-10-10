import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/ui/components.dart';
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

class NearbyEventBanner extends ConsumerWidget {
  const NearbyEventBanner({required this.city, super.key});
  final String city;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(nextCityEventProvider(city));
    final state = ref.watch(communityProvider);
    final empty = !state.isLoading && !state.hasError && event == null;
    final title = state.isLoading
        ? 'Ищем встречи рядом'
        : state.hasError
        ? 'Встречи сейчас недоступны'
        : event?['title'] ?? 'Встречи рядом';
    final subtitle = state.isLoading
        ? city
        : state.hasError
        ? 'Откройте встречи и повторите загрузку.'
        : empty
        ? 'В $city пока нет встреч.'
        : venueTime(
            event?['starts_at'],
            city: city,
            timeZone: event?['time_zone'],
          );
    final action = empty ? 'Создать встречу' : 'Открыть встречи';
    return Semantics(
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push(empty ? '/edit/event' : '/events'),
        child: StudioCard(
          hero: true,
          padding: 16,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 10),
                    Text(action, style: Theme.of(context).textTheme.labelLarge),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const ExcludeSemantics(
                child: Icon(Icons.arrow_forward, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
