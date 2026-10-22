import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/backend/backend.dart';
import '../community/data/community_repository.dart';

/// Account-scoped, bounded walking reads. Public cards never contain instructions.
final walkingRepositoryProvider = Provider((ref) {
  ref.watch(authStateProvider.select((s) => s.value?.id));
  return WalkingRepository(ref);
});

class WalkingRepository {
  WalkingRepository(this.ref);
  final Ref ref;
  Future<List<Json>> list({
    String? city,
    String? district,
    String? size,
    DateTime? from,
    DateTime? until,
    String view = 'active',
    int offset = 0,
  }) async {
    final client = ref.read(backendProvider);
    final actor = client?.auth.currentUser?.id;
    if (client != null) {
      if (actor == null) return [];
      dynamic result;
      try {
        result = await client.rpc(
          city == null ? 'my_walks' : 'search_walk_requests',
          params: city == null
              ? {
                  'role_in': 'all',
                  'view_in': view,
                  'offset_in': offset,
                  'limit_in': 40,
                }
              : {
                  'city_in': city,
                  'district_in': district,
                  'size_in': size,
                  'from_in': from?.toUtc().toIso8601String(),
                  'until_in': until?.toUtc().toIso8601String(),
                  'offset_in': offset,
                  'limit_in': 40,
                },
        );
      } catch (_) {
        if (client.auth.currentUser?.id != actor) return [];
        rethrow;
      }
      if (client.auth.currentUser?.id != actor) return [];
      return (result['items'] as List).map((e) => Json.from(e)).toList();
    }
    final repo = ref.read(communityRepositoryProvider);
    final data = await repo.load();
    final uid = repo.userId;
    return rows(data, 'walk_requests')
        .where((w) {
          final applied = rows(
            data,
            'walk_applications',
          ).any((a) => a['request_id'] == w['id'] && a['helper_id'] == uid);
          final helper = rows(
            data,
            'walk_agreements',
          ).any((a) => a['request_id'] == w['id'] && a['helper_id'] == uid);
          if (city != null) {
            return DateTime.tryParse(
                      '${w['starts_at']}',
                    )?.isAfter(DateTime.now()) ==
                    true &&
                w['owner_id'] != uid &&
                w['status'] == 'open' &&
                w['city'] == city &&
                (district == null || w['district'] == district) &&
                (size == null ||
                    findRow(data, 'pets', w['pet_id'])?['size'] == size) &&
                (from == null ||
                    !DateTime.parse(w['starts_at']).isBefore(from)) &&
                (until == null ||
                    DateTime.parse(w['starts_at']).isBefore(until));
          }
          if (view == 'applications') return applied;
          if (w['owner_id'] != uid && !helper) return false;
          return view == 'history'
              ? ['completed', 'cancelled'].contains(w['status'])
              : !['completed', 'cancelled'].contains(w['status']);
        })
        .skip(offset)
        .take(40)
        .map(
          (w) => {
            for (final key in [
              'id',
              'owner_id',
              'pet_id',
              'city',
              'district',
              'starts_at',
              'started_at',
              'finished_at',
              'duration',
              'time_zone',
              'description',
              'status',
            ])
              if (w.containsKey(key)) key: w[key],
            'pet': {
              for (final field in [
                'id',
                'name',
                'kind',
                'age',
                'size',
                'temperament',
              ])
                if (findRow(data, 'pets', w['pet_id'])?.containsKey(field) ==
                    true)
                  field: findRow(data, 'pets', w['pet_id'])?[field],
            },
            'owner': {
              ...demoOwnerRating(data, w['owner_id']),
              for (final field in ['id', 'display_name', 'district'])
                if (findRow(
                      data,
                      'profiles',
                      w['owner_id'],
                    )?.containsKey(field) ==
                    true)
                  field: findRow(data, 'profiles', w['owner_id'])?[field],
            },
            'my_role': w['owner_id'] == uid
                ? 'owner'
                : rows(data, 'walk_agreements').any(
                    (a) => a['request_id'] == w['id'] && a['helper_id'] == uid,
                  )
                ? 'helper'
                : rows(data, 'walk_applications').any(
                    (a) => a['request_id'] == w['id'] && a['helper_id'] == uid,
                  )
                ? 'applicant'
                : 'viewer',
            'applied': rows(
              data,
              'walk_applications',
            ).any((a) => a['request_id'] == w['id'] && a['helper_id'] == uid),
          },
        )
        .toList();
  }

  Future<CommunityData> ownerProfile(String id) async {
    final client = ref.read(backendProvider);
    final actor = client?.auth.currentUser?.id;
    if (client == null) {
      final data = await ref.read(communityRepositoryProvider).load();
      final reviews = rows(
        data,
        'walk_owner_reviews',
      ).where((r) => r['owner_id'] == id && r['published'] == true).toList();
      final completed = rows(
        data,
        'walk_requests',
      ).where((r) => r['owner_id'] == id && r['status'] == 'completed').length;
      return {
        ...data,
        'walk_owner_reviews': reviews,
        'owner_ratings': [
          {
            'id': id,
            'rating': reviews.isEmpty
                ? null
                : reviews.fold<double>(
                        0,
                        (v, r) => v + (r['rating'] as num).toDouble(),
                      ) /
                      reviews.length,
            'review_count': reviews.length,
            'completed': completed,
          },
        ],
      };
    }
    final results = await Future.wait<dynamic>([
      client.from('profiles').select().eq('id', id).then((v) => v),
      client.rpc('owner_stats').then((v) => v),
      client
          .from('walk_owner_reviews')
          .select()
          .eq('owner_id', id)
          .eq('published', true)
          .order('created_at', ascending: false)
          .limit(40)
          .then((v) => v),
    ]);
    if (client.auth.currentUser?.id != actor) {
      throw StateError('Account changed');
    }
    final profiles = await client
        .from('profiles')
        .select()
        .inFilter(
          'id',
          {
            id,
            ...(results[2] as List).map((r) => r['author_id'] as String),
          }.toList(),
        );
    if (client.auth.currentUser?.id != actor) {
      throw StateError('Account changed');
    }
    return {
      'profiles': profiles.map((e) => Json.from(e)).toList(),
      'owner_ratings': (results[1] as List).map((e) => Json.from(e)).toList(),
      'walk_owner_reviews': (results[2] as List)
          .map((e) => Json.from(e))
          .toList(),
    };
  }

  Future<void> review(
    String id,
    int rating,
    String body, {
    required bool owner,
  }) async {
    final name = owner ? 'review_walk_owner' : 'review_walk';
    final args = {'request_in': id, 'rating_in': rating, 'body_in': body};
    await ref.read(communityProvider.notifier).command(name, args);
  }
}

final ownerProfileProvider = FutureProvider.autoDispose
    .family<CommunityData, String>(
      (ref, id) => ref.watch(walkingRepositoryProvider).ownerProfile(id),
    );
final ownerReviewEligibilityProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, id) async {
      final client = ref.watch(backendProvider);
      ref.watch(communityProvider);
      if (client == null) {
        final repo = ref.read(communityRepositoryProvider);
        final data = await repo.load();
        return !canReviewAgreement(data, id, repo.userId, owner: true);
      }

      final actor = client.auth.currentUser?.id;
      for (var offset = 0; offset <= 10000; offset += 100) {
        final result = await client.rpc(
          'my_walks',
          params: {
            'role_in': 'all',
            'view_in': 'history',
            'limit_in': 100,
            'offset_in': offset,
          },
        );
        if (client.auth.currentUser?.id != actor) {
          throw StateError('Account changed');
        }
        final items = result['items'] as List;
        final cards = items.where((w) => w['id'] == id);
        if (cards.isNotEmpty) {
          return cards.first['owner_review_written'] == true ||
              !(cards.first['allowed_actions'] as List).contains(
                'review_owner',
              );
        }
        if (items.length < 100) break;
      }
      throw StateError('Agreement unavailable');
    });
final publicHelperPreferencesProvider = FutureProvider.autoDispose
    .family<Json?, String>((ref, id) async {
      ref.watch(authStateProvider.select((s) => s.value?.id));
      final client = ref.watch(backendProvider);
      if (client == null) return null;
      final actor = client.auth.currentUser?.id;
      final result = await client
          .from('walking_helper_profiles')
          .select()
          .eq('user_id', id)
          .maybeSingle();
      if (client.auth.currentUser?.id != actor) {
        throw StateError('Account changed');
      }
      return result;
    });

bool canReviewAgreement(
  CommunityData data,
  String id,
  String? uid, {
  required bool owner,
}) {
  if (uid == null) return false;
  final request = findRow(data, 'walk_requests', id);
  final agreement = rows(
    data,
    'walk_agreements',
  ).where((a) => a['request_id'] == id).firstOrNull;
  if (request?['status'] != 'completed' ||
      agreement == null ||
      agreement['helper_id'] == request?['owner_id']) {
    return false;
  }
  return owner
      ? agreement['helper_id'] == uid &&
            !rows(data, 'walk_owner_reviews').any((r) => r['request_id'] == id)
      : request?['owner_id'] == uid &&
            !rows(data, 'walk_reviews').any((r) => r['request_id'] == id);
}

Json demoOwnerRating(CommunityData data, String ownerId) {
  final reviews = rows(
    data,
    'walk_owner_reviews',
  ).where((r) => r['owner_id'] == ownerId && r['published'] == true).toList();
  return {
    'review_count': reviews.length,
    'rating': reviews.isEmpty
        ? null
        : reviews.fold<double>(
                0,
                (sum, r) => sum + (r['rating'] as num).toDouble(),
              ) /
              reviews.length,
  };
}
