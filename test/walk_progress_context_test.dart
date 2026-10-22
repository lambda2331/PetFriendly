import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/features/chat/conversation_context.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/walks/walk_progress.dart';

void main() {
  test('Every server workflow stage has a role-specific next step', () {
    final stages = [
      'open',
      'assigned',
      'in_progress',
      'awaiting_confirmation',
      'completed',
    ];
    for (var i = 0; i < stages.length; i++) {
      final owner = WalkProgress.forRequest(
        status: stages[i],
        owner: true,
        helper: false,
      );
      final helper = WalkProgress.forRequest(
        status: stages[i],
        owner: false,
        helper: true,
      );
      expect(owner.stage, i);
      expect(helper.stage, i);
      expect(owner.instruction, isNot(helper.instruction));
    }
    expect(
      WalkProgress.forRequest(
        status: 'assigned',
        owner: true,
        helper: false,
      ).instruction,
      contains('отмечает выбранный помощник'),
    );
    expect(
      WalkProgress.forRequest(
        status: 'awaiting_confirmation',
        owner: false,
        helper: true,
      ).instruction,
      contains('Дождитесь подтверждения владельца'),
    );
    expect(
      WalkProgress.forRequest(
        status: 'open',
        owner: false,
        helper: false,
        applied: true,
      ).instruction,
      contains('отклик отправлен'),
    );
    expect(
      WalkProgress.forRequest(
        status: 'completed',
        owner: true,
        helper: false,
        reviewed: true,
      ).instruction,
      contains('уже сохранён'),
    );
    expect(
      WalkProgress.forRequest(
        status: 'cancelled',
        owner: true,
        helper: false,
      ).stage,
      isNull,
    );
  });
  test(
    'Unrelated viewer receives status context without participant instruction',
    () {
      final value = WalkProgress.forRequest(
        status: 'assigned',
        owner: false,
        helper: false,
      );
      expect(value.instruction, contains('только её участники'));
    },
  );
  test('Community, meetup and walk chats omit detail route links', () {
    expect(
      ConversationContext.fromConversation({
        'kind': 'group',
        'context_id': 'group-id',
      }),
      isNull,
    );
    expect(
      ConversationContext.fromConversation({
        'kind': 'event',
        'context_id': 'event-id',
      }),
      isNull,
    );
    expect(
      ConversationContext.fromConversation({
        'kind': 'walk',
        'context_id': 'request-id',
      }),
      isNull,
    );
    expect(
      ConversationContext.fromConversation({
        'kind': 'direct',
        'context_id': 'person',
      }),
      isNull,
    );
    expect(
      ConversationContext.fromConversation({'kind': 'walk', 'context_id': ''}),
      isNull,
    );
    expect(ConversationContext.fromConversation(null), isNull);
  });
  test('Walk chat is exposed only to owner or assigned helper', () {
    final data = {
      'walk_requests': [
        {'id': 'request', 'owner_id': 'owner'},
      ],
      'walk_agreements': [
        {'request_id': 'request', 'helper_id': 'helper'},
      ],
      'conversations': [
        {'id': 'chat', 'kind': 'walk', 'context_id': 'request'},
      ],
      'conversation_members': [
        {'conversation_id': 'chat', 'user_id': 'owner'},
        {'conversation_id': 'chat', 'user_id': 'helper'},
      ],
    };
    expect(walkConversationId(data, 'request', 'owner'), 'chat');
    expect(walkConversationId(data, 'request', 'helper'), 'chat');
    expect(walkConversationId(data, 'request', 'stranger'), isNull);
    expect(walkConversationId(data, 'request', null), isNull);
    data['conversation_members']![1]['left_at'] = '2026-10-12T10:00:00Z';
    expect(walkConversationId(data, 'request', 'helper'), isNull);
  });
  test(
    'Demo assignment creates contextual conversation like server assignment',
    () async {
      final repo = DemoCommunityRepository();
      final request = repo.data['walk_requests']!.first;
      request['owner_id'] = repo.userId;
      await repo.command('demo_application', {'request_in': request['id']});
      await repo.command('assign_walk', {
        'request_in': request['id'],
        'helper_in': demoSasha,
      });
      expect(
        walkConversationId(await repo.load(), request['id'], repo.userId),
        isNotNull,
      );
    },
  );
}
