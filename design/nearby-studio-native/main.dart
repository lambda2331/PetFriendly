import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:petfriendly/app/app.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/core/ui/components.dart';
import 'package:petfriendly/features/nearby/city_sheet.dart';
import 'package:petfriendly/features/nearby/fullscreen_map_screen.dart';
import 'package:petfriendly/features/nearby/place_filters.dart';
import 'package:petfriendly/l10n/localization.dart';
import 'fixture.dart';

void main() {
  final q = Uri.base.queryParameters;
  runApp(
    UncontrolledProviderScope(
      container: nearbyReviewContainer(
        locale: q['locale'] ?? 'ru',
        dark: q['theme'] == 'dark',
        empty: q['state'] == 'empty',
        scenario: q['state'] == 'error' || q['state'] == 'loading'
            ? q['state']!
            : 'populated',
        city: q['city'] ?? 'Минск',
      ),
      child: NearbyMockApp(
        empty: q['state'] == 'empty',
        scenario: q['state'] ?? 'populated',
        scale: double.tryParse(q['scale'] ?? '1') ?? 1,
      ),
    ),
  );
}

/// The review changes only Nearby. Other destinations reuse current real routes.
final nearbyReviewRouterProvider = Provider<GoRouter>((ref) {
  final original = ref.watch(routerProvider);
  final router = GoRouter(
    initialLocation: '/review-nearby',
    routes: [
      GoRoute(
        path: '/review-nearby',
        builder: (context, state) {
          final q = Uri.base.queryParameters;
          return Consumer(
            builder: (context, widgetRef, child) => NearbyReferenceScreen(
              empty: q['state'] == 'empty',
              scenario: q['state'] ?? 'populated',
              onMode: () => chooseMode(context, widgetRef),
              onDestination: (index) => context.go(
                [
                  '/review-nearby',
                  '/people',
                  '/walks',
                  '/chats',
                  '/profile',
                ][index],
              ),
              onCity: () => showStudioSelectionSheet<void>(
                context: context,
                builder: (sheet) => CitySheet(
                  city: ref.read(prototypeProvider).city,
                  onSelected: (city) {
                    ref.read(prototypeProvider.notifier).setCity(city);
                    Navigator.pop(sheet);
                  },
                  onLocate: () {
                    Navigator.pop(sheet);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Synthetic preview · location is not requested',
                        ),
                      ),
                    );
                  },
                ),
              ),
              onList: () => context.push('/places'),
              onMap: () => context.push(
                '/map',
                extra: FullscreenMapArgs(
                  places: ref.read(filteredPlacesProvider),
                  city: ref.read(prototypeProvider).city,
                ),
              ),
              onMeetups: () => context.push('/events'),
            ),
          );
        },
      ),
      ...original.configuration.routes,
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class NearbyMockApp extends ConsumerWidget {
  const NearbyMockApp({
    this.empty = false,
    this.scenario = 'populated',
    this.scale = 1,
    super.key,
  });
  final bool empty;
  final String scenario;
  final double scale;
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    locale: ref.watch(languageProvider),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: studioTheme(Brightness.light),
    darkTheme: studioTheme(Brightness.dark),
    themeMode: ref.watch(prototypeProvider).theme,
    builder: (c, child) => MediaQuery(
      data: MediaQuery.of(c).copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    routerConfig: ref.watch(nearbyReviewRouterProvider),
  );
}
