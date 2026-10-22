import 'walking_studio_components.dart';
import 'package:intl/intl.dart';
import '../../l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/ui/components.dart';
import '../community/data/community_repository.dart';
import 'walking_repository.dart';
import '../../core/media/preview_photos.dart';
import 'walking_profile_components.dart';
import 'walking_form_drafts.dart';

class OwnerProfileScreen extends ConsumerWidget {
  const OwnerProfileScreen({required this.id, super.key});
  final String id;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final self = ref.watch(communityRepositoryProvider).userId == id;
    final state = ref.watch(ownerProfileProvider(id));
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(24) * 2 + 12,
        title: Text(
          self ? "Ваша репутация".tr(context) : "Профиль владельца".tr(context),
          maxLines: 2,
        ),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: TextButton(
            onPressed: () => ref.invalidate(ownerProfileProvider(id)),
            child: Text("Профиль не загрузился · повторить".tr(context)),
          ),
        ),
        data: (data) {
          final profile = findRow(data, 'profiles', id);
          if (profile == null) {
            return Center(child: Text("Профиль недоступен".tr(context)));
          }
          final stats = findRow(data, 'owner_ratings', id);
          final count = (stats?['review_count'] as num?)?.toInt();
          final rating = stats?['rating'] as num?;
          return WalkingActionTheme(
            child: PageBody(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IdentityPicture(
                    id: 'profile:$id',
                    name: '${profile['display_name']}',
                    icon: Icons.person_outline,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${profile['display_name']}',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                if ('${profile['district'] ?? ''}'.isNotEmpty)
                  Text('${profile['district']}'),
                if ('${profile['about'] ?? ''}'.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('${profile['about']}'),
                  ),
                SectionTitle("Опыт как владельца".tr(context)),
                Text(
                  count == null || (count > 0 && rating == null)
                      ? "Репутация сейчас недоступна".tr(context)
                      : count == 0
                      ? "Пока нет отзывов".tr(context)
                      : "{p0} из 5 · {p1}".tr(
                          context,
                          arguments: {
                            'p0': NumberFormat(
                              '0.0',
                              context.languageCode,
                            ).format(rating),
                            'p1': stringsFor(
                              context.languageCode,
                            ).reviewCount(count),
                          },
                        ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (stats?['completed'] != null)
                  Text(
                    stringsFor(
                      context.languageCode,
                    ).ownerCompletedCount((stats!['completed'] as num).toInt()),
                  ),
                const SizedBox(height: 12),
                Text(
                  "Отзывы помогают принять решение, но не гарантируют безопасность."
                      .tr(context),
                ),
                if (!self) OwnerContact(id: id),
                SectionTitle("Отзывы помощников".tr(context)),
                for (final review in rows(data, 'walk_owner_reviews'))
                  WalkingReviewTile(
                    key: ValueKey('owner-review-${review['id']}'),
                    review: review,
                    author: findRow(data, 'profiles', review['author_id']),
                    ownerReview: true,
                    isSelf: self,
                    replyEditor: self
                        ? OwnerReviewReply(
                            review: review,
                            onSaved: () =>
                                ref.invalidate(ownerProfileProvider(id)),
                          )
                        : null,
                  ),
                if (count == 0)
                  Text(
                    "Первый отзыв появится после подтверждённой прогулки.".tr(
                      context,
                    ),
                  ),
                if (!self)
                  TextButton(
                    onPressed: () => context.push('/report/profile/$id'),
                    child: Text("Пожаловаться на профиль".tr(context)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class OwnerReviewReply extends ConsumerStatefulWidget {
  const OwnerReviewReply({
    required this.review,
    required this.onSaved,
    super.key,
  });
  final Json review;
  final VoidCallback onSaved;
  @override
  ConsumerState<OwnerReviewReply> createState() => _OwnerReplyState();
}

class _OwnerReplyState extends ConsumerState<OwnerReviewReply> {
  final text = TextEditingController();
  bool editing = false, busy = false;
  String get draftKey => 'owner-reply:${widget.review['id']}';
  @override
  void initState() {
    super.initState();
    text.text =
        ref.read(walkingFormDraftsProvider)[draftKey]?.text ??
        '${widget.review['owner_reply'] ?? ''}';
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
              onChanged: (value) => ref
                  .read(walkingFormDraftsProvider.notifier)
                  .keep(draftKey, text: value),
              enabled: !busy,
              maxLength: 1000,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Ответ на отзыв".tr(context),
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: busy
                      ? null
                      : () async {
                          if (text.text.trim().isEmpty) return;
                          setState(() => busy = true);
                          try {
                            await ref
                                .read(communityProvider.notifier)
                                .command('reply_walk_owner_review', {
                                  'review_in': widget.review['id'],
                                  'body_in': text.text.trim(),
                                });
                            ref
                                .read(walkingFormDraftsProvider.notifier)
                                .clear(draftKey);
                            widget.onSaved();
                            if (mounted) setState(() => editing = false);
                          } catch (_) {
                            if (context.mounted) {
                              notice(
                                context,
                                "Ответ не опубликован. Текст сохранён — попробуйте снова."
                                    .tr(context),
                              );
                            }
                          } finally {
                            if (mounted) setState(() => busy = false);
                          }
                        },
                  child: Text(
                    busy
                        ? "Публикуем…".tr(context)
                        : "Опубликовать ответ".tr(context),
                  ),
                ),
                OutlinedButton(
                  onPressed: busy
                      ? null
                      : () => setState(() => editing = false),
                  child: Text("Позже".tr(context)),
                ),
              ],
            ),
          ],
        )
      : WalkingRowActions(
          trailing: OutlinedButton.icon(
            icon: const Icon(Icons.reply_outlined, size: 18),
            onPressed: busy
                ? null
                : () {
                    if (text.text.isEmpty) {
                      text.text =
                          ref.read(walkingFormDraftsProvider)[draftKey]?.text ??
                          '${widget.review['owner_reply'] ?? ''}';
                    }
                    setState(() => editing = true);
                  },
            label: Text(
              ('${widget.review['owner_reply'] ?? ''}'.isEmpty
                      ? 'Ответить'
                      : "Изменить ответ")
                  .tr(context),
            ),
          ),
        );
}

class OwnerContact extends ConsumerStatefulWidget {
  const OwnerContact({required this.id, super.key});
  final String id;
  @override
  ConsumerState<OwnerContact> createState() => _OwnerContactState();
}

class _OwnerContactState extends ConsumerState<OwnerContact> {
  bool busy = false;
  Future<void> run(bool block) async {
    if (busy) return;
    if (block) {
      final accepted = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text("Заблокировать пользователя?".tr(context)),
          content: Text(
            "Новые личные сообщения и доступ к профилям будут ограничены.".tr(
              context,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: Text("Назад".tr(context)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text("Заблокировать".tr(context)),
            ),
          ],
        ),
      );
      if (accepted != true || !mounted) return;
    }
    final account = ref.read(communityRepositoryProvider).userId;
    setState(() => busy = true);
    try {
      final result = await ref
          .read(communityProvider.notifier)
          .command(
            block ? 'block' : 'direct',
            block ? {'target_id': widget.id} : {'target': widget.id},
          );
      if (!mounted || account != ref.read(communityRepositoryProvider).userId) {
        return;
      }
      if (block) {
        context.pop();
      } else if (result != null) {
        context.push('/chat/$result');
      } else {
        throw StateError('Chat unavailable');
      }
    } catch (_) {
      if (mounted) {
        notice(
          context,
          "Не удалось выполнить действие. Попробуйте снова.".tr(context),
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 16),
      FilledButton(
        onPressed: busy ? null : () => run(false),
        child: Text(
          busy ? "Подождите…".tr(context) : "Обсудить прогулку".tr(context),
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: busy ? null : () => run(true),
          child: Text("Заблокировать".tr(context)),
        ),
      ),
    ],
  );
}
