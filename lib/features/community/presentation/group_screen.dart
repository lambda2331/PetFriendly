import '../../../core/ui/studio_review.dart';
import '../../../l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ui/components.dart';
import '../../../core/media/preview_photos.dart';
import '../data/community_repository.dart';
import '../data/community_browse.dart';

Future<void> showCommunityDetails(BuildContext context, String id) async {
  while (context.mounted) {
    if (!context.mounted) return;
    final route = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      sheetAnimationStyle: studioSheetAnimation(context),
      builder: (_) => GroupScreen(id: id, sheet: true),
    );
    if (!context.mounted || route == null) break;
    await context.push(route);
  }
}

class GroupScreen extends ConsumerStatefulWidget {
  const GroupScreen({required this.id, this.sheet = false, super.key});
  final String id;
  final bool sheet;
  @override
  ConsumerState<GroupScreen> createState() => _GroupState();
}

class _GroupState extends ConsumerState<GroupScreen> {
  bool opening = false;
  void open(String route) {
    if (widget.sheet) {
      Navigator.pop(context, route);
    } else {
      context.push(route);
    }
  }

  Future<void> updatePhoto() async {
    try {
      final bytes = await pickPreviewPhoto();
      if (mounted && bytes != null) {
        await savePhoto(ref, 'group:${widget.id}', bytes);
      }
    } catch (_) {
      if (mounted) notice(context, 'Не удалось открыть фото'.tr(context));
    }
  }

  Future<void> membership(bool joined) async {
    try {
      await ref
          .read(communityMembershipProvider.notifier)
          .change(widget.id, joined: joined);
    } catch (_) {
      if (mounted) notice(context, 'Не удалось изменить участие'.tr(context));
    }
  }

  Future<void> invite(CommunityData data, Json group) async {
    final target = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      showDragHandle: false,
      backgroundColor: Theme.of(context).colorScheme.surface,
      isScrollControlled: true,
      sheetAnimationStyle: studioSheetAnimation(context),
      builder: (_) => CommunityInvitationSheet(id: widget.id),
    );
    // A dismissed invitation leaves the original community sheet underneath.
    if (target == null || !mounted || opening) return;
    setState(() => opening = true);
    try {
      final cid = await ref.read(communityProvider.notifier).command('direct', {
        'target': target,
      });
      if (mounted && cid != null) {
        final draft = Uri.encodeComponent(
          'Присоединяйтесь к «{p0}»!\npetfriendly://group/{p1}'.tr(
            context,
            arguments: {'p0': group['title'], 'p1': widget.id},
          ),
        );
        open('/chat/$cid?draft=$draft');
      }
    } catch (_) {
      if (mounted) {
        notice(context, 'Не удалось открыть приглашение'.tr(context));
      }
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(communityProvider);
    final data = snapshot.value ?? <String, List<Json>>{};
    final group = findRow(data, 'groups', widget.id);
    final busy =
        opening || ref.watch(communityMembershipProvider).contains(widget.id);
    final uid = ref.watch(communityRepositoryProvider).userId;
    final members = rows(data, 'group_members')
        .where((m) => m['group_id'] == widget.id)
        .map((m) => m['user_id'])
        .toSet()
        .toList();
    final joined = members.contains(uid);
    final owner = group?['owner_id'] == uid;
    final organizer = findRow(data, 'profiles', group?['owner_id']);
    final chat = rows(data, 'conversations')
        .where((c) => c['kind'] == 'group' && c['context_id'] == widget.id)
        .firstOrNull;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (snapshot.isLoading && !snapshot.hasValue)
          const Center(child: CircularProgressIndicator()),
        if (snapshot.hasError && !snapshot.hasValue) ...[
          Text(
            'Не удалось загрузить сообщество. Проверьте соединение и попробуйте снова.'
                .tr(context),
          ),
          TextButton(
            onPressed: () => ref.invalidate(communityProvider),
            child: Text('Повторить загрузку'.tr(context)),
          ),
        ],
        if (!snapshot.isLoading && !snapshot.hasError && group == null)
          Text('Сообщество недоступно'.tr(context)),
        if (group != null) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              if (owner)
                Tooltip(
                  message: 'Фото сообщества'.tr(context),
                  child: InkWell(
                    key: const ValueKey('community-edit-photo'),
                    borderRadius: BorderRadius.circular(16),
                    onTap: updatePhoto,
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: Stack(
                        children: [
                          IdentityPicture(
                            id: 'group:${widget.id}',
                            name: group['title'],
                            icon: Icons.people_outline,
                            size: 56,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.surface,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.photo_camera_outlined,
                                size: 16,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                IdentityPicture(
                  id: 'group:${widget.id}',
                  name: group['title'],
                  icon: Icons.people_outline,
                  size: 56,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${memberCount(members.length, locale: context.languageCode)} · ${(joined ? 'Вы участвуете' : 'Открытое сообщество').tr(context)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (organizer != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Организатор: {p0}'.tr(
                          context,
                          arguments: {'p0': organizer['display_name'] ?? ''},
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (joined)
            LayoutBuilder(
              builder: (context, constraints) {
                final buttons = [
                  FilledButton.icon(
                    key: const ValueKey('community-chat'),
                    onPressed: busy || chat == null
                        ? null
                        : () => open('/chat/${chat['id']}'),
                    icon: const Icon(Icons.chat_bubble_outline, size: 20),
                    label: Text('Чат'.tr(context)),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('community-invite'),
                    onPressed: busy ? null : () => invite(data, group),
                    icon: const Icon(Icons.person_add_alt, size: 20),
                    label: Text('Пригласить'.tr(context)),
                  ),
                ];
                return MediaQuery.textScalerOf(context).scale(14) > 20
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          buttons.first,
                          const SizedBox(height: 8),
                          buttons.last,
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: buttons.first),
                          const SizedBox(width: 8),
                          Expanded(child: buttons.last),
                        ],
                      );
              },
            ),
          if (!joined)
            FilledButton(
              key: const ValueKey('community-membership'),
              onPressed: busy ? null : () => membership(false),
              child: Text(
                (busy ? 'Вступаем…' : 'Вступить в сообщество').tr(context),
              ),
            ),
          if (joined && chat == null) ...[
            const SizedBox(height: 8),
            Text(
              'Чат сообщества пока недоступен. Попробуйте обновить данные.'.tr(
                context,
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(communityProvider),
              child: Text('Повторить загрузку'.tr(context)),
            ),
          ],
          if ('${group['description'] ?? ''}'.trim().isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(group['description']),
          ],
          const SizedBox(height: 24),
          for (final section in [
            ('members', 'Участники'),
            ('rules', 'Правила сообщества'),
            ('meetings', 'Встречи сообщества'),
          ])
            StudioReviewRow(
              title: section.$2.tr(context),
              onTap: () => open(
                section.$1 == 'meetings'
                    ? '/group/${widget.id}/meetings'
                    : '/group/${widget.id}/${section.$1}',
              ),
            ),
          if (joined && !owner) ...[
            const SizedBox(height: 24),
            const Divider(height: 1),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                key: const ValueKey('community-leave'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  alignment: Alignment.centerLeft,
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: busy ? null : () => membership(true),
                icon: const Icon(Icons.logout, size: 20),
                label: Text(
                  (busy ? 'Подождите…' : 'Выйти из сообщества').tr(context),
                ),
              ),
            ),
          ],
        ],
      ],
    );
    return widget.sheet
        ? StudioReviewSheet(
            title: group?['title'] ?? 'Сообщество'.tr(context),
            child: content,
          )
        : Scaffold(
            appBar: AppBar(
              title: Text(group?['title'] ?? 'Сообщество'.tr(context)),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: content,
            ),
          );
  }
}

class CommunityInvitationSheet extends ConsumerStatefulWidget {
  const CommunityInvitationSheet({required this.id, super.key});
  final String id;
  @override
  ConsumerState<CommunityInvitationSheet> createState() => _InvitationState();
}

class _InvitationState extends ConsumerState<CommunityInvitationSheet> {
  final search = TextEditingController();
  bool copied = false;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(communityProvider).value ?? <String, List<Json>>{};
    final candidates = invitationCandidates(
      data,
      ref.watch(communityRepositoryProvider).userId,
      widget.id,
      search.text,
    );
    return StudioReviewSheet(
      title: 'Приглашение'.tr(context),
      closeKey: const ValueKey('invite-close'),
      fixedContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Выберите человека или скопируйте ссылку.'.tr(context),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          TextField(
            key: const ValueKey('invite-search'),
            controller: search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintMaxLines: 1,
              prefixIcon: const Icon(Icons.search),
              hintText: 'Найти человека'.tr(context),
            ),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (candidates.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Никого не нашли'.tr(context),
                textAlign: TextAlign.center,
              ),
            ),
          for (final p in candidates)
            InkWell(
              key: ValueKey('invite-person-${p['id']}'),
              onTap: () => Navigator.pop(context, p['id'] as String),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    IdentityPicture(
                      id: 'profile:${p['id']}',
                      name: p['display_name'],
                      icon: Icons.person_outline,
                      size: 40,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['display_name'] ?? '',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if ('${p['district'] ?? ''}'.isNotEmpty)
                            Text(
                              p['district'],
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const ValueKey('invite-copy'),
            onPressed: () async {
              try {
                await Clipboard.setData(
                  ClipboardData(text: 'petfriendly://group/${widget.id}'),
                );
                if (mounted) setState(() => copied = true);
              } catch (_) {
                if (context.mounted) {
                  notice(context, 'Не удалось скопировать ссылку'.tr(context));
                }
              }
            },
            icon: const Icon(Icons.link),
            label: Text(
              (copied ? 'Ссылка скопирована' : 'Скопировать ссылку').tr(
                context,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CommunitySectionScreen extends ConsumerWidget {
  const CommunitySectionScreen({
    required this.id,
    required this.section,
    super.key,
  });
  final String id, section;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communityProvider),
        data = state.value ?? <String, List<Json>>{};
    final group = findRow(data, 'groups', id);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          (section == 'members' ? 'Участники' : 'Правила сообщества').tr(
            context,
          ),
        ),
      ),
      body: state.isLoading && group == null
          ? StudioReviewState(title: 'Загружаем…'.tr(context), loading: true)
          : group == null
          ? StudioReviewState(
              title: 'Сообщество недоступно'.tr(context),
              action: OutlinedButton(
                onPressed: () => ref.invalidate(communityProvider),
                child: Text('Повторить'.tr(context)),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('${group['title']}', style: studioIdentityText),
                const SizedBox(height: 24),
                if (section == 'members') ...[
                  for (final member in rows(
                    data,
                    'group_members',
                  ).where((m) => m['group_id'] == id))
                    if (findRow(data, 'profiles', member['user_id'])
                        case final person?)
                      StudioReviewRow(
                        title: '${person['display_name']}',
                        subtitle: '${person['district'] ?? ''}',
                        leading: const Icon(Icons.person_outline),
                        onTap: () => context.push('/owner/${person['id']}'),
                      ),
                ] else ...[
                  for (final rule in [
                    (
                      'Уважайте друг друга',
                      'Обсуждайте вопросы спокойно, без оскорблений.',
                    ),
                    (
                      'Берегите личные данные',
                      'Не публикуйте чужие адреса и контакты без согласия.',
                    ),
                    (
                      'Учитывайте питомцев',
                      'Уточняйте условия встречи и не навязывайте общение.',
                    ),
                  ]) ...[
                    Text(rule.$1.tr(context), style: studioIdentityText),
                    const SizedBox(height: 8),
                    Text(rule.$2.tr(context)),
                    const SizedBox(height: 24),
                  ],
                ],
              ],
            ),
    );
  }
}
