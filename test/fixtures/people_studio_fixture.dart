import 'package:petfriendly/features/community/data/community_repository.dart';
import 'meetup_studio_fixture.dart';

const socialGroup = '00000000-0000-4000-8000-000000000081';
const socialChat = '00000000-0000-4000-8000-000000000082';
const socialKat = '00000000-0000-4000-8000-000000000083';

class PeopleStudioRepository extends MeetupStudioRepository {
  PeopleStudioRepository({super.scenario}) {
    data['profiles'] = [
      {'id': userId, 'display_name': 'Вы'},
      {
        'id': demoAnna,
        'display_name': 'Анна',
        'district': 'Центральный район',
        'interests': 'Прогулки в парке, походы',
      },
      {
        'id': socialKat,
        'display_name': 'Екатерина Александровская-Лисовская',
        'district': 'Советский район',
        'interests': 'Походы',
      },
    ];
    data['pets'] = [
      for (final name in ['Бруно', 'Марта', 'Арчи'])
        {
          'id': name,
          'owner_id': demoAnna,
          'name': name,
          'kind': 'собака',
          'temperament': 'спокойный',
        },
    ];
    data['groups'] = [
      {
        'id': socialGroup,
        'title': 'Соседи с питомцами',
        'description':
            'Знакомимся с соседями, обсуждаем маршруты и встречаемся на прогулках в Центральном районе.',
        'owner_id': demoAnna,
      },
      {
        'id': 'discover',
        'title': 'Спокойные прогулки',
        'description': 'Небольшая компания для прогулок без спешки.',
        'owner_id': demoAnna,
      },
    ];
    data['group_members'] = [
      {'group_id': socialGroup, 'user_id': userId},
      {'group_id': socialGroup, 'user_id': demoAnna},
    ];
    data['conversations']!.add({
      'id': socialChat,
      'kind': 'group',
      'context_id': socialGroup,
    });
    data['conversation_members']!.add({
      'conversation_id': socialChat,
      'user_id': userId,
      'active': true,
    });
  }
}
