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
import '../nearby/place_row.dart';
import '../community/data/community_repository.dart';
import '../walks/helper_reputation.dart';
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
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      sheetAnimationStyle: studioSheetAnimation(context),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: StudioSheetHeader(title: 'Оформление'),
            ),
            ...ThemeMode.values.map(
              (mode) => ListTile(
                title: Text(themeLabel(mode)),
                leading: Icon(switch (mode) {
                  ThemeMode.system => Icons.brightness_auto_outlined,
                  ThemeMode.light => Icons.light_mode_outlined,
                  ThemeMode.dark => Icons.dark_mode_outlined,
                }),
                trailing: mode == selected ? const Icon(Icons.check) : null,
                onTap: () {
                  ref.read(prototypeProvider.notifier).setTheme(mode);
                  Navigator.pop(ctx);
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(prototypeProvider);
    final favoriteCatalog = ref.watch(favoriteCatalogProvider);
    final saved = <String, Place>{
      for (final p in [
        ...favoriteCatalog.value ?? [],
        ...ref.watch(placeContributionsProvider).value ?? [],
      ])
        if (state.favorites.contains(p.id)) p.id: p,
    }.values.toList();
    return ref
        .watch(communityProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(communityProvider),
              child: const Text('Повторить загрузку профиля'),
            ),
          ),
          data: (data) {
            final uid = ref.read(communityRepositoryProvider).userId;
            final profile = findRow(data, 'profiles', uid) ?? {};
            final pets = rows(data, 'pets').where((p) => p['owner_id'] == uid);
            Future<void> photo(String id) async {
              try {
                final bytes = await pickPreviewPhoto();
                if (bytes != null && context.mounted) {
                  final persistent = await savePhoto(ref, id, bytes);
                  if (!context.mounted) return;
                  notice(
                    context,
                    persistent
                        ? 'Фото сохранено'
                        : 'Фото для просмотра · до перезапуска',
                  );
                }
              } catch (_) {
                if (context.mounted) {
                  notice(
                    context,
                    'Не удалось сохранить фото. Проверьте соединение и выберите изображение до 8 МБ.',
                  );
                }
              }
            }

            final about = (profile['about'] ?? '').toString().trim();
            final interests = (profile['interests'] ?? '').toString().trim();
            return PageBody(
              children: [
                StudioCard(
                  key: const Key('profile-identity'),
                  padding: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Tooltip(
                            message: 'Изменить фото профиля',
                            excludeFromSemantics: true,
                            child: Semantics(
                              label: 'Фото профиля',
                              button: true,
                              container: true,
                              excludeSemantics: true,
                              onTap: () => photo('profile:$uid'),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(32),
                                onTap: () => photo('profile:$uid'),
                                child: SizedBox.square(
                                  dimension: 64,
                                  child: Stack(
                                    children: [
                                      IdentityPicture(
                                        id: 'profile:$uid',
                                        name: profile['display_name'],
                                        icon: Icons.person_outline,
                                        size: 64,
                                      ),
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.surface,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.camera_alt_outlined,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (profile['display_name'] ?? '')
                                          .toString()
                                          .trim()
                                          .isEmpty
                                      ? 'Ваш профиль'
                                      : profile['display_name'],
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontSize: 20),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  (profile['district'] ?? '')
                                          .toString()
                                          .trim()
                                          .isEmpty
                                      ? 'Район не указан'
                                      : profile['district'],
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (about.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(about),
                      ],
                      if (interests.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          interests,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Tooltip(
                        message: 'Редактировать профиль',
                        excludeFromSemantics: true,
                        child: OutlinedButton.icon(
                          onPressed: () => context.push('/edit/profile'),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('Редактировать профиль'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'В публичном профиле виден только район.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                SectionTitle(
                  'Мои питомцы',
                  compact: true,
                  trailing: pets.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Добавить питомца',
                          onPressed: () => context.push('/edit/pet'),
                          icon: const Icon(Icons.add),
                        ),
                ),
                if (pets.isEmpty) ...[
                  Text(
                    'Добавьте питомца — знакомиться будет проще.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/edit/pet'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Добавить питомца'),
                    ),
                  ),
                ],
                ...pets.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: StudioCard(
                      padding: 14,
                      child: Row(
                        children: [
                          Semantics(
                            label: 'Фото питомца ${p['name']}',
                            button: true,
                            child: InkWell(
                              onTap: () => photo('pet:${p['id']}'),
                              child: IdentityPicture(
                                id: 'pet:${p['id']}',
                                icon: Icons.pets_outlined,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p['name'],
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                MetadataLine(
                                  items: [p['kind'], ageYears(p['age'])],
                                ),
                                if ((p['temperament'] ?? '')
                                    .toString()
                                    .trim()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    p['temperament'],
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Редактировать питомца',
                            onPressed: () =>
                                context.push('/edit/pet?id=${p['id']}'),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SectionTitle('Мой опыт выгула', compact: true),
                Builder(
                  builder: (context) {
                    final reputation = HelperReputation.fromData(
                      data,
                      uid ?? '',
                      demo: ref.read(communityRepositoryProvider).isDemo,
                    );
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(reputation.reviewLabel),
                      subtitle: Text(reputation.completedLabel),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: uid == null
                          ? null
                          : () => context.push('/helper/$uid'),
                    );
                  },
                ),
                if (saved.isNotEmpty)
                  SectionTitle(
                    'Избранные места',
                    compact: true,
                    trailing: Text(
                      '${saved.length}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                if (saved.isEmpty &&
                    state.favorites.isNotEmpty &&
                    favoriteCatalog.isLoading) ...[
                  const SectionTitle('Избранные места', compact: true),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  const Text('Загружаем сохранённые места…'),
                ] else if (saved.isEmpty &&
                    state.favorites.isNotEmpty &&
                    favoriteCatalog.hasError) ...[
                  const SectionTitle('Избранные места', compact: true),
                  const Text('Избранные места не загрузились.'),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => ref.invalidate(favoriteCatalogProvider),
                      child: const Text('Повторить загрузку мест'),
                    ),
                  ),
                ] else if (saved.isEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.favorite_border, size: 20),
                    title: const Text('Избранные места'),
                    subtitle: Text(
                      state.favorites.isEmpty
                          ? 'Сохраняйте места на карте — они появятся здесь.'
                          : 'Сохранённые места сейчас недоступны.',
                    ),
                    trailing: const Icon(Icons.chevron_right, size: 20),
                    onTap: () => context.push('/places'),
                  ),
                ],
                ...saved.map((p) => PlaceRow(place: p)),
              ],
            );
          },
        );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(prototypeProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: PageBody(
        children: [
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Тема приложения'),
            subtitle: Text(themeLabel(state.theme)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                const ProfileScreen().chooseTheme(context, ref, state.theme),
          ),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('Уведомления'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/notifications'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Безопасность и приватность'),
            subtitle: const Text('Аккаунт, сессии и личные данные'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/security'),
          ),
          if (Firebase.apps.isNotEmpty)
            SwitchListTile(
              secondary: const Icon(Icons.bug_report_outlined),
              title: const Text('Отчёты об ошибках'),
              subtitle: const Text('Отправлять технические отчёты в Firebase'),
              value: ref.watch(crashReportingProvider),
              onChanged: (enabled) async {
                try {
                  await ref
                      .read(crashReportingProvider.notifier)
                      .setEnabled(enabled);
                } catch (_) {
                  if (context.mounted) {
                    notice(context, 'Не удалось изменить настройку');
                  }
                }
              },
            ),
          if (ref.watch(moderationAvailableProvider).value == true)
            ListTile(
              leading: const Icon(Icons.fact_check_outlined),
              title: const Text('Модерация'),
              onTap: () => context.push('/moderation'),
            ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('О приложении и данных'),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'PetFriendly',
              applicationVersion: '0.1',
              children: [
                const SelectableText(
                  AppConfig.portfolio
                      ? 'Portfolio demo: the map and places are fictional. No live map tiles, location tracking or backend services are connected. The native application uses Mapbox and an attributed OpenStreetMap catalog.'
                      : 'Каталог: © OpenStreetMap contributors · ODbL\nhttps://www.openstreetmap.org/copyright\n\nДопуск питомцев уточняется по данным сообщества.',
                ),
              ],
            ),
          ),
          if (ref.watch(backendProvider) != null) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(
                ref.watch(accountActionsProvider).isLoading
                    ? 'Выходим…'
                    : 'Выйти из аккаунта',
              ),
              subtitle: const Text('На этом устройстве'),
              enabled: !ref.watch(accountActionsProvider).isLoading,
              onTap: () async {
                try {
                  await ref.read(accountActionsProvider.notifier).signOut();
                  if (context.mounted) context.go('/login');
                } catch (_) {
                  if (context.mounted) {
                    notice(context, 'Не удалось выйти. Повторите попытку.');
                  }
                }
              },
            ),
          ],
          if (ref.read(communityRepositoryProvider).isDemo) const DemoCaption(),
        ],
      ),
    );
  }
}
