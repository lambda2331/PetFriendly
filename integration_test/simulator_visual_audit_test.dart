import 'support/native_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/backend/backend.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/auth/onboarding_controller.dart';
import 'package:petfriendly/features/chat/chat_repository.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/nearby/city_catalog.dart';
import 'package:petfriendly/features/nearby/place_row.dart';
import 'package:petfriendly/features/walks/account_mode.dart';
import 'package:petfriendly/features/walks/personal_walking_controller.dart';
import 'package:petfriendly/l10n/localization.dart';
import '../design/nearby-studio-native/fixture.dart';
import '../test/fixtures/people_studio_fixture.dart';
import 'personal_walking_flow_test.dart'
    show nativeWalkingFixture, nativeChat, nativeHelperChat;
import 'review60_native_flow_test.dart' as meetings;

final auditCaptures = <Map<String, Object?>>[];

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const tablet = bool.fromEnvironment('AUDIT_TABLET');
  if (!tablet) meetings.main();

  for (final variant
      in tablet
          ? [(false, 'ru', 1.0)]
          : [(false, 'ru', 1.0), (true, 'ru', 1.0), (true, 'pl', 2.0)]) {
    testWidgets('Simulator visual audit $variant', (tester) async {
      final repo = PeopleStudioRepository();
      final walking = nativeWalkingFixture();
      for (final key in [
        'profiles',
        'pets',
        'conversations',
        'conversation_members',
      ]) {
        for (final row in walking.data[key]!) {
          final id = row['id'];
          if (id != null) repo.data[key]!.removeWhere((r) => r['id'] == id);
          repo.data[key]!.add(row);
        }
      }
      for (final key in [
        'walk_requests',
        'walk_agreements',
        'walk_details',
        'walk_reviews',
        'helper_ratings',
      ]) {
        repo.data[key] = walking.data[key]!;
      }
      final direct = await repo.command('direct', {'target': demoAnna});
      final account = DemoAccountModeRepository();
      await account.chooseRole('both');
      await account.saveHelperProfile(
        const HelperProfile(
          city: 'Минск',
          district: 'Центральный район',
          introduction: 'Люблю спокойные прогулки.',
          serviceDistricts: ['Центральный район'],
          availability: [WeeklyAvailability(day: 0, start: 540, end: 1020)],
        ),
      );
      final c = ProviderContainer(
        overrides: [
          backendProvider.overrideWithValue(null),
          preferencesProvider.overrideWithValue(
            NearbyReviewPreferences(locale: variant.$2, dark: variant.$1),
          ),
          communityRepositoryProvider.overrideWithValue(repo),
          chatRepositoryProvider.overrideWithValue(DemoChatRepository()),
          cityCatalogServiceProvider.overrideWithValue(NearbyReviewCatalog()),
          accountModeRepositoryProvider.overrideWithValue(account),
        ],
      );
      tester.platformDispatcher.textScaleFactorTestValue = variant.$3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const PetFriendlyApp()),
      );
      await tester.pumpAndSettle();
      final router = c.read(routerProvider);
      final prefix =
          '${tablet ? 'ipad' : 'iphone'}-${variant.$2}-${variant.$1 ? 'dark' : 'light'}-${variant.$3}';
      Future<void> shot(String name) async {
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 250));
        final root =
            Offset.zero &
            (tester.view.physicalSize / tester.view.devicePixelRatio);
        final text = <Map<String, Object?>>[];
        for (final e in find.byType(RichText).evaluate()) {
          final r = e.renderObject;
          if (r is! RenderParagraph || !r.attached || !r.hasSize) continue;
          final box = r.localToGlobal(Offset.zero) & r.size;
          if (!root.overlaps(box)) continue;
          text.add({
            'text': r.text.toPlainText(),
            'font': r.text.style?.fontFamily,
            'size': r.text.style?.fontSize,
            'weight': r.text.style?.fontWeight?.value,
            'rect': [box.left, box.top, box.width, box.height],
            'truncated': r.didExceedMaxLines,
          });
        }
        auditCaptures.add({
          'name': '$prefix-$name',
          'route': router.state.uri.toString(),
          'viewport': [root.width, root.height],
          'textScale': variant.$3,
          'texts': text,
        });
        await binding.takeScreenshot('$prefix-$name');
        binding.reportData!['visualAudit'] = auditCaptures;
        expect(tester.takeException(), isNull, reason: '$prefix-$name');
      }

      Future<void> tap(Finder finder) async {
        await tapNativeReady(tester, finder);
      }

      String tr(String text) => translateForLanguage(text, locale: variant.$2);
      await shot('nearby');
      await tap(find.byKey(const Key('choose-city')));
      await shot('city-sheet');
      Navigator.of(tester.element(find.byKey(const Key('city-input')))).pop();
      await tester.pumpAndSettle();
      await tap(find.byKey(const Key('nearby-places-list')));
      await shot('places');
      await tap(find.byKey(const Key('place-more-filters')));
      await shot('places-filters');
      Navigator.of(tester.element(find.text(tr('Показать места')))).pop();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(PlaceRow).first,
        160,
        scrollable: find.byType(Scrollable).last,
      );
      await tap(find.byType(PlaceRow).first);
      await shot('place-details');
      Navigator.of(
        tester.element(find.byKey(const Key('open-place-review'))),
      ).pop();
      await tester.pumpAndSettle();
      router.go('/people');
      await shot('people');
      await tap(
        find.descendant(
          of: find.byKey(const ValueKey('people-community-segment')),
          matching: find.text(tr('Сообщества')),
        ),
      );
      await shot('communities');
      await tap(find.text('Соседи с питомцами'));
      await shot('community-details');
      Navigator.of(
        tester.element(find.byKey(const ValueKey('community-chat'))),
      ).pop();
      await tester.pumpAndSettle();
      router.go('/profile');
      await shot('profile');
      await tap(find.byTooltip(tr('Редактировать профиль')));
      await shot('profile-editor');
      await tap(find.byKey(const ValueKey('field.display_name')));
      await shot('profile-keyboard');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      Navigator.of(
        tester.element(find.byKey(const ValueKey('field.display_name'))),
      ).pop();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byTooltip(tr('Настройки')),
        -180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tap(find.byTooltip(tr('Настройки')));
      await shot('settings');
      router.go('/walks');
      await shot('walking-current');
      c
          .read(personalWalkingProvider.notifier)
          .select(PersonalWalkingTab.history);
      await shot('walking-history');
      c
          .read(personalWalkingProvider.notifier)
          .select(PersonalWalkingTab.profile);
      await shot('walking-reviews');
      router.push('/chat/$nativeChat');
      await shot('walking-chat');
      await tap(find.byKey(const Key('walking-chat-status')));
      await shot('walking-progress');
      Navigator.of(tester.element(find.byTooltip(tr('Закрыть')).last)).pop();
      await tester.pumpAndSettle();
      router.go('/chats');
      await shot('chats');
      router.push('/chat/$direct');
      await shot('direct-chat');
      await tap(find.byKey(const Key('message-input')));
      await tester.enterText(
        find.byKey(const Key('message-input')),
        'Тестовый черновик',
      );
      await shot('chat-keyboard');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();
      router.push('/chat/$direct');
      await tester.pumpAndSettle();
      expect(find.text('Тестовый черновик'), findsOneWidget);
      if (variant.$2 == 'ru' && !variant.$1) {
        await c.read(accountModeProvider.notifier).switchMode('helper');
        router.go('/requests');
        await shot('helper-requests');
        router.go('/my-walks');
        await shot('helper-walks');
        router.push('/chat/$nativeHelperChat');
        await tester.pumpAndSettle();
        await tap(find.byKey(const Key('walking-chat-status')));
        await shot('helper-start');
        await tap(find.byKey(const Key('walking-chat-action-start')));
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(seconds: 2)),
        );
        await tester.pump();
        await shot('helper-running');
        await tap(find.byKey(const Key('walking-chat-action-finish')));
        await shot('helper-awaiting-confirmation');
        Navigator.of(tester.element(find.byTooltip(tr('Закрыть')).last)).pop();
        await tester.pumpAndSettle();
      }
      router.go('/login');
      await shot('login');
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      c.dispose();
    });
  }

  testWidgets('Simulator onboarding appearance and validation', (tester) async {
    final c = ProviderContainer(
      overrides: [
        backendProvider.overrideWithValue(null),
        preferencesProvider.overrideWithValue(NearbyReviewPreferences()),
        communityRepositoryProvider.overrideWithValue(
          DemoCommunityRepository(seedSamples: false),
        ),
        accountModeRepositoryProvider.overrideWithValue(
          DemoAccountModeRepository(),
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const PetFriendlyApp()),
    );
    await tester.pumpAndSettle();
    c.read(routerProvider).go('/onboarding');
    await tester.pumpAndSettle();
    await c.read(onboardingProvider.future);
    final controller = c.read(onboardingProvider.notifier);
    Future<void> shot(String name) async {
      await tester.pumpAndSettle();
      await binding.takeScreenshot(
        '${tablet ? 'ipad' : 'iphone'}-onboarding-$name',
      );
      expect(tester.takeException(), isNull);
    }

    await shot('role');
    controller.chooseRole('owner');
    await controller.advance();
    await shot('profile');
    await controller.advance();
    await shot('errors');
    controller.field('name', 'Александра Ковальская');
    controller.city('Минск');
    await controller.advance();
    await shot('pet');
    await controller.advance(skipPet: true);
    await shot('ready');
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    c.dispose();
  });
}
