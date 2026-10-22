import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';

class DeferredCommunity implements CommunityRepository {
  DeferredCommunity(this.userId);
  @override
  final String userId;
  @override
  bool get isDemo => true;
  final response = Completer<String?>();
  @override
  Future<CommunityData> load() async => {
    'profiles': [
      {'id': userId},
    ],
  };
  @override
  Future<String?> command(String action, Json values) => response.future;
}

void main() {
  test('Account change rejects the previous account command result', () async {
    final first = DeferredCommunity('first');
    final second = DeferredCommunity('second');
    final container = ProviderContainer(
      overrides: [communityRepositoryProvider.overrideWithValue(first)],
    );
    addTearDown(container.dispose);
    await container.read(communityProvider.future);
    final operation = container
        .read(communityProvider.notifier)
        .command('chat', {});
    final rejection = expectLater(operation, throwsStateError);
    container.updateOverrides([
      communityRepositoryProvider.overrideWithValue(second),
    ]);
    await container.read(communityProvider.future);
    first.response.complete('private-first-chat');
    await rejection;
    expect(
      container.read(communityProvider).value?['profiles']?.single['id'],
      'second',
    );
  });
}
