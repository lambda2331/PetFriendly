import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/nearby/city_catalog.dart';
import 'package:petfriendly/features/walks/account_mode.dart';
import 'package:petfriendly/features/walks/helper_onboarding.dart';
import 'widget_test.dart' show EmptyCatalog, MemoryPreferences;

Future<ProviderContainer> onboarding(
  WidgetTester tester, {
  bool dark = false,
  double scale = 1,
  HelperProfile? profile,
}) async {
  tester.view.physicalSize = const Size(320, 800);
  tester.view.devicePixelRatio = 1;
  tester.platformDispatcher.textScaleFactorTestValue = scale;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  final account = DemoAccountModeRepository();
  await account.chooseRole('helper');
  if (profile != null) await account.saveHelperProfile(profile);
  final prefs = MemoryPreferences();
  prefs.values['theme'] = dark ? 'dark' : 'light';
  final community = DemoCommunityRepository();
  for (final row in community.data['profiles'] ?? <Json>[]) {
    if (row['id'] == community.userId) row['about'] = '';
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        cityCatalogServiceProvider.overrideWithValue(EmptyCatalog()),
        communityRepositoryProvider.overrideWithValue(community),
        accountModeRepositoryProvider.overrideWithValue(account),
      ],
      child: const PetFriendlyApp(),
    ),
  );
  await tester.pumpAndSettle();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(StudioShell)),
  );
  container.read(routerProvider).go('/helper/onboarding');
  await tester.pumpAndSettle();
  expect(find.byType(HelperOnboardingScreen), findsOneWidget);
  return container;
}

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'Onboarding CTA is visible at 200% in ${dark ? 'dark' : 'light'} theme and above keyboard',
      (tester) async {
        await onboarding(tester, dark: dark, scale: 2);
        final action = find.byKey(const Key('helper-onboarding-action'));
        expect(find.text('Шаг 1 из 2'), findsOneWidget);
        final initial = tester.getRect(action);
        expect(initial.bottom, lessThanOrEqualTo(800));
        expect(initial.height, greaterThanOrEqualTo(48));
        expect(tester.takeException(), isNull);
        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        addTearDown(tester.view.resetViewInsets);
        await tester.pumpAndSettle();
        final keyboardRect = tester.getRect(action);
        expect(keyboardRect.bottom, lessThanOrEqualTo(500));
        expect(keyboardRect.height, greaterThanOrEqualTo(48));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Optional introduction reveals progressively and draft survives step changes',
    (tester) async {
      final container = await onboarding(tester);
      final optional = find.text('О себе и опыте · необязательно');
      final name = find.widgetWithText(TextFormField, 'Имя');
      await tester.ensureVisible(name);
      await tester.enterText(name, 'Александра Длинноеимя');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
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
      await tester.tap(optional);
      await tester.pumpAndSettle();
      final introduction = find.byKey(
        const ValueKey('helper-field-Коротко о себе · необязательно'),
      );
      await tester.scrollUntilVisible(
        introduction,
        160,
        scrollable: find
            .descendant(
              of: find.byType(HelperOnboardingScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.enterText(introduction, 'Люблю спокойные прогулки');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('helper-onboarding-action')));
      await tester.pumpAndSettle();
      expect(find.text('Шаг 2 из 2'), findsOneWidget);
      expect(
        container.read(helperDraftProvider)?.name,
        'Александра Длинноеимя',
      );
      expect(
        container.read(helperDraftProvider)?.profile.introduction,
        'Люблю спокойные прогулки',
      );
      final areaInput = find.byKey(const Key('helper-district-input'));
      await tester.scrollUntilVisible(
        areaInput,
        160,
        scrollable: find
            .descendant(
              of: find.byType(HelperOnboardingScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.enterText(areaInput, 'Śródmieście');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('helper-add-district')));
      await tester.pumpAndSettle();
      expect(container.read(helperDraftProvider)?.profile.serviceDistricts, [
        'Śródmieście',
      ]);
      expect(find.widgetWithText(InputChip, 'Śródmieście'), findsOneWidget);
      await tester.enterText(areaInput, 'Śródmieście');
      await tester.tap(find.byKey(const Key('helper-add-district')));
      await tester.pumpAndSettle();
      expect(container.read(helperDraftProvider)?.profile.serviceDistricts, [
        'Śródmieście',
      ]);
      expect(find.text('Этот район уже добавлен'), findsOneWidget);
      await tester.enterText(areaInput, '');
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      final zone = find.text('Минск · UTC+3');
      await tester.scrollUntilVisible(
        zone,
        160,
        scrollable: find
            .descendant(
              of: find.byType(HelperOnboardingScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(zone, findsOneWidget);
      expect(find.text('Europe/Minsk'), findsNothing);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Шаг 1 из 2'),
        -160,
        scrollable: find
            .descendant(
              of: find.byType(HelperOnboardingScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Шаг 1 из 2'), findsOneWidget);
      await tester.ensureVisible(name);
      expect(find.text('Александра Длинноеимя'), findsOneWidget);
      expect(
        container.read(helperDraftProvider)?.profile.introduction,
        'Люблю спокойные прогулки',
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Overlapping availability retains dialog values until corrected',
    (tester) async {
      final container = await onboarding(
        tester,
        profile: const HelperProfile(
          availability: [WeeklyAvailability(day: 0, start: 540, end: 1020)],
        ),
      );
      await tester.tap(find.byKey(const Key('helper-onboarding-action')));
      await tester.pumpAndSettle();
      final add = find.text('Добавить время');
      await tester.scrollUntilVisible(
        add,
        160,
        scrollable: find
            .descendant(
              of: find.byType(HelperOnboardingScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(add);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Добавить'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.text('Интервалы одного дня не должны пересекаться'),
        findsOneWidget,
      );
      expect(
        container.read(helperDraftProvider)?.profile.availability,
        hasLength(1),
      );
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Вторник').last);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Добавить'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      final recovered = container
          .read(helperDraftProvider)!
          .profile
          .availability
          .last;
      expect(recovered.day, 1);
      expect(recovered.start, 540);
      expect(recovered.end, 1020);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Unadded district draft survives navigation away and recreation',
    (tester) async {
      final container = await onboarding(tester);
      await tester.tap(find.byKey(const Key('helper-onboarding-action')));
      await tester.pumpAndSettle();
      final input = find.byKey(const Key('helper-district-input'));
      await tester.scrollUntilVisible(
        input,
        160,
        scrollable: find
            .descendant(
              of: find.byType(HelperOnboardingScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.enterText(input, 'Praga-Północ');
      expect(
        container.read(helperDraftProvider)?.districtEntry,
        'Praga-Północ',
      );
      expect(
        container.read(helperDraftProvider)?.profile.serviceDistricts,
        isEmpty,
      );
      tester.testTextInput.hide();
      container.read(routerProvider).go('/requests');
      await tester.pumpAndSettle();
      container.read(routerProvider).go('/helper/onboarding');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        input,
        160,
        scrollable: find
            .descendant(
              of: find.byType(HelperOnboardingScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(
        tester.widget<TextFormField>(input).controller!.text,
        'Praga-Północ',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
