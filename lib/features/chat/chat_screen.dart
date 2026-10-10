import 'chat_media.dart';
import 'chat_media_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/studio_theme.dart';
import '../../core/ui/components.dart';
import '../../core/media/preview_photos.dart';
import 'chat_repository.dart';
import 'inbox_repository.dart';
import 'conversation_context.dart';
import '../../core/time/display_time.dart';
import '../../core/backend/backend.dart';
import '../community/data/community_repository.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({this.showHeader = true, super.key});
  final bool showHeader;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final community = ref.watch(communityProvider);
    final inbox = ref.watch(chatInboxProvider);
    final repository = ref.read(communityRepositoryProvider);
    final data = community.value ?? {};
    final entries = inbox.value
        ?.where(
          (entry) =>
              entry.accountId == null || entry.accountId == repository.userId,
        )
        .toList();
    final loading = community.isLoading || inbox.isLoading;
    final failed = community.hasError || inbox.hasError;
    void retry() {
      if (community.hasError) ref.invalidate(communityProvider);
      ref.invalidate(chatInboxProvider);
    }

    final empty = !loading && !failed && entries?.isEmpty == true;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showHeader)
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            'Чаты',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Новая переписка',
                        onPressed: () => context.push('/new-chat'),
                        icon: const Icon(Icons.add_comment_outlined, size: 22),
                      ),
                    ],
                  ),
                if (showHeader) const SizedBox(height: 4),
                Text(
                  'Люди, встречи и сообщества.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (empty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Align(
                alignment: const Alignment(0, -.25),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ExcludeSemantics(
                        child: Icon(
                          Icons.chat_bubble_outline,
                          size: 32,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Пока нет переписок',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Познакомьтесь с людьми рядом или присоединитесь к встрече.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () => context.go('/people'),
                        child: const Text('Найти компанию'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            sliver: SliverList.list(
              children: [
                if (loading)
                  Semantics(
                    label: 'Загружаем переписки',
                    liveRegion: true,
                    child: const LinearProgressIndicator(),
                  ),
                if (failed) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Не удалось обновить переписки. Проверьте соединение.',
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: retry,
                      child: const Text('Повторить'),
                    ),
                  ),
                ],
                for (final (index, entry)
                    in (entries ?? <InboxEntry>[]).indexed) ...[
                  if (index > 0) const Divider(height: 1),
                  InboxRow(
                    entry: entry,
                    title: conversationTitle(data, entry.id, repository.userId),
                    author: entry.mine
                        ? 'Вы'
                        : findRow(
                                data,
                                'profiles',
                                entry.senderId,
                              )?['display_name']
                              as String?,
                    onTap: () => context.push('/chat/${entry.id}'),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class InboxRow extends StatelessWidget {
  const InboxRow({
    required this.entry,
    required this.title,
    required this.onTap,
    this.author,
    super.key,
  });
  final InboxEntry entry;
  final String title;
  final String? author;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final preview = entry.preview == null
        ? 'Начать переписку'
        : '${author == null ? '' : '$author: '}${entry.preview}';
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const InitialAvatar('', icon: Icons.chat_bubble_outline),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      preview,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (entry.lastActivity != null || entry.unread > 0) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (entry.lastActivity != null)
                            MetadataLine(
                              items: [compactChatTime(entry.lastActivity)],
                            ),
                          if (entry.unread > 0)
                            Semantics(
                              label: 'Непрочитанных сообщений: ${entry.unread}',
                              child: ExcludeSemantics(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: StudioColors.of(context).tint,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${entry.unread}',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

String conversationTitle(CommunityData data, String id, String? uid) {
  final conversation = findRow(data, 'conversations', id);
  if (conversation == null) return chatName(id);
  if (conversation['kind'] == 'group') {
    return findRow(data, 'groups', conversation['context_id'])?['title'] ??
        'Сообщество';
  }
  if (conversation['kind'] == 'event') {
    return findRow(data, 'events', conversation['context_id'])?['title'] ??
        'Встреча';
  }
  if (conversation['kind'] == 'walk') return 'Договорённость о выгуле';
  final target =
      conversation['target'] ??
      rows(data, 'conversation_members')
          .where((m) => m['conversation_id'] == id && m['user_id'] != uid)
          .firstOrNull?['user_id'];
  return findRow(data, 'profiles', target)?['display_name'] ??
      'Личная переписка';
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({required this.id, this.draft, super.key});
  final String id;
  final String? draft;
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final input = TextEditingController(), scroll = ScrollController();
  String? readFingerprint;
  MediaDraft? media;
  bool choosingMedia = false;
  bool initiallyScrolled = false;
  List<ChatMessage> renderedMessages = [];

  void acknowledge(List<ChatMessage> messages) {
    final latest = messages.where((m) => m.delivery == 'sent').lastOrNull;
    if (latest == null) return;
    final fingerprint = '${latest.id}:${latest.sentAt}';
    if (readFingerprint == fingerprint) return;
    readFingerprint = fingerprint;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || ModalRoute.of(context)?.isCurrent == false) return;
      if (!initiallyScrolled && scroll.hasClients) {
        scroll.jumpTo(scroll.position.maxScrollExtent);
        initiallyScrolled = true;
      }
      if (!scroll.hasClients || scroll.position.extentAfter > 80) {
        readFingerprint = null;
        return;
      }
      try {
        await ref.read(chatReadProvider.notifier).markRead(widget.id, messages);
      } catch (_) {
        // Keep the server unread cursor unchanged when a read acknowledgement fails.
        if (mounted) readFingerprint = null;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    input.text = widget.draft ?? '';
    scroll.addListener(() {
      if (scroll.hasClients && scroll.position.extentAfter <= 80) {
        acknowledge(renderedMessages);
      }
    });
  }

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> attach() async {
    setState(() => choosingMedia = true);
    try {
      final service = ref.read(chatMediaServiceProvider);
      final draft = await service.pickImage();
      if (mounted && draft != null) setState(() => media = draft);
    } on FormatException catch (error) {
      if (mounted) notice(context, error.message);
    } catch (_) {
      if (mounted) {
        notice(context, 'Не удалось выбрать вложение. Попробуйте другой файл.');
      }
    } finally {
      if (mounted) setState(() => choosingMedia = false);
    }
  }

  void send() {
    final draft = media;
    if (choosingMedia) return;
    if (draft == null) {
      if (input.text.trim().isEmpty) return;
      ref.read(chatProvider.notifier).send(widget.id, input.text);
    } else {
      ref.read(chatProvider.notifier).sendMedia(widget.id, draft, input.text);
      setState(() => media = null);
    }
    input.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(
          scroll.position.maxScrollExtent,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final stream = ref.watch(chatMessagesProvider(widget.id));
    ref.watch(chatMediaAvailableProvider);
    final pending = ref.watch(chatProvider)[widget.id] ?? [];
    final remote = ref.watch(backendProvider) != null;
    final messages = remote
        ? [
            ...(stream.value ?? <ChatMessage>[]).where(
              (m) =>
                  m.accountId ==
                  ref.read(backendProvider)?.auth.currentUser?.id,
            ),
            ...pending.where(
              (m) =>
                  m.accountId ==
                  ref.read(backendProvider)?.auth.currentUser?.id,
            ),
          ]
        : (pending.isNotEmpty
              ? pending
              : stream.value ??
                    ref.read(chatRepositoryProvider).messages(widget.id));
    renderedMessages = messages;
    acknowledge(messages);
    final data = ref.watch(communityProvider).value ?? {};
    final conversation = findRow(data, 'conversations', widget.id);
    final linkedContext = ConversationContext.fromConversation(conversation);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              conversationTitle(
                data,
                widget.id,
                ref.read(communityRepositoryProvider).userId,
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              remote
                  ? 'Только участники переписки'
                  : 'Демо-чат · сообщения только в памяти',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (linkedContext != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton.icon(
                  key: const Key('chat-context-link'),
                  onPressed: () => context.push(linkedContext.route),
                  icon: Icon(switch (conversation?['kind']) {
                    'group' => Icons.people_outline,
                    'event' => Icons.event_outlined,
                    _ => Icons.pets_outlined,
                  }, size: 18),
                  label: Text(linkedContext.label),
                ),
              ),
            ),
          if (stream.isLoading && remote) const LinearProgressIndicator(),
          if (stream.hasError && remote)
            TextButton(
              onPressed: () => ref.invalidate(chatMessagesProvider(widget.id)),
              child: const Text('Не удалось загрузить сообщения. Повторить'),
            ),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              padding: const EdgeInsets.all(24),
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final message = messages[i];
                final author = message.mine
                    ? 'Вы'
                    : findRow(
                            data,
                            'profiles',
                            message.senderId,
                          )?['display_name'] ??
                          'Участник';
                final time = message.sentAt?.toLocal();
                final invitation = conversation?['kind'] == 'group'
                    ? null
                    : RegExp(
                        r'petfriendly://group/([a-fA-F0-9-]{36})',
                      ).firstMatch(message.text)?.group(1);
                return Align(
                  alignment: message.mine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width * .76,
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: message.mine
                          ? StudioColors.lime
                          : StudioColors.of(context).tint,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!message.mine) ...[
                              IdentityPicture(
                                id: 'profile:${message.senderId}',
                                icon: Icons.person_outline,
                                size: 24,
                              ),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Text(
                                author,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: message.mine
                                      ? StudioColors.onLime
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (message.attachment != null) ...[
                          ChatMediaTile(
                            messageId: message.id,
                            attachment: message.attachment!,
                            local: message.localMedia,
                            foreground: message.mine
                                ? StudioColors.onLime
                                : null,
                          ),
                          const SizedBox(height: 6),
                        ],
                        Text(
                          message.text,
                          style: TextStyle(
                            color: message.mine ? StudioColors.onLime : null,
                          ),
                        ),
                        if (time != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            readableLocalDateTime(time),
                            style: TextStyle(
                              fontSize: 11,
                              color: message.mine
                                  ? StudioColors.onLime
                                  : Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (invitation != null)
                          TextButton(
                            onPressed: () => context.push('/group/$invitation'),
                            child: Text(
                              'Открыть сообщество',
                              style: TextStyle(
                                color: message.mine
                                    ? StudioColors.onLime
                                    : null,
                              ),
                            ),
                          ),
                        if (message.delivery == 'pending')
                          const Text(
                            'Отправляется…',
                            style: TextStyle(
                              fontSize: 11,
                              color: StudioColors.onLime,
                            ),
                          ),
                        if (message.delivery == 'failed')
                          TextButton(
                            onPressed: () => message.localMedia == null
                                ? ref
                                      .read(chatProvider.notifier)
                                      .send(
                                        widget.id,
                                        message.text,
                                        retryId: message.id,
                                      )
                                : ref
                                      .read(chatProvider.notifier)
                                      .sendMedia(
                                        widget.id,
                                        message.localMedia!,
                                        message.text,
                                        retryId: message.id,
                                      ),
                            child: const Text('Не отправлено · повторить'),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (choosingMedia)
            const LinearProgressIndicator(
              semanticsLabel: 'Подготовка вложения',
            ),
          if (media != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (media!.kind == 'image')
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        media!.bytes,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    const Icon(Icons.videocam_outlined, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${media!.label} · ${(media!.bytes.length / 1024 / 1024).toStringAsFixed(1)} МБ',
                    ),
                  ),
                  IconButton(
                    tooltip: 'Убрать вложение',
                    onPressed: () => setState(() => media = null),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    key: const Key('attach-media'),
                    tooltip: 'Добавить фото или видео',
                    onPressed: choosingMedia
                        ? null
                        : () =>
                              ref.read(chatMediaAvailableProvider).value == true
                              ? attach()
                              : notice(
                                  context,
                                  'Вложения сейчас недоступны. Попробуйте позже.',
                                ),
                    icon: const Icon(Icons.add),
                  ),
                  Expanded(
                    child: TextField(
                      textAlignVertical: TextAlignVertical.top,
                      key: const Key('message-input'),
                      controller: input,
                      maxLength: 1000,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'Написать сообщение…',
                        counterText: '',
                      ),
                      onSubmitted: (_) => send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    key: const Key('send-message'),
                    tooltip: 'Отправить',
                    onPressed: send,
                    icon: const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
