import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/backend/backend.dart';
import '../community/data/community_repository.dart';
import 'place_repository.dart';

class PlaceRating {
  const PlaceRating(this.average, this.count);
  final double average;
  final int count;
}

final placeRatingProvider = Provider.family<PlaceRating?, Place>((ref, place) {
  final data = ref.watch(communityProvider).value ?? {};
  if (!ref.watch(communityRepositoryProvider).isDemo) {
    final stats = rows(
      data,
      'place_rating_stats',
    ).where((r) => r['place_id'] == place.id).firstOrNull;
    return stats == null
        ? null
        : PlaceRating(
            (stats['average_rating'] as num).toDouble(),
            (stats['review_count'] as num).toInt(),
          );
  }
  final reviews = rows(
    data,
    'place_reviews',
  ).where((r) => r['place_id'] == place.id).toList();
  if (reviews.isNotEmpty) {
    return PlaceRating(
      reviews.fold<double>(0, (sum, r) => sum + (r['rating'] as num)) /
          reviews.length,
      reviews.length,
    );
  }
  return place.rating == null || place.reviewCount == 0
      ? null
      : PlaceRating(place.rating!, place.reviewCount);
});

class PlaceFeedback {
  const PlaceFeedback(this.reviews, this.own);
  final List<Json> reviews;
  final Json? own;
}

final placeFeedbackProvider = FutureProvider.autoDispose
    .family<PlaceFeedback, String>((ref, id) async {
      final data = await ref.watch(communityProvider.future);
      final uid = ref.watch(communityRepositoryProvider).userId;
      final client = ref.watch(backendProvider);
      if (client == null) {
        final reviews = rows(
          data,
          'place_reviews',
        ).where((r) => r['place_id'] == id).toList();
        return PlaceFeedback(
          reviews,
          reviews.where((r) => r['author_id'] == uid).firstOrNull,
        );
      }
      final reviews = await client
          .from('place_reviews')
          .select()
          .eq('place_id', id)
          .order('created_at', ascending: false)
          .limit(50);
      final own = await client
          .from('place_reviews')
          .select()
          .eq('place_id', id)
          .eq('author_id', uid!)
          .maybeSingle();
      return PlaceFeedback(
        reviews.map((r) => Map<String, dynamic>.from(r)).toList(),
        own,
      );
    });
