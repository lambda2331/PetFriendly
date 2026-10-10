import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/ui/components.dart';
import '../../core/media/preview_photos.dart';
import '../community/data/community_repository.dart';
import '../../core/time/display_time.dart';
import 'helper_reputation.dart';
import 'walk_progress.dart';

String walkStatus(String value) => switch (value) {
  'assigned' => 'Помощник выбран',
  'in_progress' => 'На прогулке',
  'awaiting_confirmation' => 'Ждёт подтверждения',
  'completed' => 'Завершено',
  'cancelled' => 'Отменено',
  _ => 'Ищем помощника',
};

class WalksScreen extends ConsumerWidget {
  const WalksScreen({this.showHeader = true, super.key});
  final bool showHeader;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communityProvider);
    final uid = ref.read(communityRepositoryProvider).userId;
    return state.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(
        child: TextButton(
          onPressed: () => ref.invalidate(communityProvider),
          child: const Text('Повторить загрузку'),
        ),
      ),
      data: (data) => PageBody(
        children: [
          if (showHeader)
            const ScreenIntro(
              'Помощь с выгулом',
              compact: true,
              subtitle: 'Попросите соседей о помощи или помогите сами.',
            ),
          if (!showHeader)
            Text(
              'Попросите соседей о помощи или помогите сами.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.push('/edit/walk'),
            icon: const Icon(Icons.add),
            label: const Text('Попросить о выгуле'),
          ),
          if (rows(data, 'walk_requests').any(
            (w) => isMyActiveWalk(
              data,
              w,
              ref.read(communityRepositoryProvider).userId,
            ),
          ))
            const SectionTitle('Мои договорённости', compact: true),
          ...rows(data, 'walk_requests')
              .where(
                (w) => isMyActiveWalk(
                  data,
                  w,
                  ref.read(communityRepositoryProvider).userId,
                ),
              )
              .map(
                (w) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Прогулка с ${findRow(data, 'pets', w['pet_id'])?['name'] ?? 'питомцем'}',
                  ),
                  subtitle: MetadataLine(
                    items: [
                      walkStatus(w['status']),
                      venueTime(
                        w['starts_at'],
                        city: w['city'],
                        timeZone: w['time_zone'] as String?,
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/walk/${w['id']}'),
                ),
              ),
          if (rows(data, 'walk_requests').any((w) => w['status'] == 'open'))
            const SectionTitle('Запросы на прогулку', compact: true)
          else
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Пока нет запросов на прогулку.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ...rows(
            data,
            'walk_requests',
          ).where((w) => w['status'] == 'open').map((w) {
            final pet = findRow(data, 'pets', w['pet_id']);
            final owner = findRow(data, 'profiles', w['owner_id']);
            final count = rows(
              data,
              'walk_applications',
            ).where((a) => a['request_id'] == w['id']).length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: StudioCard(
                padding: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IdentityPicture(
                          id: 'pet:${pet?['id']}',
                          icon: Icons.pets_outlined,
                          size: 48,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Прогулка с ${pet?['name'] ?? 'питомцем'}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              MetadataLine(
                                items: [
                                  pet?['kind'] ?? 'Питомец',
                                  if (pet?['age'] != null)
                                    ageYears(pet?['age']),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 14,
                      runSpacing: 8,
                      children: [
                        WalkFact(
                          Icons.event_outlined,
                          venueTime(
                            w['starts_at'],
                            city: w['city'],
                            timeZone: w['time_zone'] as String?,
                          ),
                        ),
                        WalkFact(Icons.schedule, '${w['duration']} мин'),
                        WalkFact(
                          Icons.location_on_outlined,
                          owner?['district'] ?? w['city'],
                        ),
                      ],
                    ),
                    if ((pet?['temperament'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        pet!['temperament'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if ((w['description'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        w['description'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    MetadataLine(
                      items: [walkStatus(w['status']), '$count откликов'],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            owner?['display_name'] ?? 'Владелец',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.push('/walk/${w['id']}'),
                          child: const Text('Подробнее и отклики'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          if (rows(data, 'walk_requests').any(
            (w) =>
                ['completed', 'cancelled'].contains(w['status']) &&
                isMyWalk(data, w, ref.read(communityRepositoryProvider).userId),
          ))
            const SectionTitle('История прогулок', compact: true),
          ...rows(data, 'walk_requests')
              .where(
                (w) =>
                    ['completed', 'cancelled'].contains(w['status']) &&
                    isMyWalk(
                      data,
                      w,
                      ref.read(communityRepositoryProvider).userId,
                    ),
              )
              .map(
                (w) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Прогулка с ${findRow(data, 'pets', w['pet_id'])?['name'] ?? 'питомцем'}',
                  ),
                  subtitle: MetadataLine(
                    items: [
                      walkStatus(w['status']),
                      venueTime(
                        w['starts_at'],
                        city: w['city'],
                        timeZone: w['time_zone'],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/walk/${w['id']}'),
                ),
              ),
          if (rows(data, 'profiles').any((p) => p['id'] != uid))
            const SectionTitle('Помощники', compact: true),
          ...rows(data, 'profiles')
              .where(
                (p) => p['id'] != ref.read(communityRepositoryProvider).userId,
              )
              .map(
                (p) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: InitialAvatar(
                    (p['display_name'] as String).substring(0, 1),
                  ),
                  title: Text(p['display_name']),
                  subtitle: HelperReputationText(
                    data: data,
                    id: p['id'],
                    demo: ref.read(communityRepositoryProvider).isDemo,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/helper/${p['id']}'),
                ),
              ),
        ],
      ),
    );
  }
}

class WalkDetailScreen extends ConsumerStatefulWidget {
  const WalkDetailScreen({required this.id, super.key});
  final String id;
  @override
  ConsumerState<WalkDetailScreen> createState() => _WalkDetailState();
}

class _WalkDetailState extends ConsumerState<WalkDetailScreen> {
  bool busy = false, confirming = false;
  String get id => widget.id;
  Future<void> action(
    BuildContext context,
    WidgetRef ref,
    String name,
    Json args,
  ) async {
    if (busy || confirming) return;
    confirming = true;
    final risky = name == 'assign_walk' || args['next_status'] == 'cancelled';
    if (risky) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            name == 'assign_walk' ? 'Выбрать помощника?' : 'Отменить заявку?',
          ),
          content: Text(
            name == 'assign_walk'
                ? 'Вы создадите договорённость с выбранным помощником. Сначала просмотрите его профиль и обсудите детали прогулки. Отзывы помогают принять решение, но не гарантируют безопасность.'
                : 'Открытая заявка больше не будет принимать отклики.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Назад'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                name == 'assign_walk' ? 'Выбрать помощника' : 'Отменить заявку',
              ),
            ),
          ],
        ),
      );
      confirming = false;
      if (accepted != true || !mounted) return;
    }
    confirming = false;
    setState(() => busy = true);
    try {
      await ref.read(communityProvider.notifier).command(name, args);
      if (context.mounted) notice(context, walkActionSuccess(name, args));
    } catch (_) {
      if (context.mounted) {
        notice(
          context,
          'Не удалось обновить заявку. Проверьте соединение и обновите её: статус мог измениться.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityProvider);
    if (state.isLoading || state.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Заявка на выгул')),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(communityProvider),
                  child: const Text('Заявка не загрузилась · повторить'),
                ),
              ),
      );
    }
    final data = state.value ?? {};
    final request = findRow(data, 'walk_requests', id);
    if (request == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Заявка недоступна')),
      );
    }
    final repository = ref.read(communityRepositoryProvider),
        uid = repository.userId;
    final owner = request['owner_id'] == uid;
    final pet = findRow(data, 'pets', request['pet_id']);
    final applications = rows(
      data,
      'walk_applications',
    ).where((a) => a['request_id'] == id).toList();
    final agreements = rows(
      data,
      'walk_agreements',
    ).where((a) => a['request_id'] == id).toList();
    final helper = agreements.firstOrNull?['helper_id'];
    final applied = applications.any((a) => a['helper_id'] == uid);
    final reviewed = rows(
      data,
      'walk_reviews',
    ).any((r) => r['request_id'] == id);
    final progress = WalkProgress.forRequest(
      status: request['status'],
      owner: owner,
      helper: helper == uid && uid != null,
      applied: applied,
      reviewed: reviewed,
    );
    final conversationId = walkConversationId(data, id, uid);
    final chatIsPrimary =
        (owner && ['assigned', 'in_progress'].contains(request['status'])) ||
        (helper == uid && request['status'] == 'awaiting_confirmation') ||
        (request['status'] == 'completed' && (!owner || reviewed));
    final instructions = rows(
      data,
      'walk_details',
    ).where((d) => d['request_id'] == id).firstOrNull?['instructions'];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заявка на выгул'),
        actions: [
          IconButton(
            tooltip: 'Обновить статус заявки',
            onPressed: busy ? null : () => ref.invalidate(communityProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        key: PageStorageKey('walk-detail-$id'),
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          ScreenIntro(
            'Прогулка с ${pet?['name'] ?? 'питомцем'}',
            compact: true,
            subtitle: venueTime(
              request['starts_at'],
              city: request['city'],
              timeZone: request['time_zone'] as String?,
            ),
          ),
          const SizedBox(height: 20),
          WalkProgressView(progress: progress),
          const SizedBox(height: 20),
          if (conversationId != null) ...[
            if (chatIsPrimary)
              FilledButton.icon(
                onPressed: () => context.push('/chat/$conversationId'),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Чат договорённости'),
              )
            else
              OutlinedButton.icon(
                onPressed: () => context.push('/chat/$conversationId'),
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Чат договорённости'),
              ),
            const SizedBox(height: 16),
          ],
          StudioCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MetadataLine(
                  items: ['${request['duration']} минут', request['city']],
                ),
                const SizedBox(height: 10),
                Text(request['description'] ?? ''),
                if (instructions != null && '$instructions'.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text('Приватные инструкции'),
                  Text(instructions),
                ],
                if (helper != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    'Помощник: ${findRow(data, 'profiles', helper)?['display_name'] ?? 'Пользователь'}',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          if (busy) const LinearProgressIndicator(),

          if (request['status'] == 'open' && !owner)
            FilledButton(
              style: applied
                  ? FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    )
                  : null,
              onPressed: busy
                  ? null
                  : () => action(
                      context,
                      ref,
                      applied ? 'withdraw_walk' : 'apply_walk',
                      {'request_in': id},
                    ),
              child: Text(applied ? 'Отменить отклик' : 'Предложить помощь'),
            ),
          if (owner && request['status'] == 'open') ...[
            const SectionTitle('Отклики'),
            if (applications.isEmpty) const Text('Пока никто не откликнулся.'),
            ...applications.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      findRow(
                            data,
                            'profiles',
                            a['helper_id'],
                          )?['display_name'] ??
                          'Помощник',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    HelperReputationText(
                      data: data,
                      id: a['helper_id'],
                      demo: repository.isDemo,
                    ),
                    Wrap(
                      spacing: 12,
                      children: [
                        TextButton(
                          onPressed: () =>
                              context.push('/helper/${a['helper_id']}'),
                          child: const Text('Профиль и отзывы'),
                        ),
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => action(context, ref, 'assign_walk', {
                                  'request_in': id,
                                  'helper_in': a['helper_id'],
                                }),
                          child: const Text('Выбрать помощника'),
                        ),
                      ],
                    ),
                    const Divider(),
                  ],
                ),
              ),
            ),
            if (repository.isDemo)
              TextButton(
                onPressed: busy
                    ? null
                    : () => action(context, ref, 'demo_application', {
                        'request_in': id,
                      }),
                child: const Text('Добавить тестовый отклик Саши'),
              ),
          ],
          if (request['status'] == 'assigned' &&
              (helper == uid || repository.isDemo))
            FilledButton(
              onPressed: busy
                  ? null
                  : () => action(context, ref, 'advance_walk', {
                      'request_in': id,
                      'next_status': 'in_progress',
                    }),
              style: repository.isDemo && helper != uid
                  ? FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    )
                  : null,
              child: Text(
                repository.isDemo
                    ? 'Демо: помощник начал прогулку'
                    : 'Начать прогулку',
              ),
            ),
          if (request['status'] == 'in_progress' &&
              (helper == uid || repository.isDemo))
            FilledButton(
              onPressed: busy
                  ? null
                  : () => action(context, ref, 'advance_walk', {
                      'request_in': id,
                      'next_status': 'awaiting_confirmation',
                    }),
              style: repository.isDemo && helper != uid
                  ? FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    )
                  : null,
              child: Text(
                repository.isDemo
                    ? 'Демо: помощник завершил прогулку'
                    : 'Завершить прогулку',
              ),
            ),
          if (request['status'] == 'awaiting_confirmation' && owner)
            FilledButton(
              onPressed: busy
                  ? null
                  : () => action(context, ref, 'advance_walk', {
                      'request_in': id,
                      'next_status': 'completed',
                    }),
              child: const Text('Подтвердить завершение'),
            ),
          if (request['status'] == 'completed' && owner && !reviewed)
            FilledButton(
              onPressed: () => context.push('/review/$id'),
              child: const Text('Оценить помощника'),
            ),
          const SizedBox(height: 20),
          TextButton.icon(
            onPressed: () => context.push('/report/walk/$id'),
            icon: const Icon(Icons.flag_outlined, size: 18),
            label: const Text('Сообщить о проблеме'),
          ),
          if (owner && request['status'] == 'open') ...[
            const SizedBox(height: 16),
            const Divider(),
            TextButton(
              onPressed: busy
                  ? null
                  : () => action(context, ref, 'advance_walk', {
                      'request_in': id,
                      'next_status': 'cancelled',
                    }),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Отменить заявку'),
            ),
          ],
          if (repository.isDemo) const DemoCaption(),
        ],
      ),
    );
  }
}

class HelperScreen extends ConsumerWidget {
  const HelperScreen({this.id = demoSasha, super.key});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communityProvider);
    if (state.isLoading || state.hasError) {
      return Scaffold(
        appBar: AppBar(title: const Text('Профиль помощника')),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(communityProvider),
                  child: const Text('Профиль не загрузился · повторить'),
                ),
              ),
      );
    }
    final data = state.value ?? {};
    final profile = findRow(data, 'profiles', id) ?? {};
    final reviews = rows(
      data,
      'walk_reviews',
    ).where((r) => r['helper_id'] == id && r['published'] == true).toList();
    final reputation = HelperReputation.fromData(
      data,
      id,
      demo: ref.read(communityRepositoryProvider).isDemo,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Профиль помощника')),
      body: PageBody(
        children: [
          ScreenIntro(
            profile['display_name'] ?? 'Помощник',
            compact: true,
            subtitle: profile['about'] ?? '',
          ),
          const SectionTitle('Опыт выгула'),
          MetadataLine(
            items: [reputation.reviewLabel, reputation.completedLabel],
          ),
          const SizedBox(height: 12),
          const Text(
            'Отзывы и опыт помогают принять решение, но не гарантируют безопасность.',
          ),
          ...reviews.map(
            (r) => Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '★ ${r['rating']} · ${findRow(data, 'profiles', r['author_id'])?['display_name'] ?? 'Владелец'}',
                  ),
                  Text(r['body'] ?? ''),
                  MetadataLine(
                    items: [
                      readableDate(r['created_at']),
                      'По завершённому выгулу',
                    ],
                  ),
                  if ((r['helper_reply'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text('Ответ помощника'),
                    Text(r['helper_reply']),
                    MetadataLine(items: [readableDate(r['replied_at'])]),
                  ],
                  if (id == ref.read(communityRepositoryProvider).userId)
                    ReplyToReview(review: r),
                  TextButton(
                    onPressed: () => context.push('/report/review/${r['id']}'),
                    child: const Text('Пожаловаться на отзыв'),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              try {
                final cid = await ref.read(communityProvider.notifier).command(
                  'direct',
                  {'target': id},
                );
                if (context.mounted && cid != null) context.push('/chat/$cid');
              } catch (_) {
                if (context.mounted) notice(context, 'Переписка недоступна');
              }
            },
            child: const Text('Обсудить прогулку'),
          ),
          TextButton(
            onPressed: () => context.push('/report/profile/$id'),
            child: const Text('Пожаловаться'),
          ),
          const SizedBox(height: 16),
          const Divider(),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              await ref.read(communityProvider.notifier).command('block', {
                'target_id': id,
              });
              if (context.mounted) {
                Navigator.pop(context);
                notice(context, 'Пользователь заблокирован');
              }
            },
            child: const Text('Заблокировать'),
          ),
          if (ref.read(communityRepositoryProvider).isDemo) const DemoCaption(),
        ],
      ),
    );
  }
}

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({required this.id, super.key});
  final String id;
  @override
  ConsumerState<ReviewScreen> createState() => _ReviewState();
}

class _ReviewState extends ConsumerState<ReviewScreen> {
  int? rating;
  bool saving = false;
  final comment = TextEditingController();
  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Отзыв о выгуле')),
    body: PageBody(
      children: [
        const ScreenIntro('Как прошла прогулка?', compact: true),
        const SizedBox(height: 20),
        DropdownButtonFormField<int>(
          initialValue: rating,
          decoration: const InputDecoration(labelText: 'Оценка'),
          items: [1, 2, 3, 4, 5]
              .map((n) => DropdownMenuItem(value: n, child: Text('$n ★')))
              .toList(),
          hint: const Text('Выберите оценку'),
          onChanged: (v) => setState(() => rating = v),
        ),
        const SizedBox(height: 16),
        TextField(
          textAlignVertical: TextAlignVertical.top,
          controller: comment,
          maxLength: 1000,
          maxLines: 4,
          decoration: const InputDecoration(labelText: 'Комментарий'),
        ),
        const SizedBox(height: 12),
        const Text('Отзыв будет публичным. Не указывайте адреса и контакты.'),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: saving || rating == null
              ? null
              : () async {
                  setState(() => saving = true);
                  try {
                    await ref
                        .read(communityProvider.notifier)
                        .command('review_walk', {
                          'request_in': widget.id,
                          'rating_in': rating,
                          'body_in': comment.text.trim(),
                        });
                    if (context.mounted) Navigator.pop(context);
                  } catch (_) {
                    if (context.mounted) {
                      notice(context, 'Отзыв недоступен или уже опубликован');
                    }
                  } finally {
                    if (mounted) setState(() => saving = false);
                  }
                },
          child: Text(saving ? 'Публикуем…' : 'Опубликовать'),
        ),
      ],
    ),
  );
}

class WalkFact extends StatelessWidget {
  const WalkFact(this.icon, this.text, {super.key});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16),
      const SizedBox(width: 6),
      Flexible(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
    ],
  );
}

class HelperReputationText extends StatelessWidget {
  const HelperReputationText({
    required this.data,
    required this.id,
    required this.demo,
    super.key,
  });
  final CommunityData data;
  final String id;
  final bool demo;
  @override
  Widget build(BuildContext context) {
    final r = HelperReputation.fromData(data, id, demo: demo);
    return Text('${r.reviewLabel}\n${r.completedLabel}');
  }
}

class ReplyToReview extends ConsumerStatefulWidget {
  const ReplyToReview({required this.review, super.key});
  final Json review;
  @override
  ConsumerState<ReplyToReview> createState() => _ReplyToReviewState();
}

class _ReplyToReviewState extends ConsumerState<ReplyToReview> {
  final text = TextEditingController();
  bool saving = false, editing = false;
  @override
  void initState() {
    super.initState();
    text.text = widget.review['helper_reply'] ?? '';
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => editing
      ? Column(
          children: [
            TextField(
              controller: text,
              minLines: 2,
              maxLines: 4,
              maxLength: 1000,
              decoration: const InputDecoration(labelText: 'Ответ на отзыв'),
            ),
            const Text(
              'Ответ будет публичным. Не указывайте адреса и инструкции по уходу.',
            ),
            TextButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (text.text.trim().isEmpty) {
                        notice(context, 'Напишите ответ');
                        return;
                      }
                      setState(() => saving = true);
                      try {
                        await ref
                            .read(communityProvider.notifier)
                            .command('reply_walk_review', {
                              'review_in': widget.review['id'],
                              'body_in': text.text.trim(),
                            });
                        if (context.mounted) {
                          setState(() => editing = false);
                          notice(context, 'Ответ опубликован');
                        }
                      } catch (_) {
                        if (context.mounted) {
                          notice(
                            context,
                            'Не удалось опубликовать. Проверьте соединение и повторите.',
                          );
                        }
                      } finally {
                        if (mounted) setState(() => saving = false);
                      }
                    },
              child: Text(saving ? 'Публикуем…' : 'Опубликовать ответ'),
            ),
            TextButton(
              onPressed: saving ? null : () => setState(() => editing = false),
              child: const Text('Отмена'),
            ),
          ],
        )
      : TextButton(
          onPressed: () => setState(() => editing = true),
          child: Text(
            (widget.review['helper_reply'] ?? '').toString().isEmpty
                ? 'Ответить на отзыв'
                : 'Изменить ответ',
          ),
        );
}

class WalkProgressView extends StatelessWidget {
  const WalkProgressView({required this.progress, super.key});
  final WalkProgress progress;

  @override
  Widget build(BuildContext context) {
    final stage = progress.stage;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (stage != null) ...[
          Semantics(
            header: true,
            label:
                'Этап ${stage + 1} из ${WalkProgress.stages.length}: ${WalkProgress.stages[stage]}',
            child: ExcludeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      WalkProgress.stages[stage],
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${stage + 1} / ${WalkProgress.stages.length}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ExcludeSemantics(
            child: Row(
              key: const Key('walk-progress-rail'),
              children: [
                for (var i = 0; i < WalkProgress.stages.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: i == stage ? 6 : 4,
                      decoration: BoxDecoration(
                        color: i <= stage
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(3),
                        border: i == stage
                            ? Border.all(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: .4,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context).scale(1);
              final inline = scale <= 1.2 && constraints.maxWidth >= 300;
              Widget label(int i, {required bool centered}) => Semantics(
                label:
                    '${i + 1}. ${WalkProgress.stages[i]}, ${i < stage
                        ? 'завершён'
                        : i == stage
                        ? 'текущий этап'
                        : 'предстоит'}',
                child: ExcludeSemantics(
                  child: Text(
                    WalkProgress.stages[i],
                    textAlign: centered ? TextAlign.center : TextAlign.left,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: i == stage
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: i == stage
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
              if (inline) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < WalkProgress.stages.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(child: label(i, centered: true)),
                    ],
                  ],
                );
              }
              final width = scale > 1.6 || constraints.maxWidth < 280
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 16) / 2;
              return Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < WalkProgress.stages.length; i++)
                    SizedBox(
                      width: width,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ExcludeSemantics(
                            child: Icon(
                              i < stage
                                  ? Icons.check
                                  : i == stage
                                  ? Icons.arrow_forward
                                  : Icons.remove,
                              size: 16,
                              color: i == stage
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(child: label(i, centered: false)),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
        ],
        Text(progress.instruction, key: const Key('walk-next-step')),
      ],
    );
  }
}
