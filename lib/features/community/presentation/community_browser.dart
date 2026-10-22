import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'group_screen.dart';
import '../../../core/media/preview_photos.dart';
import '../../../core/ui/components.dart';
import 'social_components.dart';
import '../../../l10n/localization.dart';
import '../../walks/account_mode.dart';
import '../data/community_repository.dart';
import '../data/community_browse.dart';

class CommunityBrowser extends ConsumerWidget {
  const CommunityBrowser({
    required this.data,
    required this.query,
    required this.clearSearch,
    super.key,
  });
  final CommunityData data;
  final String query;
  final VoidCallback clearSearch;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(communityRepositoryProvider).userId;
    final filter = ref.watch(communityBrowseProvider).participation;
    final groups = browseCommunities(
      data,
      uid,
      query: query,
      participation: filter,
    );
    final joinedIds = rows(
      data,
      'group_members',
    ).where((m) => m['user_id'] == uid).map((m) => m['group_id']).toSet();
    final catalogEmpty = rows(data, 'groups').isEmpty;
    void reset() {
      clearSearch();
      ref
          .read(communityBrowseProvider.notifier)
          .select(CommunityParticipation.all);
    }

    final canCreate = ref.watch(accountModeProvider).value?.canOwn == true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (groups.isEmpty)
          _CommunityEmpty(
            catalogEmpty: catalogEmpty,
            hasQuery: query.trim().isNotEmpty,
            filter: filter,
            canCreate: canCreate,
            reset: reset,
          ),
        if (filter == CommunityParticipation.all) ...[
          if (groups.any((g) => joinedIds.contains(g['id'])))
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Мои сообщества'.tr(context),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ...groups
              .where((g) => joinedIds.contains(g['id']))
              .map(
                (g) => CommunityBrowseRow(group: g, data: data, joined: true),
              ),
          if (groups.any((g) => !joinedIds.contains(g['id'])))
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 16),
              child: Text(
                'Найти новые'.tr(context),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ...groups
              .where((g) => !joinedIds.contains(g['id']))
              .map(
                (g) => CommunityBrowseRow(group: g, data: data, joined: false),
              ),
        ] else
          ...groups.map(
            (g) => CommunityBrowseRow(
              group: g,
              data: data,
              joined: joinedIds.contains(g['id']),
            ),
          ),
      ],
    );
  }
}

class _CommunityEmpty extends ConsumerWidget {
  const _CommunityEmpty({
    required this.catalogEmpty,
    required this.hasQuery,
    required this.filter,
    required this.canCreate,
    required this.reset,
  });
  final bool catalogEmpty, hasQuery, canCreate;
  final CommunityParticipation filter;
  final VoidCallback reset;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (catalogEmpty) {
      return SocialContentState(
        centered: true,
        icon: Icons.people_outline,
        title: 'Пока нет сообществ'.tr(context),
        loading: !canCreate && ref.watch(communityProvider).isLoading,
        message: 'Сообщества появятся здесь, когда их создадут.'.tr(context),
        actionLabel: 'Повторить загрузку'.tr(context),
        onAction: () => ref.read(communityProvider.notifier).refresh(),
      );
    }
    if (hasQuery) {
      return SocialContentState(
        centered: true,
        icon: Icons.search,
        title: 'Сообщества не найдены'.tr(context),
        message: 'Попробуйте другое название или сбросьте фильтры.'.tr(context),
        actionLabel: 'Сбросить'.tr(context),
        onAction: reset,
      );
    }
    if (filter == CommunityParticipation.joined) {
      return SocialContentState(
        centered: true,
        icon: Icons.people_outline,
        title: 'Вы пока не вступили в сообщества.'.tr(context),
        message: 'Выберите сообщество по интересам и вступите добровольно.'.tr(
          context,
        ),
        actionLabel: 'Найти сообщество'.tr(context),
        onAction: () => ref
            .read(communityBrowseProvider.notifier)
            .select(CommunityParticipation.discover),
      );
    }
    return SocialContentState(
      centered: true,
      icon: Icons.check_circle_outline,
      title: 'Вы уже участвуете во всех доступных сообществах.'.tr(context),
      message: 'Ваши сообщества находятся во вкладке «Мои».'.tr(context),
      actionLabel: 'Мои сообщества'.tr(context),
      onAction: () => ref
          .read(communityBrowseProvider.notifier)
          .select(CommunityParticipation.joined),
    );
  }
}

class CommunityBrowseRow extends ConsumerWidget {
  const CommunityBrowseRow({
    required this.group,
    required this.data,
    required this.joined,
    super.key,
  });
  final Json group;
  final CommunityData data;
  final bool joined;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final members = rows(
      data,
      'group_members',
    ).where((m) => m['group_id'] == group['id']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            key: ValueKey('community-${group['id']}'),
            borderRadius: BorderRadius.circular(16),
            onTap: () => showCommunityDetails(context, group['id'] as String),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IdentityPicture(
                        id: 'group:${group['id']}',
                        name: group['title'],
                        icon: Icons.people_outline,
                        size: 56,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group['title'] ?? '',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              memberCount(
                                    members
                                        .map((m) => m['user_id'])
                                        .toSet()
                                        .length,
                                    locale: context.languageCode,
                                  ) +
                                  (joined
                                      ? ' · ${"Вы участвуете".tr(context)}'
                                      : ''),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  if ('${group['description'] ?? ''}'.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      group['description'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }
}
