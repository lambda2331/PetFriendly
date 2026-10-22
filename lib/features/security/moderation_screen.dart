import '../../l10n/localization.dart';
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
      if (mounted) notice(context, "Решение сохранено".tr(context));
    } catch (_) {
      if (mounted) {
        notice(
          context,
          "Не удалось сохранить решение. Проверьте MFA и соединение.".tr(
            context,
          ),
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
          action == 'hide'
              ? "Скрыть публикацию".tr(context)
              : "Завершить рассмотрение".tr(context),
        ),
        content: TextFormField(
          textAlignVertical: TextAlignVertical.top,
          onChanged: (value) => note = value,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            labelText: "Основание решения".tr(context),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog),
            child: Text("Отмена".tr(context)),
          ),
          TextButton(
            onPressed: () {
              if (note.trim().isNotEmpty) Navigator.pop(dialog, note.trim());
            },
            child: Text("Сохранить".tr(context)),
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
      title: Text("Модерация".tr(context)),
      actions: [
        IconButton(
          tooltip: "Обновить".tr(context),
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
              child: Text(
                "Требуется роль модератора и подтверждённая MFA".tr(context),
              ),
            ),
          ),
          data: (queue) => ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                "Предложенные места".tr(context),
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
                      child: Text("Опубликовать".tr(context)),
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => run('review_place_submission', {
                              'submission_in': raw['id'],
                              'approve_in': false,
                            }),
                      child: Text("Отклонить".tr(context)),
                    ),
                  ],
                ),
              ],
              if ((queue['submissions'] ?? []).isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text("Нет мест на проверке".tr(context)),
                ),
              const Divider(),
              Text(
                "Жалобы".tr(context),
                style: Theme.of(context).textTheme.titleLarge,
              ),
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
                      child: Text("Рассмотрено".tr(context)),
                    ),
                    if (['place', 'review'].contains(raw['target_kind']))
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => report(
                                Map<String, dynamic>.from(raw),
                                'hide',
                              ),
                        child: Text("Скрыть".tr(context)),
                      ),
                  ],
                ),
              ],
              if ((queue['reports'] ?? []).isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text("Нет новых жалоб".tr(context)),
                ),
              Text(
                "Очередь: до 50 записей. После рассмотрения загрузится следующая партия."
                    .tr(context),
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
  );
}
