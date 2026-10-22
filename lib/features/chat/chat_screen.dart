import 'shared_content.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/ui/studio_review.dart';
import 'new_chat_screen.dart';
import 'chat_info_sheet.dart';
import '../../l10n/localization.dart';
import 'chat_media.dart';
import 'chat_composer_draft.dart';
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
import '../walks/walking_chat_controller.dart';
import '../walks/walking_chat_widgets.dart';
import '../walks/walking_chat_report.dart';

class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({this.showHeader = true, super.key});
  final bool showHeader;
  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen> {
  String query = '';
  String filter = 'all';
  @override
  Widget build(BuildContext context) {
    final community = ref.watch(communityProvider),
        inbox = ref.watch(chatInboxProvider);
    final repository = ref.watch(communityRepositoryProvider);
    final data = community.value ?? {};
    final all = (inbox.value ?? [])
        .where((e) => e.accountId == null || e.accountId == repository.userId)
        .toList();
    final entries = all.where((e) {
      final kind = findRow(data, 'conversations', e.id)?['kind'] ?? 'direct';
      final type = kind == 'walk'
          ? 'walk'
          : ['group', 'event'].contains(kind)
          ? 'community'
          : 'direct';
      return (filter == 'all' || filter == type) &&
          conversationTitle(
            data,
            e.id,
            repository.userId,
            locale: context.languageCode,
          ).toLowerCase().contains(query.trim().toLowerCase());
    }).toList();
    void retry() {
      ref.invalidate(communityProvider);
      ref.invalidate(chatInboxProvider);
    }

    final keys = ['all', 'direct', 'community', 'walk'],
        labels = ['Все', 'Личные', 'Сообщества', 'Прогулки'];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Чаты'.tr(context),
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(fontSize: 28),
              ),
            ),
            IconButton.filled(
              tooltip: 'Новая переписка'.tr(context),
              onPressed: () => showNewChatSheet(context),
              icon: const Icon(LucideIcons.plus),
            ),
          ],
        ),
        const SizedBox(height: 20),
        TextField(
          onChanged: (s) => setState(() => query = s),
          decoration: InputDecoration(
            hintText: 'Имя или переписка'.tr(context),
            prefixIcon: const Icon(LucideIcons.search),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final style = DefaultTextStyle.of(context).style.merge(
              const TextStyle(fontFamily: 'Golos Text', fontSize: 14),
            );
            final widths = labels.map((label) {
              final painter = TextPainter(
                text: TextSpan(
                  text: label.tr(context),
                  style: style.copyWith(fontWeight: FontWeight.w600),
                ),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
              )..layout();
              return painter.width.ceilToDouble() + 18;
            }).toList();
            final total = widths.fold<double>(0, (a, b) => a + b);
            final extra = total < constraints.maxWidth
                ? (constraints.maxWidth - total) / keys.length
                : 0.0;
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < keys.length; i++)
                    Semantics(
                      selected: filter == keys[i],
                      button: true,
                      child: InkWell(
                        onTap: () => setState(() => filter = keys[i]),
                        child: Container(
                          width: widths[i] + extra,
                          constraints: const BoxConstraints(minHeight: 48),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: filter == keys[i]
                                    ? Theme.of(context).colorScheme.onSurface
                                    : StudioColors.of(context).line,
                                width: filter == keys[i] ? 2 : 1,
                              ),
                            ),
                          ),
                          child: Text(
                            labels[i].tr(context),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            softWrap: false,
                            style: style.copyWith(
                              fontWeight: filter == keys[i]
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        if (community.isLoading || inbox.isLoading)
          StudioReviewState(
            title: 'Загружаем переписки…'.tr(context),
            loading: true,
          )
        else if (community.hasError || inbox.hasError)
          StudioReviewState(
            title: 'Не удалось загрузить'.tr(context),
            message: 'Проверьте соединение и попробуйте снова.'.tr(context),
            icon: LucideIcons.cloudOff,
            action: OutlinedButton(
              onPressed: retry,
              child: Text('Повторить'.tr(context)),
            ),
          )
        else if (all.isEmpty)
          StudioReviewState(
            title: 'Пока нет переписок'.tr(context),
            message: 'Найдите человека и начните разговор.'.tr(context),
            icon: LucideIcons.messageSquare,
            action: OutlinedButton(
              onPressed: () => showNewChatSheet(context),
              child: Text('Новая переписка'.tr(context)),
            ),
          )
        else if (entries.isEmpty)
          StudioReviewState(
            title: 'Ничего не найдено'.tr(context),
            message: 'Попробуйте другое имя.'.tr(context),
            icon: LucideIcons.search,
          ),
        if (!community.isLoading && !inbox.isLoading)
          for (final (index, e) in entries.indexed) ...[
            if (index > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Divider(height: 1),
              ),
            InboxRow(
              entry: e,
              title: conversationTitle(
                data,
                e.id,
                repository.userId,
                locale: context.languageCode,
              ),
              kind:
                  findRow(data, 'conversations', e.id)?['kind'] as String? ??
                  'direct',
              avatarId: chatCounterpart(data, e.id, repository.userId),
              author: e.mine
                  ? 'Вы'.tr(context)
                  : findRow(data, 'profiles', e.senderId)?['display_name']
                        as String?,
              onTap: () => context.push('/chat/${e.id}'),
            ),
          ],
      ],
    );
  }
}

String? chatCounterpart(CommunityData data, String id, String? uid) =>
    rows(data, 'conversation_members')
            .where(
              (m) =>
                  m['conversation_id'] == id &&
                  m['user_id'] != uid &&
                  m['left_at'] == null,
            )
            .firstOrNull?['user_id']
        as String?;

class InboxRow extends StatelessWidget {
  const InboxRow({
    required this.entry,
    required this.title,
    required this.onTap,
    this.author,
    this.kind = 'direct',
    this.avatarId,
    super.key,
  });
  final InboxEntry entry;
  final String title, kind;
  final String? author, avatarId;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final label = switch (kind) {
      'group' => 'Сообщество',
      'event' => 'Встреча',
      'walk' => 'Прогулка',
      _ => 'Личная переписка',
    };
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (avatarId == null)
                const InitialAvatar('', icon: LucideIcons.user)
              else
                IdentityPicture(
                  id: 'profile:$avatarId',
                  name: ['direct', 'walk'].contains(kind) ? title : null,
                  icon: switch (kind) {
                    'group' => LucideIcons.users,
                    'event' => LucideIcons.calendarDays,
                    _ => LucideIcons.user,
                  },
                  size: 56,
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(title, style: studioIdentityText)),
                        if (entry.lastActivity != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            compactChatTime(
                              entry.lastActivity,
                              locale: context.languageCode,
                            ),
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label.tr(context),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.preview == null
                                ? 'Начать переписку'.tr(context)
                                : '${author == null ? '' : '$author: '}${sharedMessagePreview(entry.preview!, context)}',
                            maxLines:
                                MediaQuery.textScalerOf(context).scale(1) > 1.3
                                ? 3
                                : 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: entry.unread > 0
                                      ? Theme.of(context).colorScheme.onSurface
                                      : null,
                                ),
                          ),
                        ),
                        if (entry.unread > 0) ...[
                          const SizedBox(width: 8),
                          Semantics(
                            label: 'Непрочитанных сообщений: {p0}'.tr(
                              context,
                              arguments: {'p0': entry.unread},
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: StudioColors.lime,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${entry.unread}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: StudioColors.onLime,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String conversationTitle(
  CommunityData data,
  String id,
  String? uid, {
  String locale = 'ru',
}) {
  final conversation = findRow(data, 'conversations', id);
  if (conversation == null) return chatName(id);
  if (conversation['kind'] == 'group') {
    return findRow(data, 'groups', conversation['context_id'])?['title'] ??
        translateForLanguage('Сообщество', locale: locale);
  }
  if (conversation['kind'] == 'event') {
    return findRow(data, 'events', conversation['context_id'])?['title'] ??
        translateForLanguage('Встреча', locale: locale);
  }
  if (conversation['kind'] == 'walk') {
    return translateForLanguage('Договорённость о выгуле', locale: locale);
  }
  final target =
      conversation['target'] ??
      rows(data, 'conversation_members')
          .where((m) => m['conversation_id'] == id && m['user_id'] != uid)
          .firstOrNull?['user_id'];
  return findRow(data, 'profiles', target)?['display_name'] ??
      translateForLanguage('Личная переписка', locale: locale);
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
  String? sharedEventId;
  bool choosingMedia = false;
  bool initiallyScrolled = false;
  List<ChatMessage> renderedMessages = [];
  String? walkingLoadedAccount;
  late ChatComposerDrafts composerDrafts;
  bool restoringComposer = false;

  bool composerCurrent(ChatComposerDrafts store) =>
      mounted &&
      store.active &&
      identical(ref.read(chatComposerDraftsProvider), store);

  void keepComposer() {
    if (restoringComposer || !composerCurrent(composerDrafts)) return;
    composerDrafts.keep(
      widget.id,
      ChatComposerDraft(text: input.text, media: media, eventId: sharedEventId),
    );
  }

  void restoreComposer({bool initial = false}) {
    restoringComposer = true;
    final draft = composerDrafts.read(widget.id);
    input.text = draft?.text ?? (initial ? widget.draft ?? '' : '');
    media = draft?.media;
    sharedEventId = draft?.eventId;
    restoringComposer = false;
    keepComposer();
  }

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
    composerDrafts = ref.read(chatComposerDraftsProvider);
    restoreComposer(initial: true);
    input.addListener(keepComposer);
    ref.listenManual(chatComposerDraftsProvider, (previous, next) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!composerCurrent(next)) return;
        setState(() {
          composerDrafts = next;
          choosingMedia = false;
          restoreComposer();
        });
      });
    });
    scroll.addListener(() {
      if (scroll.hasClients && scroll.position.extentAfter <= 80) {
        acknowledge(renderedMessages);
      }
    });
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      restoreComposer(initial: true);
      readFingerprint = null;
      initiallyScrolled = false;
    }
  }

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> attach() async {
    final store = composerDrafts;
    final conversationId = widget.id;
    if (!composerCurrent(store)) return;
    setState(() => choosingMedia = true);
    try {
      final service = ref.read(chatMediaServiceProvider);
      final draft = await service.pickImage();
      if (mounted &&
          composerCurrent(store) &&
          widget.id == conversationId &&
          draft != null) {
        setState(() => media = draft);
        keepComposer();
      }
    } on FormatException catch (error) {
      if (mounted && composerCurrent(store) && widget.id == conversationId) {
        notice(context, error.message);
      }
    } catch (_) {
      if (mounted && composerCurrent(store) && widget.id == conversationId) {
        notice(
          context,
          "Не удалось выбрать вложение. Попробуйте другой файл.".tr(context),
        );
      }
    } finally {
      if (mounted && composerCurrent(store) && widget.id == conversationId) {
        setState(() => choosingMedia = false);
      }
    }
  }

  void send() {
    final draft = media;
    final body = [
      if (input.text.trim().isNotEmpty) input.text.trim(),
      if (sharedEventId != null)
        'petfriendly://event/${Uri.encodeComponent(sharedEventId!)}',
    ].join('\n');
    if (choosingMedia || !composerCurrent(composerDrafts)) return;
    if (!chatTextFitsLimit(body)) {
      notice(
        context,
        "Сообщение должно быть не длиннее 1000 символов".tr(context),
      );
      return;
    }
    if (draft == null) {
      if (body.isEmpty) return;
      ref.read(chatProvider.notifier).send(widget.id, body);
    } else {
      ref.read(chatProvider.notifier).sendMedia(widget.id, draft, body);
      setState(() => media = null);
    }
    setState(() => sharedEventId = null);
    input.clear();
    keepComposer();
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
    final snapshot = ref.watch(communityProvider);
    final data = snapshot.value ?? <String, List<Json>>{};
    final conversation = findRow(data, 'conversations', widget.id);
    final repository = ref.watch(communityRepositoryProvider);
    final legacyDemo =
        repository is DemoCommunityRepository &&
        repository.seedSamples &&
        ['anna', 'event', 'neighbors'].contains(widget.id);
    if (!snapshot.hasValue || (conversation == null && !legacyDemo)) {
      return Scaffold(
        appBar: AppBar(centerTitle: true, title: Text('Чат'.tr(context))),
        body: StudioReviewState(
          title: (snapshot.isLoading ? 'Загружаем…' : 'Переписка недоступна')
              .tr(context),
          loading: snapshot.isLoading,
          action: snapshot.isLoading
              ? null
              : OutlinedButton(
                  onPressed: () => ref.invalidate(communityProvider),
                  child: Text('Повторить'.tr(context)),
                ),
        ),
      );
    }
    ref.watch(chatComposerDraftsProvider);
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

    final linkedContext = ConversationContext.fromConversation(conversation);
    final uid = ref.watch(communityRepositoryProvider).userId;
    final isWalk = conversation?['kind'] == 'walk';
    ref.listen(communityProvider, (previous, next) {
      if (isWalk && next.value != null && previous?.value != next.value) {
        ref.read(walkingChatProvider.notifier).load(widget.id);
      }
    });
    final walkingState = isWalk
        ? ref.watch(walkingChatProvider).records[widget.id]
        : null;
    final accountKey = '$uid:${widget.id}';
    if (isWalk && walkingLoadedAccount != accountKey) {
      walkingLoadedAccount = accountKey;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(walkingChatProvider.notifier).load(widget.id);
      });
    }
    final walkingItem = walkingState?.item;
    final counterpart = walkingItem == null
        ? null
        : (walkingItem['my_role'] == 'helper'
                  ? walkingItem['owner']
                  : walkingItem['helper'])
              as Map?;

    final counterpartId =
        counterpart?['id'] as String? ??
        rows(data, 'conversation_members')
                .where(
                  (m) =>
                      m['conversation_id'] == widget.id &&
                      m['user_id'] != uid &&
                      m['left_at'] == null,
                )
                .firstOrNull?['user_id']
            as String?;
    final title = isWalk
        ? ((counterpart?['display_name'] as String?) ??
              (findRow(data, 'profiles', counterpartId)?['display_name']
                  as String?) ??
              'Участник'.tr(context))
        : conversationTitle(data, widget.id, uid, locale: context.languageCode);
    final privacyLabel = remote
        ? 'Только участники переписки'.tr(context)
        : 'Демо-чат · сообщения только в памяти'.tr(context);
    final compactWalkKeyboard = MediaQuery.viewInsetsOf(context).bottom > 0;
    final titleStyle = Theme.of(context).textTheme.titleMedium!;
    final titleWidth = (MediaQuery.sizeOf(context).width - 56 - 52 - 20).clamp(
      1.0,
      double.infinity,
    );
    double textHeight(String text, TextStyle style, {int? maxLines}) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: maxLines,
      )..layout(maxWidth: titleWidth);
      final height = painter.height;
      painter.dispose();
      return height;
    }

    final toolbarHeight =
        (textHeight(
                  title,
                  titleStyle,
                  maxLines: isWalk || compactWalkKeyboard ? 2 : null,
                ) +
                16)
            .clamp(kToolbarHeight, double.infinity);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: toolbarHeight,
        leadingWidth: 56,
        leading: IconButton(
          tooltip: 'Назад'.tr(context),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/chats');
            }
          },
          icon: const Icon(LucideIcons.arrowLeft),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: StudioColors.of(context).line),
        ),
        titleSpacing: 0,
        title: PopupMenuButton<String>(
          tooltip: 'О переписке'.tr(context),
          onSelected: (value) {
            if (value == 'info') showChatInfo(context, ref, widget.id);
            if (value == 'report') showWalkingChatReport(context, widget.id);
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'info',
              child: Text('О переписке'.tr(context)),
            ),
            if (isWalk)
              PopupMenuItem(
                key: const Key('walking-chat-report'),
                value: 'report',
                enabled: walkingItem != null,
                child: Text('Сообщить о проблеме'.tr(context)),
              ),
          ],
          child: Row(
            key: conversation?['kind'] == 'group'
                ? const Key('chat-readonly-context')
                : null,
            children: [
              ...[
                SizedBox(
                  child: IdentityPicture(
                    key: const Key('walking-chat-counterpart-avatar'),
                    id: 'profile:$counterpartId',
                    name: ['group', 'event'].contains(conversation?['kind'])
                        ? null
                        : title,
                    icon: conversation?['kind'] == 'group'
                        ? LucideIcons.users
                        : conversation?['kind'] == 'event'
                        ? LucideIcons.calendarDays
                        : LucideIcons.user,
                    size: 40,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: titleStyle,
                      maxLines: isWalk || compactWalkKeyboard ? 2 : null,
                      overflow: isWalk || compactWalkKeyboard
                          ? TextOverflow.ellipsis
                          : TextOverflow.visible,
                      semanticsLabel: isWalk || compactWalkKeyboard
                          ? '$title · $privacyLabel'
                          : null,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          if (conversation?['kind'] == 'event')
            ChatMeetingContext(conversation: conversation!),
          if (isWalk)
            WalkingChatContext(
              id: widget.id,
              maximumHeight:
                  (MediaQuery.sizeOf(context).height -
                      MediaQuery.viewInsetsOf(context).bottom) *
                  (compactWalkKeyboard ? .18 : .30),
            ),
          if (linkedContext != null)
            ListTile(
              key: const Key('chat-context-link'),
              title: Text(linkedContext.label.tr(context)),
              trailing: const Icon(LucideIcons.chevronRight),
              onTap: () => context.push(linkedContext.route),
            ),
          if (stream.isLoading && remote) const LinearProgressIndicator(),
          if (stream.hasError && remote)
            TextButton(
              onPressed: () => ref.invalidate(chatMessagesProvider(widget.id)),
              child: Text(
                "Не удалось загрузить сообщения. Повторить".tr(context),
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: scroll,
              padding: const EdgeInsets.all(20),
              itemCount: messages.length,
              itemBuilder: (context, i) {
                final message = messages[i];
                final author = message.mine
                    ? "Вы".tr(context)
                    : findRow(
                            data,
                            'profiles',
                            message.senderId,
                          )?['display_name'] ??
                          "Участник".tr(context);
                final time = message.sentAt?.toLocal();
                final previousTime = i > 0
                    ? messages[i - 1].sentAt?.toLocal()
                    : null;
                final showDay =
                    time != null &&
                    (previousTime == null ||
                        previousTime.year != time.year ||
                        previousTime.month != time.month ||
                        previousTime.day != time.day);
                final bubble = Align(
                  alignment: message.mine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: (MediaQuery.sizeOf(context).width - 40) * .90,
                    ),
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: message.mine
                          ? StudioColors.lime
                          : StudioColors.of(context).tint,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!message.mine) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
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
                          SizedBox(height: isWalk ? 4 : 6),
                        ],
                        if (message.attachment != null) ...[
                          ChatMediaTile(
                            messageId: message.id,
                            attachment: message.attachment!,
                            local: message.localMedia,
                            foreground: message.mine
                                ? StudioColors.onLime
                                : null,
                          ),
                          SizedBox(height: isWalk ? 4 : 6),
                        ],
                        if (sharedRecord(message.text) case final reference?)
                          SharedRecordCard(reference: reference),
                        Text(
                          message.text
                              .replaceAll(
                                RegExp(
                                  r'petfriendly://(event|group)/[^\s/?#]+',
                                ),
                                '',
                              )
                              .trim(),
                          style: TextStyle(
                            color: message.mine ? StudioColors.onLime : null,
                          ),
                        ),
                        if (isWalk || time != null) ...[
                          SizedBox(height: isWalk ? 4 : 6),
                          Text(
                            [
                              if (message.mine) author,
                              if (time != null)
                                readableLocalDateTime(
                                  time,
                                  locale: context.languageCode,
                                ).split(' · ').last,
                            ].join(' · '),
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
                        if (message.delivery == 'pending')
                          Text(
                            "Отправляется…".tr(context),
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
                            child: Text(
                              "Не отправлено · повторить".tr(context),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showDay)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12, top: 4),
                        child: Text(
                          DateUtils.isSameDay(time, DateTime.now())
                              ? 'Сегодня'.tr(context)
                              : readableLocalDateTime(
                                  time,
                                  locale: context.languageCode,
                                ).split(' · ').first,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    bubble,
                  ],
                );
              },
            ),
          ),
          if (choosingMedia)
            LinearProgressIndicator(
              semanticsLabel: "Подготовка вложения".tr(context),
            ),
          if (sharedEventId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: SharedRecordCard(
                      reference: (kind: 'event', id: sharedEventId!),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Убрать вложение'.tr(context),
                    onPressed: () {
                      setState(() => sharedEventId = null);
                      keepComposer();
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
          if (media != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isWalk ? 20 : 16),
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
                      "{p0} · {p1} МБ".tr(
                        context,
                        arguments: {
                          'p0': media!.label,
                          'p1': (media!.bytes.length / 1024 / 1024)
                              .toStringAsFixed(1),
                        },
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: "Убрать вложение".tr(context),
                    onPressed: () {
                      setState(() => media = null);
                      keepComposer();
                    },
                    icon: const Icon(LucideIcons.x),
                  ),
                ],
              ),
            ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: compactWalkKeyboard
                  ? ((MediaQuery.sizeOf(context).height -
                                MediaQuery.viewInsetsOf(context).bottom -
                                MediaQuery.paddingOf(context).top -
                                toolbarHeight) *
                            .5)
                        .clamp(48.0, double.infinity)
                  : double.infinity,
            ),
            child: SingleChildScrollView(
              child: SafeArea(
                top: false,
                child: Container(
                  decoration: isWalk
                      ? BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.outlineVariant,
                            ),
                          ),
                        )
                      : null,
                  padding: isWalk
                      ? const EdgeInsets.fromLTRB(20, 12, 20, 12)
                      : const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      IconButton(
                        key: const Key('attach-media'),
                        tooltip: "Добавить фото".tr(context),
                        onPressed: choosingMedia
                            ? null
                            : () =>
                                  ref.read(chatMediaAvailableProvider).value ==
                                      true
                                  ? attach()
                                  : notice(
                                      context,
                                      "Вложения сейчас недоступны. Попробуйте позже."
                                          .tr(context),
                                    ),
                        icon: const Icon(LucideIcons.image),
                      ),
                      Expanded(
                        child: TextField(
                          textAlignVertical: TextAlignVertical.top,
                          key: const Key('message-input'),
                          controller: input,
                          maxLength: 1000,
                          minLines: 1,
                          maxLines: compactWalkKeyboard ? 2 : 4,
                          decoration: InputDecoration(
                            hintText: "Написать сообщение…".tr(context),
                            counterText: '',
                          ),
                          onSubmitted: (_) => send(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        key: const Key('send-message'),
                        style: IconButton.styleFrom(
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                        ),
                        tooltip: "Отправить".tr(context),
                        onPressed: send,
                        icon: const Icon(Icons.arrow_upward),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
