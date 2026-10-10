import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/features/walks/helper_reputation.dart';

void main() {
  test(
    'production reputation uses RPC aggregates, never visible review subset',
    () {
      final reputation = HelperReputation.fromData(
        {
          'helper_ratings': [
            {
              'id': 'helper',
              'rating': 4.5,
              'review_count': 12,
              'completed': 18,
            },
          ],
          'walk_reviews': [
            {'helper_id': 'helper', 'published': true, 'rating': 1},
          ],
        },
        'helper',
        demo: false,
      );
      expect(reputation.rating, 4.5);
      expect(reputation.reviewCount, 12);
      expect(reputation.completed, 18);
    },
  );
  test('missing production aggregates are unavailable, never synthesized', () {
    final reputation = HelperReputation.fromData(
      {
        'walk_reviews': [
          {'helper_id': 'helper', 'published': true, 'rating': 5},
        ],
      },
      'helper',
      demo: false,
    );
    expect(reputation.rating, isNull);
    expect(reputation.reviewCount, isNull);
    expect(reputation.completed, isNull);
  });
  test('new helpers have no stars and remain represented', () {
    final reputation = HelperReputation.fromData(
      {
        'helper_ratings': [
          {'id': 'helper', 'rating': null, 'review_count': 0, 'completed': 0},
        ],
      },
      'helper',
      demo: false,
    );
    expect(reputation.reviewLabel, 'Пока нет отзывов');
    expect(reputation.completed, 0);
  });
  test('active agreements include owner and assigned helper only', () {
    final data = {
      'walk_agreements': [
        {'request_id': 'walk', 'helper_id': 'helper'},
      ],
    };
    final request = {'id': 'walk', 'owner_id': 'owner', 'status': 'assigned'};
    expect(isMyActiveWalk(data, request, 'owner'), isTrue);
    expect(isMyActiveWalk(data, request, 'helper'), isTrue);
    expect(isMyActiveWalk(data, request, 'stranger'), isFalse);
    expect(
      isMyActiveWalk(data, {...request, 'status': 'completed'}, 'owner'),
      isFalse,
    );
  });
}
