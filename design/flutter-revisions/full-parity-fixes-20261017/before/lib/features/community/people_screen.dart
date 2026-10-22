import 'presentation/events_screen.dart';
import '../../l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/ui/components.dart';
import '../../core/media/preview_photos.dart';
import '../walks/account_mode.dart';
import 'data/community_repository.dart';
import 'data/community_search.dart';
import 'data/community_browse.dart';
import 'presentation/community_browser.dart';
import 'presentation/social_components.dart';

class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({this.initialTab = 0, super.key});
  final int initialTab;
  @override
  ConsumerState<PeopleScreen> createState() => _PeopleState();
}

class _PeopleState extends ConsumerState<PeopleScreen> {
  late int tab = widget.initialTab;
  String? district;
  final expanded = <String>{};
  final searches = [TextEditingController(), TextEditingController()];
  String get query => tab == 2 ? '' : searches[tab].text.trim();
  void clearSearch() => setState(() => searches[tab].clear());
  @override
  void dispose() {
    for (final s in searches) {
      s.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(communityProvider);
    final data = snapshot.value ?? <String, List<Json>>{};
    final districts =
        rows(data, 'profiles')
            .map((p) => '${p['district'] ?? ''}'.trim())
            .where((d) => d.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    final participation = ref.watch(communityBrowseProvider).participation;
    final people = searchPeople(
      data,
      ref.watch(communityRepositoryProvider).userId,
      query,
    ).where((p) => district == null || p['district'] == district).toList();
    final children = <Widget>[
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ScreenIntro(
                (tab == 2 ? 'Встречи' : 'Знакомьтесь рядом.').tr(context),
              ),
            ),
            if (tab == 2 &&
                ref.watch(accountModeProvider).value?.canOwn == true)
              IconButton.filled(
                key: const ValueKey('meetup-create'),
                tooltip: 'Создать встречу'.tr(context),
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  minimumSize: const Size(48, 48),
                ),
                onPressed: () => context.push('/edit/event'),
                icon: const Icon(Icons.add),
              ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: StudioSegmentTabs<int>(
          key: const ValueKey('people-community-segment'),
          entries: {
            0: 'Люди'.tr(context),
            1: 'Сообщества'.tr(context),
            2: 'Встречи'.tr(context),
          },
          value: tab,
          selectedWeight: FontWeight.w700,
          onChanged: (value) => setState(() => tab = value),
        ),
      ),
      if (tab != 2)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      key: ValueKey('community-search-$tab'),
                      controller: searches[tab],
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText:
                            (tab == 0 ? 'Имя, питомец или интерес' : 'Поиск')
                                .tr(context),
                        suffixIcon: query.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Очистить поиск'.tr(context),
                                onPressed: clearSearch,
                                icon: const Icon(Icons.close),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StudioFilterMenu<String>(
                    key: const ValueKey('social-filter'),
                    tooltip: 'Фильтры'.tr(context),
                    icon: Icon(
                      Icons.filter_list,
                      color:
                          (tab == 0
                              ? district != null
                              : participation != CommunityParticipation.all)
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    value: tab == 0 ? (district ?? 'all') : participation.name,
                    onSelected: (value) {
                      if (tab == 0) {
                        setState(
                          () => district = value == 'all' ? null : value,
                        );
                      } else {
                        ref
                            .read(communityBrowseProvider.notifier)
                            .select(
                              CommunityParticipation.values.byName(value),
                            );
                      }
                    },
                    options: tab == 0
                        ? [
                            (value: 'all', label: 'Все районы'.tr(context)),
                            ...districts.map((d) => (value: d, label: d)),
                          ]
                        : [
                            for (final f in CommunityParticipation.values)
                              (
                                value: f.name,
                                label: (switch (f) {
                                  CommunityParticipation.all => 'Все',
                                  CommunityParticipation.joined => 'Мои',
                                  CommunityParticipation.discover => 'Новые',
                                }).tr(context),
                              ),
                          ],
                  ),
                  if (tab == 1 &&
                      ref.watch(accountModeProvider).value?.canOwn == true) ...[
                    const SizedBox(width: 8),
                    IconButton.filled(
                      key: const ValueKey('community-create'),
                      tooltip: 'Создать сообщество'.tr(context),
                      style: IconButton.styleFrom(
                        fixedSize: const Size(48, 48),
                      ),
                      onPressed: () => context.push('/edit/group'),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      Expanded(
        child: tab == 2
            ? const EventsScreen(embedded: true)
            : ListView(
                key: const ValueKey('people-list'),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                children: [
                  if (snapshot.isLoading)
                    SocialContentState(
                      centered: true,
                      title:
                          (tab == 0 ? 'Загрузка людей' : 'Загрузка сообществ')
                              .tr(context),
                      loading: true,
                    ),
                  if (snapshot.hasError)
                    SocialContentState(
                      centered: true,
                      title: 'Не удалось загрузить людей и сообщества.'.tr(
                        context,
                      ),
                      message: 'Проверьте соединение и повторите загрузку.'.tr(
                        context,
                      ),
                      actionLabel: 'Повторить загрузку'.tr(context),
                      onAction: () =>
                          ref.read(communityProvider.notifier).refresh(),
                    ),
                  if (snapshot.hasValue) ...[
                    if (tab == 0) ...[
                      ...people.map(
                        (p) => PersonStudioRow(
                          key: ValueKey('person-${p['id']}'),
                          person: p,
                          pets: rows(
                            data,
                            'pets',
                          ).where((pet) => pet['owner_id'] == p['id']).toList(),
                          expanded: expanded.contains(p['id']),
                          onToggle: () => setState(() {
                            if (!expanded.add(p['id'] as String)) {
                              expanded.remove(p['id']);
                            }
                          }),
                        ),
                      ),
                      if (people.isEmpty)
                        SocialContentState(
                          centered: true,
                          title:
                              (query.isEmpty && district == null
                                      ? 'Пока никого нет. Загляните позже.'
                                      : 'Никого не нашли')
                                  .tr(context),
                          message: 'Попробуйте другое имя, питомца или интерес.'
                              .tr(context),
                          actionLabel: query.isNotEmpty || district != null
                              ? 'Сбросить'.tr(context)
                              : null,
                          onAction: () {
                            clearSearch();
                            setState(() => district = null);
                          },
                        ),
                    ] else
                      CommunityBrowser(
                        data: data,
                        query: query,
                        clearSearch: clearSearch,
                      ),
                    if (ref.read(communityRepositoryProvider).isDemo)
                      const DemoCaption(),
                  ],
                ],
              ),
      ),
    ];
    return LayoutBuilder(
      builder: (ctx, bounds) {
        if (bounds.maxHeight < 360 ||
            (MediaQuery.textScalerOf(ctx).scale(16) > 22 &&
                bounds.maxHeight < 500)) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...children.take(children.length - 1),
                SizedBox(height: 400, child: (children.last as Expanded).child),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      },
    );
  }
}

class PersonStudioRow extends ConsumerWidget {
  const PersonStudioRow({
    required this.person,
    required this.pets,
    required this.expanded,
    required this.onToggle,
    super.key,
  });
  final Json person;
  final List<Json> pets;
  final bool expanded;
  final VoidCallback onToggle;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasDetails =
        pets.isNotEmpty || '${person['interests'] ?? ''}'.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IdentityPicture(
                id: 'profile:${person['id']}',
                name: person['display_name'],
                icon: Icons.person_outline,
                size: 56,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person['display_name'] ?? '',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      person['district'] ?? 'Район не указан'.tr(context),
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (pets.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: pets.length > 1 ? 48 : 32,
                  height: 32,
                  child: Stack(
                    children: [
                      for (var i = 0; i < pets.take(2).length; i++)
                        Positioned(
                          left: i * 16.0,
                          child: IdentityPicture(
                            id: 'pet:${pets[i]['id']}',
                            name: pets[i]['name'],
                            icon: Icons.pets_outlined,
                            size: 32,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        petSummary(pets, context.languageCode),
                        style: theme.textTheme.bodyMedium,
                      ),
                      if (pets.length > 1)
                        Text(
                          petCount(pets.length, context.languageCode),
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (hasDetails) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    key: ValueKey('person-details-${person['id']}'),
                    onPressed: onToggle,
                    icon: Icon(
                      expanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                    ),
                    label: Text((expanded ? 'Скрыть' : 'Детали').tr(context)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (!hasDetails) ...[const Spacer(), const SizedBox(width: 8)],
              Expanded(
                child: OutlinedButton.icon(
                  key: ValueKey('person-chat-${person['id']}'),
                  onPressed: () async {
                    try {
                      final cid = await ref
                          .read(communityProvider.notifier)
                          .command('direct', {'target': person['id']});
                      if (context.mounted && cid != null) {
                        context.push('/chat/$cid');
                      }
                    } catch (_) {
                      if (context.mounted) {
                        notice(context, 'Переписка недоступна'.tr(context));
                      }
                    }
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 20),
                  label: Text('Чат'.tr(context)),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: studioSheetAnimation(context).duration ?? Duration.zero,
            child: expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final pet in pets)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                IdentityPicture(
                                  id: 'pet:${pet['id']}',
                                  name: pet['name'],
                                  icon: Icons.pets_outlined,
                                  size: 32,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    [
                                          pet['name'],
                                          pet['kind'],
                                          pet['temperament'],
                                        ]
                                        .where(
                                          (v) =>
                                              v != null &&
                                              '$v'.trim().isNotEmpty,
                                        )
                                        .join(' · '),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if ('${person['interests'] ?? ''}'
                            .trim()
                            .isNotEmpty) ...[
                          Text(
                            'Интересы'.tr(context),
                            style: theme.textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(person['interests']),
                        ],
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
