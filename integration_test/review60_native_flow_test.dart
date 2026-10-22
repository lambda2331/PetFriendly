import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/l10n/localization.dart';
import '../test/fixtures/meetup_studio_fixture.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  Future<void> capture(WidgetTester tester, String name) async {
    await tester.pumpAndSettle();
    // Let the native raster surface publish the settled frame before capture.
    await tester.pump(const Duration(milliseconds: 250));
    await binding.takeScreenshot(name);
  }

  testWidgets('Review 60 native meeting flows and large text', (tester) async {
    for (final variant in [(false, 'ru', 1.0), (true, 'pl', 2.0)]) {
      final c = meetupStudioContainer(locale: variant.$2, dark: variant.$1);
      tester.platformDispatcher.textScaleFactorTestValue = variant.$3;
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const PetFriendlyApp()),
      );
      await tester.pumpAndSettle();
      final router = c.read(routerProvider);
      router.go('/events');
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<StatefulNavigationShell>(
              find.byType(StatefulNavigationShell),
            )
            .currentIndex,
        1,
      );
      final prefix = variant.$1 ? 'dark-pl-large' : 'light-ru';
      await capture(tester, '$prefix-meetings');
      await tester.tap(find.byKey(const ValueKey('meetup-date-filter')));
      await tester.pumpAndSettle();
      await capture(tester, '$prefix-filters');
      router.pop();
      await tester.pumpAndSettle();
      final meetingRow = find.byKey(const ValueKey('meetup-$meetupFixtureId'));
      await tester.ensureVisible(meetingRow);
      await tester.pumpAndSettle();
      await tester.tapAt(tester.getTopLeft(meetingRow) + const Offset(80, 28));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/event/$meetupFixtureId');
      await capture(tester, '$prefix-details');
      router.pop();
      await tester.pumpAndSettle();
      final create = find.byKey(const ValueKey('meetup-create'));
      await tester.ensureVisible(create);
      await tester.pumpAndSettle();
      await tester.tap(create);
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/edit/event');
      await capture(tester, '$prefix-create');
      final date = find.byKey(const ValueKey('walking-date-trigger'));
      await tester.scrollUntilVisible(
        date,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(date);
      await tester.pumpAndSettle();
      await capture(tester, '$prefix-date');
      final ctx = tester.element(find.byType(CalendarDatePicker));
      await tester.tap(find.byTooltip('Закрыть'.tr(ctx)));
      await tester.pumpAndSettle();
      final time = find.byKey(const ValueKey('shared-time-trigger'));
      await tester.scrollUntilVisible(
        time,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(time);
      await tester.pumpAndSettle();
      await capture(tester, '$prefix-time');
      await tester.tap(
        find.byTooltip(
          'Закрыть'.tr(
            tester.element(find.byKey(const ValueKey('shared-time-hours'))),
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.pop();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      c.dispose();
    }
    tester.platformDispatcher.clearTextScaleFactorTestValue();
  });
}
