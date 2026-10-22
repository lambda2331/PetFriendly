import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/nearby/city_catalog.dart';
import 'package:petfriendly/features/nearby/place_repository.dart';
import 'package:petfriendly/features/profiles/profile_screen.dart';
import 'package:petfriendly/features/walks/account_mode.dart';
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
  if (populated) {
    repo.data['profiles']!.add({'id': demoAnna, 'display_name': 'Анна'});
    repo.data['walk_reviews'] = [
      {
        'id': 'latest',
        'helper_id': demoAlex,
        'author_id': demoAnna,
        'rating': 5,
        'published': true,
        'body': 'Луна вернулась довольной. Спасибо за прогулку!',
        'created_at': '2026-10-10T10:00:00Z',
      },
      {
        'id': 'hidden',
        'helper_id': demoAlex,
        'author_id': demoAnna,
        'rating': 1,
        'published': false,
        'body': 'Скрытый отзыв',
        'created_at': '2026-10-11T10:00:00Z',
      },
    ];
  }
  return repo;
}

Future<GoRouter> mount(
  WidgetTester tester,
  Brightness brightness, {
  required bool populated,
  bool whitespace = false,
  String mode = 'owner',
  Future<List<Place>> Function()? loadFavorites,
  bool savedFavorite = false,
  bool settle = true,
}) async {
  final preferences = MemoryPreferences();
  if (populated || savedFavorite) preferences.values['favorites'] = favorite.id;
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
        path: '/walks',
        builder: (_, _) => const Scaffold(body: Text('Запросы на выгул')),
      ),
      GoRoute(
        path: '/my-walks',
        builder: (_, _) => const Scaffold(body: Text('Мои выгулы')),
      ),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(
        path: '/roles',
        builder: (_, _) => const Scaffold(body: Text('Управление ролями')),
      ),
      GoRoute(
        path: '/places',
        builder: (_, _) => const Scaffold(body: Text('Список мест')),
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
        accountModeRepositoryProvider.overrideWithValue(
          DemoAccountModeRepository()
            ..current = AccountMode(mode: mode, needsRoleSelection: false),
        ),
        favoriteCatalogProvider.overrideWith(
          (ref) => loadFavorites != null
              ? loadFavorites()
              : Future.value(populated ? [favorite] : <Place>[]),
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
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
  return router;
}

Future<void> tapProfileEntry(WidgetTester tester, String label) async {
  final target = find.text(label);
  await tester.scrollUntilVisible(
    target,
    180,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'Approved profile empty states stay scrollable at 320px/2x: $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(320, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final router = await mount(tester, brightness, populated: false);
        addTearDown(router.dispose);
        expect(find.text('Опыт и отзывы'), findsNothing);
        await tester.scrollUntilVisible(
          find.text('Добавьте своего питомца'),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Добавьте своего питомца'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Пока нет избранных мест'),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Пока нет избранных мест'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'Approved profile keeps bio, pets, inline favorites without duplicate reputation: $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(320, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final router = await mount(tester, brightness, populated: true);
        addTearDown(router.dispose);
        expect(find.text('Люблю тихие прогулки.'), findsOneWidget);
        expect(find.text('Опыт и отзывы'), findsNothing);
        await tester.scrollUntilVisible(
          find.text('Луна'),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Луна'));
        await tester.pumpAndSettle();
        expect(find.text('Знакомится постепенно'), findsOneWidget);
        expect(find.text('Редактировать питомца'), findsOneWidget);
        expect(tester.takeException(), isNull);
        Navigator.of(tester.element(find.text('Знакомится постепенно'))).pop();
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text(favorite.name),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text(favorite.name), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('Helper profile has no requirement to add a pet', (tester) async {
    final router = await mount(
      tester,
      Brightness.light,
      populated: false,
      mode: 'helper',
    );
    addTearDown(router.dispose);
    expect(find.text('Мои питомцы'), findsNothing);
    expect(find.text('Добавьте своего питомца'), findsNothing);
  });
  testWidgets('Profile edit is a fixed-header sheet, not a route change', (
    tester,
  ) async {
    final router = await mount(tester, Brightness.light, populated: true);
    addTearDown(router.dispose);
    await tester.tap(find.byTooltip('Редактировать профиль'));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, '/profile');
    expect(find.text('Редактировать профиль'), findsOneWidget);
    expect(find.byKey(const ValueKey('field.display_name')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('Settings retains roles and security management', (tester) async {
    final router = await mount(tester, Brightness.light, populated: false);
    addTearDown(router.dispose);
    router.push('/settings');
    await tester.pumpAndSettle();
    await tapProfileEntry(tester, 'Режим приложения');
    expect(find.text('Управление ролями'), findsOneWidget);
  });
  testWidgets('Favorites load, fail and retry inline without claiming empty', (
    tester,
  ) async {
    final result = Completer<List<Place>>();
    var attempts = 0;
    final router = await mount(
      tester,
      Brightness.light,
      populated: false,
      savedFavorite: true,
      settle: false,
      loadFavorites: () =>
          ++attempts == 1 ? result.future : Future.value([favorite]),
    );
    addTearDown(router.dispose);
    await tester.scrollUntilVisible(
      find.text('Загружаем сохранённые места…'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    result.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(find.text('Избранные места не загрузились.'), findsOneWidget);
    await tester.ensureVisible(find.text('Повторить'));
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.text(favorite.name), findsOneWidget);
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
  });
}
