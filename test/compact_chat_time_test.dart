import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/time/display_time.dart';

void main() {
  test(
    'Inbox labels use local time today and retain year across calendar boundaries',
    () {
      final now = DateTime(2026, 10, 9, 16);
      expect(compactChatTime(DateTime(2026, 10, 9, 9, 5), now: now), '09:05');
      expect(
        compactChatTime(DateTime(2026, 10, 8, 23, 59), now: now),
        '8 окт.',
      );
      expect(
        compactChatTime(
          DateTime(2025, 12, 31, 23, 59),
          now: DateTime(2026, 1, 1),
        ),
        '31 дек. 2025',
      );
      final instant = DateTime.utc(2026, 10, 9, 23, 59);
      final local = instant.toLocal();
      expect(
        compactChatTime(instant.toIso8601String(), now: local),
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}',
      );
      expect(compactChatTime('invalid', now: now), isEmpty);
    },
  );
}
