import 'community_repository.dart';

List<Json> searchPeople(CommunityData data, String? userId, String query) {
  final term = query.toLowerCase().trim();
  final blocked = rows(data, 'blocks').map((b) => b['target_id']).toSet();
  return rows(data, 'profiles').where((person) {
    if (person['id'] == userId || blocked.contains(person['id'])) return false;
    final pets = rows(
      data,
      'pets',
    ).where((pet) => pet['owner_id'] == person['id']);
    return '${person['display_name']} ${person['interests']} ${person['district']} '
            '${pets.map((pet) => '${pet['name']} ${pet['kind']} ${pet['temperament']}').join(' ')}'
        .toLowerCase()
        .contains(term);
  }).toList();
}

List<Json> searchGroups(CommunityData data, String query) =>
    rows(data, 'groups')
        .where(
          (group) => '${group['title']} ${group['description']}'
              .toLowerCase()
              .contains(query.toLowerCase().trim()),
        )
        .toList();
