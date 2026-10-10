import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ui/components.dart';
import '../../../core/media/preview_photos.dart';
import '../data/community_repository.dart';

class GroupScreen extends ConsumerStatefulWidget {
  const GroupScreen({required this.id, super.key});
  final String id;
  @override
  ConsumerState<GroupScreen> createState() => _GroupState();
}

class _GroupState extends ConsumerState<GroupScreen> {
  bool busy = false;
  Future<void> membership(bool joined) async {
    setState(() => busy = true);
    try {
      await ref.read(communityProvider.notifier).command(
        joined ? 'leave_group' : 'join_group',
        {'group_in': widget.id},
      );
    } catch (_) {
      if (mounted) notice(context, 'Не удалось изменить участие');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void invite(CommunityData data, Json group) {
    final uid = ref.read(communityRepositoryProvider).userId;
    final members = rows(
      data,
      'group_members',
    ).where((m) => m['group_id'] == widget.id).map((m) => m['user_id']).toSet();
    final candidates = rows(data, 'profiles')
        .where(
          (p) =>
              p['id'] != uid &&
              !members.contains(p['id']) &&
              !rows(data, 'blocks').any((b) => b['target_id'] == p['id']),
        )
        .toList();
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      sheetAnimationStyle: studioSheetAnimation(context),
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * .55,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Пригласить в сообщество',
                style: Theme.of(ctx).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Откроется черновик личного сообщения. Человек сам решит, вступать ли ему.',
              ),
              const SizedBox(height: 16),
              if (candidates.isEmpty)
                const Text('Все доступные люди уже участвуют.'),
              ...candidates.map(
                (p) => ListTile(
                  leading: IdentityPicture(
                    id: 'profile:${p['id']}',
                    icon: Icons.person_outline,
                    size: 40,
                  ),
                  title: Text(p['display_name']),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () async {
                    Navigator.pop(ctx);
                    try {
                      final cid = await ref
                          .read(communityProvider.notifier)
                          .command('direct', {'target': p['id']});
                      if (mounted && cid != null) {
                        final draft = Uri.encodeComponent(
                          'Присоединяйтесь к «${group['title']}»!\npetfriendly://group/${widget.id}',
                        );
                        context.push('/chat/$cid?draft=$draft');
                      }
                    } catch (_) {
                      if (mounted) {
                        notice(context, 'Не удалось открыть приглашение');
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(communityProvider).value ?? {};
    final group = findRow(data, 'groups', widget.id);
    if (group == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Сообщество недоступно')),
      );
    }
    final uid = ref.read(communityRepositoryProvider).userId;
    final members = rows(
      data,
      'group_members',
    ).where((m) => m['group_id'] == widget.id).toList();
    final joined = members.any((m) => m['user_id'] == uid);
    final owner = group['owner_id'] == uid;
    final chat = rows(data, 'conversations')
        .where((c) => c['kind'] == 'group' && c['context_id'] == widget.id)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Сообщество'),
        actions: [
          if (owner)
            IconButton(
              tooltip: 'Фото сообщества',
              icon: const Icon(Icons.add_photo_alternate_outlined),
              onPressed: () async {
                try {
                  final bytes = await pickPreviewPhoto();
                  if (mounted && context.mounted && bytes != null) {
                    final persistent = await savePhoto(
                      ref,
                      'group:${widget.id}',
                      bytes,
                    );
                    if (!mounted || !context.mounted) return;
                    notice(
                      context,
                      persistent
                          ? 'Фото сохранено'
                          : 'Предпросмотр фото · до перезапуска',
                    );
                  }
                } catch (_) {
                  if (mounted && context.mounted) {
                    notice(context, 'Не удалось открыть фото');
                  }
                }
              },
            ),
        ],
      ),
      body: PageBody(
        children: [
          CommunityCover(
            id: 'group:${widget.id}',
            title: group['title'],
            prominent: true,
          ),
          const SizedBox(height: 8),
          MetadataLine(
            items: [memberCount(members.length), 'Открытое сообщество'],
          ),
          const SizedBox(height: 16),
          Text(group['description']),
          const SizedBox(height: 20),
          if (!joined)
            FilledButton(
              onPressed: busy ? null : () => membership(false),
              child: Text(busy ? 'Вступаем…' : 'Вступить в сообщество'),
            ),
          if (joined) ...[
            FilledButton.icon(
              onPressed: chat == null
                  ? null
                  : () => context.push('/chat/${chat['id']}'),
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Открыть чат сообщества'),
            ),
            TextButton.icon(
              onPressed: () => invite(data, group),
              icon: const Icon(Icons.person_add_alt, size: 18),
              label: const Text('Пригласить человека'),
            ),
          ],
          const SectionTitle('Участники'),
          ...members.map((m) {
            final p = findRow(data, 'profiles', m['user_id']);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: IdentityPicture(
                id: 'profile:${m['user_id']}',
                name: p?['display_name'],
                icon: Icons.person_outline,
                size: 40,
              ),
              title: Text(p?['display_name'] ?? 'Участник'),
              subtitle: m['user_id'] == group['owner_id']
                  ? const MetadataLine(items: ['Организатор'])
                  : null,
            );
          }),
          if (joined && !owner)
            TextButton(
              onPressed: busy ? null : () => membership(true),
              child: const Text('Выйти из сообщества'),
            ),
          Text(
            joined
                ? 'В чате видно имя автора и время каждого сообщения.'
                : 'Чат доступен после вступления. Вас не добавляют без вашего согласия.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
