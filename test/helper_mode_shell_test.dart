import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/nearby/city_catalog.dart';
import 'package:petfriendly/features/walks/account_mode.dart';
import 'package:petfriendly/features/walks/helper_requests_screen.dart';
import 'widget_test.dart' show EmptyCatalog, MemoryPreferences;

void main() {
  testWidgets('Mode switch keeps account and replaces only navigation shell', (
    tester,
  ) async {
    final account = DemoAccountModeRepository();
    await account.chooseRole('both');
    final community = DemoCommunityRepository();
    final originalIdentity = community.userId;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(MemoryPreferences()),
          cityCatalogServiceProvider.overrideWithValue(EmptyCatalog()),
          accountModeRepositoryProvider.overrideWithValue(account),
          communityRepositoryProvider.overrideWithValue(community),
        ],
        child: const PetFriendlyApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('nav-0')), findsWidgets);
    expect(find.byKey(const ValueKey('nav-1')), findsWidgets);
    expect(find.byKey(const ValueKey('nav-5')), findsNothing);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(StudioShell)),
    );
    await container.read(accountModeProvider.notifier).switchMode('helper');
    container.read(routerProvider).go('/requests');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('nav-5')), findsWidgets);
    expect(find.byKey(const ValueKey('nav-6')), findsWidgets);
    expect(find.byKey(const ValueKey('nav-0')), findsNothing);
    expect(find.byType(RequestsScreen), findsOneWidget);
    expect(community.userId, originalIdentity);
    ProviderScope.containerOf(
      tester.element(find.byType(StudioShell)),
    ).read(routerProvider).go('/profile');
    await tester.pumpAndSettle();
    expect(find.text('Алекс'), findsOneWidget);
    expect(find.text('Саша'), findsNothing);
    await container.read(accountModeProvider.notifier).switchMode('owner');
    container.read(routerProvider).go('/nearby');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('nav-0')), findsWidgets);
    expect(find.byKey(const ValueKey('nav-1')), findsWidgets);
    expect(find.byKey(const ValueKey('nav-5')), findsNothing);
    expect(community.userId, originalIdentity);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Helper shell remains usable at compact width and enlarged text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final account = DemoAccountModeRepository();
      await account.chooseRole('helper');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(MemoryPreferences()),
            cityCatalogServiceProvider.overrideWithValue(EmptyCatalog()),
            accountModeRepositoryProvider.overrideWithValue(account),
          ],
          child: const PetFriendlyApp(),
        ),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(StudioShell));
      final container = ProviderScope.containerOf(context);
      container.read(routerProvider).go('/requests');
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('nav-5')), findsWidgets);
      expect(find.byKey(const ValueKey('nav-6')), findsWidgets);
      expect(find.byKey(const ValueKey('nav-0')), findsNothing);
      expect(find.text('Помощник'), findsNothing);
      expect(find.byKey(const ValueKey('nav-5')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
