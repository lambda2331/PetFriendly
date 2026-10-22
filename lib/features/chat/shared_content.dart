import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/ui/components.dart';
import '../../core/ui/studio_review.dart';
import '../../l10n/localization.dart';
import '../community/data/community_repository.dart';
import 'chat_composer_draft.dart';

/// Canonical public record links travel in the existing authenticated message
/// body. No private payload or recipient membership is copied by sharing.
({String kind, String id})? sharedRecord(String text) {
  final match = RegExp(
    r'petfriendly://(event|group)/([^\s/?#]+)',
  ).firstMatch(text);
  if (match == null) return null;
  try {
    return (kind: match[1]!, id: Uri.decodeComponent(match[2]!));
  } on FormatException {
    return null;
  }
}

Future<void> shareMeeting(
  BuildContext context,
  WidgetRef ref,
  String id,
) async {
  final repository = ref.read(communityRepositoryProvider);
  final drafts = ref.read(chatComposerDraftsProvider);
  final data = ref.read(communityProvider).value ?? {};
  final chats = rows(data, 'conversations');
  final selected = await showStudioSelectionSheet<String>(
    context: context,
    builder: (ctx) => StudioReviewSheet(
      title: 'Поделиться'.tr(ctx),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (chats.isEmpty) StudioReviewState(title: 'Пока нет чатов'.tr(ctx)),
          for (final chat in chats)
            StudioReviewRow(
              key: ValueKey('share-chat-${chat['id']}'),
              title: conversationShareTitle(
                data,
                chat,
                repository.userId,
                locale: ctx.languageCode,
              ),
              leading: const Icon(Icons.chat_bubble_outline),
              onTap: () => Navigator.pop(ctx, '${chat['id']}'),
            ),
        ],
      ),
    ),
  );
  if (selected == null ||
      !context.mounted ||
      !drafts.active ||
      !identical(repository, ref.read(communityRepositoryProvider)) ||
      !identical(drafts, ref.read(chatComposerDraftsProvider))) {
    return;
  }
  final previous = drafts.read(selected);
  drafts.keep(
    selected,
    ChatComposerDraft(
      text: previous?.text ?? '',
      media: previous?.media,
      eventId: id,
    ),
  );
  await context.push('/chat/$selected');
}

String conversationShareTitle(
  CommunityData data,
  Json chat,
  String? uid, {
  String locale = 'ru',
}) {
  final kind = chat['kind'];
  final row = kind == 'group'
      ? findRow(data, 'groups', chat['context_id'])
      : kind == 'event'
      ? findRow(data, 'events', chat['context_id'])
      : findRow(
          data,
          'profiles',
          chat['target'] ??
              rows(data, 'conversation_members')
                  .where(
                    (m) =>
                        m['conversation_id'] == chat['id'] &&
                        m['user_id'] != uid,
                  )
                  .firstOrNull?['user_id'],
        );
  return '${row?['title'] ?? row?['display_name'] ?? chat['title'] ?? translateForLanguage('Чат', locale: locale)}';
}

class SharedRecordCard extends ConsumerWidget {
  const SharedRecordCard({required this.reference, super.key});
  final ({String kind, String id}) reference;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(communityProvider).value ?? {};
    final event = reference.kind == 'event';
    final row = findRow(data, event ? 'events' : 'groups', reference.id);
    return Semantics(
      button: true,
      child: OutlinedButton.icon(
        icon: Icon(event ? Icons.event_outlined : Icons.groups_outlined),
        label: Text(
          '${row?['title'] ?? (event ? 'Встреча'.tr(context) : 'Сообщество'.tr(context))}',
        ),
        onPressed: () => context.push(
          '/${event ? 'event' : 'group'}/${Uri.encodeComponent(reference.id)}',
        ),
      ),
    );
  }
}

String sharedMessagePreview(String text, BuildContext context) {
  final reference = sharedRecord(text);
  if (reference == null) return text;
  final caption = text
      .replaceAll(RegExp(r'petfriendly://(event|group)/[^\s/?#]+'), '')
      .trim();
  return [
    (reference.kind == 'event' ? 'Встреча' : 'Сообщество').tr(context),
    if (caption.isNotEmpty) caption,
  ].join(' · ');
}
