import '../features/auth/onboarding_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../features/chat/inbox_repository.dart';
import '../l10n/localization.dart';
import '../features/chat/new_chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/storage/prototype_store.dart';
import '../core/theme/studio_theme.dart';
import '../features/nearby/nearby_screen.dart';
import '../features/nearby/nearby_studio_layout.dart';
import '../features/nearby/fullscreen_map_screen.dart';
import '../features/nearby/places_list_screen.dart';
import '../features/nearby/add_place_screen.dart';
import '../features/nearby/place_contributions.dart';
import '../features/nearby/place_feedback_screen.dart';
import '../features/community/people_screen.dart';
import '../features/walks/walks_screen.dart';
import '../features/walks/account_mode.dart';
import '../features/walks/helper_onboarding.dart';
import '../features/walks/helper_requests_screen.dart';
import '../features/walks/owner_profile_screen.dart';
import '../features/walks/personal_walking_hub.dart';
import '../features/walks/walking_conditions_screen.dart';
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
import '../core/ui/studio_motion.dart';
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
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/start', builder: (_, _) => const FirstActionScreen()),
      GoRoute(path: '/roles', builder: (_, _) => const RoleSelectionScreen()),
      GoRoute(
        path: '/helper/conditions',
        builder: (_, _) => const WalkingConditionsScreen(),
      ),
      GoRoute(
        path: '/helper/preferences',
        builder: (_, _) => const HelperOnboardingScreen(preferencesOnly: true),
      ),
      GoRoute(
        path: '/helper/onboarding',
        builder: (_, _) => const HelperOnboardingScreen(),
      ),
      GoRoute(
        path: '/owner/:id',
        redirect: (_, state) =>
            state.pathParameters['id'] ==
                ref.read(communityRepositoryProvider).userId
            ? '${walkingHubPath(ref)}?tab=profile&role=owner'
            : null,
        builder: (_, state) =>
            OwnerProfileScreen(id: state.pathParameters['id']!),
      ),
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
              GoRoute(
                path: '/events',
                redirect: (_, state) =>
                    state.uri.queryParameters['group'] == null
                    ? null
                    : '/group/${state.uri.queryParameters['group']}/meetings',
                builder: (_, _) => const PeopleScreen(initialTab: 2),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/walks',
                builder: (_, state) => AccountWalkingPage(
                  requests: false,
                  initialTab: walkingTabFromUri(state.uri),
                  initialProfileRole: state.uri.queryParameters['role'],
                ),
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
                builder: (_, _) => const ModeProfileScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/requests',
                builder: (_, _) => const AccountWalkingPage(requests: true),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my-walks',
                builder: (_, state) => AccountWalkingPage(
                  requests: false,
                  initialTab: walkingTabFromUri(state.uri),
                  initialProfileRole: state.uri.queryParameters['role'],
                ),
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
      GoRoute(
        path: '/group/:id/:section',
        builder: (_, state) => state.pathParameters['section'] == 'meetings'
            ? EventsScreen(communityId: state.pathParameters['id'])
            : CommunitySectionScreen(
                id: state.pathParameters['id']!,
                section: state.pathParameters['section']!,
              ),
      ),
      GoRoute(
        path: '/edit/:kind',
        builder: (_, state) => EditScreen(
          kind: state.pathParameters['kind']!,
          initialCommunity: state.uri.queryParameters['group'],
          id: state.uri.queryParameters['id'],
          welcome: state.uri.queryParameters['welcome'] == 'true',
        ),
      ),
      GoRoute(
        path: '/walk/:id',
        builder: (_, state) => WalkDetailScreen(
          id: state.pathParameters['id']!,
          chatCentered: true,
        ),
      ),
      GoRoute(
        path: '/review/:id',
        builder: (_, state) => ReviewScreen(
          id: state.pathParameters['id']!,
          role: state.uri.queryParameters['role'] ?? 'helper',
        ),
      ),
      GoRoute(
        path: '/helper/:id',
        redirect: (_, state) =>
            state.pathParameters['id'] ==
                ref.read(communityRepositoryProvider).userId
            ? '${walkingHubPath(ref)}?tab=profile&role=helper'
            : null,
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
      GoRoute(
        path: '/helper',
        redirect: (_, _) => '${walkingHubPath(ref)}?tab=profile&role=helper',
      ),
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
      ref.invalidate(accountModeProvider);
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
    locale: ref.watch(languageProvider),
    supportedLocales: AppLocalizations.supportedLocales,
    localeListResolutionCallback: resolveAppLocale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
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
                .disableAnimations ||
            WidgetsBinding
                .instance
                .platformDispatcher
                .accessibilityFeatures
                .reduceMotion
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
    final account = ref.watch(accountModeProvider).value;
    final helper = account?.mode == 'helper';
    final stackedHeader =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final branches = helper ? const [5, 6, 3, 4] : const [0, 1, 2, 3, 4];
    final selected = branches.indexOf(shell.currentIndex);
    return Scaffold(
      appBar: shell.currentIndex == 0
          ? NearbyStudioHeader(
              dark: dark,
              notificationAction: IconButton(
                tooltip: 'Последние события'.tr(context),
                onPressed: () => context.push('/notifications'),
                icon: const Icon(LucideIcons.bell),
              ),
              themeLabel: (dark ? 'Светлая тема' : 'Тёмная тема').tr(context),
              onTheme: () => ref
                  .read(prototypeProvider.notifier)
                  .setTheme(dark ? ThemeMode.light : ThemeMode.dark),
              settingsAction: IconButton(
                tooltip: 'Настройки'.tr(context),
                onPressed: () => context.push('/settings'),
                icon: const Icon(LucideIcons.settings2),
              ),
              stacked: stackedHeader,
              tall: MediaQuery.textScalerOf(context).scale(1) > 1.3,
              fallbackBadge: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: StudioColors.of(context).tint,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  AppConfig.backendEnabled ? 'ALPHA' : 'ДЕМО'.tr(context),
                  style: const TextStyle(fontSize: 10, letterSpacing: .8),
                ),
              ),
            )
          : AppBar(
              toolbarHeight: MediaQuery.textScalerOf(context).scale(1) > 1.3
                  ? 104
                  : 48,
              titleSpacing: 20,
              title: FittedBox(
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
              ),
              actions: [
                if (shell.currentIndex == 4) ...[
                  IconButton(
                    tooltip: 'Последние события'.tr(context),
                    onPressed: () => context.push('/notifications'),
                    icon: const Icon(LucideIcons.bell),
                  ),
                  IconButton(
                    tooltip: 'Тема приложения'.tr(context),
                    onPressed: () => const ProfileScreen().chooseTheme(
                      context,
                      ref,
                      state.theme,
                    ),
                    icon: Icon(dark ? LucideIcons.sun : LucideIcons.moon),
                  ),
                  IconButton(
                    tooltip: 'Настройки'.tr(context),
                    onPressed: () => context.push('/settings'),
                    icon: const Icon(LucideIcons.settings2),
                  ),
                ],
                const SizedBox(width: 10),
              ],
            ),
      body: TweenAnimationBuilder<double>(
        key: ValueKey(shell.currentIndex),
        tween: Tween(begin: 0, end: 1),
        duration: StudioMotion.duration(context, StudioMotion.tab),
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
        child: _StudioBottomNav(
          branches: branches,
          selected: selected,
          onSelect: (branch) => shell.goBranch(
            branch,
            initialLocation: branch == shell.currentIndex,
          ),
        ),
      ),
    );
  }
}

class _StudioBottomNav extends ConsumerStatefulWidget {
  const _StudioBottomNav({
    required this.branches,
    required this.selected,
    required this.onSelect,
  });
  final List<int> branches;
  final int selected;
  final ValueChanged<int> onSelect;
  @override
  ConsumerState<_StudioBottomNav> createState() => _StudioBottomNavState();
}

class _StudioBottomNavState extends ConsumerState<_StudioBottomNav> {
  final itemKeys = <int, GlobalKey>{};
  int? get activeBranch =>
      widget.selected >= 0 && widget.selected < widget.branches.length
      ? widget.branches[widget.selected]
      : null;
  @override
  void didUpdateWidget(_StudioBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected ||
        oldWidget.branches != widget.branches) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final target = itemKeys[activeBranch]?.currentContext;
        if (mounted && target != null) {
          Scrollable.ensureVisible(
            target,
            alignment: .5,
            duration: Duration.zero,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(communityRepositoryProvider).userId;
    final unread = (ref.watch(chatInboxProvider).value ?? []).any(
      (e) => (e.accountId == null || e.accountId == uid) && e.unread > 0,
    );
    String label(int branch) => switch (branch) {
      0 => 'Рядом',
      1 => 'Люди',
      2 => 'Выгул',
      3 => 'Чаты',
      4 => 'Я',
      5 => 'Запросы',
      _ => 'Мои прогулки',
    }.tr(context);
    const style = TextStyle(
      fontFamily: 'Golos Text',
      fontSize: 12,
      fontWeight: FontWeight.w700,
      height: 20 / 12,
      letterSpacing: 0,
    );
    final painter = TextPainter(
      text: TextSpan(
        text: activeBranch == null ? '' : label(activeBranch!),
        style: style,
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final labelWidth = (painter.width + 54).ceilToDouble();
    painter.dispose();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final selectedWidth = labelWidth.clamp(
              constraints.maxWidth * 2 / (widget.branches.length + 1),
              double.infinity,
            );
            final minimumWidth = activeBranch == null
                ? widget.branches.length * 48.0
                : selectedWidth + (widget.branches.length - 1) * 48;
            final scrolling = minimumWidth > constraints.maxWidth;
            final idleWidth = scrolling
                ? 48.0
                : activeBranch == null
                ? constraints.maxWidth / widget.branches.length
                : (constraints.maxWidth - selectedWidth) /
                      (widget.branches.length - 1);
            final row = Row(
              children: [
                for (final (i, branch) in widget.branches.indexed)
                  SizedBox(
                    width: i == widget.selected ? selectedWidth : idleWidth,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Semantics(
                        key: ValueKey('nav-$branch'),
                        label: label(branch),
                        onTap: () => widget.onSelect(branch),
                        selected: i == widget.selected,
                        button: true,
                        excludeSemantics: true,
                        child: Tooltip(
                          message: label(branch),
                          child: Material(
                            color: i == widget.selected
                                ? StudioColors.lime
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              key: itemKeys.putIfAbsent(branch, GlobalKey.new),
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => widget.onSelect(branch),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 48,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: i == widget.selected ? 10 : 0,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Badge(
                                        smallSize: 7,
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                        isLabelVisible: branch == 3 && unread,
                                        child: Icon(
                                          switch (branch) {
                                            0 => LucideIcons.compass,
                                            1 => LucideIcons.users,
                                            2 || 6 => LucideIcons.pawPrint,
                                            3 => LucideIcons.messageSquare,
                                            4 => LucideIcons.user,
                                            _ => LucideIcons.listFilter,
                                          },
                                          size: 22,
                                          color: i == widget.selected
                                              ? StudioColors.onLime
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      if (i == widget.selected) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          label(branch),
                                          softWrap: false,
                                          style: style.copyWith(
                                            color: StudioColors.onLime,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
            return scrolling
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: row,
                  )
                : row;
          },
        ),
      ),
    );
  }
}

class ModeProfileScreen extends ConsumerWidget {
  const ModeProfileScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => const ProfileScreen();
}

PersonalWalkingTab? walkingTabFromUri(Uri uri) =>
    switch (uri.queryParameters['tab']) {
      'history' => PersonalWalkingTab.history,
      'profile' => PersonalWalkingTab.profile,
      _ => null,
    };
String walkingHubPath(Ref ref) =>
    ref.read(accountModeProvider).value?.mode == 'helper'
    ? '/my-walks'
    : '/walks';

Future<void> chooseMode(BuildContext context, WidgetRef ref) async {
  final account = ref.read(accountModeProvider).value;
  if (account == null || account.pending) return;
  if (account.role != 'both' || account.needsRoleSelection) {
    context.push('/roles');
    return;
  }
  final selected = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Ваш режим".tr(context),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            "Один аккаунт. Переписки и история остаются с вами.".tr(context),
          ),
          const SizedBox(height: 16),
          for (final mode in ['owner', 'helper'])
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                mode == 'owner' ? LucideIcons.user : LucideIcons.pawPrint,
              ),
              title: Text(
                mode == 'owner'
                    ? "Владелец питомца".tr(context)
                    : "Помощник по выгулу".tr(context),
              ),
              trailing: mode == account.mode ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, mode),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/roles');
            },
            child: Text("Изменить роли".tr(context)),
          ),
        ],
      ),
    ),
  );
  if (selected == null || selected == account.mode || !context.mounted) return;
  try {
    await ref.read(accountModeProvider.notifier).switchMode(selected);
    if (context.mounted &&
        ref.read(accountModeProvider).value?.mode == selected) {
      context.go(selected == 'helper' ? '/requests' : '/nearby');
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Не удалось переключить режим. Попробуйте снова.".tr(context),
          ),
        ),
      );
    }
  }
}

class AccountWalkingPage extends ConsumerWidget {
  const AccountWalkingPage({
    required this.requests,
    this.initialTab,
    this.initialProfileRole,
    super.key,
  });
  final bool requests;
  final PersonalWalkingTab? initialTab;
  final String? initialProfileRole;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider.select((state) => state.value?.id));
    return requests
        ? RequestsScreen(key: ValueKey(uid))
        : PersonalWalkingHub(
            key: ValueKey(uid),
            initialTab: initialTab,
            initialProfileRole: initialProfileRole,
          );
  }
}
