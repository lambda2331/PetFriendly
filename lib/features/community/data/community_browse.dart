import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'community_repository.dart';

enum CommunityParticipation { all, joined, discover }

class CommunityBrowseFilter {
  const CommunityBrowseFilter({
    this.participation = CommunityParticipation.all,
  });
  final CommunityParticipation participation;
}

class CommunityBrowseController extends Notifier<CommunityBrowseFilter> {
  @override
  CommunityBrowseFilter build() {
    ref.watch(communityRepositoryProvider);
    return const CommunityBrowseFilter();
  }

  void select(CommunityParticipation value) =>
      state = CommunityBrowseFilter(participation: value);
}

final communityBrowseProvider =
    NotifierProvider<CommunityBrowseController, CommunityBrowseFilter>(
      CommunityBrowseController.new,
    );

List<Json> browseCommunities(
  CommunityData data,
  String? userId, {
  String query = '',
  CommunityParticipation participation = CommunityParticipation.all,
}) {
  final joined = rows(data, 'group_members')
      .where((member) => member['user_id'] == userId)
      .map((member) => member['group_id'])
      .toSet();
  final term = query.trim().toLowerCase();
  return rows(data, 'groups').where((group) {
    final included = switch (participation) {
      CommunityParticipation.all => true,
      CommunityParticipation.joined => joined.contains(group['id']),
      CommunityParticipation.discover => !joined.contains(group['id']),
    };
    return included &&
        '${group['title'] ?? ''} ${group['description'] ?? ''}'
            .toLowerCase()
            .contains(term);
  }).toList();
}

/// Serializes membership changes without dropping the visible snapshot on failure.
class CommunityMembershipController extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    ref.watch(communityRepositoryProvider);
    return {};
  }

  Future<void> change(String id, {required bool joined}) async {
    if (state.contains(id)) return;
    final repository = ref.read(communityRepositoryProvider);
    state = {...state, id};
    try {
      await ref.read(communityProvider.notifier).command(
        joined ? 'leave_group' : 'join_group',
        {'group_in': id},
      );
    } finally {
      if (ref.mounted && ref.read(communityRepositoryProvider) == repository) {
        state = {...state}..remove(id);
      }
    }
  }
}

final communityMembershipProvider =
    NotifierProvider<CommunityMembershipController, Set<String>>(
      CommunityMembershipController.new,
    );

List<Json> invitationCandidates(
  CommunityData data,
  String? userId,
  String groupId,
  String query,
) {
  final members = rows(
    data,
    'group_members',
  ).where((m) => m['group_id'] == groupId).map((m) => m['user_id']).toSet();
  final blocked = rows(data, 'blocks').map((b) => b['target_id']).toSet();
  final term = query.toLowerCase().trim();
  return rows(data, 'profiles')
      .where(
        (p) =>
            p['id'] != userId &&
            !members.contains(p['id']) &&
            !blocked.contains(p['id']) &&
            '${p['display_name'] ?? ''} ${p['district'] ?? ''}'
                .toLowerCase()
                .contains(term),
      )
      .toList();
}
