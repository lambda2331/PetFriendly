import '../community/data/community_repository.dart';

/// Describes the existing server workflow; it does not authorize transitions.
class WalkProgress {
  const WalkProgress({required this.stage, required this.instruction});
  final int? stage;
  final String instruction;
  static const stages = [
    'Отклики',
    'Договорённость',
    'Прогулка',
    'Подтверждение',
    'Завершено',
  ];

  factory WalkProgress.forRequest({
    required String status,
    required bool owner,
    required bool helper,
    bool applied = false,
    bool reviewed = false,
  }) {
    final stage = switch (status) {
      'open' => 0,
      'assigned' => 1,
      'in_progress' => 2,
      'awaiting_confirmation' => 3,
      'completed' => 4,
      _ => null,
    };
    final instruction = switch (status) {
      'open' when owner =>
        'Просмотрите профили и отзывы откликнувшихся, затем выберите помощника.',
      'open' when applied =>
        'Ваш отклик отправлен. Дождитесь решения владельца.',
      'open' =>
        'Просмотрите описание прогулки и предложите помощь, если можете участвовать.',
      'assigned' when helper =>
        'Обсудите детали с владельцем в чате. Когда прогулка начнётся, нажмите «Начать прогулку».',
      'assigned' when owner =>
        'Обсудите детали в чате. Начало прогулки отмечает выбранный помощник.',
      'in_progress' when helper =>
        'По окончании нажмите «Завершить прогулку». Затем владелец подтвердит завершение.',
      'in_progress' when owner =>
        'Помощник отмечает окончание прогулки. После этого вы сможете подтвердить завершение.',
      'awaiting_confirmation' when owner =>
        'Проверьте, что прогулка завершилась, и нажмите «Подтвердить завершение».',
      'awaiting_confirmation' when helper =>
        'Вы отметили окончание. Дождитесь подтверждения владельца.',
      'completed' when owner && !reviewed =>
        'Прогулка завершена. Поделитесь опытом — оставьте отзыв о помощнике.',
      'completed' when owner && reviewed =>
        'Прогулка завершена. Ваш отзыв уже сохранён.',
      'completed' when helper =>
        'Прогулка завершена. Отзыв владельца появится в вашем профиле, когда будет опубликован.',
      'cancelled' => 'Заявка отменена и больше не принимает отклики.',
      _ =>
        'Здесь показан текущий статус заявки. Изменять договорённость могут только её участники.',
    };
    return WalkProgress(stage: stage, instruction: instruction);
  }
}

String? walkConversationId(CommunityData data, String requestId, String? uid) {
  if (uid == null) return null;
  final request = findRow(data, 'walk_requests', requestId);
  final participant =
      request?['owner_id'] == uid ||
      rows(
        data,
        'walk_agreements',
      ).any((a) => a['request_id'] == requestId && a['helper_id'] == uid);
  if (!participant) return null;
  return rows(data, 'conversations')
          .where(
            (c) =>
                c['kind'] == 'walk' &&
                c['context_id'] == requestId &&
                rows(data, 'conversation_members').any(
                  (m) =>
                      m['conversation_id'] == c['id'] &&
                      m['user_id'] == uid &&
                      m['left_at'] == null &&
                      m['active'] != false,
                ),
          )
          .firstOrNull?['id']
      as String?;
}
