import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/backend/backend.dart';

/// Opt-in, device-build-only replay. Never changes server completion state.
/// Release builds ignore the flag, including when it is accidentally supplied.
final onboardingReplayProvider = Provider<bool>((ref) {
  if (!kDebugMode || !const bool.fromEnvironment('REPLAY_ONBOARDING')) {
    return false;
  }
  ref.watch(authStateProvider.select((state) => state.value?.id));
  final user = ref.read(backendProvider)?.auth.currentUser;
  if (user == null) return false;
  const providers = {'google', 'custom:telegram'};
  return providers.contains(user.appMetadata['provider']) ||
      (user.identities?.any(
            (identity) => providers.contains(identity.provider),
          ) ??
          false);
});
