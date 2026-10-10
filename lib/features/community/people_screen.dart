import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/ui/components.dart';
import '../../core/media/preview_photos.dart';
import 'data/community_repository.dart';
import 'data/community_search.dart';

class PeopleScreen extends ConsumerStatefulWidget {
  const PeopleScreen({super.key});
  @override
  ConsumerState<PeopleScreen> createState() => _PeopleState();
}

class _PeopleState extends ConsumerState<PeopleScreen> {
  int tab = 0;
  final searches = [TextEditingController(), TextEditingController()];
  String get query => searches[tab].text.trim();
  void clearSearch() => setState(() => searches[tab].clear());
  @override
  void dispose() {
    for (final search in searches) {
      search.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('Люди рядом')),
                  ButtonSegment(value: 1, label: Text('Сообщества')),
                ],
                selected: {tab},
                showSelectedIcon: false,
                onSelectionChanged: (value) => setState(() {
                  tab = value.first;
                }),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              textAlignVertical: TextAlignVertical.top,
              key: ValueKey('community-search-$tab'),
              controller: searches[tab],
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Очистить поиск',
                        onPressed: clearSearch,
                        icon: const Icon(Icons.close),
                      ),
                hintText: tab == 0
                    ? 'Имя, питомец или интерес'
                    : 'Название или интерес',
              ),
            ),
          ],
        ),
      ),
      Expanded(
        child: ref
            .watch(communityProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Не удалось загрузить людей и сообщества. Проверьте соединение и попробуйте снова.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => ref.invalidate(communityProvider),
                        child: const Text('Повторить загрузку'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (data) {
                final repository = ref.read(communityRepositoryProvider);
                final people = searchPeople(data, repository.userId, query);
                final groups = searchGroups(data, query);
                return PageBody(
                  children: [
                    if (tab == 0) ...[
                      Text(
                        'Точное местоположение людей скрыто.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      ...people.map((p) {
                        final pets = rows(
                          data,
                          'pets',
                        ).where((pet) => pet['owner_id'] == p['id']);
                        final name =
                            '${p['display_name']}${pets.isEmpty ? '' : ' и ${pets.first['name']}'}';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    IdentityPicture(
                                      id: 'profile:${p['id']}',
                                      name: p['display_name'],
                                      icon: Icons.person_outline,
                                      size: 48,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                          MetadataLine(
                                            items: [
                                              p['district'] ??
                                                  'Район не указан',
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Написать $name',
                                      onPressed: () async {
                                        try {
                                          final cid = await ref
                                              .read(communityProvider.notifier)
                                              .command('direct', {
                                                'target': p['id'],
                                              });
                                          if (context.mounted && cid != null) {
                                            context.push('/chat/$cid');
                                          }
                                        } catch (_) {
                                          if (context.mounted) {
                                            notice(
                                              context,
                                              'Переписка недоступна',
                                            );
                                          }
                                        }
                                      },
                                      icon: const Icon(
                                        Icons.chat_bubble_outline,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (pets.isNotEmpty)
                                  Row(
                                    children: [
                                      const Icon(Icons.pets_outlined, size: 16),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: MetadataLine(
                                          items: [
                                            pets.first['kind'] ?? 'Питомец',
                                            if ('${pets.first['temperament'] ?? ''}'
                                                .trim()
                                                .isNotEmpty)
                                              pets.first['temperament'],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                if ((p['interests'] ?? '')
                                    .toString()
                                    .isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    p['interests'],
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                                const SizedBox(height: 16),
                                const Divider(height: 1),
                              ],
                            ),
                          ),
                        );
                      }),
                      if (people.isEmpty) ...[
                        Text(
                          query.isEmpty
                              ? 'Пока никого нет. Загляните позже.'
                              : 'Никого не нашли',
                        ),
                        if (query.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text(
                            'Попробуйте другое имя, питомца или интерес.',
                          ),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: clearSearch,
                              child: const Text('Сбросить поиск'),
                            ),
                          ),
                        ],
                      ],
                    ] else ...[
                      Row(
                        children: [
                          Expanded(
                            child: const ScreenIntro(
                              'Найдите сообщество',
                              compact: true,
                            ),
                          ),
                          IconButton(
                            tooltip: 'Создать сообщество',
                            onPressed: () => context.push('/edit/group'),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                      TextButton.icon(
                        onPressed: () => context.push('/events'),
                        icon: const Icon(Icons.event_outlined, size: 18),
                        label: const Text('Совместные прогулки'),
                      ),
                      if (groups.isEmpty) ...[
                        Text(
                          query.isEmpty
                              ? 'Пока нет сообществ. Создайте своё.'
                              : 'Сообщества не найдены',
                        ),
                        if (query.isNotEmpty)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton(
                              onPressed: clearSearch,
                              child: const Text('Сбросить поиск'),
                            ),
                          ),
                      ],
                      ...groups.map((g) {
                        final members = rows(
                          data,
                          'group_members',
                        ).where((m) => m['group_id'] == g['id']);
                        final joined = members.any(
                          (m) => m['user_id'] == repository.userId,
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => context.push('/group/${g['id']}'),
                            child: StudioCard(
                              padding: 14,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CommunityCover(
                                    id: 'group:${g['id']}',
                                    title: g['title'],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    g['description'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.people_outline,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: MetadataLine(
                                          items: [
                                            memberCount(members.length),
                                            joined
                                                ? 'Вы участвуете'
                                                : 'Открытое сообщество',
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward, size: 18),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                    if (repository.isDemo) const DemoCaption(),
                  ],
                );
              },
            ),
      ),
    ],
  );
}
