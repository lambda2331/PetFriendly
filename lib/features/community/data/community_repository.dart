import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef Json = Map<String, dynamic>;
typedef CommunityData = Map<String, List<Json>>;

abstract class CommunityRepository {
  String? get userId;
  bool get isDemo;
  Future<CommunityData> load();
  Future<String?> command(String action, Json values);
}

final communityRepositoryProvider = Provider<CommunityRepository>(
  (ref) => DemoCommunityRepository(),
);

class CommunityController extends AsyncNotifier<CommunityData> {
  @override
  Future<CommunityData> build() =>
      ref.watch(communityRepositoryProvider).load();
  Future<String?> command(String action, Json values) async {
    final result = await ref
        .read(communityRepositoryProvider)
        .command(action, values);
    state = AsyncData(await ref.read(communityRepositoryProvider).load());
    return result;
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(communityRepositoryProvider).load(),
    );
  }
}

final communityProvider =
    AsyncNotifierProvider<CommunityController, CommunityData>(
      CommunityController.new,
    );
List<Json> rows(CommunityData data, String table) => data[table] ?? [];
Json? findRow(CommunityData data, String table, String? id) {
  for (final row in rows(data, table)) {
    if (row['id'] == id) return row;
  }
  return null;
}

const demoAlex = '00000000-0000-4000-8000-000000000001';
const demoAnna = '00000000-0000-4000-8000-000000000002';
const demoSasha = '00000000-0000-4000-8000-000000000003';

class DemoCommunityRepository implements CommunityRepository {
  DemoCommunityRepository({this.seedSamples = true}) {
    final tomorrow = DateTime.now()
        .add(const Duration(days: 1))
        .toUtc()
        .toIso8601String();
    data = {
      'groups': [
        {
          'id': '00000000-0000-4000-8000-000000000041',
          'owner_id': demoAnna,
          'title': 'Соседи с питомцами',
          'description': 'Прогулки, знакомства и советы по району',
        },
      ],
      'group_members': [
        {
          'group_id': '00000000-0000-4000-8000-000000000041',
          'user_id': demoAnna,
        },
      ],
      'profiles': [
        {
          'id': demoAlex,
          'display_name': 'Алекс',
          'district': 'Центральный район',
          'about': 'Люблю прогулки и новые знакомства.',
          'interests': 'Прогулки, походы',
        },
        {
          'id': demoAnna,
          'display_name': 'Анна',
          'district': 'Центральный район',
          'about': 'Гуляем с Бруно каждый вечер.',
          'interests': 'Спокойные прогулки',
        },
        {
          'id': demoSasha,
          'display_name': 'Саша',
          'district': 'Советский район',
          'about': 'Помогаю соседям с прогулками.',
          'interests': 'Выгул',
        },
      ],
      'pets': [
        {
          'id': '00000000-0000-4000-8000-000000000011',
          'owner_id': demoAlex,
          'name': 'Луна',
          'kind': 'Собака',
          'age': 2,
          'temperament': 'Любит игры, знакомится постепенно',
        },
        {
          'id': '00000000-0000-4000-8000-000000000012',
          'owner_id': demoAnna,
          'name': 'Бруно',
          'kind': 'Собака',
          'age': 3,
          'temperament': 'Спокойный и дружелюбный',
        },
      ],
      'events': [
        {
          'id': '00000000-0000-4000-8000-000000000021',
          'owner_id': demoAnna,
          'title': 'Вечерняя прогулка',
          'city': 'Минск',
          'time_zone': 'Europe/Minsk',
          'starts_at': tomorrow,
          'capacity': 8,
          'description': 'Спокойный темп и новые знакомства',
          'cancelled': false,
        },
      ],
      'event_members': [
        {
          'event_id': '00000000-0000-4000-8000-000000000021',
          'user_id': demoAnna,
        },
      ],
      'walk_requests': [
        {
          'id': '00000000-0000-4000-8000-000000000031',
          'owner_id': demoAnna,
          'pet_id': '00000000-0000-4000-8000-000000000012',
          'city': 'Минск',
          'time_zone': 'Europe/Minsk',
          'starts_at': tomorrow,
          'duration': 45,
          'description': 'Помогите прогуляться с Бруно',
          'status': 'open',
        },
      ],
      'walk_details': [],
      'walk_applications': [],
      'walk_agreements': [],
      'walk_reviews': [],
      'conversations': [],
      'conversation_members': [],
      'messages': [],
      'reports': [],
      'notifications': [],
      'place_reviews': [],
      'blocks': [],
    };
    if (!seedSamples) {
      for (final key in data.keys) {
        data[key] = [];
      }
      data['profiles'] = [
        {'id': demoAlex, 'display_name': 'Новый пользователь'},
      ];
    }
  }
  final bool seedSamples;
  late CommunityData data;
  @override
  String get userId => demoAlex;
  @override
  bool get isDemo => true;
  @override
  Future<CommunityData> load() async => {
    for (final entry in data.entries)
      entry.key: entry.value.map((r) => Map<String, dynamic>.from(r)).toList(),
  };
  String id() => const Uuid().v4();
  @override
  Future<String?> command(String action, Json v) async {
    switch (action) {
      case 'group':
        final gid = id();
        data['groups']!.add({
          'id': gid,
          'owner_id': userId,
          'title': v['title_in'],
          'description': v['description_in'],
        });
        data['group_members']!.add({'group_id': gid, 'user_id': userId});
        data['conversations']!.add({
          'id': id(),
          'kind': 'group',
          'context_id': gid,
        });
        return gid;
      case 'join_group':
        final gid = v['group_in'];
        if (!data['group_members']!.any(
          (m) => m['group_id'] == gid && m['user_id'] == userId,
        )) {
          data['group_members']!.add({'group_id': gid, 'user_id': userId});
          if (!data['conversations']!.any(
            (c) => c['kind'] == 'group' && c['context_id'] == gid,
          )) {
            data['conversations']!.add({
              'id': id(),
              'kind': 'group',
              'context_id': gid,
            });
          }
        }
        break;
      case 'leave_group':
        data['group_members']!.removeWhere(
          (m) => m['group_id'] == v['group_in'] && m['user_id'] == userId,
        );
        break;
      case 'profile':
        data['profiles']!.firstWhere((p) => p['id'] == userId).addAll(v);
        break;
      case 'pet':
        final existing = v['id'];
        if (existing == null) {
          data['pets']!.add({...v, 'id': id(), 'owner_id': userId});
        } else {
          final pet = data['pets']!.firstWhere(
            (p) => p['id'] == existing && p['owner_id'] == userId,
          );
          pet.addAll(v);
        }
        break;
      case 'event':
        final eid = id();
        data['events']!.add({
          'id': eid,
          'owner_id': userId,
          'title': v['title_in'],
          'city': v['city_in'],
          'time_zone': v['timezone_in'],
          'starts_at': v['starts_in'],
          'capacity': v['capacity_in'],
          'description': v['description_in'],
          'cancelled': false,
        });
        data['event_members']!.add({'event_id': eid, 'user_id': userId});
        return eid;
      case 'join_event':
        final eid = v['event_in'];
        final event = data['events']!.firstWhere((e) => e['id'] == eid);
        final members = data['event_members']!.where(
          (m) => m['event_id'] == eid,
        );
        if (members.any((m) => m['user_id'] == userId)) return null;
        if (members.length >= event['capacity']) {
          throw StateError('Нет свободных мест');
        }
        data['event_members']!.add({'event_id': eid, 'user_id': userId});
        break;
      case 'leave_event':
        data['event_members']!.removeWhere(
          (m) => m['event_id'] == v['event_in'] && m['user_id'] == userId,
        );
        break;
      case 'walk':
        final rid = id();
        if (!data['pets']!.any(
          (p) => p['id'] == v['pet_in'] && p['owner_id'] == userId,
        )) {
          throw StateError('Выберите своего питомца');
        }
        data['walk_requests']!.add({
          'id': rid,
          'owner_id': userId,
          'pet_id': v['pet_in'],
          'city': v['city_in'],
          'time_zone': v['timezone_in'],
          'starts_at': v['starts_in'],
          'duration': v['duration_in'],
          'description': v['description_in'],
          'status': 'open',
        });
        data['walk_details']!.add({
          'request_id': rid,
          'instructions': v['instructions_in'],
        });
        return rid;
      case 'apply_walk':
        final rid = v['request_in'];
        final request = data['walk_requests']!.firstWhere(
          (w) => w['id'] == rid,
        );
        if (request['owner_id'] == userId || request['status'] != 'open') {
          throw StateError('Отклик недоступен');
        }
        if (!data['walk_applications']!.any(
          (a) => a['request_id'] == rid && a['helper_id'] == userId,
        )) {
          data['walk_applications']!.add({
            'request_id': rid,
            'helper_id': userId,
          });
        }
        break;
      case 'withdraw_walk':
        data['walk_applications']!.removeWhere(
          (a) => a['request_id'] == v['request_in'] && a['helper_id'] == userId,
        );
        break;
      case 'demo_application':
        if (!data['walk_applications']!.any(
          (a) =>
              a['request_id'] == v['request_in'] && a['helper_id'] == demoSasha,
        )) {
          data['walk_applications']!.add({
            'request_id': v['request_in'],
            'helper_id': demoSasha,
          });
        }
        break;
      case 'assign_walk':
        final request = data['walk_requests']!.firstWhere(
          (w) => w['id'] == v['request_in'] && w['owner_id'] == userId,
        );
        if (request['status'] != 'open' ||
            !data['walk_applications']!.any(
              (a) =>
                  a['request_id'] == v['request_in'] &&
                  a['helper_id'] == v['helper_in'],
            )) {
          throw StateError('Выбор недоступен');
        }
        request['status'] = 'assigned';
        final aid = id();
        data['walk_agreements']!.add({
          'id': aid,
          'request_id': request['id'],
          'helper_id': v['helper_in'],
        });
        data['conversations']!.add({
          'id': id(),
          'kind': 'walk',
          'context_id': request['id'],
        });
        return aid;
      case 'advance_walk':
        final request = data['walk_requests']!.firstWhere(
          (w) => w['id'] == v['request_in'],
        );
        final next = v['next_status'];
        // Demo-only helper simulation is explicit in the UI; server enforces roles.
        const transitions = {
          'assigned': 'in_progress',
          'in_progress': 'awaiting_confirmation',
          'awaiting_confirmation': 'completed',
          'open': 'cancelled',
        };
        if (transitions[request['status']] != next) {
          throw StateError('Переход недоступен');
        }
        request['status'] = next;
        break;
      case 'review_walk':
        final request = data['walk_requests']!.firstWhere(
          (w) => w['id'] == v['request_in'] && w['owner_id'] == userId,
        );
        if (request['status'] != 'completed' ||
            data['walk_reviews']!.any(
              (r) => r['request_id'] == request['id'],
            )) {
          throw StateError('Отзыв недоступен');
        }
        final agreement = data['walk_agreements']!.firstWhere(
          (a) => a['request_id'] == request['id'],
        );
        data['walk_reviews']!.add({
          'id': id(),
          'request_id': request['id'],
          'author_id': userId,
          'helper_id': agreement['helper_id'],
          'rating': v['rating_in'],
          'body': v['body_in'],
          'published': true,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
        break;
      case 'reply_walk_review':
        final review = data['walk_reviews']!.firstWhere(
          (r) =>
              r['id'] == v['review_in'] &&
              r['helper_id'] == userId &&
              r['published'] == true,
          orElse: () => throw StateError('Ответ на отзыв недоступен'),
        );
        final body = (v['body_in'] ?? '').toString().trim();
        final request = findRow(data, 'walk_requests', review['request_id']);
        final eligible = rows(data, 'walk_agreements').any(
          (a) =>
              a['request_id'] == review['request_id'] &&
              a['helper_id'] == userId,
        );
        if (body.isEmpty ||
            body.length > 1000 ||
            !eligible ||
            request?['status'] != 'completed' ||
            request?['owner_id'] == userId ||
            request?['owner_id'] != review['author_id']) {
          throw StateError('Проверьте отзыв и текст ответа');
        }
        review.addAll({
          'helper_reply': body,
          'replied_at': DateTime.now().toUtc().toIso8601String(),
        });
        break;
      case 'direct':
        final target = v['target'];
        final existing = data['conversations']!.where(
          (c) => c['target'] == target,
        );
        if (existing.isNotEmpty) return existing.first['id'];
        final cid = id();
        data['conversations']!.add({
          'id': cid,
          'kind': 'direct',
          'target': target,
        });
        return cid;
      case 'place_review':
        if (data['place_reviews']!.any(
          (r) => r['place_id'] == v['place_id'] && r['author_id'] == userId,
        )) {
          throw StateError('Вы уже оставили отзыв');
        }
        if (v['rating'] is! int ||
            v['rating'] < 1 ||
            v['rating'] > 5 ||
            (v['body'] ?? '').toString().length > 1000) {
          throw StateError('Недопустимый отзыв');
        }
        data['place_reviews']!.add({
          ...v,
          'id': id(),
          'author_id': userId,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        });
        break;
      case 'place_correction':
        break;
      case 'report':
        data['reports']!.add({...v, 'id': id(), 'author_id': userId});
        break;
      case 'block':
        data['blocks']!.add({'user_id': userId, 'target_id': v['target_id']});
        break;
      default:
        throw StateError('Неизвестное действие');
    }
    return null;
  }
}

class SupabaseCommunityRepository implements CommunityRepository {
  SupabaseCommunityRepository(this.client);
  final SupabaseClient client;
  @override
  String? get userId => client.auth.currentUser?.id;
  @override
  bool get isDemo => false;
  @override
  Future<CommunityData> load() async {
    if (userId == null) return {};
    const tables = [
      'groups',
      'group_members',
      'profiles',
      'pets',
      'events',
      'event_members',
      'walk_requests',
      'walk_details',
      'walk_applications',
      'walk_agreements',
      'walk_reviews',
      'conversations',
      'conversation_members',
      'reports',
      'notifications',
      'place_reviews',
      'blocks',
    ];
    final results = await Future.wait(
      tables.map((t) => client.from(t).select().limit(1000)),
    );
    final snapshot = {
      for (var i = 0; i < tables.length; i++)
        tables[i]: results[i].map((r) => Map<String, dynamic>.from(r)).toList(),
    };
    final stats = await client.rpc('helper_stats');
    snapshot['helper_ratings'] = (stats as List)
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
    final placeStats = await client.rpc('place_rating_stats');
    snapshot['place_rating_stats'] = (placeStats as List)
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
    return snapshot;
  }

  @override
  Future<String?> command(String action, Json values) async {
    if (userId == null) throw StateError('Войдите в аккаунт');
    switch (action) {
      case 'profile':
        await client.from('profiles').update(values).eq('id', userId!);
        return null;
      case 'pet':
        final copy = {...values};
        final existing = copy.remove('id');
        if (existing == null) {
          await client.from('pets').insert({...copy, 'owner_id': userId});
        } else {
          await client
              .from('pets')
              .update(copy)
              .eq('id', existing)
              .eq('owner_id', userId!);
        }
        return null;
      case 'place_review':
        await client.from('place_reviews').insert({
          ...values,
          'author_id': userId,
        });
        return null;
      case 'place_correction':
        await client.from('place_corrections').insert({
          ...values,
          'author_id': userId,
        });
        return null;
      case 'report':
        await client.from('reports').insert({...values, 'author_id': userId});
        return null;
      case 'block':
        await client.from('blocks').upsert({
          'user_id': userId,
          'target_id': values['target_id'],
        });
        return null;
      case 'demo_application':
        throw StateError('Демо-действие отключено');
      case 'direct':
        return await client.rpc('open_direct', params: values) as String;
      default:
        final rpc = switch (action) {
          'event' => 'create_event_at_zone',
          'group' => 'create_group',
          'walk' => 'create_walk_at_zone',
          _ => action,
        };
        final result = await client.rpc(rpc, params: values);
        return result is String ? result : null;
    }
  }
}
