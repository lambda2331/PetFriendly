import 'package:intl/intl.dart';
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

String petSummary(List<Json> pets, String locale) {
  if (pets.length == 1) {
    return [
      pets.first['name'],
      pets.first['kind'],
    ].where((v) => v != null && '$v'.isNotEmpty).join(' · ');
  }
  return '${pets.take(2).map((p) => p['name']).join(', ')}${pets.length > 2 ? ' +${pets.length - 2}' : ''}';
}

String petCount(int count, String locale) => switch (locale) {
  'en' => Intl.plural(
    count,
    one: '$count pet',
    other: '$count pets',
    locale: locale,
  ),
  'be' => Intl.plural(
    count,
    one: '$count гадаванец',
    few: '$count гадаванцы',
    many: '$count гадаванцаў',
    other: '$count гадаванцаў',
    locale: locale,
  ),
  'pl' => Intl.plural(
    count,
    one: '$count zwierzę',
    few: '$count zwierzęta',
    many: '$count zwierząt',
    other: '$count zwierząt',
    locale: locale,
  ),
  _ => Intl.plural(
    count,
    one: '$count питомец',
    few: '$count питомца',
    many: '$count питомцев',
    other: '$count питомцев',
    locale: 'ru',
  ),
};
