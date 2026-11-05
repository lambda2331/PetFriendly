import '../../core/display_numbers.dart';
import '../community/data/community_repository.dart';

/// Production values come exclusively from helper_stats; demo uses fixture data.
class HelperReputation {
  const HelperReputation(this.rating, this.reviewCount, this.completed);
  final double? rating;
  final int? reviewCount, completed;
  factory HelperReputation.fromData(
    CommunityData data,
    String id, {
    required bool demo,
  }) {
    final stats = findRow(data, 'helper_ratings', id);
    if (stats != null) {
      final count = (stats['review_count'] as num?)?.toInt() ?? 0;
      return HelperReputation(
        count == 0 ? null : (stats['rating'] as num?)?.toDouble(),
        count,
        (stats['completed'] as num?)?.toInt(),
      );
    }
    if (!demo) return const HelperReputation(null, null, null);
    final reviews = rows(
      data,
      'walk_reviews',
    ).where((r) => r['helper_id'] == id && r['published'] == true).toList();
    final completed = rows(data, 'walk_agreements')
        .where(
          (a) =>
              a['helper_id'] == id &&
              findRow(data, 'walk_requests', a['request_id'])?['status'] ==
                  'completed',
        )
        .length;
    return HelperReputation(
      reviews.isEmpty
          ? null
          : reviews.fold<double>(
                  0,
                  (sum, r) => sum + (r['rating'] as num).toDouble(),
                ) /
                reviews.length,
      reviews.length,
      completed,
    );
  }
  String get reviewLabel => reviewCount == null
      ? 'Отзывы сейчас недоступны'
      : rating == null
      ? 'Пока нет отзывов'
      : '★ ${displayDecimal(rating!)} · $reviewCount отзывов';
  String get completedLabel => completed == null
      ? 'Опыт сейчас недоступен'
      : '$completed завершённых выгулов';
}

bool isMyActiveWalk(CommunityData data, Json request, String? uid) =>
    isMyWalk(data, request, uid) &&
    [
      'assigned',
      'in_progress',
      'awaiting_confirmation',
    ].contains(request['status']);

bool isMyWalk(CommunityData data, Json request, String? uid) =>
    uid != null &&
    (request['owner_id'] == uid ||
        rows(data, 'walk_agreements').any(
          (a) => a['request_id'] == request['id'] && a['helper_id'] == uid,
        ));
String walkActionSuccess(String action, Json args) => switch (action) {
  'apply_walk' => 'Отклик отправлен',
  'withdraw_walk' => 'Отклик отменён',
  'assign_walk' => 'Помощник выбран. Договорённость создана',
  'demo_application' => 'Тестовый отклик добавлен',
  _ => switch (args['next_status']) {
    'cancelled' => 'Заявка отменена',
    'in_progress' => 'Прогулка началась',
    'awaiting_confirmation' => 'Владелец может подтвердить завершение',
    'completed' => 'Завершение подтверждено',
    _ => 'Заявка обновлена',
  },
};
