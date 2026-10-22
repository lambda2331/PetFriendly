import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/backend/backend.dart';
import '../community/data/community_repository.dart';
import 'chat_media.dart';

class ChatComposerDraft {
  const ChatComposerDraft({this.text = '', this.media, this.eventId});
  final String text;
  final MediaDraft? media;
  final String? eventId;
}

/// Only processed photo bytes and unsent text in account-scoped memory.
/// Retired stores reject late writes from a picker or an exiting route.
class ChatComposerDrafts {
  final _values = <String, ChatComposerDraft>{};
  bool _active = true;
  bool get active => _active;
  ChatComposerDraft? read(String id) => _active ? _values[id] : null;
  void keep(String id, ChatComposerDraft value) {
    if (!_active) return;
    if (value.text.isEmpty && value.media == null && value.eventId == null) {
      _values.remove(id);
    } else {
      _values[id] = value;
    }
  }

  void retire() {
    _active = false;
    _values.clear();
  }
}

final chatComposerDraftsProvider = Provider<ChatComposerDrafts>((ref) {
  ref.watch(authStateProvider.select((state) => state.value?.id));
  ref.watch(communityRepositoryProvider);
  final drafts = ChatComposerDrafts();
  ref.onDispose(drafts.retire);
  return drafts;
});
