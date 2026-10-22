import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/walks/account_mode.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/community/presentation/events_screen.dart';

class EventFixtureController extends CommunityController {
  EventFixtureController(this.data);
  final CommunityData data;
  @override
  Future<CommunityData> build() async => data;
}

CommunityData eventFixture({bool joined = false}) => {
  'events': [
    {
      'id': 'synthetic-event',
      'owner_id': demoAnna,
      'title': 'Спокойная прогулка с питомцами у парка',
      'description': 'Встреча без спешки для знакомства соседей.',
      'city': 'Минск',
      'time_zone': 'Europe/Minsk',
      'starts_at': DateTime.now()
          .add(const Duration(days: 2))
          .toUtc()
          .toIso8601String(),
      'capacity': 8,
    },
  ],
  'event_members': [
    {'event_id': 'synthetic-event', 'user_id': demoAnna},
    if (joined) {'event_id': 'synthetic-event', 'user_id': demoAlex},
  ],
  'conversations': [
    {'id': 'synthetic-chat', 'kind': 'event', 'context_id': 'synthetic-event'},
  ],
};

void main() {
  testWidgets(
    'Focused joined event uses consistent actions and keeps cancellation secondary',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communityProvider.overrideWith(
              () => EventFixtureController(eventFixture(joined: true)),
            ),
          ],
          child: MaterialApp(
            theme: studioTheme(Brightness.light),
            home: const EventsScreen(focusedEventId: 'synthetic-event'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('meetup-chat-synthetic-event')),
        findsOneWidget,
      );
      expect(find.text('Открыть чат'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TextButton),
          matching: find.text('Отменить участие'),
        ),
        findsOneWidget,
      );
      final visibleCopy = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .whereType<String>()
          .join('\n');
      expect(RegExp('Минск').allMatches(visibleCopy).length, 1);
    },
  );

  testWidgets(
    'Meetup filters reset without exposing history or changing city',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communityProvider.overrideWith(
              () => EventFixtureController(eventFixture()),
            ),
            preferencesProvider.overrideWithValue(_EventPreferences()),
            accountModeProvider.overrideWith(_EventAccount.new),
          ],
          child: MaterialApp(
            theme: studioTheme(Brightness.light),
            home: const EventsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('meetup-search')),
        'нет совпадения',
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Подходящих встреч пока нет'),
        200,
        scrollable: find
            .byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            )
            .first,
      );
      expect(find.text('Подходящих встреч пока нет'), findsOneWidget);
      await tester.ensureVisible(find.text('Сбросить фильтры'));
      await tester.tap(find.text('Сбросить фильтры'));
      await tester.pumpAndSettle();
      expect(find.text('Подходящих встреч пока нет'), findsNothing);
      expect(find.text('История'), findsNothing);
      final context = tester.element(find.byType(EventsScreen));
      expect(
        ProviderScope.containerOf(context).read(prototypeProvider).city,
        'Минск',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Event list reserves primary emphasis for creation and metadata reflows',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            communityProvider.overrideWith(
              () => EventFixtureController(eventFixture()),
            ),
            preferencesProvider.overrideWithValue(_EventPreferences()),
            accountModeProvider.overrideWith(_EventAccount.new),
          ],
          child: MaterialApp(
            theme: studioTheme(Brightness.dark),
            home: const MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2)),
              child: EventsScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('meetup-participation-synthetic-event')),
        findsNothing,
      );
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byTooltip('Создать встречу'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('meetup-synthetic-event')),
        250,
        scrollable: find
            .byWidgetPredicate(
              (widget) =>
                  widget is Scrollable &&
                  widget.axisDirection == AxisDirection.down,
            )
            .first,
      );
      expect(find.text('Присоединиться'), findsNothing);
      expect(find.text('Детали'), findsNothing);
      expect(
        find.byKey(const ValueKey('meetup-synthetic-event')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

class _EventPreferences implements PreferencesRepository {
  @override
  String? read(String key) => key == 'city' ? 'Минск' : null;
  @override
  Future<void> write(String key, String value) async {}
}

class _EventAccount extends AccountModeController {
  @override
  Future<AccountMode> build() async => const AccountMode(
    role: 'owner',
    mode: 'owner',
    needsRoleSelection: false,
  );
}
