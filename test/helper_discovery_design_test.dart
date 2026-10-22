import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/walks/helper_requests_screen.dart';
import 'package:petfriendly/l10n/localization.dart';

DemoCommunityRepository discoveryFixture() {
  final repo = DemoCommunityRepository(seedSamples: false);
  repo.data['walk_requests'] = [
    {
      'id': 'discovery-request',
      'owner_id': demoAnna,
      'pet_id': 'discovery-pet',
      'status': 'open',
      'city': 'Минск',
      'district': 'Центральный',
      'starts_at': DateTime.now()
          .add(const Duration(days: 3))
          .toIso8601String(),
    },
  ];
  repo.data['pets'] = [
    {'id': 'discovery-pet', 'name': 'Синтетический питомец', 'size': 'small'},
  ];
  return repo;
}

Future<void> mount(
  WidgetTester tester,
  Widget screen,
  DemoCommunityRepository repo, {
  String locale = 'ru',
  bool dark = false,
  double scale = 1,
  bool settle = true,
}) async {
  tester.view.physicalSize = const Size(320, 900);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [communityRepositoryProvider.overrideWithValue(repo)],
      child: MaterialApp(
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: studioTheme(dark ? Brightness.dark : Brightness.light),
        home: Scaffold(body: screen),
      ),
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('district draft applies explicitly and can reset', (
    tester,
  ) async {
    await mount(tester, const RequestsScreen(), discoveryFixture());
    await tester.tap(find.byTooltip('Фильтры'));
    await tester.pumpAndSettle();
    final district = find.byWidgetPredicate(
      (w) => w is TextField && w.textInputAction == TextInputAction.done,
    );
    await tester.enterText(district, 'Нет такого района');
    await tester.pumpAndSettle();
    expect(
      find.text('Фильтры изменены. Примените их, чтобы обновить результаты.'),
      findsOneWidget,
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Закрыть').last);
    await tester.pumpAndSettle();
    expect(find.text('Синтетический питомец'), findsNothing);
    await tester.tap(find.byTooltip('Фильтры'));
    await tester.pumpAndSettle();
    final reset = find.descendant(of:find.byKey(const Key('walking-sheet-scroll')),matching:find.text('Сбросить фильтры')).first;
    await tester.scrollUntilVisible(
      reset,
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('walking-sheet-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(reset);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Закрыть').last);
    await tester.pumpAndSettle();
    expect(find.text('Синтетический питомец'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('district chooser uses actual loaded public area', (
    tester,
  ) async {
    await mount(tester, const RequestsScreen(), discoveryFixture());
    await tester.tap(find.byTooltip('Фильтры'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Выбрать район'));
    await tester.pumpAndSettle();
    final districtOption = find.descendant(
      of: find.byType(ListTile),
      matching: find.text('Центральный'),
    );
    expect(districtOption, findsOneWidget);
    await tester.tap(districtOption);
    await tester.pumpAndSettle();
    expect(find.text('Поиск: Минск · Центральный'), findsOneWidget);
    expect(find.text('Синтетический питомец'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('history has contextual empty copy and returns to upcoming', (
    tester,
  ) async {
    await mount(
      tester,
      const MyWalksScreen(),
      DemoCommunityRepository(seedSamples: false),
    );
    await tester.tap(find.text('История прогулок'));
    await tester.pumpAndSettle();
    expect(
      find.text('Завершённые и отменённые прогулки появятся здесь.'),
      findsOneWidget,
    );
    expect(find.text('Отклики'), findsNothing);
    await tester.tap(find.text('К предстоящим прогулкам'));
    await tester.pumpAndSettle();
    expect(find.text('Предстоящие'), findsOneWidget);
    expect(find.text('Посмотреть запросы'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'help explains application, agreement and reviews; can scroll and close at 2x',
    (tester) async {
      await mount(
        tester,
        const RequestsScreen(),
        discoveryFixture(),
        scale: 2,
        dark: true,
      );
      await tester.tap(find.byTooltip('Как это работает'));
      await tester.pumpAndSettle();
      expect(find.text('Как проходит прогулка'),findsOneWidget);
      final eligibility=find.text('Кто может оставить отзыв');
      await tester.ensureVisible(eligibility);
      await tester.tap(eligibility);
      await tester.pumpAndSettle();
      expect(find.text('Отклик ещё не означает назначение.'),findsOneWidget);
      final finalStep=find.text('После подтверждённого завершения каждый назначенный участник может оставить один отзыв о другом. Нельзя оценивать себя или человека вне этой договорённости.');
      await tester.ensureVisible(finalStep);
      expect(finalStep.hitTestable(),findsOneWidget);
      await tester.tap(find.byTooltip('Закрыть'));
      await tester.pumpAndSettle();
      expect(find.byType(WalkingHowItWorksSheet), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Синтетический питомец'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Синтетический питомец').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  for (final error in [false, true]) {
    testWidgets(
      'pagination ${error ? 'error' : 'loading'} retains rows and supplies footer recovery',
      (tester) async {
        var retried = false;
        final item = {
          'id': 'existing',
          'pet': {'id': 'pet', 'name': 'Уже найденный питомец'},
          'city': 'Минск',
          'starts_at': DateTime.now().toIso8601String(),
          'status': 'open',
        };
        await mount(
          tester,
          WalkingListResult(
            snapshot: error
                ? AsyncSnapshot<List<Map<String, dynamic>>>.withError(
                    ConnectionState.done,
                    Exception('next page'),
                  )
                : const AsyncSnapshot<List<Map<String, dynamic>>>.nothing(),
            retainedItems: [item],
            onRetry: () {},
            empty: 'Empty',
            onPageRetry: () => retried = true,
          ),
          DemoCommunityRepository(seedSamples: false),
          settle: error,
        );
        expect(find.text('Уже найденный питомец'), findsOneWidget);
        if (error) {
          await tester.tap(find.text('Повторить'));
          expect(retried, isTrue);
        } else {
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final locale in ['ru', 'en']) {
    testWidgets('320px 2x district label and guidance wrap in $locale', (
      tester,
    ) async {
      await mount(
        tester,
        const RequestsScreen(),
        discoveryFixture(),
        locale: locale,
        scale: 2,
      );
      final context = tester.element(find.byType(RequestsScreen));
      await tester.tap(find.byTooltip('Фильтры'.tr(context)));
      await tester.pumpAndSettle();
      final labelText = translateForLanguage(
        'Район · необязательно',
        locale: locale,
      );
      final instructionText = translateForLanguage(
        'Введите район или выберите из найденных.',
        locale: locale,
      );
      for (final content in [labelText, instructionText]) {
        final finder = find.text(content);
        expect(finder, findsOneWidget);
        final paragraph = tester.renderObject<RenderParagraph>(finder);
        expect(paragraph.didExceedMaxLines, isFalse);
        final boxes = paragraph.getBoxesForSelection(
          TextSelection(baseOffset: 0, extentOffset: content.length),
        );
        expect(
          boxes.map((box) => box.top).toSet().length,
          greaterThan(1),
          reason: 'Long label/instruction should wrap at enlarged text',
        );
      }
      final labelledField = find.byWidgetPredicate(
        (widget) => widget is Semantics && widget.properties.label == labelText,
      );
      expect(
        find.descendant(of: labelledField, matching: find.byType(TextField)),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final locale in ['ru', 'en']) {
    for (final dark in [false, true]) {
      testWidgets(
        '320px 2x tabs keep complete $locale labels ${dark ? 'dark' : 'light'}',
        (tester) async {
          String selected = 'active';
          await mount(
            tester,
            StatefulBuilder(
              builder: (context, update) => WalkingViewTabs(
                value: selected,
                onChanged: (value) => update(() => selected = value),
              ),
            ),
            DemoCommunityRepository(seedSamples: false),
            locale: locale,
            dark: dark,
            scale: 2,
          );
          final label = 'Предстоящие';
          final upcoming = find.text(
            translateForLanguage(label, locale: locale),
          );
          final applications = find.text(
            translateForLanguage('Отклики', locale: locale),
          );
          expect(upcoming, findsOneWidget);
          expect(
            tester.getTopLeft(applications).dy,
            greaterThan(tester.getTopLeft(upcoming).dy),
          );
          await tester.tap(applications);
          await tester.pumpAndSettle();
          expect(selected, 'applications');
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
