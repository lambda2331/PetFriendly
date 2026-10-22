import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/chat/chat_repository.dart';
import 'package:petfriendly/features/chat/chat_screen.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/community/presentation/forms.dart';
import 'package:petfriendly/features/nearby/city_catalog.dart';
import 'package:petfriendly/features/walks/account_mode.dart';
import 'package:petfriendly/features/walks/helper_requests_screen.dart';
import 'package:petfriendly/features/walks/personal_walking_controller.dart';
import 'package:petfriendly/features/walks/walking_conditions_screen.dart';
import 'package:petfriendly/features/walks/walks_screen.dart';
import '../test/widget_test.dart' show MemoryPreferences, EmptyCatalog;
import 'personal_walking_flow_test.dart'
    show nativeWalkingFixture, tapVisible, openWalkingAction;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Walks Studio owner/helper flows in both themes', (tester) async {
    for (final theme in ['light', 'dark']) {
      final repo = nativeWalkingFixture();
      repo.data['walk_requests']!.addAll([
        {
          'id': 'open-own',
          'owner_id': demoAlex,
          'pet_id': 'pet-luna',
          'status': 'open',
          'city': 'Минск',
          'district': 'Центральный район',
          'time_zone': 'Europe/Minsk',
          'duration': 45,
          'starts_at': DateTime.now()
              .toUtc()
              .add(const Duration(days: 3))
              .toIso8601String(),
          'description': 'Спокойная прогулка на шлейке.',
        },
        {
          'id': 'public',
          'owner_id': demoAnna,
          'pet_id': 'pet-luna',
          'status': 'open',
          'city': 'Минск',
          'district': 'Центральный район',
          'time_zone': 'Europe/Minsk',
          'duration': 30,
          'starts_at': DateTime.now()
              .toUtc()
              .add(const Duration(days: 4))
              .toIso8601String(),
          'description': 'Выбираем спокойный маршрут.',
        },
      ]);
      final account = DemoAccountModeRepository();
      await account.chooseRole('both');
      await account.saveHelperProfile(
        const HelperProfile(
          city: 'Минск',
          district: 'Центральный район',
          introduction: 'Люблю спокойные прогулки.',
          experience: 'Помогаю друзьям с питомцами.',
          dogSizes: ['small', 'medium'],
          serviceDistricts: ['Центральный'],
          availability: [WeeklyAvailability(day: 0, start: 540, end: 720)],
        ),
      );
      final container = ProviderContainer(
        overrides: [
          preferencesProvider.overrideWithValue(
            MemoryPreferences()
              ..values.addAll({
                'theme': theme,
                'language': 'ru',
                'city': 'Минск',
                'manualCity': 'true',
              }),
          ),
          communityRepositoryProvider.overrideWithValue(repo),
          accountModeRepositoryProvider.overrideWithValue(account),
          chatRepositoryProvider.overrideWithValue(DemoChatRepository()),
          cityCatalogServiceProvider.overrideWithValue(EmptyCatalog()),
        ],
      );
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const PetFriendlyApp(),
        ),
      );
      await tester.pumpAndSettle();
      final router = container.read(routerProvider);
      router.go('/walks');
      await tester.pumpAndSettle();
      final current = find.byKey(const ValueKey('current-entry-current'));
      await binding.takeScreenshot('current-$theme');
      await tapVisible(
        tester,
        find.descendant(of: current, matching: find.text('Детали')),
      );
      expect(find.text('Передача питомца'), findsOneWidget);
      await binding.takeScreenshot('agreement-details-$theme');
      await tapVisible(tester, find.byTooltip('Закрыть').hitTestable().last);
      await tapVisible(
        tester,
        find.descendant(of: current, matching: find.text('Чат')),
      );
      expect(find.byType(ChatScreen), findsOneWidget);
      await binding.takeScreenshot('chat-$theme');
      await openWalkingAction(tester, 'confirm');
      await tapVisible(
        tester,
        find.byKey(const Key('walking-chat-action-review_helper')),
      );
      expect(find.byType(DropdownButtonFormField<int>), findsNothing);
      await tapVisible(
        tester,
        find.byKey(const ValueKey('walking-review-star-5')),
      );
      await tester.enterText(
        find.descendant(
          of: find.byType(ReviewScreen),
          matching: find.byType(TextField),
        ),
        'Всё согласовали заранее, прогулка прошла хорошо.',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await binding.takeScreenshot('review-form-$theme');
      await tapVisible(tester, find.text('Опубликовать'));
      expect(
        repo.data['walk_reviews']!.any((r) => r['request_id'] == 'current'),
        isTrue,
      );
      await tapVisible(tester, find.byTooltip('Закрыть').hitTestable().last);
      router.pop();
      await tester.pumpAndSettle();
      final own = find.byKey(const ValueKey('current-entry-open-own'));
      await tapVisible(
        tester,
        find.descendant(of: own, matching: find.text('Детали')),
      );
      expect(find.text('Что нужно знать'), findsOneWidget);
      expect(find.text('Передача питомца'), findsNothing);
      await binding.takeScreenshot('request-details-$theme');
      await tapVisible(tester, find.byTooltip('Закрыть').hitTestable().last);
      await tapVisible(
        tester,
        find.descendant(of: own, matching: find.text('Отклики')),
      );
      await binding.takeScreenshot('applications-$theme');
      await tapVisible(tester, find.byTooltip('Закрыть').hitTestable().last);
      await tapVisible(tester, find.byKey(const ValueKey('walking-create')));
      expect(find.byType(EditScreen), findsOneWidget);
      await binding.takeScreenshot('create-form-$theme');
      await tapVisible(
        tester,
        find.byKey(const ValueKey('walking-date-trigger')),
      );
      expect(find.byType(CalendarDatePicker), findsOneWidget);
      await binding.takeScreenshot('create-calendar-$theme');
      await tapVisible(tester, find.byTooltip('Закрыть').hitTestable().last);
      final headerY = tester
          .getTopLeft(find.text('Попросить о выгуле').last)
          .dy;
      await tester.drag(find.byType(ListView).last, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text('Попросить о выгуле').last).dy,
        headerY,
      );
      await tester.scrollUntilVisible(
        find.widgetWithText(FilledButton, 'Опубликовать запрос'),
        180,
        scrollable: find
            .descendant(
              of: find.byType(EditScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await binding.takeScreenshot('create-footer-$theme');
      expect(
        tester.getTopLeft(find.text('Попросить о выгуле').last).dy,
        headerY,
      );
      await tapVisible(tester, find.byTooltip('Закрыть').hitTestable().last);
      container
          .read(personalWalkingProvider.notifier)
          .select(PersonalWalkingTab.history);
      await tester.pumpAndSettle();
      await binding.takeScreenshot('history-$theme');
      await tester.enterText(
        find.byKey(const ValueKey('walking-history-search')),
        'неизвестный питомец',
      );
      await tester.pumpAndSettle();
      expect(find.text('Прогулки не найдены'), findsOneWidget);
      FocusManager.instance.primaryFocus?.unfocus();
      container
          .read(personalWalkingProvider.notifier)
          .select(PersonalWalkingTab.profile);
      container.read(personalWalkingProvider.notifier).selectRole('helper');
      await tester.pumpAndSettle();
      await binding.takeScreenshot('reviews-$theme');
      await tapVisible(
        tester,
        find.byKey(const ValueKey('walking-conditions-link')),
      );
      expect(find.byType(WalkingConditionsScreen), findsOneWidget);
      await binding.takeScreenshot('conditions-$theme');
      await tapVisible(tester, find.byTooltip('Закрыть').hitTestable().last);
      await container.read(accountModeProvider.notifier).switchMode('helper');
      router.go('/my-walks');
      await tester.pumpAndSettle();
      container
          .read(personalWalkingProvider.notifier)
          .select(PersonalWalkingTab.current);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('walking-create')), findsNothing);
      await binding.takeScreenshot('helper-current-$theme');
      router.go('/requests');
      await tester.pumpAndSettle();
      expect(find.byType(RequestsScreen), findsOneWidget);
      await binding.takeScreenshot('helper-requests-$theme');
      await tapVisible(tester, find.byTooltip('Фильтры'));
      await binding.takeScreenshot('request-filters-$theme');
      await tapVisible(tester, find.byTooltip('Закрыть').hitTestable().last);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      await tester.pumpAndSettle();
    }
  });
}
