import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ui/components.dart';
import '../../../core/time/display_time.dart';
import '../data/community_repository.dart';

String eventTime(dynamic value, {String? city, String? timeZone}) =>
    venueTime(value, city: city, timeZone: timeZone);

class EventsScreen extends ConsumerWidget {
  const EventsScreen({this.focusedEventId, super.key});
  final String? focusedEventId;
  Future<void> changeParticipation(BuildContext context, WidgetRef ref,
      String id, bool joined) async {
    try {
      await ref.read(communityProvider.notifier).command(
        joined ? 'leave_event' : 'join_event', {'event_in': id},
      );
    } catch (_) {
      if (context.mounted) {
        notice(context, 'Не удалось изменить участие. Возможно, свободных мест нет.');
      }
    }
  }

  void openChat(BuildContext context, CommunityData data, String id) {
    final chat = rows(data, 'conversations').where((c) =>
      c['kind'] == 'event' && c['context_id'] == id).firstOrNull;
    if (chat != null) {
      context.push('/chat/${chat['id']}');
    } else {
      notice(context, 'Чат появится после подключения данных встречи');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communityProvider);
    final uid = ref.read(communityRepositoryProvider).userId;
    return Scaffold(
      appBar: AppBar(
        title: Text(focusedEventId == null ? 'Совместные прогулки' : 'Встреча'),
      ),
      floatingActionButton: focusedEventId != null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => context.push('/edit/event'),
              icon: const Icon(Icons.add),
              label: const Text('Создать встречу'),
            ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(communityProvider),
            child: const Text('Повторить загрузку'),
          ),
        ),
        data: (data) => PageBody(
          children: [
            if (focusedEventId == null) ...[
              const ScreenIntro('Выберите прогулку', compact: true),
              const SizedBox(height: 20),
            ],
            if (focusedEventId != null &&
                findRow(data, 'events', focusedEventId) == null)
              const Text('Встреча недоступна. Возможно, её больше нет.'),
            if (rows(data, 'events').isEmpty)
              const Text('Пока нет встреч. Создайте первую.'),
            ...rows(
              data,
              'events',
            ).where((e) => focusedEventId == null || e['id'] == focusedEventId).map((
              e,
            ) {
              final members = rows(
                data,
                'event_members',
              ).where((m) => m['event_id'] == e['id']).toList();
              final joined = members.any((m) => m['user_id'] == uid);
              final dateLabel = eventTime(e['starts_at'], city: e['city'], timeZone: e['time_zone']);
              final city = e['city'] as String? ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: StudioCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e['title'],
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      MetadataLine(items: [
                        dateLabel,
                        if (city.isNotEmpty && !dateLabel.contains(city)) city,
                        '${members.length} из ${e['capacity']} участников',
                      ]),
                      const SizedBox(height: 8),
                      Text(e['description'] ?? ''),

                      const SizedBox(height: 14),
                      if (e['owner_id'] == uid)
                        const MetadataLine(items: ['Вы организатор'])
                      else if (focusedEventId != null && !joined)
                        FilledButton(
                          onPressed: () => changeParticipation(context, ref, e['id'], false),
                          child: const Text('Присоединиться'),
                        )
                      else
                        OutlinedButton(
                          onPressed: () => changeParticipation(context, ref, e['id'], joined),
                          child: Text(joined ? 'Отменить участие' : 'Присоединиться'),
                        ),
                      if (joined) ...[
                        const SizedBox(height: 8),
                        if (focusedEventId != null)
                          FilledButton.icon(
                            onPressed: () => openChat(context, data, e['id']),
                            icon: const Icon(Icons.chat_bubble_outline, size: 18),
                            label: const Text('Чат встречи'),
                          )
                        else
                          TextButton(
                            onPressed: () => openChat(context, data, e['id']),
                            child: const Text('Чат встречи'),
                          ),
                      ],
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
