import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/walks/walking_studio_components.dart';
import 'package:petfriendly/features/walks/walking_chat_widgets.dart';
import 'package:petfriendly/features/walks/walks_screen.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/l10n/localization.dart';
import 'walking_detail_forms_test.dart' show WalkingFixture;
import 'package:petfriendly/features/walks/account_mode.dart';
import 'package:petfriendly/features/walks/walking_conditions_screen.dart';
import 'personal_walking_hub_test.dart' show HubCommunityFixture;

void main() {
  for (final locale in ['ru', 'en', 'be', 'pl']) {
    testWidgets('Inline calendar $locale at 320px and 200%', (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      var value = DateTime.utc(2026, 10, 20, 10, 0);
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(Brightness.dark),
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: StatefulBuilder(
                builder: (context, setState) => WalkingDateField(
                  value: value,
                  timeZone: 'Europe/Minsk',
                  firstDate: DateTime(2026, 10, 13),
                  onChanged: (d) => setState(() => value = d),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('walking-date-trigger')));
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDatePicker), findsOneWidget);
      final done = 'Готово'.tr(tester.element(find.byType(WalkingDateField)));
      expect(find.text(done), findsOneWidget);
      await tester.tap(
        find.byTooltip(
          'Закрыть'.tr(tester.element(find.byType(WalkingDateField))),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('shared-time-trigger')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('shared-time-hours')),
        '11',
      );
      expect(value.hour, isNot(11));
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.tap(find.text(done));
      await tester.pumpAndSettle();
      expect(value.hour, 11);
      expect(value.day, 20);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Walking sheet heading stays fixed while content scrolls', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(Brightness.light),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => WalkingChatSheet(
                  title: 'Детали',
                  children: List.generate(30, (n) => Text('Заметка $n')),
                ),
              ),
              child: const Text('Открыть'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();
    final y = tester.getTopLeft(find.text('Детали')).dy;
    await tester.drag(
      find.byKey(const Key('walking-sheet-scroll')),
      const Offset(0, -250),
    );
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Детали')).dy, y);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Public request sheet omits private handover for every viewer', (
    tester,
  ) async {
    for (final actor in ['self', 'helper', 'stranger']) {
      final fixture = WalkingFixture(account: actor, status: 'open');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [communityRepositoryProvider.overrideWithValue(fixture)],
          child: MaterialApp(
            theme: studioTheme(Brightness.light),
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showWalkRequestSheet(context, id: 'walk'),
                  child: const Text('Открыть'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Открыть'));
      await tester.pumpAndSettle();
      expect(find.text('Синтетические приватные инструкции'), findsNothing);
      expect(find.text('Владелец'), findsWidgets);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    }
  });
  testWidgets(
    'Compact conditions preserve multiple schedules and existing profile fields',
    (tester) async {
      final account = DemoAccountModeRepository();
      await account.chooseRole('both');
      await account.saveHelperProfile(
        const HelperProfile(
          city: 'Минск',
          district: 'Центральный',
          introduction: 'Сохранённое описание',
          experience: 'Первый опыт',
          serviceDistricts: ['Центральный', 'Советский'],
          dogSizes: ['small', 'large'],
          availability: [
            WeeklyAvailability(day: 0, start: 540, end: 1020),
            WeeklyAvailability(day: 2, start: 1080, end: 1200),
          ],
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountModeRepositoryProvider.overrideWithValue(account),
            communityRepositoryProvider.overrideWithValue(
              HubCommunityFixture(),
            ),
          ],
          child: MaterialApp(
            theme: studioTheme(Brightness.light),
            home: Scaffold(
              body: Builder(
                builder: (ctx) => TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: ctx,
                    isScrollControlled: true,
                    builder: (_) =>
                        const WalkingConditionsScreen(embedded: true),
                  ),
                  child: const Text('Открыть'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Открыть'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Готов обсуждать прогулки'));
      await tester.pumpAndSettle();
      expect(find.byType(SwitchListTile), findsOneWidget);
      await tester.tap(find.byTooltip('Закрыть').last);
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Когда'));
      await tester.tap(find.text('Когда'));
      await tester.pumpAndSettle();
      expect(find.text('Добавить время'), findsOneWidget);
      await tester.tap(find.byTooltip('Закрыть').last);
      await tester.pumpAndSettle();
      final input = find.byKey(const ValueKey('conditions-experience'));
      await tester.ensureVisible(input);
      await tester.enterText(input, 'Обновлённый опыт');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final save = find.byKey(const Key('helper-onboarding-action'));
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      final p = await account.loadHelperProfile();
      expect(p!.experience, 'Обновлённый опыт');
      expect(p.introduction, 'Сохранённое описание');
      expect(p.city, 'Минск');
      expect(p.district, 'Центральный');
      expect(p.serviceDistricts, ['Центральный', 'Советский']);
      expect(p.dogSizes, ['small', 'large']);
      expect(p.availability.map((s) => s.toJson()).toList(), [
        {'day': 0, 'start': 540, 'end': 1020},
        {'day': 2, 'start': 1080, 'end': 1200},
      ]);
      expect(find.byType(WalkingConditionsScreen), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
