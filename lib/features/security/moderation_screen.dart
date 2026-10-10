import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/backend/backend.dart';
import '../../core/ui/components.dart';
import '../nearby/place_contributions.dart';
import '../nearby/city_catalog.dart';
import '../community/data/community_repository.dart';

final moderationAvailableProvider = FutureProvider<bool>((ref) async {
  ref.watch(authStateProvider);
  final client = ref.watch(backendProvider);
  if (client == null || client.auth.currentUser == null) return false;
  return await client.rpc('moderation_available') == true;
});
final moderationQueueProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
      ref.watch(authStateProvider);
      final client = ref.watch(backendProvider);
      if (client == null) return {};
      return Map<String, dynamic>.from(await client.rpc('moderation_queue'));
    });

class ModerationScreen extends ConsumerStatefulWidget {
  const ModerationScreen({super.key});
  @override
  ConsumerState<ModerationScreen> createState() => _ModerationState();
}

class _ModerationState extends ConsumerState<ModerationScreen> {
  bool busy = false;
  Future<void> run(String name, Map<String, dynamic> params) async {
    setState(() => busy = true);
    try {
      await ref.read(backendProvider)!.rpc(name, params: params);
      ref.invalidate(moderationQueueProvider);
      ref.invalidate(placeContributionsProvider);
      ref.invalidate(cityCatalogProvider);
      ref.invalidate(communityProvider);
      if (mounted) notice(context, 'Решение сохранено');
    } catch (_) {
      if (mounted) {
        notice(
          context,
          'Не удалось сохранить решение. Проверьте MFA и соединение.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> report(Map<String, dynamic> item, String action) async {
    var note = '';
    final value = await showDialog<String>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(
          action == 'hide' ? 'Скрыть публикацию' : 'Завершить рассмотрение',
        ),
        content: TextFormField(
          textAlignVertical: TextAlignVertical.top,
          onChanged: (value) => note = value,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(labelText: 'Основание решения'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (note.trim().isNotEmpty) Navigator.pop(dialog, note.trim());
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (value != null) {
      await run('resolve_report', {
        'report_in': item['id'],
        'action_in': action,
        'note_in': value,
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Модерация'),
      actions: [
        IconButton(
          tooltip: 'Обновить',
          onPressed: busy
              ? null
              : () => ref.invalidate(moderationQueueProvider),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: ref
        .watch(moderationQueueProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => context.push('/security'),
              child: const Text(
                'Требуется роль модератора и подтверждённая MFA',
              ),
            ),
          ),
          data: (queue) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Предложенные места',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              for (final raw in queue['submissions'] ?? []) ...[
                const SizedBox(height: 16),
                Text(
                  raw['name'],
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text('${raw['category']} · ${raw['city']}'),
                Text(raw['description']),
                Row(
                  children: [
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => run('review_place_submission', {
                              'submission_in': raw['id'],
                              'approve_in': true,
                            }),
                      child: const Text('Опубликовать'),
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => run('review_place_submission', {
                              'submission_in': raw['id'],
                              'approve_in': false,
                            }),
                      child: const Text('Отклонить'),
                    ),
                  ],
                ),
              ],
              if ((queue['submissions'] ?? []).isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Нет мест на проверке'),
                ),
              const Divider(),
              Text('Жалобы', style: Theme.of(context).textTheme.titleLarge),
              for (final raw in queue['reports'] ?? []) ...[
                const SizedBox(height: 16),
                Text(raw['reason']),
                Text(
                  '${raw['target_kind']} · ${raw['target_id']}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => report(
                              Map<String, dynamic>.from(raw),
                              'dismiss',
                            ),
                      child: const Text('Рассмотрено'),
                    ),
                    if (['place', 'review'].contains(raw['target_kind']))
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => report(
                                Map<String, dynamic>.from(raw),
                                'hide',
                              ),
                        child: const Text('Скрыть'),
                      ),
                  ],
                ),
              ],
              if ((queue['reports'] ?? []).isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Нет новых жалоб'),
                ),
              const Text(
                'Очередь: до 50 записей. После рассмотрения загрузится следующая партия.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
  );
}
