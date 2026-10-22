import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/core/ui/studio_pickers.dart';
import 'package:petfriendly/l10n/localization.dart';

void main() {
  const formats = {
    'ru': '24-часовой формат',
    'en': '24-hour format',
    'be': '24-гадзінны фармат',
    'pl': 'Format 24-godzinny',
  };
  for (final locale in formats.keys) {
    for (final brightness in Brightness.values) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'Time $locale $brightness $scale: keyboard, validation, commit and cancel',
          (tester) async {
            tester.view.physicalSize = const Size(320, 800);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            var selected = const TimeOfDay(hour: 9, minute: 30);
            await tester.pumpWidget(
              MaterialApp(
                theme: studioTheme(brightness),
                locale: Locale(locale),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    alwaysUse24HourFormat: false,
                  ),
                  child: child!,
                ),
                home: Builder(
                  builder: (context) => Scaffold(
                    body: TextButton(
                      key: const ValueKey('open'),
                      onPressed: () async {
                        final result = await showStudioTimePicker(
                          context: context,
                          initialTime: selected,
                          timeZone: 'Europe/Warsaw',
                        );
                        if (result != null) selected = result;
                      },
                      child: const Text('Open'),
                    ),
                  ),
                ),
              ),
            );
            await tester.tap(find.byKey(const ValueKey('open')));
            await tester.pumpAndSettle();
            expect(find.text(formats[locale]!), findsOneWidget);
            expect(find.text('Europe/Warsaw'), findsOneWidget);
            expect(find.text('09'), findsOneWidget);
            expect(find.text('30'), findsOneWidget);
            final hours = find.byKey(const ValueKey('shared-time-hours'));
            final minutes = find.byKey(const ValueKey('shared-time-minutes'));
            final done = find.byKey(const ValueKey('shared-time-done'));
            if (scale == 1) {
              expect(tester.getSize(hours).width, closeTo(100, .01));
              expect(tester.getSize(minutes).width, closeTo(100, .01));
            }
            expect(tester.takeException(), isNull);
            double paintedHeight(Finder field) => InputDecorator.containerOf(
              tester.element(
                find.descendant(of: field, matching: find.byType(EditableText)),
              ),
            )!.size.height;
            expect(paintedHeight(hours), greaterThanOrEqualTo(64));
            expect(paintedHeight(minutes), greaterThanOrEqualTo(64));
            await tester.enterText(hours, '23');
            await tester.enterText(minutes, '60');
            tester.view.viewInsets = const FakeViewPadding(bottom: 300);
            await tester.pumpAndSettle();
            expect(tester.getRect(done).bottom, lessThanOrEqualTo(500));
            await tester.tap(done);
            await tester.pumpAndSettle();
            expect(selected, const TimeOfDay(hour: 9, minute: 30));
            expect(done, findsOneWidget);
            expect(paintedHeight(hours), greaterThanOrEqualTo(64));
            expect(paintedHeight(minutes), greaterThanOrEqualTo(64));
            await tester.ensureVisible(minutes);
            await tester.enterText(minutes, '59');
            await tester.tap(done);
            await tester.pumpAndSettle();
            expect(selected, const TimeOfDay(hour: 23, minute: 59));
            tester.view.viewInsets = FakeViewPadding.zero;
            await tester.pumpAndSettle();
            await tester.tap(find.byKey(const ValueKey('open')));
            await tester.pumpAndSettle();
            expect(find.text('23'), findsOneWidget);
            await tester.enterText(hours, '05');
            final close = 'Закрыть'.tr(tester.element(done));
            await tester.tap(find.byTooltip(close));
            await tester.pumpAndSettle();
            expect(selected, const TimeOfDay(hour: 23, minute: 59));
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('Unknown time zone is explicit and does not default to Minsk', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(Brightness.light),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => showStudioTimePicker(
                context: context,
                initialTime: const TimeOfDay(hour: 0, minute: 0),
                timeZone: null,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Часовой пояс не выбран'), findsOneWidget);
    expect(find.text('Europe/Minsk'), findsNothing);
  });

  testWidgets(
    'Temporal caller forwards its zone and preserves wall date/time',
    (tester) async {
      var value = DateTime.utc(2026, 3, 29, 1, 30);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(Brightness.light),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, update) => StudioTemporalFields(
                value: value,
                firstDate: DateTime.utc(2026, 3, 1),
                timeZone: 'Europe/Warsaw',
                onChanged: (next) => update(() => value = next),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('shared-time-trigger')));
      await tester.pumpAndSettle();
      expect(find.text('Europe/Warsaw'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('shared-time-hours')),
        '03',
      );
      await tester.enterText(
        find.byKey(const ValueKey('shared-time-minutes')),
        '45',
      );
      await tester.tap(find.byKey(const ValueKey('shared-time-done')));
      await tester.pumpAndSettle();
      expect(value, DateTime.utc(2026, 3, 29, 3, 45));
      expect(tester.takeException(), isNull);
    },
  );
}
