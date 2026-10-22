import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/l10n/localization.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/walks/account_mode.dart';
import 'package:petfriendly/features/walks/personal_walking_controller.dart';
import 'package:petfriendly/features/walks/personal_walking_hub.dart';
import 'package:petfriendly/features/walks/walking_repository.dart';
import 'package:petfriendly/features/walks/walking_conditions_screen.dart';
import 'package:petfriendly/features/walks/walking_chat_widgets.dart';
import 'package:petfriendly/features/walks/walks_screen.dart';

class PagedWalkingFixture extends WalkingRepository {
  PagedWalkingFixture(
    super.ref, {
    this.longNames = false,
    this.chatAvailable = true,
    this.active = false,
  });
  final bool chatAvailable, active;
  final bool longNames;
  final offsets = <int>[];
  bool failMore = true;
  Completer<List<Json>>? barrier;
  @override
  Future<List<Json>> list({
    String? city,
    String? district,
    String? size,
    DateTime? from,
    DateTime? until,
    String view = 'active',
    int offset = 0,
  }) async {
    if (view != 'history' && !active) return [];
    if (view == 'applications') return [];
    offsets.add(offset);
    if (barrier != null) return barrier!.future;
    if (offset > 0 && failMore) throw StateError('Synthetic next-page failure');
    return List.generate(
      offset == 0 ? 40 : 3,
      (i) => {
        'id': 'history-${offset + i}',
        'my_role': i.isEven ? 'owner' : 'helper',
        'status': active ? 'assigned' : 'completed',
        'starts_at': DateTime.utc(
          2026,
          10,
          10,
          21,
          30,
        ).subtract(Duration(days: i)).toIso8601String(),
        'city': 'Минск',
        'time_zone': 'Europe/Minsk',
        'pet': {
          'id': 'pet',
          'name': longNames ? 'Луна с длинным синтетическим именем' : 'Луна',
        },
        'owner': {'display_name': 'Владелец синтетической прогулки'},
        'helper': {'display_name': 'Помощник синтетической прогулки'},
        'conversation_id': chatAvailable ? 'private-chat' : null,
        'district': 'Публичный район',
        'description': 'Подробности синтетической прогулки',
        'allowed_actions': [i.isEven ? 'review_helper' : 'review_owner'],
      },
    );
  }
}

const longReview =
    'Синтетический отзыв: помощник заранее обсудил привычки питомца, спокойно провёл прогулку и внимательно отнёсся к нашим пожеланиям. ';

class HubCommunityFixture implements CommunityRepository {
  @override
  String get userId => 'self';
  @override
  bool get isDemo => false;
  @override
  Future<String?> command(String action, Json values) async => null;
  @override
  Future<CommunityData> load() async => {
    'profiles': [
      {
        'id': 'self',
        'display_name': 'Александра Владимировна Ковальская-Лисовская',
        'district': 'Длинный синтетический публичный район',
      },
      {'id': 'author', 'display_name': 'Екатерина Александровская-Лисовская'},
    ],
    'helper_ratings': [
      {'id': 'self', 'rating': 4.8, 'review_count': 1, 'completed': 12},
    ],
    'owner_ratings': [
      {'id': 'self', 'rating': 4.9, 'review_count': 1, 'completed': 9},
    ],
    'walk_reviews': [
      {
        'id': 'helper-review',
        'helper_id': 'self',
        'author_id': 'author',
        'published': true,
        'rating': 5,
        'created_at': '2026-10-01T18:00:00Z',
        'body': longReview * 4,
      },
    ],
    'walk_owner_reviews': [
      {
        'id': 'owner-review',
        'owner_id': 'self',
        'author_id': 'author',
        'published': true,
        'rating': 5,
        'created_at': '2026-10-01T18:00:00Z',
        'body': longReview * 4,
      },
    ],
  };
}

class EmptyCommunityController extends CommunityController {
  @override
  Future<CommunityData> build() async => {};
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    for (final font in ['Manrope', 'GolosText']) {
      final loader = FontLoader(font == 'GolosText' ? 'Golos Text' : font)
        ..addFont(rootBundle.load('assets/fonts/$font.ttf'));
      await loader.load();
    }
  });
  test('Period uses the venue calendar across UTC midnight and both roles', () {
    final period = WalkingPeriod(
      DateTime(2026, 10, 11),
      DateTime(2026, 10, 11),
    );
    final row = <String, dynamic>{
      'starts_at': '2026-10-10T21:30:00Z',
      'time_zone': 'Europe/Minsk',
    };
    expect(period.includes(row), true);
    expect(period.includes({...row, 'time_zone': 'Europe/Warsaw'}), false);
    expect(period.includes({'starts_at': 'invalid'}), false);
  });

  test('Assigned actions lead own requests and keep historical roles', () {
    final rows = <Json>[
      {'id': 'open', 'my_role': 'owner', 'status': 'open'},
      {
        'id': 'future',
        'my_role': 'helper',
        'status': 'assigned',
        'allowed_actions': ['start'],
      },
      {
        'id': 'confirm',
        'my_role': 'owner',
        'status': 'awaiting_confirmation',
        'allowed_actions': ['confirm'],
      },
      {
        'id': 'finish',
        'my_role': 'helper',
        'status': 'in_progress',
        'allowed_actions': ['finish'],
      },
      {'id': 'applied', 'my_role': 'applicant', 'status': 'assigned'},
    ];
    expect(personalAgreements(rows).map((r) => r['id']), [
      'confirm',
      'finish',
      'future',
    ]);
  });

  test('Unassigned applicant has no agreement chat or lifecycle actions', () {
    final item = <String, dynamic>{
      'id': 'w',
      'owner_id': 'owner',
      'my_role': 'applicant',
      'status': 'open',
    };
    final card = demoPersonalWalkingCard(item, {
      'walk_requests': [item],
      'conversations': [
        {'id': 'private', 'kind': 'walk', 'context_id': 'w'},
      ],
    }, 'applicant');
    expect(card['conversation_id'], isNull);
    expect(walkingActions(card), isEmpty);
  });

  test(
    'Completed review eligibility retains participation and prevents repeats',
    () {
      final request = <String, dynamic>{
        'id': 'w',
        'owner_id': 'owner',
        'status': 'completed',
        'my_role': 'owner',
      };
      final data = <String, List<Json>>{
        'walk_requests': [request],
        'walk_agreements': [
          {'id': 'a', 'request_id': 'w', 'helper_id': 'helper'},
        ],
      };
      expect(
        walkingActions(demoPersonalWalkingCard(request, data, 'owner')),
        contains('review_helper'),
      );
      data['walk_reviews'] = [
        {'id': 'r', 'request_id': 'w'},
      ];
      expect(
        walkingActions(demoPersonalWalkingCard(request, data, 'owner')),
        isNot(contains('review_helper')),
      );
      expect(
        walkingActions(
          demoPersonalWalkingCard(
            {...request, 'status': 'cancelled'},
            {
              ...data,
              'walk_requests': [
                {...request, 'status': 'cancelled'},
              ],
            },
            'helper',
          ),
        ),
        isEmpty,
      );
    },
  );

  test(
    'Identical consecutive weekdays summarize without merging different times',
    () {
      final grouped = compactWalkingSchedule(const [
        WeeklyAvailability(day: 0, start: 540, end: 600),
        WeeklyAvailability(day: 1, start: 540, end: 600),
        WeeklyAvailability(day: 2, start: 600, end: 660),
        WeeklyAvailability(day: 4, start: 540, end: 600),
      ]);
      expect(grouped.length, 3);
      expect(grouped.first.firstDay, 0);
      expect(grouped.first.lastDay, 1);
    },
  );

  test('Next-page failure retains rows and retries the same offset', () async {
    late PagedWalkingFixture fixture;
    final container = ProviderContainer(
      overrides: [
        walkingRepositoryProvider.overrideWith(
          (ref) => fixture = PagedWalkingFixture(ref),
        ),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(personalWalkingProvider.notifier);
    await controller.load('history');
    expect(
      container.read(personalWalkingProvider).pages['history']!.items.length,
      40,
    );
    await controller.load('history');
    final failed = container.read(personalWalkingProvider).pages['history']!;
    expect(failed.items.length, 40);
    expect(failed.error, isNotNull);
    fixture.failMore = false;
    await controller.load('history');
    expect(fixture.offsets, [0, 40, 40]);
    expect(
      container.read(personalWalkingProvider).pages['history']!.items.length,
      43,
    );
    expect(
      container.read(personalWalkingProvider).pages['history']!.hasMore,
      false,
    );
  });

  test(
    'Account reset discards an in-flight page and clears local selection',
    () async {
      late PagedWalkingFixture fixture;
      final container = ProviderContainer(
        overrides: [
          walkingRepositoryProvider.overrideWith(
            (ref) => fixture = PagedWalkingFixture(ref),
          ),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(personalWalkingProvider.notifier);
      await controller.load('history');
      fixture.barrier = Completer<List<Json>>();
      final oldFixture = fixture;
      controller.select(PersonalWalkingTab.history);
      controller.setPeriod(
        WalkingPeriod(DateTime(2026, 1, 1), DateTime(2026, 1, 31)),
      );
      final stale = controller.load('history');
      container.invalidate(walkingRepositoryProvider);
      container.read(personalWalkingProvider);
      await Future<void>.delayed(Duration.zero);
      oldFixture.barrier!.complete([
        {'id': 'old-account', 'my_role': 'owner', 'status': 'completed'},
      ]);
      await stale;
      await Future<void>.delayed(Duration.zero);
      final state = container.read(personalWalkingProvider);
      expect(state.tab, PersonalWalkingTab.current);
      expect(state.period, isNull);
      expect(
        state.pages['history']!.items.any((row) => row['id'] == 'old-account'),
        false,
      );
    },
  );

  testWidgets(
    'Same route hub applies changed aliases and ignores absent hints',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          walkingRepositoryProvider.overrideWith(
            (ref) => PagedWalkingFixture(ref),
          ),
          communityRepositoryProvider.overrideWithValue(HubCommunityFixture()),
          communityProvider.overrideWith(EmptyCommunityController.new),
          ownerProfileProvider.overrideWith(
            (ref, id) async => <String, List<Json>>{},
          ),
          helperProfileProvider.overrideWith((ref) async => null),
        ],
      );
      addTearDown(container.dispose);
      Future<void> mount({PersonalWalkingTab? tab, String? role}) async {
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: studioTheme(Brightness.light),
              home: Scaffold(
                body: PersonalWalkingHub(
                  key: const ValueKey('same-account'),
                  initialTab: tab,
                  initialProfileRole: role,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      await mount();
      container
          .read(personalWalkingProvider.notifier)
          .select(PersonalWalkingTab.history);
      await tester.pumpAndSettle();
      await mount(tab: PersonalWalkingTab.profile, role: 'helper');
      expect(
        container.read(personalWalkingProvider).tab,
        PersonalWalkingTab.profile,
      );
      expect(container.read(personalWalkingProvider).profileRole, 'helper');
      await mount(tab: PersonalWalkingTab.profile, role: 'owner');
      expect(container.read(personalWalkingProvider).profileRole, 'owner');
      await mount();
      expect(
        container.read(personalWalkingProvider).tab,
        PersonalWalkingTab.profile,
      );
      expect(container.read(personalWalkingProvider).profileRole, 'owner');
      expect(tester.takeException(), isNull);
    },
  );

  for (final chatAvailable in [true, false]) {
    testWidgets(
      'History chat $chatAvailable uses explicit details and review actions',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            walkingRepositoryProvider.overrideWith(
              (ref) => PagedWalkingFixture(ref, chatAvailable: chatAvailable),
            ),
            communityRepositoryProvider.overrideWithValue(
              HubCommunityFixture(),
            ),
            communityProvider.overrideWith(EmptyCommunityController.new),
          ],
        );
        addTearDown(container.dispose);
        final router = GoRouter(
          routes: [
            GoRoute(
              path: '/',
              builder: (_, _) => const Scaffold(
                body: PersonalWalkingHub(
                  initialTab: PersonalWalkingTab.history,
                ),
              ),
            ),
            GoRoute(
              path: '/chat/:id',
              builder: (_, state) =>
                  Scaffold(body: Text('chat:${state.pathParameters['id']}')),
            ),
            GoRoute(
              path: '/walk/:id',
              builder: (_, state) =>
                  Scaffold(body: Text('detail:${state.pathParameters['id']}')),
            ),
          ],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
              theme: studioTheme(Brightness.light),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final entry = find.byKey(const ValueKey('history-entry-history-0'));
        await tester.scrollUntilVisible(
          entry,
          100,
          scrollable: find
              .descendant(
                of: find.byType(ListView),
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(
          find.descendant(of: entry, matching: find.byType(ExpansionTile)),
          findsNothing,
        );
        expect(
          find.descendant(of: entry, matching: find.byType(FilledButton)),
          findsNothing,
        );
        expect(
          find.descendant(of: entry, matching: find.byType(OutlinedButton)),
          findsNWidgets(chatAvailable ? 3 : 2),
        );
        expect(
          find.descendant(of: entry, matching: find.text('Чат')),
          chatAvailable ? findsOneWidget : findsNothing,
        );
        expect(find.text('Открыть договорённость'), findsNothing);
        await tester.tap(
          find.descendant(of: entry, matching: find.text('Детали')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byType(chatAvailable ? WalkingChatSheet : WalkDetailScreen),
          findsOneWidget,
        );
        expect(router.routeInformationProvider.value.uri.path, '/');
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('Assigned Current opens chat through explicit Chat button', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        walkingRepositoryProvider.overrideWith(
          (ref) => PagedWalkingFixture(ref, active: true),
        ),
        communityRepositoryProvider.overrideWithValue(HubCommunityFixture()),
        communityProvider.overrideWith(EmptyCommunityController.new),
      ],
    );
    addTearDown(container.dispose);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: PersonalWalkingHub()),
        ),
        GoRoute(
          path: '/chat/:id',
          builder: (_, state) =>
              Scaffold(body: Text('chat:${state.pathParameters['id']}')),
        ),
        GoRoute(
          path: '/walk/:id',
          builder: (_, state) =>
              Scaffold(body: Text('detail:${state.pathParameters['id']}')),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          theme: studioTheme(Brightness.light),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final entry = find.byKey(const ValueKey('current-entry-history-39'));
    await tester.scrollUntilVisible(
      entry,
      100,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(
      find.descendant(of: entry, matching: find.byType(ExpansionTile)),
      findsNothing,
    );
    expect(
      find.descendant(of: entry, matching: find.byType(FilledButton)),
      findsNothing,
    );
    expect(
      find.descendant(of: entry, matching: find.byType(OutlinedButton)),
      findsNWidgets(2),
    );
    expect(
      find.descendant(of: entry, matching: find.text('Чат')),
      findsOneWidget,
    );
    expect(find.text('Открыть договорённость'), findsNothing);
    await tester.tap(find.descendant(of: entry, matching: find.text('Чат')));
    await tester.pumpAndSettle();
    expect(find.text('chat:private-chat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Full walking profile fits 320px at 200% with role tabs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer(
      overrides: [
        walkingRepositoryProvider.overrideWith(
          (ref) => PagedWalkingFixture(ref),
        ),
        communityRepositoryProvider.overrideWithValue(HubCommunityFixture()),
        communityProvider.overrideWith(EmptyCommunityController.new),
        ownerProfileProvider.overrideWith(
          (ref, id) async => <String, List<Json>>{},
        ),
        helperProfileProvider.overrideWith((ref) async => null),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: studioTheme(Brightness.light),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const Scaffold(
            body: PersonalWalkingHub(initialTab: PersonalWalkingTab.profile),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
    final roleTab = find.byKey(const ValueKey('walking-role-helper'));
    await tester.ensureVisible(roleTab);
    await tester.tap(roleTab);
    await tester.pumpAndSettle();
    expect(container.read(personalWalkingProvider).profileRole, 'helper');
    expect(tester.takeException(), isNull);
  });

  for (final locale in ['ru', 'en', 'be', 'pl']) {
    for (final brightness in Brightness.values) {
      for (final view in ['history', 'owner', 'helper']) {
        testWidgets('Populated $view $locale ${brightness.name}: 320px / 200%', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(320, 812);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repository = HubCommunityFixture();
          final container = ProviderContainer(
            overrides: [
              communityRepositoryProvider.overrideWithValue(repository),
              walkingRepositoryProvider.overrideWith(
                (ref) => PagedWalkingFixture(ref, longNames: true),
              ),
              ownerProfileProvider.overrideWith((ref, id) => repository.load()),
              helperProfileProvider.overrideWith(
                (ref) async => const HelperProfile(
                  city: 'Минск',
                  district: 'Длинный синтетический публичный район',
                  introduction:
                      'Длинное введение помощника для проверки переноса строк в доступном размере.',
                  experience: 'Опыт прогулок с питомцами разного размера.',
                  dogSizes: ['small', 'medium', 'large'],
                  serviceDistricts: [
                    'Длинный первый район',
                    'Длинный второй район',
                  ],
                  availability: [
                    WeeklyAvailability(day: 0, start: 540, end: 720),
                    WeeklyAvailability(day: 1, start: 540, end: 720),
                  ],
                ),
              ),
            ],
          );
          addTearDown(container.dispose);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp(
                theme: studioTheme(brightness),
                locale: Locale(locale),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(2)),
                  child: child!,
                ),
                home: Scaffold(
                  body: PersonalWalkingHub(
                    initialTab: view == 'history'
                        ? PersonalWalkingTab.history
                        : PersonalWalkingTab.profile,
                    initialProfileRole: view == 'history' ? null : view,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (view == 'history') {
            final entry = find.byKey(const ValueKey('history-entry-history-0'));
            await tester.scrollUntilVisible(
              entry,
              100,
              scrollable: find
                  .descendant(
                    of: find.byType(ListView),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            final pet = find.descendant(
              of: entry,
              matching: find.text('Луна с длинным синтетическим именем'),
            );
            await Scrollable.ensureVisible(tester.element(pet), alignment: .3);
            await tester.pumpAndSettle();
            expect(
              find.descendant(of: entry, matching: find.byType(ExpansionTile)),
              findsNothing,
            );
            await tester.drag(find.byType(ListView), const Offset(0, -250));
          } else {
            final roleTab = find.byKey(ValueKey('walking-role-$view'));
            await tester.ensureVisible(roleTab);
            await tester.tap(roleTab);
            await tester.pumpAndSettle();
            expect(find.byType(ExpansionTile), findsNothing);
            await tester.scrollUntilVisible(
              find.text(longReview * 4),
              180,
              maxScrolls: 60,
              scrollable: find
                  .descendant(
                    of: find.byType(ListView),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            await tester.pumpAndSettle();
            await tester.drag(find.byType(ListView), const Offset(0, -250));
          }
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  for (final count in <int?>[0, null]) {
    testWidgets(
      'Review counts $count remain honest with retry for unavailable totals',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            communityRepositoryProvider.overrideWithValue(
              HubCommunityFixture(),
            ),
            communityProvider.overrideWith(EmptyCommunityController.new),
            walkingRepositoryProvider.overrideWith(
              (ref) => PagedWalkingFixture(ref),
            ),
            helperProfileProvider.overrideWith((ref) async => null),
            ownerProfileProvider.overrideWith(
              (ref, id) async => {
                'owner_ratings': [
                  {
                    'id': 'self',
                    'review_count': count,
                    'completed': count == 0 ? 3 : null,
                  },
                ],
              },
            ),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: studioTheme(Brightness.light),
              home: const Scaffold(
                body: PersonalWalkingHub(
                  initialTab: PersonalWalkingTab.profile,
                  initialProfileRole: 'owner',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        if (count == 0) {
          expect(find.text('Пока нет отзывов'), findsOneWidget);
          expect(
            find.text('Отзывы появляются после подтверждённых прогулок.'),
            findsOneWidget,
          );
          expect(find.text('Повторить загрузку опыта'), findsNothing);
        } else {
          expect(find.text('Отзывы недоступны'), findsOneWidget);
          expect(find.text('Пока нет отзывов'), findsNothing);
          expect(find.text('Повторить загрузку опыта'), findsOneWidget);
        }
        expect(find.text('0.0'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'Identity belongs only to Reviews and Conditions precedes either reputation role',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          communityRepositoryProvider.overrideWithValue(HubCommunityFixture()),
          walkingRepositoryProvider.overrideWith(
            (ref) => PagedWalkingFixture(ref),
          ),
          ownerProfileProvider.overrideWith(
            (ref, id) => HubCommunityFixture().load(),
          ),
          helperProfileProvider.overrideWith(
            (ref) async => const HelperProfile(
              city: 'Минск',
              district: 'Центральный район',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => const Scaffold(body: PersonalWalkingHub()),
          ),
          GoRoute(
            path: '/helper/conditions',
            builder: (_, _) => const WalkingConditionsScreen(),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
            theme: studioTheme(Brightness.light),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('walking-review-identity')),
        findsNothing,
      );
      final controller = container.read(personalWalkingProvider.notifier);
      controller.select(PersonalWalkingTab.history);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('walking-review-identity')),
        findsNothing,
      );
      controller.select(PersonalWalkingTab.profile);
      controller.selectRole('owner');
      await tester.pumpAndSettle();
      final identity = find.byKey(const ValueKey('walking-review-identity'));
      final link = find.byKey(const ValueKey('walking-conditions-link'));
      expect(identity, findsOneWidget);
      expect(link, findsOneWidget);
      expect(
        tester.getRect(link).center.dy,
        greaterThanOrEqualTo(tester.getRect(identity).top),
      );
      expect(
        tester.getRect(link).right,
        lessThanOrEqualTo(tester.getRect(identity).right),
      );
      expect(find.byType(ExpansionTile), findsNothing);
      expect(find.text('Отзывы о вас как о владельце'), findsNothing);
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(find.byType(WalkingConditionsScreen), findsOneWidget);
    },
  );

  for (final locale in ['ru', 'en', 'be', 'pl']) {
    for (final brightness in Brightness.values) {
      testWidgets(
        'Grouped Conditions $locale ${brightness.name} fits 320px / 200%',
        (tester) async {
          tester.view.physicalSize = const Size(320, 812);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final container = ProviderContainer(
            overrides: [
              helperProfileProvider.overrideWith(
                (ref) async => const HelperProfile(
                  city: 'Минск',
                  district: 'Центральный район',
                  serviceDistricts: [
                    'Центральный район',
                    'Центральный район',
                    'Советский район',
                  ],
                  dogSizes: ['small', 'medium', 'large'],
                  introduction: 'Синтетические условия прогулок.',
                  availability: [
                    WeeklyAvailability(day: 0, start: 540, end: 1020),
                    WeeklyAvailability(day: 1, start: 540, end: 1020),
                  ],
                ),
              ),
              accountModeRepositoryProvider.overrideWithValue(
                DemoAccountModeRepository(),
              ),
            ],
          );
          addTearDown(container.dispose);
          final router = GoRouter(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const WalkingConditionsScreen(),
              ),
              GoRoute(
                path: '/helper/preferences',
                builder: (_, _) =>
                    const Scaffold(body: Text('existing editor')),
              ),
            ],
          );
          addTearDown(router.dispose);
          await tester.pumpWidget(
            UncontrolledProviderScope(
              container: container,
              child: MaterialApp.router(
                routerConfig: router,
                theme: studioTheme(brightness),
                locale: Locale(locale),
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(2)),
                  child: child!,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final context = tester.element(find.byType(WalkingConditionsScreen));
          expect(find.text('Минск · Центральный район'), findsOneWidget);
          expect(
            find.text(
              'Районы: {p0}'.tr(context, arguments: {'p0': 'Советский район'}),
            ),
            findsOneWidget,
          );
          expect(
            find.text(
              'Размер собак: {p0}'.tr(
                context,
                arguments: {
                  'p0': [
                    'Небольшие',
                    'Средние',
                    'Крупные',
                  ].map((s) => s.tr(context)).join(', '),
                },
              ),
            ),
            findsOneWidget,
          );
          final status = find.text('Готов обсуждать прогулки'.tr(context));
          await tester.scrollUntilVisible(status, 120);
          expect(status, findsOneWidget);
          final edit = find.widgetWithText(
            OutlinedButton,
            'Редактировать условия'.tr(context),
          );
          await tester.scrollUntilVisible(edit, 120);
          expect(tester.getSize(edit).height, greaterThanOrEqualTo(48));
          await tester.tap(edit);
          await tester.pumpAndSettle();
          expect(find.text('existing editor'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets(
    'Tab keyboard navigation keeps selected state and label visible',
    (tester) async {
      var value = PersonalWalkingTab.current;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(textScaler: TextScaler.linear(2)),
              child: Center(
                child: SizedBox(
                  width: 272,
                  child: StatefulBuilder(
                    builder: (context, update) => PersonalWalkingTabs(
                      value: value,
                      onChanged: (tab) => update(() => value = tab),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final first = tester.widget<InkWell>(find.byType(InkWell).first);
      first.focusNode!.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(value, PersonalWalkingTab.profile);
      final selected = tester
          .widgetList<Semantics>(
            find.descendant(
              of: find.byType(PersonalWalkingTabs),
              matching: find.byType(Semantics),
            ),
          )
          .where((widget) => widget.properties.selected == true);
      expect(selected.length, 1);
      final rail = tester.getRect(find.byType(SingleChildScrollView));
      final label = tester.getRect(find.text('Отзывы'));
      expect(label.left, greaterThanOrEqualTo(rail.left));
      expect(label.right, lessThanOrEqualTo(rail.right));
      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(value, PersonalWalkingTab.current);
      expect(tester.takeException(), isNull);
    },
  );

  for (final locale in ['ru', 'en', 'be', 'pl']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Short tabs $locale fit 320px at $scale scale', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            locale: Locale(locale),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: studioTheme(Brightness.light),
            home: Scaffold(
              body: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Center(
                  child: SizedBox(
                    width: 272,
                    child: PersonalWalkingTabs(
                      value: PersonalWalkingTab.history,
                      onChanged: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final texts = find.descendant(
          of: find.byType(PersonalWalkingTabs),
          matching: find.byType(Text),
        );
        expect(texts, findsNWidgets(3));
        final first = tester.getRect(texts.at(0));
        final second = tester.getRect(texts.at(1));
        expect(second.center.dy, closeTo(first.center.dy, 1));
        final scroll = tester.widget<SingleChildScrollView>(
          find.byType(SingleChildScrollView),
        );
        expect(scroll.scrollDirection, Axis.horizontal);
        final position = tester
            .state<ScrollableState>(find.byType(Scrollable))
            .position;
        expect(position.maxScrollExtent, scale == 1 ? 0 : greaterThan(0));
        for (final text in tester.widgetList<Text>(texts)) {
          expect(text.maxLines, 1);
          expect(text.softWrap, false);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
