import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/community/presentation/events_screen.dart';
import 'package:petfriendly/features/community/presentation/meetup_controller.dart';
import '../test/fixtures/meetup_studio_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Meetup Studio native visual states and chat history', (
    tester,
  ) async {
    for (final dark in [false, true]) {
      for (final locale in ['ru', 'en', 'be', 'pl']) {
        final c = meetupStudioContainer(locale: locale, dark: dark);
        tester.platformDispatcher.textScaleFactorTestValue = locale == 'pl'
            ? 2
            : 1;
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: const PetFriendlyApp(),
          ),
        );
        await tester.pumpAndSettle();
        final router = c.read(routerProvider);
        router.go('/events');
        await tester.pumpAndSettle();
        await Future<void>.delayed(const Duration(milliseconds: 600));
        await tester.pumpAndSettle();
        final prefix = '$locale-${dark ? 'dark' : 'light'}';
        await binding.takeScreenshot('$prefix-list');
        if (locale == 'ru') {
          await tester.tap(find.byKey(const ValueKey('meetup-date-filter')));
          await tester.pumpAndSettle();
          await binding.takeScreenshot('$prefix-date-menu');
          await tester.tap(find.text('На выходных').last);
          await tester.pumpAndSettle();
          await tester.tap(find.widgetWithText(FilledButton, 'Применить'));
          await tester.pumpAndSettle();
          // Relative filtering commits explicitly; restore all dates before the
          // stable fixture journey, so this test also works on weekdays.
          await tester.tap(find.byKey(const ValueKey('meetup-date-filter')));
          await tester.pumpAndSettle();
          expect(
            tester
                .widget<RadioGroup<MeetupDate>>(
                  find.byType(RadioGroup<MeetupDate>),
                )
                .groupValue,
            MeetupDate.weekend,
          );
          await tester.tap(find.text('Любая дата').last);
          await tester.tap(find.widgetWithText(FilledButton, 'Применить'));
          await tester.pumpAndSettle();
          await tester.ensureVisible(
            find.byKey(const ValueKey('meetup-$meetupFixtureId')),
          );
          await tester.tap(
            find.byKey(const ValueKey('meetup-$meetupFixtureId')),
          );
          await tester.pumpAndSettle();
          expect(router.state.uri.path, '/event/$meetupFixtureId');
          await binding.takeScreenshot('$prefix-expanded');
          for (var n = 0; n < 2; n++) {
            await tester.ensureVisible(
              find.byKey(const ValueKey('meetup-chat-$meetupFixtureId')),
            );
            await tester.tap(
              find.byKey(const ValueKey('meetup-chat-$meetupFixtureId')),
            );
            await tester.pumpAndSettle();
            expect(find.byKey(const Key('message-input')), findsOneWidget);
            expect(find.byKey(const Key('attach-media')), findsOneWidget);
            expect(find.byKey(const Key('chat-context-link')), findsNothing);
            if (n == 0) await binding.takeScreenshot('$prefix-chat');
            router.pop();
            await tester.pumpAndSettle();
            expect(router.state.uri.path, '/event/$meetupFixtureId');
            expect(
              find.byKey(const ValueKey('meetup-chat-$meetupFixtureId')),
              findsOneWidget,
            );
          }
          router.pop();
          await tester.pumpAndSettle();
          expect(router.state.uri.path, '/events');
          expect(c.read(prototypeProvider).manualCity, isTrue);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        c.dispose();
      }
      tester.platformDispatcher.clearTextScaleFactorTestValue();
      for (final scenario in ['empty', 'error', 'loading']) {
        final c = meetupStudioContainer(
          dark: dark,
          repository: MeetupStudioRepository(scenario: scenario),
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: c,
            child: const PetFriendlyApp(),
          ),
        );
        if (scenario == 'loading') {
          await tester.pump(const Duration(milliseconds: 500));
        } else {
          await tester.pumpAndSettle();
        }
        c.read(routerProvider).go('/events');
        if (scenario == 'loading') {
          await tester.pump(const Duration(milliseconds: 500));
          await Future<void>.delayed(const Duration(milliseconds: 600));
          await tester.pump();
        } else {
          await tester.pumpAndSettle();
          await Future<void>.delayed(const Duration(milliseconds: 600));
        }
        expect(find.byType(MeetupContentState), findsOneWidget);
        await binding.takeScreenshot('ru-${dark ? 'dark' : 'light'}-$scenario');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        c.dispose();
      }
    }
  }, timeout: const Timeout(Duration(minutes: 4)));
}
