import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/community/presentation/events_screen.dart';

void main() {
  for (final dark in [false, true]) {
    for (final content in ['none', 'whitespace', 'description', 'map']) {
      testWidgets('Details visibility: $content dark=$dark', (tester) async {
        var chatOpened = false;
        final event = <String, dynamic>{
          'id': 'event',
          'owner_id': 'me',
          'title': 'Встреча',
          'city': 'Минск',
          'time_zone': 'Europe/Minsk',
          'starts_at': DateTime.now()
              .add(const Duration(days: 2))
              .toIso8601String(),
          'description': content == 'description'
              ? 'Встречаемся у входа'
              : content == 'whitespace'
              ? '  \n  '
              : null,
          if (content == 'map') ...{'latitude': 53.9, 'longitude': 27.5},
        };
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(dark ? Brightness.dark : Brightness.light),
            home: Scaffold(
              body: ListView(
                children: [
                  MeetupCard(
                    event: event,
                    data: const {},
                    uid: 'me',
                    onChat: () => chatOpened = true,
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final details = find.byKey(const ValueKey('meetup-details-event'));
        expect(
          details,
          content == 'description' || content == 'map'
              ? findsOneWidget
              : findsNothing,
        );
        await tester.tap(find.byKey(const ValueKey('meetup-chat-event')));
        expect(chatOpened, isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  }
  testWidgets('No details does not hide a joined participant cancellation', (
    tester,
  ) async {
    var cancelled = false;
    final event = <String, dynamic>{
      'id': 'event',
      'owner_id': 'other',
      'title': 'Встреча',
      'city': 'Минск',
      'starts_at': DateTime.now()
          .add(const Duration(days: 2))
          .toIso8601String(),
    };
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(Brightness.light),
        home: Scaffold(
          body: ListView(
            children: [
              MeetupCard(
                event: event,
                data: const {
                  'event_members': [
                    {'event_id': 'event', 'user_id': 'me'},
                  ],
                },
                uid: 'me',
                onChat: () {},
                onParticipation: (joined) => cancelled = joined,
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('meetup-details-event')), findsNothing);
    await tester.tap(find.text('Отменить участие'));
    expect(cancelled, isTrue);
  });
}
