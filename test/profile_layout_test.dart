import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/nearby/city_catalog.dart';
import 'package:petfriendly/features/nearby/place_repository.dart';
import 'package:petfriendly/features/nearby/place_row.dart';
import 'package:petfriendly/features/profiles/profile_screen.dart';
import 'widget_test.dart' show MemoryPreferences;

const favorite = Place(
  'profile-favorite',
  'Любимый сквер',
  'Парк',
  'Минск',
  null,
  0,
  '',
  'Допуск не уточнён',
  Icons.park_outlined,
);

DemoCommunityRepository fixture({
  required bool populated,
  bool whitespace = false,
}) {
  final repo = DemoCommunityRepository(seedSamples: false);
  repo.data['profiles'] = [
    {
      'id': demoAlex,
      'display_name': populated ? 'Александра с питомцами' : 'Алекс',
      'district': populated
          ? 'Центральный район'
          : whitespace
          ? '  '
          : null,
      'about': populated
          ? 'Люблю тихие прогулки.'
          : whitespace
          ? '   '
          : null,
      'interests': populated
          ? 'Походы, спокойные прогулки'
          : whitespace
          ? '  '
          : null,
    },
  ];
  repo.data['pets'] = populated
      ? [
          {
            'id': 'profile-pet',
            'owner_id': demoAlex,
            'name': 'Луна',
            'kind': 'Собака',
            'age': 2,
            'temperament': 'Знакомится постепенно',
          },
          {
            'id': 'quiet-pet',
            'owner_id': demoAlex,
            'name': 'Мур',
            'kind': 'Кот',
            'age': null,
            'temperament': '  ',
          },
        ]
      : [];
  repo.data['helper_ratings'] = [
    {
      'id': demoAlex,
      'rating': populated ? 4.8 : null,
      'review_count': populated ? 12 : 0,
      'completed': populated ? 18 : 0,
    },
  ];
  return repo;
}

Future<GoRouter> mount(
  WidgetTester tester,
  Brightness brightness, {
  required bool populated,
  bool whitespace = false,
}) async {
  final preferences = MemoryPreferences();
  if (populated) preferences.values['favorites'] = favorite.id;
  final router = GoRouter(
    initialLocation: '/profile',
    routes: [
      GoRoute(
        path: '/profile',
        builder: (_, _) => const Scaffold(body: ProfileScreen()),
      ),
      GoRoute(
        path: '/edit/:kind',
        builder: (_, state) => Scaffold(
          appBar: AppBar(title: const Text('Редактирование')),
          body: Text(
            'kind=${state.pathParameters['kind']};id=${state.uri.queryParameters['id'] ?? ''}',
          ),
        ),
      ),
      GoRoute(
        path: '/helper/:id',
        builder: (_, _) => const Scaffold(body: Text('Опыт помощника')),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        communityRepositoryProvider.overrideWithValue(
          fixture(populated: populated, whitespace: whitespace),
        ),
        preferencesProvider.overrideWithValue(preferences),
        favoriteCatalogProvider.overrideWith(
          (ref) async => populated ? [favorite] : [],
        ),
      ],
      child: MaterialApp.router(
        theme: studioTheme(brightness),
        routerConfig: router,
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
  return router;
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'Sparse profile has no empty optional text or reserved gaps at 320px/2x: $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(320, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final absentRouter = await mount(tester, brightness, populated: false);
        final absentPosition = tester.getTopLeft(find.text('Добавить питомца'));
        await tester.scrollUntilVisible(
          find.text('Пока нет отзывов'),
          180,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text('Пока нет отзывов'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Избранные места'),
          180,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text('Избранные места'), findsOneWidget);
        expect(find.byType(PlaceRow), findsNothing);
        expect(tester.takeException(), isNull);
        final blankRouter = await mount(
          tester,
          brightness,
          populated: false,
          whitespace: true,
        );
        addTearDown(absentRouter.dispose);
        addTearDown(blankRouter.dispose);
        expect(
          tester.getTopLeft(find.text('Добавить питомца')),
          absentPosition,
        );
        expect(
          find.text('В публичном профиле виден только район.'),
          findsOneWidget,
        );
        final blankTexts = tester
            .widgetList<Text>(find.byType(Text))
            .where((text) => text.data != null && text.data!.trim().isEmpty);
        expect(blankTexts, isEmpty);
        await tester.scrollUntilVisible(
          find.text('Пока нет отзывов'),
          180,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text('Пока нет отзывов'), findsOneWidget);
        expect(find.textContaining('★ 0'), findsNothing);
        expect(find.text('0 завершённых выгулов'), findsOneWidget);
        expect(
          find.text('Демонстрационные данные · PetFriendly 0.1'),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'Populated profile keeps identities, reputation and inline favorites at 320px/2x: $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(320, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final router = await mount(tester, brightness, populated: true);
        addTearDown(router.dispose);
        expect(find.text('Александра с питомцами'), findsOneWidget);
        expect(find.text('Люблю тихие прогулки.'), findsOneWidget);
        expect(find.text('Походы, спокойные прогулки'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Луна'),
          180,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text('Луна'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Мур'),
          180,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text('Мур'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('★ 4,8 · 12 отзывов'),
          180,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text('★ 4,8 · 12 отзывов'), findsOneWidget);
        expect(find.text('18 завершённых выгулов'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.byType(PlaceRow),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        expect(find.text(favorite.name), findsOneWidget);
        expect(find.text('Избранные места'), findsOneWidget);
        expect(find.text(' '), findsNothing);
        expect(find.text('  '), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('Profile and pet edit/add controls retain their route targets', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = await mount(tester, Brightness.light, populated: true);
    addTearDown(router.dispose);
    await tester.ensureVisible(find.byTooltip('Редактировать профиль'));
    await tester.tap(find.byTooltip('Редактировать профиль'));
    await tester.pumpAndSettle();
    expect(find.text('kind=profile;id='), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Добавить питомца'));
    await tester.tap(find.byTooltip('Добавить питомца'));
    await tester.pumpAndSettle();
    expect(find.text('kind=pet;id='), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    final editPet = find.byTooltip('Редактировать питомца').first;
    await tester.ensureVisible(editPet);
    await tester.tap(editPet);
    await tester.pumpAndSettle();
    expect(find.text('kind=pet;id=profile-pet'), findsOneWidget);
  });
}
