import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/media/preview_photos.dart';
import '../../core/ui/components.dart';
import '../../core/ui/studio_review.dart';
import '../../core/time/display_time.dart';
import '../../l10n/localization.dart';
import '../community/data/community_repository.dart';

class ChatMeetingContext extends StatelessWidget {
  const ChatMeetingContext({required this.conversation, super.key});
  final Json conversation;
  @override
  Widget build(BuildContext context) => Consumer(
    builder: (context, ref, _) {
      final event =
          findRow(
            ref.watch(communityProvider).value ?? {},
            'events',
            conversation['context_id'],
          ) ??
          {};
      return Container(
        key: const Key('chat-readonly-context'),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Row(
          children: [
            const InitialAvatar('', icon: LucideIcons.calendarDays, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venueTime(
                      event['starts_at'],
                      city: event['city'],
                      timeZone: event['time_zone'] as String?,
                      locale: context.languageCode,
                    ),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (event['place_name'] != null || event['district'] != null)
                    Text(
                      '${event['place_name'] ?? event['district']}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

void showChatInfo(BuildContext context, WidgetRef ref, String id) {
  final data = ref.read(communityProvider).value ?? {};
  final conversation = findRow(data, 'conversations', id) ?? {};
  final kind = conversation['kind'];
  final group = kind == 'group' || kind == 'event';
  final uid = ref.read(communityRepositoryProvider).userId;
  final members = chatMemberRows(data, conversation);
  final counterpart =
      conversation['target'] ??
      members.where((m) => m['user_id'] != uid).firstOrNull?['user_id'];
  final identity = group
      ? findRow(
          data,
          kind == 'group' ? 'groups' : 'events',
          conversation['context_id'],
        )
      : findRow(data, 'profiles', counterpart);
  final name =
      (identity?[group ? 'title' : 'display_name'] ?? 'Участник'.tr(context))
          .toString();
  showStudioSelectionSheet<void>(
    context: context,
    builder: (ctx) => StudioReviewSheet(
      title:
          (group
                  ? kind == 'group'
                        ? 'О сообществе'
                        : 'О встрече'
                  : 'О переписке')
              .tr(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IdentityPicture(
                id: group
                    ? '${kind == 'group' ? 'group' : 'event'}:${conversation['context_id']}'
                    : 'profile:$counterpart',
                name: group ? null : name,
                icon: group ? LucideIcons.users : LucideIcons.user,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: studioIdentityText),
                    const SizedBox(height: 4),
                    Text(
                      group
                          ? memberCount(
                              members.length,
                              locale: context.languageCode,
                            )
                          : '${identity?['district'] ?? ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (group) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            StudioReviewRow(
              title: 'Участники'.tr(context),
              subtitle: memberCount(
                members.length,
                locale: context.languageCode,
              ),
              leading: SizedBox(
                width: 80,
                height: 36,
                child: Stack(
                  children: [
                    for (final (index, m) in members.take(3).indexed)
                      Positioned(
                        left: index * 22.0,
                        child: IdentityPicture(
                          id: 'profile:${m['user_id']}',
                          icon: LucideIcons.user,
                          size: 36,
                        ),
                      ),
                  ],
                ),
              ),
              onTap: () {
                Navigator.pop(ctx);
                showChatMembers(context, data, members);
              },
            ),
          ],
          const SizedBox(height: 12),
          StudioReviewRow(
            title:
                (group
                        ? kind == 'group'
                              ? 'Пожаловаться на сообщество'
                              : 'Пожаловаться на встречу'
                        : 'Пожаловаться')
                    .tr(context),
            leading: const Icon(LucideIcons.flag),
            onTap: () {
              Navigator.pop(ctx);
              context.push(
                '/report/${group
                    ? kind == 'group'
                          ? 'group'
                          : 'event'
                    : 'profile'}/${group ? conversation['context_id'] : counterpart}',
              );
            },
          ),
          if (!group && counterpart != null)
            StudioReviewRow(
              title: 'Заблокировать'.tr(context),
              leading: const Icon(LucideIcons.userX),
              onTap: () {
                Navigator.pop(ctx);
                showStudioConfirmation(
                  context,
                  title: 'Заблокировать'.tr(context),
                  onConfirm: () async {
                    try {
                      await ref.read(communityProvider.notifier).command(
                        'block',
                        {'target_id': counterpart},
                      );
                      if (context.mounted) {
                        notice(context, 'Сохранено'.tr(context));
                      }
                    } catch (_) {
                      if (context.mounted) {
                        notice(
                          context,
                          'Не удалось сохранить. Проверьте данные и соединение.'
                              .tr(context),
                        );
                      }
                    }
                  },
                );
              },
            ),
        ],
      ),
    ),
  );
}

void showChatMembers(
  BuildContext context,
  CommunityData data,
  List<Json> members,
) {
  String query = '';
  showStudioSelectionSheet<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        final found = members
            .map(
              (m) =>
                  findRow(data, 'profiles', m['user_id']) ??
                  {'id': m['user_id'], 'display_name': 'Участник'.tr(context)},
            )
            .where(
              (p) => '${p['display_name']}'.toLowerCase().contains(
                query.toLowerCase(),
              ),
            )
            .toList();
        return StudioReviewSheet(
          title: 'Участники'.tr(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                onChanged: (s) => setState(() => query = s),
                decoration: InputDecoration(
                  hintText: 'Найти участника'.tr(context),
                  prefixIcon: const Icon(LucideIcons.search),
                ),
              ),
              if (found.isEmpty)
                StudioReviewState(
                  title: 'Ничего не найдено'.tr(context),
                  message: 'Попробуйте другое имя.'.tr(context),
                ),
              for (final p in found)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      IdentityPicture(
                        id: 'profile:${p['id']}',
                        name: p['display_name'],
                        icon: LucideIcons.user,
                        size: 36,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          p['display_name'],
                          style: studioIdentityText,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    ),
  );
}

List<Json> chatMemberRows(CommunityData data, Json conversation) {
  final kind = conversation['kind'];
  return kind == 'group'
      ? rows(
          data,
          'group_members',
        ).where((m) => m['group_id'] == conversation['context_id']).toList()
      : kind == 'event'
      ? rows(
          data,
          'event_members',
        ).where((m) => m['event_id'] == conversation['context_id']).toList()
      : rows(data, 'conversation_members')
            .where(
              (m) =>
                  m['conversation_id'] == conversation['id'] &&
                  m['left_at'] == null,
            )
            .toList();
}
