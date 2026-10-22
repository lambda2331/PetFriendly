import 'package:petfriendly/features/chat/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/nearby/city_catalog.dart';
import 'package:petfriendly/features/walks/account_mode.dart';
import 'package:petfriendly/features/walks/helper_onboarding.dart';
import 'package:petfriendly/features/walks/walking_conditions_screen.dart';
import 'package:petfriendly/features/walks/personal_walking_hub.dart';
import 'package:petfriendly/features/walks/personal_walking_controller.dart';
import 'package:petfriendly/features/community/presentation/forms.dart';
import 'package:petfriendly/l10n/localization.dart';
import 'widget_test.dart' show EmptyCatalog, MemoryPreferences;

Future<ProviderContainer> mountWalkingRoutes(WidgetTester tester) async {
  final account = DemoAccountModeRepository();
  await account.chooseRole('both');
  await account.saveHelperProfile(
    const HelperProfile(
      introduction: 'Сохранённый опыт',
      dogSizes: ['small'],
      serviceDistricts: ['Центральный'],
    ),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        preferencesProvider.overrideWithValue(MemoryPreferences()),
        cityCatalogServiceProvider.overrideWithValue(EmptyCatalog()),
        accountModeRepositoryProvider.overrideWithValue(account),
        communityRepositoryProvider.overrideWithValue(
          DemoCommunityRepository(),
        ),
      ],
      child: const PetFriendlyApp(),
    ),
  );
  await tester.pumpAndSettle();
  return ProviderScope.containerOf(tester.element(find.byType(StudioShell)));
}

void main() {
  testWidgets(
    'Conditions opens the compact form and retains its draft on Close',
    (tester) async {
      final container = await mountWalkingRoutes(tester);
      final router = container.read(routerProvider);
      router.go('/walks?tab=profile&role=helper');
      await tester.pumpAndSettle();
      container
          .read(personalWalkingProvider.notifier)
          .select(PersonalWalkingTab.profile);
      await tester.pumpAndSettle();
      final action = find.byKey(const ValueKey('walking-conditions-link'));
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.byType(WalkingConditionsScreen), findsOneWidget);
      expect(find.byType(HelperOnboardingScreen), findsOneWidget);
      expect(find.text('Редактировать условия'), findsNothing);
      final experience = find.byKey(const ValueKey('conditions-experience'));
      await tester.ensureVisible(experience);
      await tester.enterText(experience, 'Новый синтетический опыт');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Закрыть').last);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/walks');
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextFormField>(experience).controller!.text,
        'Новый синтетический опыт',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Legacy assigned link replaces its detail with chat; Back returns once',
    (tester) async {
      final account = DemoAccountModeRepository();
      await account.chooseRole('both');
      final repo = DemoCommunityRepository(seedSamples: false);
      repo.data['profiles'] = [
        {'id': demoAlex, 'display_name': 'Владелец'},
        {'id': demoAnna, 'display_name': 'Помощник'},
      ];
      repo.data['pets'] = [
        {'id': 'pet', 'owner_id': demoAlex, 'name': 'Луна'},
      ];
      repo.data['walk_requests'] = [
        {
          'id': 'assigned',
          'owner_id': demoAlex,
          'pet_id': 'pet',
          'status': 'assigned',
          'city': 'Минск',
          'time_zone': 'Europe/Minsk',
          'starts_at': '2026-10-17T09:00:00Z',
        },
      ];
      repo.data['walk_agreements'] = [
        {'request_id': 'assigned', 'helper_id': demoAnna},
      ];
      repo.data['conversations'] = [
        {'id': 'walk-chat', 'kind': 'walk', 'context_id': 'assigned'},
      ];
      repo.data['conversation_members'] = [
        {'conversation_id': 'walk-chat', 'user_id': demoAlex},
        {'conversation_id': 'walk-chat', 'user_id': demoAnna},
      ];
      repo.data['walk_details'] = [
        {
          'request_id': 'assigned',
          'instructions': 'Секретная передача питомца',
        },
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(MemoryPreferences()),
            cityCatalogServiceProvider.overrideWithValue(EmptyCatalog()),
            accountModeRepositoryProvider.overrideWithValue(account),
            communityRepositoryProvider.overrideWithValue(repo),
          ],
          child: const PetFriendlyApp(),
        ),
      );
      await tester.pumpAndSettle();
      final container = ProviderScope.containerOf(
        tester.element(find.byType(StudioShell)),
      );
      final router = container.read(routerProvider);
      router.go('/walks');
      await tester.pumpAndSettle();
      router.push('/walk/assigned');
      await tester.pumpAndSettle();
      expect(find.byType(ChatScreen), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(PersonalWalkingHub), findsOneWidget);
      expect(router.canPop(), isFalse);
      repo.data['conversation_members']![0]['left_at'] = '2026-10-12T10:00:00Z';
      container.invalidate(communityProvider);
      router.go('/walk/assigned');
      await tester.pumpAndSettle();
      expect(find.byType(ChatScreen), findsNothing);
      expect(find.text('Чат этой прогулки недоступен'), findsOneWidget);
      expect(find.text('Секретная передача питомца'), findsNothing);
      expect(find.text('Начать прогулку'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Create sheet blocks shell tabs and restores the walking context',
    (tester) async {
      final container = await mountWalkingRoutes(tester);
      final router = container.read(routerProvider);
      router.go('/walks');
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Попросить о выгуле'));
      await tester.pumpAndSettle();
      expect(find.byType(EditScreen), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('nav-3'), skipOffstage: false),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/walks');
      expect(find.byType(EditScreen), findsOneWidget);
      await tester.tap(find.byTooltip('Закрыть').last);
      await tester.pumpAndSettle();
      expect(find.byType(EditScreen), findsNothing);
      expect(find.byType(PersonalWalkingHub), findsOneWidget);
    },
  );

  testWidgets(
    'Own profile aliases update the same hub without role or identity changes',
    (tester) async {
      final container = await mountWalkingRoutes(tester);
      final router = container.read(routerProvider);
      final uid = container.read(communityRepositoryProvider).userId;
      router.go('/walks');
      await tester.pumpAndSettle();
      expect(find.byType(PersonalWalkingHub), findsOneWidget);
      container
          .read(personalWalkingProvider.notifier)
          .select(PersonalWalkingTab.history);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, '/walks');
      router.go('/helper/$uid');
      await tester.pumpAndSettle();
      expect(
        container.read(personalWalkingProvider).tab,
        PersonalWalkingTab.profile,
      );
      expect(container.read(personalWalkingProvider).profileRole, 'helper');
      router.go('/owner/$uid');
      await tester.pumpAndSettle();
      expect(container.read(personalWalkingProvider).profileRole, 'owner');
      expect(container.read(accountModeProvider).value!.mode, 'owner');
      expect(container.read(communityRepositoryProvider).userId, uid);
      router.go('/helper/$demoAnna');
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/helper/$demoAnna',
      );
      expect(tester.takeException(), isNull);
    },
  );
  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'Preferences editor is one form and preserves identity at $scale text',
      (tester) async {
        tester.view.physicalSize = const Size(320, 900);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final container = await mountWalkingRoutes(tester);
        final repo = container.read(communityRepositoryProvider);
        final before = findRow(
          (await repo.load()),
          'profiles',
          repo.userId,
        )!['display_name'];
        final router = container.read(routerProvider);
        router.go('/walks?tab=profile&role=helper');
        await tester.pumpAndSettle();
        container
            .read(personalWalkingProvider.notifier)
            .select(PersonalWalkingTab.profile);
        await tester.pumpAndSettle();
        router.push('/helper/preferences');
        await tester.pumpAndSettle();
        expect(find.byType(HelperOnboardingScreen), findsOneWidget);
        expect(find.text('Шаг 1 из 2'), findsNothing);
        expect(find.text('Выбрать фото'), findsNothing);
        expect(find.text('Имя'), findsNothing);
        final context = tester.element(find.byType(HelperOnboardingScreen));
        final target = find.byKey(
          ValueKey(
            'helper-field-${"Коротко о себе · необязательно".tr(context)}',
          ),
        );
        await tester.scrollUntilVisible(
          target,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.enterText(target, 'Обновлённые условия');
        await tester.pump();
        await tester.tap(find.byKey(const Key('helper-onboarding-action')));
        await tester.pumpAndSettle();
        expect(find.byType(HelperOnboardingScreen), findsNothing);
        expect(
          (await container
                  .read(accountModeRepositoryProvider)
                  .loadHelperProfile())!
              .introduction,
          'Обновлённые условия',
        );
        expect(
          findRow(await repo.load(), 'profiles', repo.userId)!['display_name'],
          before,
        );
        expect(
          container.read(personalWalkingProvider).tab,
          PersonalWalkingTab.profile,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
