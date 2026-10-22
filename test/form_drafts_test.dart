import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'widget_test.dart' show MemoryPreferences;
import 'package:petfriendly/features/community/data/form_drafts.dart';
import 'package:petfriendly/features/community/presentation/forms.dart';
import 'package:petfriendly/features/auth/first_action_screen.dart';

void main() {
  testWidgets('Back preserves a private memory draft only by explicit choice', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/edit'),
              child: const Text('Открыть'),
            ),
          ),
        ),
        GoRoute(
          path: '/edit',
          builder: (_, _) => const EditScreen(kind: 'walk'),
        ),
      ],
    );
    addTearDown(router.dispose);
    final container = ProviderContainer(
      overrides: [preferencesProvider.overrideWithValue(MemoryPreferences())],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: studioTheme(Brightness.light),
          routerConfig: router,
        ),
      ),
    );
    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('field.instructions')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const ValueKey('field.instructions')),
      'Синтетические инструкции',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Выйти из формы?'), findsOneWidget);
    expect(container.read(formDraftsProvider).read('walk:new:false'), isNull);
    await tester.tap(find.text('Продолжить'));
    await tester.pumpAndSettle();
    expect(find.text('Синтетические инструкции'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Оставить черновик'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('field.instructions')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester
          .widget<TextFormField>(
            find.byKey(const ValueKey('field.instructions')),
          )
          .controller!
          .text,
      'Синтетические инструкции',
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Удалить изменения'));
    await tester.pumpAndSettle();
    expect(container.read(formDraftsProvider).read('walk:new:false'), isNull);
    expect(tester.takeException(), isNull);
  });

  test(
    'Account draft invalidation clears old objects and private fields',
    () async {
      final container = ProviderContainer(
        overrides: [preferencesProvider.overrideWithValue(MemoryPreferences())],
      );
      final old = container.read(formDraftsProvider);
      old.keep(
        'walk:new:false',
        FormDraft(
          {'instructions': 'synthetic'},
          DateTime.utc(2026),
          'Europe/Minsk',
          null,
          null,
        ),
      );
      container.invalidate(formDraftsProvider);
      expect(container.read(formDraftsProvider).read('walk:new:false'), isNull);
      await Future<void>.delayed(Duration.zero);
      expect(old.read('walk:new:false'), isNull);
      container.dispose();
    },
  );

  testWidgets(
    'First action choices support large text and route to useful sections',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final router = GoRouter(
        initialLocation: '/start',
        routes: [
          GoRoute(path: '/start', builder: (_, _) => const FirstActionScreen()),
          GoRoute(
            path: '/nearby',
            builder: (_, _) => const Scaffold(body: Text('Карта')),
          ),
          GoRoute(
            path: '/places',
            builder: (_, _) => const Scaffold(body: Text('Места')),
          ),
          GoRoute(
            path: '/people',
            builder: (_, _) => const Scaffold(body: Text('Люди')),
          ),
          GoRoute(
            path: '/walks',
            builder: (_, _) => const Scaffold(body: Text('Выгулы')),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp.router(
            theme: studioTheme(Brightness.dark),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Найти место для прогулки'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Найти место для прогулки'));
      await tester.pumpAndSettle();
      expect(find.text('Места'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      expect(find.text('Карта'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
