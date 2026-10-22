import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/nearby/nearby_studio_layout.dart';
import 'package:petfriendly/features/nearby/fullscreen_map_screen.dart';
import 'package:petfriendly/features/nearby/places_list_screen.dart';
import 'package:petfriendly/features/community/presentation/events_screen.dart';
import 'package:petfriendly/l10n/localization.dart';
import '../design/nearby-studio-native/fixture.dart';

/// Offline layout acceptance pairs. This does not test live Mapbox tiles.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Nearby matched native reference and real app', (tester) async {
    for (final locale in ['ru', 'en', 'be', 'pl']) {
      for (final dark in [false, true]) {
        final cases = locale == 'ru'
            ? ['populated', 'empty', 'error', 'loading']
            : ['populated'];
        for (final scenario in cases) {
          final scale = locale == 'pl' ? 2.0 : 1.0;
          final name =
              '$locale-${dark ? 'dark' : 'light'}-$scenario-${(scale * 100).toInt()}';
          for (final mock in [true, false]) {
            final c = nearbyReviewContainer(
              locale: locale,
              dark: dark,
              empty: scenario == 'empty',
              scenario: ['loading', 'error'].contains(scenario)
                  ? scenario
                  : 'populated',
            );
            tester.platformDispatcher.textScaleFactorTestValue = scale;
            final root = mock
                ? MaterialApp(
                    debugShowCheckedModeBanner: false,
                    locale: Locale(locale),
                    supportedLocales: AppLocalizations.supportedLocales,
                    localizationsDelegates:
                        AppLocalizations.localizationsDelegates,
                    theme: studioTheme(
                      dark ? Brightness.dark : Brightness.light,
                    ),
                    home: NearbyReferenceScreen(
                      empty: scenario == 'empty',
                      scenario: scenario,
                      onMode: () {},
                    ),
                  )
                : const PetFriendlyApp();
            await tester.pumpWidget(
              UncontrolledProviderScope(container: c, child: root),
            );
            if (scenario == 'loading') {
              await tester.pump(const Duration(milliseconds: 500));
              await Future<void>.delayed(const Duration(milliseconds: 300));
              await tester.pump();
            } else {
              await tester.pumpAndSettle();
            }
            expect(find.byType(NearbyStudioLayout), findsOneWidget);
            expect(tester.takeException(), isNull);
            await Future<void>.delayed(const Duration(milliseconds: 600));
            if (scenario != 'loading') await tester.pumpAndSettle();
            await binding.takeScreenshot('${mock ? 'mock' : 'app'}-$name');
            await tester.pumpWidget(const SizedBox());
            await tester.pump();
            c.dispose();
          }
        }
      }
    }
    tester.platformDispatcher.clearTextScaleFactorTestValue();
    final c = nearbyReviewContainer();
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const PetFriendlyApp()),
    );
    await tester.pumpAndSettle();
    for (final entry in [
      (const Key('nearby-places-list'), PlacesListScreen),
      (const Key('nearby-all-meetups'), EventsScreen),
      (const Key('nearby-fullscreen-map'), FullscreenMapScreen),
    ]) {
      await tester.ensureVisible(find.byKey(entry.$1));
      await tester.tap(find.byKey(entry.$1));
      await tester.pumpAndSettle();
      expect(find.byType(entry.$2), findsOneWidget);
      if (entry.$2 == EventsScreen) {
        // Meetings is the People root segment; return through bottom navigation.
        await tester.tap(find.byKey(const ValueKey('nav-0')));
      } else {
        c.read(routerProvider).pop();
      }
      await tester.pumpAndSettle();
      expect(c.read(prototypeProvider).city, 'Минск');
      expect(c.read(prototypeProvider).manualCity, isTrue);
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    c.dispose();
  });
}
