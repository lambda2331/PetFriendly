import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/painting.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/backend/backend.dart';
import '../../core/media/preview_photos.dart';
import '../../core/storage/prototype_store.dart';
import '../community/data/community_repository.dart';
import '../community/data/form_drafts.dart';
import '../chat/chat_repository.dart';
import '../chat/chat_media.dart';
import '../chat/inbox_repository.dart';
import '../notifications/notification_service.dart';

final accountActionsProvider = AsyncNotifierProvider<AccountActions, void>(
  AccountActions.new,
);

class AccountActions extends AsyncNotifier<void> {
  @override
  void build() {}

  Future<void> signOut({SignOutScope scope = SignOutScope.local}) async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    try {
      final client = ref.read(backendProvider);
      if (client == null) throw StateError('No account connected');
      await ref.read(notificationServiceProvider).unregister(client);
      await client.auth.signOut(scope: scope);
      ref.invalidate(formDraftsProvider);
      ref.invalidate(communityProvider);
      ref.invalidate(previewPhotosProvider);
      ref.invalidate(chatProvider);
      ref.invalidate(chatInboxProvider);
      ref.invalidate(chatReadProvider);
      ref.invalidate(chatRepositoryProvider);
      ref.invalidate(chatMessagesProvider);
      ref.invalidate(chatMediaBytesProvider);
      ref.invalidate(chatMediaAvailableProvider);
      imageCache.clear();
      imageCache.clearLiveImages();
      await ref.read(prototypeProvider.notifier).clearAccount();
      state = const AsyncData(null);
    } catch (error, stack) {
      state = AsyncError(error, stack);
      rethrow;
    }
  }
}
