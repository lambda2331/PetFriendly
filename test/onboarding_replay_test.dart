import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/backend/backend.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/auth/onboarding_controller.dart';
import 'package:petfriendly/features/auth/onboarding_replay.dart';
import 'package:petfriendly/features/auth/profile_suggestion.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/walks/account_mode.dart';
import 'widget_test.dart' show MemoryPreferences;

void main() {
  for (final replay in [false, true]) {
    test('Completed account replay=$replay preserves existing data', () async {
      final repository = DemoCommunityRepository();
      final account = DemoAccountModeRepository();
      await account.chooseRole('both', mode: 'owner');
      final before = jsonEncode(repository.data);
      final beforeMode = account.current;
      final container = ProviderContainer(
        overrides: [
          backendProvider.overrideWithValue(null),
          communityRepositoryProvider.overrideWithValue(repository),
          accountModeRepositoryProvider.overrideWithValue(account),
          preferencesProvider.overrideWithValue(MemoryPreferences()),
          profileSuggestionProvider.overrideWithValue(
            const ProfileSuggestion(name: 'Different Provider Name'),
          ),
          onboardingReplayProvider.overrideWithValue(replay),
        ],
      );
      addTearDown(container.dispose);

      final draft = await container.read(onboardingProvider.future);
      expect(draft.accountId, repository.userId);
      expect(draft.role, 'both');
      expect(draft.mode, 'owner');
      expect(draft.text('name'), 'Алекс');
      expect(draft.alreadyComplete, !replay);
      expect(draft.step, replay ? OnboardingStep.role : OnboardingStep.ready);
      expect(jsonEncode(repository.data), before);
      expect(account.current, same(beforeMode));
    });
  }
}
