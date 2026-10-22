import 'package:flutter/material.dart';
import 'support/native_controls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/chat/chat_repository.dart';
import 'package:petfriendly/features/chat/chat_screen.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/nearby/city_catalog.dart';
import 'package:petfriendly/features/walks/account_mode.dart';
import 'package:petfriendly/features/walks/personal_walking_controller.dart';
import 'package:petfriendly/features/walks/personal_walking_hub.dart';
import 'package:petfriendly/features/walks/walks_screen.dart';
import 'package:petfriendly/features/walks/walking_conditions_screen.dart';
import 'package:petfriendly/features/community/presentation/forms.dart';
import 'package:petfriendly/l10n/localization.dart';
import '../test/widget_test.dart' show MemoryPreferences, EmptyCatalog;

const nativeChat = '00000000-0000-4000-8000-000000000099';
const nativeHelperChat = '00000000-0000-4000-8000-000000000100';
DemoCommunityRepository nativeWalkingFixture() {
  final repo = DemoCommunityRepository(seedSamples: false);
  repo.data['profiles'] = [
    {
      'id': demoAlex,
      'display_name': 'Александра Ковальская',
      'district': 'Центральный район',
      'about': 'Спокойные прогулки рядом.',
    },
    {'id': demoAnna, 'display_name': 'Ульяна', 'district': 'Центральный район'},
  ];
  repo.data['pets'] = [
    {
      'id': 'pet-luna',
      'owner_id': demoAlex,
      'name': 'Луна',
      'kind': 'Собака',
      'age': 2,
    },
  ];
  final date = DateTime.now()
      .toUtc()
      .add(const Duration(days: 2))
      .toIso8601String();
  Json row(String id, String owner, String status) => {
    'id': id,
    'owner_id': owner,
    'pet_id': 'pet-luna',
    'status': status,
    'starts_at': status == 'completed'
        ? DateTime.now()
              .toUtc()
              .subtract(const Duration(days: 3))
              .toIso8601String()
        : status == 'awaiting_confirmation'
        ? DateTime.now()
              .toUtc()
              .subtract(const Duration(hours: 1))
              .toIso8601String()
        : date,
    'city': 'Минск',
    'district': 'Центральный район',
    'time_zone': 'Europe/Minsk',
    'duration': 45,
  };
  repo.data['walk_requests'] = [
    row('current', demoAlex, 'awaiting_confirmation'),
    row('helper-active', demoAnna, 'assigned'),
    row('history-owner', demoAlex, 'completed'),
    row('history-helper', demoAnna, 'completed'),
  ];
  repo.data['walk_agreements'] = [
    {'request_id': 'current', 'helper_id': demoAnna},
    {'request_id': 'helper-active', 'helper_id': demoAlex},
    {'request_id': 'history-owner', 'helper_id': demoAnna},
    {'request_id': 'history-helper', 'helper_id': demoAlex},
  ];
  repo.data['walk_details'] = [
    {
      'request_id': 'current',
      'instructions': 'Встречаемся у входа со стороны сквера. Вода в сумке.',
    },
  ];
  repo.data['conversations'] = [
    {'id': nativeChat, 'kind': 'walk', 'context_id': 'current'},
    {'id': nativeHelperChat, 'kind': 'walk', 'context_id': 'helper-active'},
  ];
  repo.data['conversation_members'] = [
    {'conversation_id': nativeChat, 'user_id': demoAlex, 'active': true},
    {'conversation_id': nativeChat, 'user_id': demoAnna, 'active': true},
    {'conversation_id': nativeHelperChat, 'user_id': demoAlex, 'active': true},
    {'conversation_id': nativeHelperChat, 'user_id': demoAnna, 'active': true},
  ];
  repo.data['walk_reviews'] = [
    {
      'id': 'received',
      'request_id': 'prior-helper',
      'helper_id': demoAlex,
      'author_id': demoAnna,
      'rating': 5,
      'published': true,
      'body':
          'Спасибо за внимательное отношение к просьбе выбрать спокойный маршрут. Заранее уточнила привычки собаки и подробно рассказала, как прошла прогулка. Луна вернулась довольной, обязательно обратимся снова.',
      'created_at': '2026-10-10T12:00:00Z',
    },
  ];
  repo.data['helper_ratings'] = [
    {'id': demoAlex, 'rating': 5, 'review_count': 1, 'completed': 1},
  ];
  return repo;
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tapNativeReady(tester, finder);
}

Future<void> openWalkingAction(WidgetTester tester, String action) async {
  final target = find.byKey(Key('walking-chat-action-$action'));
  if (target.evaluate().isEmpty) {
    await tapVisible(tester, find.byKey(const Key('walking-chat-status')));
  }
  expect(target, findsOneWidget);
  await tapVisible(tester, target);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Native walking hub, direct chat, review, preferences and role history in both themes',
    (tester) async {
      for (final theme in ['light', 'dark']) {
        final repo = nativeWalkingFixture();
        final account = DemoAccountModeRepository();
        await account.chooseRole('both');
        await account.saveHelperProfile(
          const HelperProfile(
            city: 'Минск',
            district: 'Центральный район',
            introduction: 'Люблю спокойные прогулки.',
            experience: 'Четыре года помогаю друзьям.',
            dogSizes: ['medium', 'small', 'large'],
            serviceDistricts: ['Центральный'],
            availability: [WeeklyAvailability(day: 0, start: 1080, end: 1260)],
          ),
        );
        final prefs = MemoryPreferences()
          ..values.addAll({
            'theme': theme,
            'language': 'ru',
            'city': 'Минск',
            'manualCity': 'true',
          });
        final container = ProviderContainer(
          overrides: [
            preferencesProvider.overrideWithValue(prefs),
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
        router.go('/profile');
        await tester.pumpAndSettle();
        await binding.takeScreenshot('native-account-$theme');
        await tapVisible(tester, find.byKey(const ValueKey('nav-2')));
        expectNativeSelectedBranch(tester, 2);
        expect(router.canPop(), isFalse);
        container
            .read(personalWalkingProvider.notifier)
            .select(PersonalWalkingTab.current);
        await tester.pumpAndSettle();
        expect(find.byType(PersonalWalkingHub), findsOneWidget);
        await binding.takeScreenshot('native-current-$theme');
        await tapVisible(
          tester,
          find.descendant(
            of: find.byKey(const ValueKey('current-entry-current')),
            matching: find.text('Чат'),
          ),
        );
        expect(find.byType(ChatScreen), findsOneWidget);
        expect(
          tester.widget<ChatScreen>(find.byType(ChatScreen)).id,
          nativeChat,
        );
        await binding.takeScreenshot('native-chat-$theme');
        final chatUri = router.routeInformationProvider.value.uri;
        await tester.enterText(
          find.byKey(const Key('message-input')),
          'Черновик прогулки',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await tapVisible(tester, find.byKey(const Key('walking-chat-details')));
        expect(find.text('Передача питомца'), findsOneWidget);
        expect(find.byWidgetPredicate((w) => w is Semantics && w.properties.label == 'Участники'), findsOneWidget);
        expect(find.text('Europe/Minsk'), findsNothing);
        expect(
          find.text('Встречаемся у входа со стороны сквера. Вода в сумке.'),
          findsOneWidget,
        );
        expect(find.byType(ExpansionTile), findsNothing);
        expect(router.routeInformationProvider.value.uri, chatUri);
        await binding.takeScreenshot('native-details-$theme');
        await tapVisible(tester, find.byTooltip('Закрыть').hitTestable().first);
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('message-input')))
              .controller!
              .text,
          'Черновик прогулки',
        );
        await tapVisible(tester, find.byTooltip('О переписке'));
        await tapVisible(tester, find.byKey(const Key('walking-chat-report')));
        await tapVisible(tester, find.text('Другое'));
        await tester.enterText(
          find.byKey(const Key('walking-report-note')),
          'Синтетическая проверка формы',
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        await binding.takeScreenshot('native-report-$theme');
        await tapVisible(tester, find.byTooltip('Закрыть').hitTestable().first);
        await tapVisible(tester, find.byTooltip('О переписке'));
        await tapVisible(tester, find.byKey(const Key('walking-chat-report')));
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('walking-report-note')))
              .controller!
              .text,
          'Синтетическая проверка формы',
        );
        await tapVisible(
          tester,
          find.byKey(const Key('walking-report-submit')),
        );
        expect(find.text('Жалоба отправлена'), findsOneWidget);
        await tapVisible(tester, find.byTooltip('Закрыть').hitTestable().first);
        await openWalkingAction(tester, 'confirm');
        expect(repo.data['walk_requests']!.first['status'], 'completed');
        expect(
          find.byKey(const Key('walking-chat-action-review_helper')),
          findsOneWidget,
        );
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('message-input')))
              .controller!
              .text,
          'Черновик прогулки',
        );
        await tapVisible(tester, find.byTooltip('Закрыть').hitTestable().last);
        await tapVisible(tester, find.byType(BackButton).hitTestable().first);
        expect(router.routeInformationProvider.value.uri.path, '/walks');
        expect(router.canPop(), isFalse);
        router.go('/chats');
        await tester.pumpAndSettle();
        await tapVisible(
          tester,
          find.byWidgetPredicate(
            (widget) => widget is InboxRow && widget.entry.id == nativeChat,
          ),
        );
        expect(find.byType(ChatScreen), findsOneWidget);
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('message-input')))
              .controller!
              .text,
          'Черновик прогулки',
        );
        await tapVisible(tester, find.byType(BackButton).hitTestable().first);
        expect(router.routeInformationProvider.value.uri.path, '/chats');
        expect(router.canPop(), isFalse);
        router.go('/walks');
        await tester.pumpAndSettle();
        await tapVisible(tester, find.text('История').first);
        await tapVisible(
          tester,
          find.descendant(
            of: find.byKey(const ValueKey('history-entry-current')),
            matching: find.text('Детали'),
          ),
        );
        expect(find.byKey(const Key('walking-sheet-header')), findsOneWidget);
        await tapVisible(tester, find.byTooltip('Закрыть').hitTestable().last);
        expect(router.routeInformationProvider.value.uri.path, '/walks');
        expect(router.canPop(), isFalse);
        final historyUri = router.routeInformationProvider.value.uri;
        await binding.takeScreenshot('native-history-$theme');
        await tapVisible(
          tester,
          find.widgetWithText(OutlinedButton, 'Оставить отзыв').first,
        );
        expect(find.byType(ReviewScreen), findsOneWidget);
        await binding.takeScreenshot('native-review-$theme');
        expect(find.byKey(const ValueKey('nav-3')).hitTestable(), findsNothing);
        await tester.pumpAndSettle();
        expect(find.byType(ReviewScreen), findsOneWidget);
        await tapVisible(tester, find.byTooltip('Закрыть').hitTestable().first);
        expect(router.routeInformationProvider.value.uri, historyUri);
        await tapVisible(tester, find.text('Отзывы').first);
        container.read(personalWalkingProvider.notifier).selectRole('helper');
        await tester.pumpAndSettle();
        await binding.takeScreenshot('native-profile-$theme');
        final receivedReviews = List<Json>.from(repo.data['walk_reviews']!);
        final receivedStats = List<Json>.from(repo.data['helper_ratings']!);
        repo.data['walk_reviews'] = [];
        repo.data['helper_ratings'] = [
          {'id': demoAlex, 'rating': null, 'review_count': 0, 'completed': 0},
        ];
        container.invalidate(communityProvider);
        await tester.pumpAndSettle();
        expect(
          find.text('Отзывы появляются после подтверждённых прогулок.'),
          findsOneWidget,
        );
        await binding.takeScreenshot('native-reviews-empty-$theme');
        repo.data['walk_reviews'] = receivedReviews;
        repo.data['helper_ratings'] = receivedStats;
        container.invalidate(communityProvider);
        await tester.pumpAndSettle();

        await tapVisible(
          tester,
          find.byKey(const ValueKey('walking-conditions-link')),
        );
        expect(find.byType(WalkingConditionsScreen), findsOneWidget);
        expect(
          find.byKey(const ValueKey('conditions-experience')),
          findsOneWidget,
        );
        await binding.takeScreenshot('native-conditions-$theme');
        // The compact editor is the conditions sheet itself.
        expect(find.text('Редактировать условия'), findsNothing);
        expect(find.text('Шаг 1 из 2'), findsNothing);
        expect(find.text('Выбрать фото'), findsNothing);
        await binding.takeScreenshot('native-preferences-$theme');
        await tapVisible(tester, find.byTooltip('Закрыть').hitTestable().last);
        expect(router.routeInformationProvider.value.uri.path, '/walks');
        await tapVisible(tester, find.text('Текущие').first);
        await tapVisible(tester, find.byTooltip('Попросить о выгуле'));
        await binding.takeScreenshot('native-information-$theme');
        expect(find.byKey(const ValueKey('nav-3')).hitTestable(), findsNothing);
        await tester.pumpAndSettle();
        expect(find.byType(EditScreen), findsOneWidget);
        expectNativeSelectedBranch(tester, 2);
        await tapVisible(tester, find.byTooltip('Закрыть').hitTestable().first);
        await container.read(accountModeProvider.notifier).switchMode('helper');
        router.go('/my-walks');
        await tester.pumpAndSettle();
        expect(container.read(communityRepositoryProvider).userId, demoAlex);
        expectNativeBranches(tester, [5, 6, 3, 4]);
        await tapVisible(tester, find.text('Текущие').first);
        await tapVisible(
          tester,
          find.descendant(
            of: find.byKey(const ValueKey('current-entry-helper-active')),
            matching: find.text('Чат'),
          ),
        );
        await openWalkingAction(tester, 'start');
        expect(
          repo.data['walk_requests']!.firstWhere(
            (r) => r['id'] == 'helper-active',
          )['status'],
          'in_progress',
        );
        await openWalkingAction(tester, 'finish');
        expect(
          repo.data['walk_requests']!.firstWhere(
            (r) => r['id'] == 'helper-active',
          )['status'],
          'awaiting_confirmation',
        );
        expect(
          find.byKey(const Key('walking-chat-action-confirm')),
          findsNothing,
        );
        await binding.takeScreenshot('native-helper-waiting-$theme');
        await tapVisible(tester, find.byTooltip('Закрыть').hitTestable().last);
        await tapVisible(tester, find.byType(BackButton).hitTestable().first);
        expect(router.routeInformationProvider.value.uri.path, '/my-walks');
        await tapVisible(tester, find.text('История').first);
        expect(find.textContaining('Как помощник'), findsWidgets);
        await container.read(languageProvider.notifier).select('en');
        await tester.pumpAndSettle();
        await binding.takeScreenshot('native-history-en-$theme');
        await tapVisible(tester, find.text('Reviews').first);
        container.read(personalWalkingProvider.notifier).selectRole('helper');
        await tester.pumpAndSettle();
        await binding.takeScreenshot('native-reviews-en-$theme');
        final reviewsScroll = find
            .descendant(
              of: find.byType(PersonalWalkingHub),
              matching: find.byType(Scrollable),
            )
            .last;
        await tester.drag(reviewsScroll, const Offset(0, -350));
        await tester.pumpAndSettle();
        await binding.takeScreenshot('native-review-actions-en-$theme');
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        container.dispose();
      }
    },
  );
}
