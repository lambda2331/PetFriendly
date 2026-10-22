import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/backend/backend.dart';
import '../community/data/community_repository.dart';

class ReviewReplyDraft {
  const ReviewReplyDraft({
    required this.text,
    this.pending = false,
    this.error,
  });
  final String text;
  final bool pending;
  final String? error;
}

/// Current-session drafts and in-flight guards only; never persisted to disk.
class ReviewReplyDrafts extends Notifier<Map<String, ReviewReplyDraft>> {
  final _operations = <String, Object>{};
  @override
  Map<String, ReviewReplyDraft> build() {
    ref.watch(authStateProvider.select((state) => state.value?.id));
    ref.watch(
      communityRepositoryProvider.select((repository) => repository.userId),
    );
    _operations.clear();
    return {};
  }

  void keep(String id, String text) {
    if (state[id]?.pending == true) {
      return;
    }
    state = {...state, id: ReviewReplyDraft(text: text)};
  }

  Future<bool> publish(String id, String fallbackText) async {
    if (state[id]?.pending == true) {
      return false;
    }
    final draft = state[id]?.text ?? fallbackText;
    final body = draft.trim();
    if (body.isEmpty || body.length > 1000) {
      state = {
        ...state,
        id: ReviewReplyDraft(
          text: draft,
          error: body.isEmpty
              ? 'Напишите ответ'
              : 'Ответ должен быть не длиннее 1000 символов',
        ),
      };
      return false;
    }
    final account = ref.read(communityRepositoryProvider).userId;
    final operation = Object();
    _operations[id] = operation;
    state = {...state, id: ReviewReplyDraft(text: draft, pending: true)};
    bool current() =>
        ref.mounted &&
        _operations[id] == operation &&
        ref.read(communityRepositoryProvider).userId == account;
    try {
      await ref.read(communityProvider.notifier).command('reply_walk_review', {
        'review_in': id,
        'body_in': body,
      });
      if (!current()) {
        return false;
      }
      _operations.remove(id);
      state = {...state}..remove(id);
      return true;
    } catch (_) {
      if (current()) {
        _operations.remove(id);
        state = {
          ...state,
          id: ReviewReplyDraft(
            text: draft,
            error: 'Не удалось опубликовать. Проверьте соединение и повторите.',
          ),
        };
      }
      return false;
    }
  }
}

final reviewReplyDraftsProvider =
    NotifierProvider<ReviewReplyDrafts, Map<String, ReviewReplyDraft>>(
      ReviewReplyDrafts.new,
    );
