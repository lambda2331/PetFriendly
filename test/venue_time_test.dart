import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/time/display_time.dart';

void main() {
  test('All launch-city times use venue zone, independent of device', () {
    expect(cityTimeZone('Гродно'), 'Europe/Minsk');
    expect(cityTimeZone('Minsk'), 'Europe/Minsk');
    expect(cityTimeZone('Unknown fixture city'), isNull);
    expect(
      venueTime('2026-10-09T12:00:00Z', city: 'Гродно'),
      contains('15:00'),
    );
    expect(
      venueTime('2026-10-09T12:00:00Z', city: 'Unknown'),
      contains('часовой пояс места не указан'),
    );
  });
  test('Venue conversion handles seasonal offsets and picker round trips', () {
    expect(
      venueDateTime(DateTime.utc(2026, 7, 1, 12), 'Europe/Warsaw').hour,
      14,
    );
    expect(
      venueDateTime(DateTime.utc(2026, 1, 1, 12), 'Europe/Warsaw').hour,
      13,
    );
    expect(
      venueWallTimeToUtc(DateTime.utc(2026, 7, 1, 14), 'Europe/Warsaw'),
      DateTime.utc(2026, 7, 1, 12),
    );
    expect(
      venueWallTimeToUtc(DateTime.utc(2026, 1, 1, 13), 'Europe/Warsaw'),
      DateTime.utc(2026, 1, 1, 12),
    );
    expect(
      venueWallTimeToUtc(DateTime.utc(2026, 10, 9, 15), 'Europe/Minsk'),
      DateTime.utc(2026, 10, 9, 12),
    );
  });
  test('Invalid and ambiguous wall times require an explicit correction', () {
    expect(
      () =>
          venueWallTimeToUtc(DateTime.utc(2026, 3, 29, 2, 30), 'Europe/Warsaw'),
      throwsFormatException,
    );
    expect(
      () => venueWallTimeToUtc(
        DateTime.utc(2026, 10, 25, 2, 30),
        'Europe/Warsaw',
      ),
      throwsFormatException,
    );
    expect(validTimeZone('invalid/fixture'), isFalse);
  });
}
