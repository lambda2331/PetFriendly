import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/backend/backend.dart';
import '../community/data/community_repository.dart';
import 'chat_repository.dart';

class InboxEntry {
  const InboxEntry({
    required this.id,
    this.preview,
    this.senderId,
    this.lastActivity,
    this.unread = 0,
    this.mine = false,
    this.accountId,
  });
  final String id;
  final String? preview, senderId;
  final String? accountId;
  final DateTime? lastActivity;
  final int unread;
  final bool mine;

  factory InboxEntry.fromJson(Map<String, dynamic> row, String? userId) =>
      InboxEntry(
        id: row['conversation_id'] as String,
        preview: row['body'] as String?,
        senderId: row['sender_id'] as String?,
        lastActivity: DateTime.tryParse('${row['created_at']}'),
        unread: (row['unread_count'] as num?)?.toInt() ?? 0,
        mine: row['sender_id'] == userId,
        accountId: userId,
      );
}

InboxEntry demoInboxEntry(
  String id,
  List<ChatMessage> messages,
  DateTime? readAt,
) {
  final latest = messages.lastOrNull;
  return InboxEntry(
    id: id,
    preview: latest?.text,
    senderId: latest?.senderId,
    mine: latest?.mine ?? false,
    lastActivity: latest?.sentAt,
    unread: messages
        .where(
          (m) =>
              !m.mine &&
              m.sentAt != null &&
              (readAt == null || m.sentAt!.isAfter(readAt)),
        )
        .length,
  );
}

List<InboxEntry> sortInbox(Iterable<InboxEntry> entries) =>
    entries.toList()..sort((a, b) {
      final byTime = (b.lastActivity ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.lastActivity ?? DateTime.fromMillisecondsSinceEpoch(0));
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });

/// Read cursors and previews live only in memory on this client.
class ChatReadController extends Notifier<Map<String, DateTime>> {
  @override
  Map<String, DateTime> build() {
    ref.watch(authStateProvider.select((state) => state.value?.id));
    return {};
  }

  Future<void> markRead(String id, List<ChatMessage> messages) async {
    final latest = messages.where((m) => m.delivery == 'sent').lastOrNull;
    if (latest?.sentAt == null) return;
    final client = ref.read(backendProvider);
    if (client == null) {
      state = {...state, id: latest!.sentAt!};
    } else {
      if (latest!.id.isEmpty) return;
      await client.rpc(
        'mark_conversation_read',
        params: {'conversation_in': id, 'message_in': latest.id},
      );
      ref.invalidate(chatInboxProvider);
    }
  }
}

final chatReadProvider =
    NotifierProvider<ChatReadController, Map<String, DateTime>>(
      ChatReadController.new,
    );

final chatInboxProvider = StreamProvider.autoDispose<List<InboxEntry>>((ref) {
  ref.watch(authStateProvider.select((state) => state.value?.id));
  final community = ref.watch(communityProvider);
  final client = ref.watch(backendProvider);
  final repository = ref.watch(communityRepositoryProvider);
  final data = community.value ?? {};
  final conversations = rows(data, 'conversations');
  final ids =
      conversations.isEmpty &&
          repository is DemoCommunityRepository &&
          repository.seedSamples
      ? ['anna', 'event', 'neighbors']
      : conversations.map((c) => c['id'] as String).toList();
  if (client == null) {
    ref.watch(chatProvider);
    final read = ref.watch(chatReadProvider);
    return Stream.value(
      sortInbox(
        ids.map(
          (id) => demoInboxEntry(
            id,
            ref.read(chatRepositoryProvider).messages(id),
            read[id],
          ),
        ),
      ),
    );
  }
  final accountId = client.auth.currentUser?.id;
  final controller = StreamController<List<InboxEntry>>();
  bool disposed = false, fetching = false, reload = false;
  Future<void> load() async {
    if (disposed) return;
    if (fetching) {
      reload = true;
      return;
    }
    fetching = true;
    try {
      final entries = <InboxEntry>[];
      for (var start = 0; start < ids.length; start += 100) {
        final end = (start + 100).clamp(0, ids.length);
        final result = await client.rpc(
          'chat_inbox',
          params: {'conversation_ids': ids.sublist(start, end)},
        );
        entries.addAll(
          (result as List).map(
            (row) =>
                InboxEntry.fromJson(Map<String, dynamic>.from(row), accountId),
          ),
        );
      }
      if (!disposed) controller.add(sortInbox(entries));
    } catch (error) {
      if (!disposed) {
        if (client.auth.currentUser == null ||
            error is PostgrestException && error.code == '42501') {
          controller.add(const <InboxEntry>[]);
        }
        controller.addError(error);
      }
    } finally {
      fetching = false;
      if (reload) {
        reload = false;
        load();
      }
    }
  }

  final subscription = client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', repository.userId ?? '')
      .listen((_) => load(), onError: (Object _) => load());
  final timer = Timer.periodic(const Duration(seconds: 15), (_) => load());
  load();
  ref.onDispose(() {
    disposed = true;
    timer.cancel();
    subscription.cancel();
    controller.close();
  });
  return controller.stream;
});
