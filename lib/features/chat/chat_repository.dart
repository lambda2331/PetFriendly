import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/backend/backend.dart';
import '../community/data/community_repository.dart';
import 'chat_media.dart';

/// Match PostgreSQL char_length: Unicode code points, not UTF-16 units.
bool chatTextFitsLimit(String text) => text.runes.length <= 1000;

class ChatMessage {
  const ChatMessage(
    this.text, {
    this.mine = false,
    this.id = '',
    this.delivery = 'sent',
    this.senderId,
    this.sentAt,
    this.accountId,
    this.attachment,
    this.localMedia,
  });
  final String text, id, delivery;
  final bool mine;
  final String? senderId, accountId;
  final DateTime? sentAt;
  final ChatAttachment? attachment;
  final MediaDraft? localMedia;
}

class DemoChatRepository {
  DemoChatRepository({this.resolveSender, this.seedMessages = true});
  final bool seedMessages;
  final String? Function(String)? resolveSender;
  final Map<String, List<ChatMessage>> _messages = {};
  List<ChatMessage> messages(String id) => List.unmodifiable(
    _messages.putIfAbsent(id, () {
      if (!seedMessages) return [];
      final sender = resolveSender == null ? demoAnna : resolveSender!(id);
      if (sender == null) {
        return [];
      }
      return [
        ChatMessage(
          'Привет! Встречаемся у входа в парк?',
          senderId: sender,
          sentAt: DateTime.now().subtract(const Duration(minutes: 4)),
        ),
        ChatMessage(
          'Да, будем с Луной в 18:30.',
          mine: true,
          sentAt: DateTime.now().subtract(const Duration(minutes: 3)),
        ),
      ];
    }),
  );
  void send(String id, String text) {
    final value = text.trim();
    if (value.isEmpty || !chatTextFitsLimit(value)) return;
    messages(id);
    _messages[id]!.add(ChatMessage(value, mine: true, sentAt: DateTime.now()));
  }

  void sendMedia(String id, MediaDraft draft, String caption) {
    validateChatUpload(draft);
    messages(id);
    _messages[id]!.add(
      ChatMessage(
        caption.isEmpty ? draft.label : caption,
        mine: true,
        sentAt: DateTime.now(),
        attachment: ChatAttachment(
          draft.kind,
          draft.mime,
          duration: draft.duration,
        ),
        localMedia: draft,
      ),
    );
  }
}

final chatRepositoryProvider = Provider((ref) {
  ref.watch(authStateProvider.select((state) => state.value?.id));
  return DemoChatRepository(
    seedMessages:
        ref.read(communityRepositoryProvider) is DemoCommunityRepository &&
        (ref.read(communityRepositoryProvider) as DemoCommunityRepository)
            .seedSamples,
    resolveSender: (id) {
      final data = ref.read(communityProvider).value ?? {};
      final conversation = findRow(data, 'conversations', id);
      if (conversation == null) return demoAnna;
      if (conversation['kind'] == 'direct') {
        return conversation['target'] as String?;
      }
      if (conversation['kind'] == 'group') {
        return rows(data, 'group_members')
                .where(
                  (m) =>
                      m['group_id'] == conversation['context_id'] &&
                      m['user_id'] !=
                          ref.read(communityRepositoryProvider).userId,
                )
                .firstOrNull?['user_id']
            as String?;
      }
      return null;
    },
  );
});
final chatMessagesProvider = StreamProvider.autoDispose
    .family<List<ChatMessage>, String>((ref, id) {
      ref.watch(authStateProvider.select((state) => state.value?.id));
      final client = ref.watch(backendProvider);
      final supportsMedia = ref.watch(chatMediaAvailableProvider).value == true;
      if (client == null) {
        return Stream.value(ref.read(chatRepositoryProvider).messages(id));
      }
      final accountId = client.auth.currentUser?.id;
      final controller = StreamController<List<ChatMessage>>();
      bool fetching = false, again = false, disposed = false;
      Future<void> load() async {
        if (disposed) return;
        if (fetching) {
          again = true;
          return;
        }
        fetching = true;
        try {
          final rows = await client
              .from('messages')
              .select(supportsMedia ? '*,chat_attachments(*)' : '*')
              .eq('conversation_id', id)
              .order('created_at', ascending: false)
              .order('id', ascending: false)
              .limit(100);
          if (!disposed) {
            controller.add(
              rows.reversed
                  .map(
                    (row) => ChatMessage(
                      row['body'],
                      id: row['id'],
                      senderId: row['sender_id'],
                      sentAt: DateTime.tryParse(row['created_at'] ?? ''),
                      mine: row['sender_id'] == accountId,
                      accountId: accountId,
                      attachment: decodeChatAttachment(row['chat_attachments']),
                    ),
                  )
                  .toList(),
            );
          }
        } catch (e) {
          if (!disposed) {
            if (client.auth.currentUser == null ||
                e is PostgrestException && e.code == '42501') {
              controller.add(const <ChatMessage>[]);
            }
            controller.addError(e);
          }
        } finally {
          fetching = false;
          if (again) {
            again = false;
            load();
          }
        }
      }

      final subscription = client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', client.auth.currentUser?.id ?? '')
          .listen((_) => load(), onError: (Object error) => load());
      load();
      final timer = Timer.periodic(const Duration(seconds: 15), (_) => load());
      ref.onDispose(() {
        disposed = true;
        timer.cancel();
        subscription.cancel();
        controller.close();
      });
      return controller.stream;
    });

class ChatController extends Notifier<Map<String, List<ChatMessage>>> {
  @override
  Map<String, List<ChatMessage>> build() {
    ref.watch(authStateProvider.select((state) => state.value?.id));
    return {};
  }

  Future<void> send(String id, String text, {String? retryId}) async {
    final value = text.trim();
    if (value.isEmpty || !chatTextFitsLimit(value)) return;
    final client = ref.read(backendProvider);
    if (client == null) {
      ref.read(chatRepositoryProvider).send(id, value);
      state = {...state, id: ref.read(chatRepositoryProvider).messages(id)};
      ref.invalidate(chatMessagesProvider(id));
      return;
    }
    final nonce = retryId ?? const Uuid().v4();
    final sendingAs = client.auth.currentUser?.id;
    final pending = (state[id] ?? []).where((m) => m.id != nonce).toList()
      ..add(
        ChatMessage(
          value,
          mine: true,
          id: nonce,
          delivery: 'pending',
          accountId: sendingAs,
          sentAt: DateTime.now(),
        ),
      );
    state = {...state, id: pending};
    try {
      await client.rpc(
        'send_message',
        params: {'conversation_in': id, 'client_id': nonce, 'body_in': value},
      );
      if (client.auth.currentUser?.id != sendingAs) return;
      state = {
        ...state,
        id: (state[id] ?? []).where((m) => m.id != nonce).toList(),
      };
      ref.invalidate(chatMessagesProvider(id));
    } catch (_) {
      if (client.auth.currentUser?.id != sendingAs) return;
      state = {
        ...state,
        id: (state[id] ?? [])
            .map(
              (m) => m.id == nonce
                  ? ChatMessage(
                      m.text,
                      mine: true,
                      id: nonce,
                      delivery: 'failed',
                      sentAt: m.sentAt,
                      senderId: m.senderId,
                      accountId: m.accountId,
                    )
                  : m,
            )
            .toList(),
      };
    }
  }

  Future<void> sendMedia(
    String id,
    MediaDraft draft,
    String caption, {
    String? retryId,
  }) async {
    validateChatUpload(draft);
    final client = ref.read(backendProvider), value = caption.trim();
    if (!chatTextFitsLimit(value)) return;
    if (client == null) {
      ref.read(chatRepositoryProvider).sendMedia(id, draft, value);
      state = {...state, id: ref.read(chatRepositoryProvider).messages(id)};
      ref.invalidate(chatMessagesProvider(id));
      return;
    }
    final nonce = retryId ?? const Uuid().v4(),
        account = client.auth.currentUser?.id;
    ChatMessage message(String delivery) => ChatMessage(
      value.isEmpty ? draft.label : value,
      id: nonce,
      mine: true,
      delivery: delivery,
      accountId: account,
      sentAt: DateTime.now(),
      attachment: ChatAttachment(
        draft.kind,
        draft.mime,
        duration: draft.duration,
      ),
      localMedia: draft,
    );
    state = {
      ...state,
      id: [
        ...(state[id] ?? []).where((m) => m.id != nonce),
        message('pending'),
      ],
    };
    try {
      await client.functions.invoke(
        'chat-media',
        body: encodeMediaUpload(draft, value),
        headers: {'Content-Type': 'application/octet-stream'},
        queryParameters: {
          'conversation': id,
          'client_id': nonce,
          'kind': draft.kind,
        },
      );
      if (client.auth.currentUser?.id != account) return;
      state = {
        ...state,
        id: (state[id] ?? []).where((m) => m.id != nonce).toList(),
      };
      ref.invalidate(chatMessagesProvider(id));
    } catch (_) {
      if (client.auth.currentUser?.id != account) return;
      state = {
        ...state,
        id: [
          ...(state[id] ?? []).where((m) => m.id != nonce),
          message('failed'),
        ],
      };
    }
  }
}

final chatProvider =
    NotifierProvider<ChatController, Map<String, List<ChatMessage>>>(
      ChatController.new,
    );
String chatName(String id) => switch (id) {
  'anna' => 'Анна и Бруно',
  'event' => 'Вечерняя прогулка',
  'mark' => 'Марк и Тедди',
  'neighbors' => 'Соседи с питомцами',
  'helper' => 'Саша',
  _ => 'Переписка',
};
