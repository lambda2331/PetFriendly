import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../notifications/notifications_screen.dart';
import '../../core/ui/studio_review.dart';
import '../../core/theme/studio_theme.dart';
import '../community/presentation/forms.dart';
import '../nearby/fullscreen_map_screen.dart';
import '../nearby/pet_access_widgets.dart';
import '../../l10n/language_picker.dart';
import '../../l10n/localization.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../core/diagnostics/crash_reporting.dart';
import '../security/moderation_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/storage/prototype_store.dart';
import '../../core/ui/components.dart';
import '../../core/media/preview_photos.dart';
import '../nearby/city_catalog.dart';
import '../nearby/place_repository.dart';
import '../nearby/place_contributions.dart';
import '../community/data/community_repository.dart';
import '../walks/account_mode.dart';
import '../../core/backend/backend.dart';
import '../auth/account_actions.dart';

String themeLabel(ThemeMode mode) => switch (mode) {
  ThemeMode.system => 'Как в системе',
  ThemeMode.light => 'Светлая',
  ThemeMode.dark => 'Тёмная',
};

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});
  void chooseTheme(BuildContext context, WidgetRef ref, ThemeMode selected) {
    showStudioSelectionSheet<void>(
      context: context,
      builder: (ctx) => StudioReviewSheet(
        title: 'Тема'.tr(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final mode in ThemeMode.values)
              StudioReviewRow(
                title: themeLabel(mode).tr(context),
                leading: Icon(switch (mode) {
                  ThemeMode.system => LucideIcons.sunMoon,
                  ThemeMode.light => LucideIcons.sun,
                  ThemeMode.dark => LucideIcons.moon,
                }),
                trailing: mode == selected
                    ? const Icon(Icons.check)
                    : const SizedBox.shrink(),
                onTap: () {
                  ref.read(prototypeProvider.notifier).setTheme(mode);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(prototypeProvider);
    final catalog = ref.watch(favoriteCatalogProvider);
    final saved = <String, Place>{
      for (final p in [
        ...catalog.value ?? [],
        ...ref.watch(placeContributionsProvider).value ?? [],
      ])
        if (state.favorites.contains(p.id)) p.id: p,
    }.values.toList();
    final community = ref.watch(communityProvider);
    final theme = Theme.of(context);
    final helper = ref.watch(accountModeProvider).value?.isHelper == true;
    Widget heading() => LayoutBuilder(
      builder: (context, constraints) {
        final titleStyle = theme.textTheme.headlineSmall!.copyWith(
          fontSize: 28,
        );
        final painter = TextPainter(
          text: TextSpan(text: 'Профиль'.tr(context), style: titleStyle),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        final actions = <Widget>[
          IconButton(
            tooltip: 'Последние события'.tr(context),
            onPressed: () => context.push('/notifications'),
            icon: const Icon(LucideIcons.bell),
          ),
          IconButton(
            tooltip: 'Тема приложения'.tr(context),
            onPressed: () => chooseTheme(context, ref, state.theme),
            icon: const Icon(LucideIcons.moon),
          ),
          IconButton(
            tooltip: 'Настройки'.tr(context),
            onPressed: () => context.push('/settings'),
            icon: const Icon(LucideIcons.settings),
          ),
        ];
        final title = Text('Профиль'.tr(context), style: titleStyle);
        return painter.width + 144 > constraints.maxWidth
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  title,
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(child: title),
                  ...actions,
                ],
              );
      },
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      children: [
        heading(),
        const SizedBox(height: 20),
        if (community.isLoading)
          StudioReviewState(
            title: 'Загружаем профиль…'.tr(context),
            loading: true,
          )
        else if (community.hasError)
          StudioReviewState(
            title: 'Не удалось загрузить'.tr(context),
            message: 'Проверьте соединение и попробуйте снова.'.tr(context),
            icon: LucideIcons.cloudOff,
            action: OutlinedButton(
              onPressed: () => ref.invalidate(communityProvider),
              child: Text('Повторить'.tr(context)),
            ),
          )
        else
          ..._content(
            context,
            ref,
            community.value ?? {},
            saved,
            catalog,
            helper,
          ),
      ],
    );
  }

  List<Widget> _content(
    BuildContext context,
    WidgetRef ref,
    CommunityData data,
    List<Place> saved,
    AsyncValue<List<Place>> catalog,
    bool helper,
  ) {
    final uid = ref.read(communityRepositoryProvider).userId;
    final profile = findRow(data, 'profiles', uid) ?? {};
    final pets = rows(data, 'pets').where((p) => p['owner_id'] == uid).toList();
    final theme = Theme.of(context);
    final city = ref.watch(prototypeProvider).city;
    final district = (profile['district'] ?? '').toString().trim();
    Widget section(String title, {Widget? action}) => Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Row(
        children: [
          Expanded(child: Text(title, style: studioIdentityText)),
          ?action,
        ],
      ),
    );
    return [
      Row(
        key: const Key('profile-identity'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IdentityPicture(
            id: 'profile:$uid',
            name: profile['display_name'] as String?,
            icon: LucideIcons.user,
            size: 64,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (profile['display_name'] ?? 'Ваш профиль'.tr(context))
                      .toString(),
                  style: studioIdentityText,
                ),
                const SizedBox(height: 4),
                Text(
                  [city, if (district.isNotEmpty) district].join(' · '),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Редактировать профиль'.tr(context),
            onPressed: () => showStudioEditSheet(context, kind: 'profile'),
            icon: const Icon(LucideIcons.pencil, size: 22),
          ),
        ],
      ),
      if ((profile['about'] ?? '').toString().trim().isNotEmpty) ...[
        const SizedBox(height: 16),
        Text(profile['about'], style: theme.textTheme.bodyMedium),
      ],
      if (!helper) ...[
        const SizedBox(height: 16),
        const Divider(height: 1),
        section(
          'Мои питомцы'.tr(context),
          action: IconButton(
            tooltip: 'Добавить питомца'.tr(context),
            onPressed: () => showStudioEditSheet(context, kind: 'pet'),
            icon: const Icon(LucideIcons.plus),
          ),
        ),
        if (pets.isEmpty)
          StudioReviewState(
            title: 'Добавьте своего питомца'.tr(context),
            message: 'Фото и несколько слов помогут соседям познакомиться.'.tr(
              context,
            ),
            icon: LucideIcons.pawPrint,
            action: OutlinedButton(
              onPressed: () => showStudioEditSheet(context, kind: 'pet'),
              child: Text('Добавить питомца'.tr(context)),
            ),
          ),
        for (final p in pets)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Material(
              color: StudioColors.of(context).tint,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: StudioColors.of(context).line),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => showPetDetails(context, p),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      IdentityPicture(
                        id: 'pet:${p['id']}',
                        icon: LucideIcons.pawPrint,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['name'], style: studioIdentityText),
                            Text(
                              [
                                    p['kind'],
                                    if ((p['breed'] ?? '')
                                        .toString()
                                        .isNotEmpty)
                                      p['breed']
                                    else
                                      ageYears(
                                        p['age'],
                                        locale: context.languageCode,
                                      ),
                                  ]
                                  .where(
                                    (v) => v != null && v.toString().isNotEmpty,
                                  )
                                  .join(' · '),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(LucideIcons.chevronRight, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
      const SizedBox(height: 16),
      const Divider(height: 1),
      section('Избранные места'.tr(context)),
      if (catalog.isLoading && ref.read(prototypeProvider).favorites.isNotEmpty)
        StudioReviewState(
          title: 'Загружаем сохранённые места…'.tr(context),
          loading: true,
        )
      else if (catalog.hasError &&
          saved.isEmpty &&
          ref.read(prototypeProvider).favorites.isNotEmpty)
        StudioReviewState(
          title: 'Избранные места не загрузились.'.tr(context),
          icon: LucideIcons.cloudOff,
          action: OutlinedButton(
            onPressed: () => ref.invalidate(favoriteCatalogProvider),
            child: Text('Повторить'.tr(context)),
          ),
        )
      else if (saved.isEmpty)
        StudioReviewState(
          title: 'Пока нет избранных мест'.tr(context),
          message: 'Сохраняйте места на странице «Рядом».'.tr(context),
          icon: LucideIcons.heart,
        )
      else
        for (final p in saved)
          StudioReviewRow(
            title: p.name,
            subtitle: '${p.city} · ${p.category.tr(context)}',
            leading: InitialAvatar('', icon: p.icon),
            onTap: () => showFavoritePlace(context, ref, p),
          ),
    ];
  }
}

void showPetDetails(BuildContext context, Json pet) =>
    showStudioSelectionSheet<void>(
      context: context,
      builder: (ctx) => StudioReviewSheet(
        title: 'Питомец'.tr(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IdentityPicture(
                  id: 'pet:${pet['id']}',
                  icon: LucideIcons.pawPrint,
                  size: 64,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pet['name'], style: studioIdentityText),
                      Text(
                        [
                              pet['kind'],
                              ageYears(
                                pet['age'],
                                locale: context.languageCode,
                              ),
                            ]
                            .where((v) => v != null && v.toString().isNotEmpty)
                            .join(' · '),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            Text('Характер и привычки'.tr(context), style: studioIdentityText),
            const SizedBox(height: 10),
            Text((pet['temperament'] ?? '').toString()),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                showStudioEditSheet(context, kind: 'pet', id: pet['id']);
              },
              icon: const Icon(LucideIcons.pencil),
              label: Text('Редактировать питомца'.tr(context)),
            ),
          ],
        ),
      ),
    );

void showFavoritePlace(BuildContext context, WidgetRef ref, Place place) =>
    showStudioSelectionSheet<void>(
      context: context,
      builder: (ctx) => StudioReviewSheet(
        title: place.name,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${place.city} · ${place.category.tr(context)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            PetAccessStatus(evidence: place.accessEvidence),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () {
                final router = GoRouter.of(context);
                Navigator.pop(ctx);
                router.push(
                  '/map',
                  extra: FullscreenMapArgs(
                    places: [place],
                    city: place.city,
                    focusPlace: place,
                  ),
                );
              },
              icon: const Icon(LucideIcons.mapPin),
              label: Text('Показать на карте'.tr(context)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                ref.read(prototypeProvider.notifier).favorite(place.id);
                Navigator.pop(ctx);
              },
              child: Text('Убрать из избранного'.tr(context)),
            ),
          ],
        ),
      ),
    );

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(prototypeProvider);
    final actions = ref.watch(accountActionsProvider);
    final items = <Widget>[
      StudioReviewRow(
        title: 'Тема'.tr(context),
        subtitle: themeLabel(state.theme).tr(context),
        leading: const Icon(LucideIcons.sunMoon),
        onTap: () =>
            const ProfileScreen().chooseTheme(context, ref, state.theme),
      ),
      StudioReviewRow(
        key: const Key('settings-language'),
        title: 'Язык'.tr(context),
        subtitle:
            appLanguages[ref.watch(languageProvider)?.languageCode] ??
            'Как на устройстве'.tr(context),
        leading: const Icon(LucideIcons.languages),
        onTap: () => chooseAppLanguage(context, ref),
      ),
      StudioReviewRow(
        title: 'Режим приложения'.tr(context),
        subtitle:
            (ref.watch(accountModeProvider).value?.isHelper == true
                    ? 'Помощник'
                    : 'Владелец')
                .tr(context),
        leading: const Icon(LucideIcons.user),
        onTap: () => context.push('/roles'),
      ),
      StudioReviewRow(
        title: 'Уведомления'.tr(context),
        subtitle: 'Текст сообщений скрыт в уведомлениях.'.tr(context),
        leading: const Icon(LucideIcons.bell),
        onTap: () => showStudioSelectionSheet<void>(
          context: context,
          builder: (ctx) => const NotificationSettingsSheet(),
        ),
      ),
      StudioReviewRow(
        title: 'О приложении и данных'.tr(context),
        leading: const Icon(LucideIcons.info),
        onTap: () => showStudioSelectionSheet<void>(
          context: context,
          builder: (ctx) => StudioReviewSheet(
            title: 'О приложении и данных'.tr(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PetFriendly', style: studioIdentityText),
                StudioReviewRow(
                  title: 'Безопасность и приватность'.tr(context),
                  subtitle: 'Аккаунт, сессии и личные данные'.tr(context),
                  leading: const Icon(Icons.shield_outlined),
                  onTap: () {
                    final router = GoRouter.of(context);
                    Navigator.pop(ctx);
                    router.push('/security');
                  },
                ),
                if (Firebase.apps.isNotEmpty)
                  Consumer(
                    builder: (context, sheetRef, _) => SwitchListTile(
                      title: Text('Отчёты об ошибках'.tr(context)),
                      value: sheetRef.watch(crashReportingProvider),
                      onChanged: (enabled) async {
                        try {
                          await sheetRef
                              .read(crashReportingProvider.notifier)
                              .setEnabled(enabled);
                        } catch (_) {
                          if (context.mounted) {
                            notice(
                              context,
                              'Не удалось изменить настройку'.tr(context),
                            );
                          }
                        }
                      },
                    ),
                  ),

                const SizedBox(height: 12),
                const SelectableText(
                  'Cities: © GeoNames · CC BY 4.0\nhttps://www.geonames.org/\nCountry names: Unicode CLDR · Unicode License V3',
                ),
                const SizedBox(height: 12),
                SelectableText(
                  'Каталог: © OpenStreetMap contributors · ODbL\nhttps://www.openstreetmap.org/copyright\n\nДопуск питомцев уточняется по данным сообщества.'
                      .tr(context),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
    return Scaffold(
      appBar: StudioReviewBrand(
        mode:
            (ref.watch(accountModeProvider).value?.isHelper == true
                    ? 'Помощник'
                    : 'Владелец')
                .tr(context),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Назад'.tr(context),
                onPressed: () => context.pop(),
                icon: const Icon(LucideIcons.arrowLeft),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Настройки'.tr(context),
                  style: Theme.of(
                    context,
                  ).textTheme.headlineSmall?.copyWith(fontSize: 28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          for (final (i, item) in items.indexed) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Divider(height: 1),
              ),
            item,
          ],
          const SizedBox(height: 12),
          if (ref.watch(moderationAvailableProvider).value == true)
            StudioReviewRow(
              title: 'Модерация'.tr(context),
              leading: const Icon(Icons.fact_check_outlined),
              onTap: () => context.push('/moderation'),
            ),
          if (ref.watch(backendProvider) != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: actions.isLoading
                      ? null
                      : () => showStudioConfirmation(
                          context,
                          title: 'Выйти из аккаунта'.tr(context),
                          onConfirm: () async {
                            try {
                              await ref
                                  .read(accountActionsProvider.notifier)
                                  .signOut();
                              if (context.mounted) context.go('/login');
                            } catch (_) {
                              if (context.mounted) {
                                notice(
                                  context,
                                  'Не удалось выйти. Повторите попытку.'.tr(
                                    context,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                  child: Text(
                    (actions.isLoading ? 'Выходим…' : 'Выйти из аккаунта').tr(
                      context,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
