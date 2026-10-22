import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/community/presentation/events_screen.dart';
import 'fixtures/meetup_studio_fixture.dart';

Future<void> press(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Dedicated details and chat Back retain originating search', (
    tester,
  ) async {
    final repo = MeetupStudioRepository();
    final c = meetupStudioContainer(repository: repo);
    addTearDown(c.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const PetFriendlyApp()),
    );
    await tester.pumpAndSettle();
    final router = c.read(routerProvider);
    router.go('/events');
    await tester.pumpAndSettle();
    expect(find.text('История'), findsNothing);
    expect(find.byKey(const ValueKey('meetup-create')), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('meetup-search')),
      'Прогулка',
    );
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await press(tester, find.byKey(const ValueKey('meetup-$meetupFixtureId')));
    expect(router.state.uri.path, '/event/$meetupFixtureId');
    expect(
      find.text(repo.data['events']!.first['description'] as String),
      findsOneWidget,
    );
    for (var n = 0; n < 2; n++) {
      await press(
        tester,
        find.byKey(const ValueKey('meetup-chat-$meetupFixtureId')),
      );
      expect(find.byKey(const Key('message-input')), findsOneWidget);
      expect(find.byKey(const Key('attach-media')), findsOneWidget);
      expect(find.byKey(const Key('chat-context-link')), findsNothing);
      router.pop();
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/event/$meetupFixtureId');
      expect(
        find.text(repo.data['events']!.first['description'] as String),
        findsOneWidget,
      );
    }
    router.pop();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/events');
    expect(
      tester
          .widget<TextField>(find.byKey(const ValueKey('meetup-search')))
          .controller!
          .text,
      'Прогулка',
    );
    expect(c.read(prototypeProvider).manualCity, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Only one creation entry and helper capability remains restricted',
    (tester) async {
      final c = meetupStudioContainer(helperOnly: true);
      addTearDown(c.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const PetFriendlyApp()),
      );
      await tester.pumpAndSettle();
      c.read(routerProvider).go('/events');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('meetup-create')), findsNothing);
    },
  );
  testWidgets(
    'Empty state is centered and loading is distinct with reduced motion',
    (tester) async {
      for (final scenario in ['empty', 'loading', 'error']) {
        final c = meetupStudioContainer(
          repository: MeetupStudioRepository(scenario: scenario),
        );
        tester.platformDispatcher.accessibilityFeaturesTestValue =
            const FakeAccessibilityFeatures(reduceMotion: true);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: const PetFriendlyApp(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 500));
        c.read(routerProvider).go('/events');
        await tester.pump(const Duration(milliseconds: 500));
        if (scenario != 'loading') {
          await tester.pumpAndSettle();
        } else {
          for (var n = 0; n < 5; n++) {
            await tester.pump(const Duration(milliseconds: 100));
          }
        }
        await tester.scrollUntilVisible(
          find.byType(MeetupContentState),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        final label = find
            .descendant(
              of: find.byType(MeetupContentState),
              matching: find.byType(Text),
            )
            .first;
        expect(tester.widget<Text>(label).textAlign, TextAlign.center);
        if (scenario == 'loading') {
          expect(find.byIcon(Icons.hourglass_empty_outlined), findsOneWidget);
        }
        if (scenario == 'empty') {
          expect(find.byKey(const ValueKey('meetup-create')), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        c.dispose();
      }
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
    },
  );
}
