import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/backend/backend.dart';
import '../community/data/community_repository.dart';

class WalkingFormDraft {
  const WalkingFormDraft({this.text = '', this.rating});
  final String text;
  final int? rating;
}

/// Account-scoped memory only. Private drafts are never written to disk.
class WalkingFormDrafts extends Notifier<Map<String, WalkingFormDraft>> {
  @override
  Map<String, WalkingFormDraft> build() {
    ref.watch(authStateProvider.select((state) => state.value?.id));
    ref.watch(
      communityRepositoryProvider.select((repository) => repository.userId),
    );
    return {};
  }

  void keep(String key, {String? text, int? rating}) {
    final previous = state[key];
    state = {
      ...state,
      key: WalkingFormDraft(
        text: text ?? previous?.text ?? '',
        rating: rating ?? previous?.rating,
      ),
    };
  }

  void clear(String key) => state = {...state}..remove(key);
}

final walkingFormDraftsProvider =
    NotifierProvider<WalkingFormDrafts, Map<String, WalkingFormDraft>>(
      WalkingFormDrafts.new,
    );
