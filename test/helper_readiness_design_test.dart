import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/l10n/localization.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/walks/account_mode.dart';
import 'package:petfriendly/features/walks/walking_repository.dart';
import 'package:petfriendly/features/walks/walks_screen.dart';
import 'helper_profile_design_test.dart' show ProfileFixture;

void main() {
  for (final locale in ['ru', 'en']) {
    for (final dark in [false, true]) {
      for (final ready in [false, true]) {
        testWidgets(
          'Own helper readiness $ready, dark $dark, $locale at 320 and 2x',
          (tester) async {
            tester.view.physicalSize = const Size(320, 900);
            tester.view.devicePixelRatio = 1;
            tester.platformDispatcher.textScaleFactorTestValue = 2;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);
            addTearDown(
              tester.platformDispatcher.clearTextScaleFactorTestValue,
            );
            final fixture = ProfileFixture('self');
            fixture.data['helper_ratings'] = [
              {'id': 'self', 'rating': null, 'review_count': 0, 'completed': 0},
            ];
            fixture.data['walk_reviews'] = [];
            final account = DemoAccountModeRepository();
            await account.chooseRole('helper');
            if (ready) {
              await account.saveHelperProfile(
                const HelperProfile(
                  city: 'Минск',
                  district: 'Центральный район',
                  serviceDistricts: ['Центральный район'],
                  availability: [
                    WeeklyAvailability(day: 1, start: 1080, end: 1200),
                  ],
                ),
              );
            }
            final router = GoRouter(
              initialLocation: '/profile',
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (_, _) => const HelperScreen(id: 'self'),
                ),
                GoRoute(
                  path: '/requests',
                  builder: (_, _) =>
                      const Scaffold(body: Text('Request destination')),
                ),
                GoRoute(
                  path: '/helper/preferences',
                  builder: (_, _) =>
                      const Scaffold(body: Text('Edit destination')),
                ),
              ],
            );
            addTearDown(router.dispose);
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  communityRepositoryProvider.overrideWithValue(fixture),
                  accountModeRepositoryProvider.overrideWithValue(account),
                ],
                child: MaterialApp.router(
                  locale: Locale(locale),
                  supportedLocales: AppLocalizations.supportedLocales,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  theme: studioTheme(dark ? Brightness.dark : Brightness.light),
                  routerConfig: router,
                ),
              ),
            );
            await tester.pumpAndSettle();
            final noReviews = find.textContaining(
              translateForLanguage('Пока нет отзывов', locale: locale),
            );
            await tester.scrollUntilVisible(
              noReviews,
              180,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.pumpAndSettle();
            expect(noReviews, findsOneWidget);
            expect(find.text('0'), findsNothing);
            expect(tester.takeException(), isNull);
            final action = ready
                ? find.byKey(const Key('helper-find-requests'))
                : find.widgetWithText(
                    FilledButton,
                    translateForLanguage(
                      'Редактировать профиль',
                      locale: locale,
                    ),
                  );
            await tester.scrollUntilVisible(
              action,
              180,
              scrollable: find.byType(Scrollable).first,
            );
            await tester.pumpAndSettle();
            await tester.tap(action);
            await tester.pumpAndSettle();
            expect(
              find.text(ready ? 'Request destination' : 'Edit destination'),
              findsOneWidget,
            );
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  }
  testWidgets(
    'Own preferences use saved demo profile and public preferences stay separate',
    (tester) async {
      final account = DemoAccountModeRepository();
      await account.saveHelperProfile(
        const HelperProfile(
          serviceDistricts: ['Советский район'],
          availability: [WeeklyAvailability(day: 2, start: 600, end: 660)],
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountModeRepositoryProvider.overrideWithValue(account),
            publicHelperPreferencesProvider(
              'other',
            ).overrideWith((ref) async => null),
          ],
          child: MaterialApp(
            locale: const Locale('ru'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: studioTheme(Brightness.light),
            home: const Scaffold(
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    HelperPreferences(id: 'self', isSelf: true),
                    HelperPreferences(id: 'other'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Районы: Советский район'), findsOneWidget);
      expect(find.textContaining('10:00–11:00'), findsOneWidget);
      expect(find.text('Предпочтения пока не указаны'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'Unavailable preferences provide retry instead of claiming empty',
    (tester) async {
      var attempts = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            helperProfileProvider.overrideWith((ref) async {
              attempts++;
              throw StateError('offline');
            }),
          ],
          child: MaterialApp(
            locale: const Locale('ru'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const Scaffold(
              body: HelperPreferences(id: 'self', isSelf: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Предпочтения пока не указаны'), findsNothing);
      await tester.tap(find.text('Предпочтения недоступны · повторить'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
    },
  );
}
