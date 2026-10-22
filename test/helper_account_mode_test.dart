import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/walks/account_mode.dart';
import 'package:petfriendly/features/walks/helper_onboarding.dart';

class FailingModeRepository extends DemoAccountModeRepository {
  bool fail = true;
  int mutations = 0;
  Completer<void>? barrier;
  @override
  Future<AccountMode> switchMode(String mode) async {
    mutations++;
    if (barrier != null) await barrier!.future;
    if (fail) throw StateError('Recoverable fixture failure');
    return super.switchMode(mode);
  }

  @override
  Future<void> saveHelperProfile(HelperProfile profile) async {
    if (fail) throw StateError('Recoverable fixture failure');
    return super.saveHelperProfile(profile);
  }
}

void main() {
  test(
    'Role change retains public helper preferences and one repository',
    () async {
      final repository = DemoAccountModeRepository();
      await repository.chooseRole('both', mode: 'helper');
      const profile = HelperProfile(city: 'Минск', district: 'Центральный');
      await repository.saveHelperProfile(profile);
      await repository.switchMode('owner');
      expect((await repository.load()).canHelp, true);
      expect(await repository.loadHelperProfile(), same(profile));
      await repository.chooseRole('owner');
      expect(await repository.loadHelperProfile(), same(profile));
      await expectLater(repository.switchMode('helper'), throwsStateError);
    },
  );
  test(
    'Pending guard and failed mode mutation keep authoritative mode',
    () async {
      final repository = FailingModeRepository()..barrier = Completer<void>();
      final container = ProviderContainer(
        overrides: [
          accountModeRepositoryProvider.overrideWithValue(repository),
        ],
      );
      addTearDown(container.dispose);
      await container.read(accountModeProvider.future);
      final controller = container.read(accountModeProvider.notifier);
      final mutation = controller.switchMode('helper');
      expect(container.read(accountModeProvider).value!.pending, true);
      await controller.switchMode('helper');
      expect(repository.mutations, 1);
      repository.barrier!.complete();
      await expectLater(mutation, throwsStateError);
      expect(container.read(accountModeProvider).value!.mode, 'owner');
      expect(container.read(accountModeProvider).value!.pending, false);
      expect(container.read(accountModeProvider).value!.error, isNotNull);
      repository.fail = false;
      await controller.switchMode('helper');
      expect(container.read(accountModeProvider).value!.mode, 'helper');
    },
  );
  test('Weekly slots use integer schema and reject overlap and overnight', () {
    const morning = WeeklyAvailability(day: 0, start: 540, end: 720);
    expect(morning.toJson(), {'day': 0, 'start': 540, 'end': 720});
    expect(
      WeeklyAvailability.validate([
        morning,
        const WeeklyAvailability(day: 0, start: 720, end: 780),
      ]),
      isNull,
    );
    expect(
      WeeklyAvailability.validate([
        morning,
        const WeeklyAvailability(day: 0, start: 600, end: 780),
      ]),
      isNotNull,
    );
    expect(
      WeeklyAvailability.validate([
        const WeeklyAvailability(day: 6, start: 1300, end: 60),
      ]),
      isNotNull,
    );
    expect(const HelperProfile(serviceDistricts: ['']).validate(), isNotNull);
  });
  for (final brightness in Brightness.values) {
    testWidgets('Role choice fits compact enlarged text in $brightness', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: studioTheme(brightness),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: const RoleSelectionScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final both = find.text('Обе роли');
      await tester.scrollUntilVisible(both, 200);
      await tester.pumpAndSettle();
      await tester.ensureVisible(both);
      await tester.pumpAndSettle();
      expect(both.hitTestable(), findsOneWidget);
      await tester.tap(both);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'Helper without pets retains failed draft and retries structured save',
    (tester) async {
      final repository = FailingModeRepository();
      await repository.chooseRole('helper');
      final community = DemoCommunityRepository(seedSamples: false);
      final router = GoRouter(
        initialLocation: '/helper/onboarding',
        routes: [
          GoRoute(
            path: '/helper/onboarding',
            builder: (_, _) => const HelperOnboardingScreen(),
          ),
          GoRoute(
            path: '/requests',
            builder: (_, _) => const Scaffold(body: Text('Запросы открыты')),
          ),
          GoRoute(
            path: '/roles',
            builder: (_, _) => const RoleSelectionScreen(),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountModeRepositoryProvider.overrideWithValue(repository),
            communityRepositoryProvider.overrideWithValue(community),
          ],
          child: MaterialApp.router(
            theme: studioTheme(Brightness.light),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      Finder input(String label) => find.byKey(ValueKey('helper-field-$label'));
      await tester.enterText(input('Имя'), 'Синтетическая Александра');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      final optional = find.text('О себе и опыте · необязательно');
      await tester.scrollUntilVisible(
        optional,
        160,
        scrollable: find
            .descendant(
              of: find.byType(HelperOnboardingScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      final disclosure = tester.widget<ExpansionTile>(
        find.byKey(const ValueKey('helper-introduction')),
      );
      if (!disclosure.initiallyExpanded) {
        await tester.tap(optional);
        await tester.pumpAndSettle();
      }
      await tester.scrollUntilVisible(
        input('Коротко о себе · необязательно'),
        160,
        scrollable: find
            .descendant(
              of: find.byType(HelperOnboardingScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.enterText(
        input('Коротко о себе · необязательно'),
        'Люблю спокойные прогулки',
      );
      await tester.scrollUntilVisible(
        find.text('Продолжить'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(HelperOnboardingScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Продолжить'));
      await tester.pumpAndSettle();
      expect(find.text('Для прогулок'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const Key('helper-district-input')),
        200,
        scrollable: find
            .descendant(
              of: find.byType(HelperOnboardingScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.enterText(
        find.byKey(const Key('helper-district-input')),
        'Центральный',
      );
      await tester.tap(find.byKey(const Key('helper-add-district')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('helper-district-input')),
        'Советский',
      );
      await tester.tap(find.byKey(const Key('helper-add-district')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Сохранить'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(HelperOnboardingScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Сохранить'),
        100,
        scrollable: find
            .descendant(
              of: find.byType(HelperOnboardingScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.textContaining('Ваши данные остались в форме'),
        -100,
        scrollable: find
            .descendant(
              of: find.byType(HelperOnboardingScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(
        find.textContaining('Ваши данные остались в форме'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('helper-district-input')),
        -200,
        scrollable: find
            .descendant(
              of: find.byType(HelperOnboardingScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.widgetWithText(InputChip, 'Центральный'), findsOneWidget);
      expect(find.widgetWithText(InputChip, 'Советский'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Сохранить'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(HelperOnboardingScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      repository.fail = false;
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Сохранить'),
        100,
        scrollable: find
            .descendant(
              of: find.byType(HelperOnboardingScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Сохранить'));
      await tester.pumpAndSettle();
      expect(find.text('Запросы открыты'), findsOneWidget);
      expect(repository.profile!.serviceDistricts, [
        'Центральный',
        'Советский',
      ]);
      expect(repository.profile!.introduction, 'Люблю спокойные прогулки');
      expect(rows(await community.load(), 'pets'), isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
}
