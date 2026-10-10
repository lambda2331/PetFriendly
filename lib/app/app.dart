import '../features/chat/new_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/storage/prototype_store.dart';
import '../core/theme/studio_theme.dart';
import '../features/nearby/nearby_screen.dart';
import '../features/nearby/fullscreen_map_screen.dart';
import '../features/nearby/places_list_screen.dart';
import '../features/nearby/add_place_screen.dart';
import '../features/nearby/place_contributions.dart';
import '../features/nearby/place_feedback_screen.dart';
import '../features/community/people_screen.dart';
import '../features/walks/walks_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/profiles/profile_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/account_entry_screen.dart';
import '../features/auth/first_action_screen.dart';
import '../features/auth/reauthentication_screen.dart';
import '../features/auth/reauthentication.dart';
import '../features/auth/password_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/backend/backend.dart';
import '../features/security/security_screen.dart';
import '../features/security/moderation_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../core/ui/privacy_shield.dart';
import '../core/media/preview_photos.dart';
import '../features/community/data/community_repository.dart';
import '../features/community/presentation/forms.dart';
import '../features/community/data/form_drafts.dart';
import '../features/community/presentation/group_screen.dart';
import '../features/community/presentation/events_screen.dart';
import '../features/community/presentation/report_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: ref.read(backendProvider) == null
        ? '/nearby'
        : '/auth/complete',
    redirect: (context, state) {
      final client = ref.read(backendProvider);
      if (client != null &&
          client.auth.currentSession == null &&
          state.uri.path != '/login') {
        return '/login';
      }
      if (client?.auth.currentSession != null && state.uri.path == '/login') {
        return '/auth/complete';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/new-chat', builder: (_, _) => const NewChatScreen()),
      GoRoute(path: '/start', builder: (_, _) => const FirstActionScreen()),
      GoRoute(
        path: '/event/:id',
        builder: (_, state) =>
            EventsScreen(focusedEventId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/reauth/google',
        builder: (_, _) => const ProviderReauthenticationScreen(
          provider: ReauthProvider.google,
        ),
      ),
      GoRoute(
        path: '/reauth/telegram',
        builder: (_, _) => const ProviderReauthenticationScreen(
          provider: ReauthProvider.telegram,
        ),
      ),
      GoRoute(
        path: '/auth/complete',
        builder: (_, _) => const AccountEntryScreen(),
      ),
      GoRoute(
        path: '/group/:id',
        builder: (_, state) => GroupScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(path: '/moderation', builder: (_, _) => const ModerationScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/add-place', builder: (_, _) => const AddPlaceScreen()),
      GoRoute(path: '/places', builder: (_, _) => const PlacesListScreen()),
      GoRoute(
        path: '/map',
        builder: (_, state) => FullscreenMapScreen(
          args: state.extra is FullscreenMapArgs
              ? state.extra as FullscreenMapArgs
              : const FullscreenMapArgs(places: [], city: 'Минск'),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => StudioShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/nearby', builder: (_, _) => const NearbyScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/people', builder: (_, _) => const PeopleScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/walks',
                builder: (_, _) => const WalksScreen(showHeader: false),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chats',
                builder: (_, _) => const ChatsScreen(showHeader: false),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (_, _) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (_, state) => ChatScreen(
          id: state.pathParameters['id']!,
          draft: state.uri.queryParameters['draft'],
        ),
      ),
      GoRoute(
        path: '/place-feedback/:id',
        builder: (_, state) => PlaceFeedbackScreen(
          id: state.pathParameters['id']!,
          correction: state.uri.queryParameters['correction'] == 'true',
        ),
      ),
      GoRoute(path: '/events', builder: (_, _) => const EventsScreen()),
      GoRoute(
        path: '/edit/:kind',
        builder: (_, state) => EditScreen(
          kind: state.pathParameters['kind']!,
          id: state.uri.queryParameters['id'],
          welcome: state.uri.queryParameters['welcome'] == 'true',
        ),
      ),
      GoRoute(
        path: '/walk/:id',
        builder: (_, state) =>
            WalkDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/review/:id',
        builder: (_, state) => ReviewScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/helper/:id',
        builder: (_, state) => HelperScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/report/:kind/:id',
        builder: (_, state) => ReportScreen(
          kind: state.pathParameters['kind']!,
          id: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (_, _) => const NotificationsScreen(),
      ),
      GoRoute(path: '/helper', builder: (_, _) => const HelperScreen()),
      GoRoute(
        path: '/security',
        builder: (_, _) => const AccountSecurityScreen(),
      ),
      GoRoute(path: '/password', builder: (_, _) => const PasswordScreen()),
      GoRoute(
        path: '/mfa',
        builder: (_, state) =>
            MfaScreen(enroll: state.uri.queryParameters['enroll'] == 'true'),
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    ],
  );
  ref.listen(authStateProvider, (previous, next) {
    if (previous?.value?.id != next.value?.id) {
      ref.invalidate(formDraftsProvider);
    }
    ref.invalidate(communityProvider);
    ref.invalidate(previewPhotosProvider);
    ref.invalidate(placeContributionsProvider);
    router.refresh();
  });
  final subscription = ref.read(backendProvider)?.auth.onAuthStateChange.listen(
    (event) {
      if (event.event == AuthChangeEvent.passwordRecovery) {
        router.go('/password');
      }
    },
  );
  ref.onDispose(() => subscription?.cancel());
  ref.onDispose(router.dispose);
  return router;
});

class PetFriendlyApp extends ConsumerWidget {
  const PetFriendlyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'PetFriendly',
    locale: const Locale('ru'),
    supportedLocales: const [Locale('ru'), Locale('en')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    builder: (context, child) => PrivacyShield(child: child!),
    debugShowCheckedModeBanner: false,
    theme: studioTheme(Brightness.light),
    darkTheme: studioTheme(Brightness.dark),
    themeMode: ref.watch(prototypeProvider.select((s) => s.theme)),
    themeAnimationDuration:
        WidgetsBinding
            .instance
            .platformDispatcher
            .accessibilityFeatures
            .disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 220),
    routerConfig: ref.watch(routerProvider),
  );
}

class StudioShell extends ConsumerWidget {
  const StudioShell({required this.shell, super.key});
  final StatefulNavigationShell shell;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(prototypeProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(context).scale(1) > 1.3
            ? 104
            : 60,
        titleSpacing: 24,
        title: shell.currentIndex == 0
            ? FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'petfriendly',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        letterSpacing: -1,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '.',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: dark
                            ? StudioColors.lime
                            : const Color(0xFF587322),
                      ),
                    ),
                  ],
                ),
              )
            : Semantics(
                header: true,
                child: Text(
                  const [
                    'Рядом',
                    'Люди',
                    'Выгул',
                    'Чаты',
                    'Профиль',
                  ][shell.currentIndex],
                  maxLines: 2,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: StudioColors.of(context).tint,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              AppConfig.backendEnabled ? 'ALPHA' : 'ДЕМО',
              style: const TextStyle(fontSize: 10, letterSpacing: .8),
            ),
          ),
          if (shell.currentIndex == 3)
            IconButton(
              tooltip: 'Новая переписка',
              onPressed: () => context.push('/new-chat'),
              icon: const Icon(Icons.add_comment_outlined, size: 22),
            ),
          if (shell.currentIndex == 0 || shell.currentIndex == 4)
            IconButton(
              tooltip: dark ? 'Светлая тема' : 'Тёмная тема',
              onPressed: () => ref
                  .read(prototypeProvider.notifier)
                  .setTheme(
                    state.theme == ThemeMode.dark || dark
                        ? ThemeMode.light
                        : ThemeMode.dark,
                  ),
              icon: Icon(
                dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              ),
            ),
          if (shell.currentIndex == 4)
            IconButton(
              tooltip: 'Настройки',
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.settings_outlined),
            ),
          const SizedBox(width: 10),
        ],
      ),
      body: TweenAnimationBuilder<double>(
        key: ValueKey(shell.currentIndex),
        tween: Tween(begin: 0, end: 1),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: shell,
        builder: (context, value, child) => Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 6 * (1 - value)),
            child: child,
          ),
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: StudioColors.of(context).line)),
        ),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) =>
              shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(
                Icons.explore_outlined,
                color: StudioColors.onLime,
              ),
              label: 'Рядом',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(
                Icons.people_outline,
                color: StudioColors.onLime,
              ),
              label: 'Люди',
            ),
            NavigationDestination(
              icon: Icon(Icons.pets_outlined),
              selectedIcon: Icon(
                Icons.pets_outlined,
                color: StudioColors.onLime,
              ),
              label: 'Выгул',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(
                Icons.chat_bubble_outline,
                color: StudioColors.onLime,
              ),
              label: 'Чаты',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(
                Icons.person_outline,
                color: StudioColors.onLime,
              ),
              label: 'Я',
            ),
          ],
        ),
      ),
    );
  }
}
