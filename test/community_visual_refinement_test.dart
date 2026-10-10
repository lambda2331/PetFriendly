import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/community/presentation/events_screen.dart';

class EventFixtureController extends CommunityController {
  EventFixtureController(this.data);
  final CommunityData data;
  @override
  Future<CommunityData> build() async => data;
}

CommunityData eventFixture({bool joined = false}) => {
  'events': [{
    'id': 'synthetic-event', 'owner_id': demoAnna,
    'title': 'Спокойная прогулка с питомцами у парка',
    'description': 'Встреча без спешки для знакомства соседей.',
    'city': 'Минск', 'time_zone': 'Europe/Minsk',
    'starts_at': '2026-10-10T15:30:00Z', 'capacity': 8,
  }],
  'event_members': [
    {'event_id': 'synthetic-event', 'user_id': demoAnna},
    if (joined) {'event_id': 'synthetic-event', 'user_id': demoAlex},
  ],
  'conversations': [{'id': 'synthetic-chat', 'kind': 'event', 'context_id': 'synthetic-event'}],
};

void main() {
  testWidgets('Focused joined event promotes chat and keeps cancellation secondary', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      communityProvider.overrideWith(() => EventFixtureController(eventFixture(joined: true))),
    ], child: MaterialApp(theme: studioTheme(Brightness.light),
      home: const EventsScreen(focusedEventId: 'synthetic-event'))));
    await tester.pumpAndSettle();
    final primary = find.byWidgetPredicate((widget) => widget is FilledButton);
    expect(primary, findsOneWidget);
    expect(find.descendant(of: primary, matching: find.text('Чат встречи')), findsOneWidget);
    expect(find.descendant(of: find.byType(OutlinedButton), matching: find.text('Отменить участие')), findsOneWidget);
    final visibleCopy = tester.widgetList<Text>(find.byType(Text))
      .map((text) => text.data).whereType<String>().join('\n');
    expect(RegExp('Минск').allMatches(visibleCopy).length, 1);
  });

  testWidgets('Event list reserves primary emphasis for creation and metadata reflows', (tester) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(overrides: [
      communityProvider.overrideWith(() => EventFixtureController(eventFixture())),
    ], child: MaterialApp(theme: studioTheme(Brightness.dark),
      home: const MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(1.8)),
        child: EventsScreen()))));
    await tester.pumpAndSettle();
    expect(find.byWidgetPredicate((widget) => widget is FilledButton), findsNothing);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Присоединиться'), findsOneWidget);
    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
