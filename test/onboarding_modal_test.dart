import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/auth/onboarding_controller.dart';
import 'package:petfriendly/features/auth/onboarding_screen.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/walks/account_mode.dart';
import 'widget_test.dart' show MemoryPreferences;

void main() {
  for (final dark in [false, true]) {
    testWidgets(
      'Onboarding manual settlement is country-qualified; inline errors at 200% dark=$dark',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repository = DemoCommunityRepository(seedSamples: false);
        final container = ProviderContainer(
          overrides: [
            communityRepositoryProvider.overrideWithValue(repository),
            accountModeRepositoryProvider.overrideWithValue(
              DemoAccountModeRepository(),
            ),
            preferencesProvider.overrideWithValue(MemoryPreferences()),
          ],
        );
        addTearDown(container.dispose);
        await container.read(onboardingProvider.future);
        await container.read(onboardingProvider.notifier).advance();
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: studioTheme(dark ? Brightness.dark : Brightness.light),
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: const OnboardingScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('onboarding-city')),
        );
        await tester.tap(find.byKey(const ValueKey('onboarding-city')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('city-input')),
          'Testville-no-match',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(const Key('onboarding-manual')));
        await tester.tap(find.byKey(const Key('onboarding-manual')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const ValueKey('onboarding-manual-city')),
          '',
        );
        await tester.ensureVisible(
          find.byKey(const Key('onboarding-manual-save')),
        );
        await tester.tap(find.byKey(const Key('onboarding-manual-save')));
        await tester.pumpAndSettle();
        expect(
          find.text('Укажите название населённого пункта.'),
          findsOneWidget,
        );
        expect(find.text('Укажите страну.'), findsOneWidget);
        await tester.enterText(
          find.byKey(const ValueKey('onboarding-manual-city')),
          'Testville',
        );
        await tester.enterText(
          find.byKey(const ValueKey('onboarding-manual-country')),
          'Polska',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const Key('onboarding-manual-save')),
        );
        await tester.tap(find.byKey(const Key('onboarding-manual-save')));
        await tester.pumpAndSettle();
        expect(
          container.read(onboardingProvider).requireValue.text('city'),
          'Testville, PL',
        );
        expect(
          container.read(onboardingProvider).requireValue.manualCity,
          true,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
