import '../../core/ui/studio_review.dart';
import 'package:intl/intl.dart';
import '../../l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/ui/components.dart';
import '../../core/media/preview_photos.dart';
import '../community/data/community_repository.dart';
import '../../core/time/display_time.dart';
import 'helper_reputation.dart';
import 'walking_profile_components.dart';
import 'reply_drafts.dart';
import 'walking_form_drafts.dart';
import 'walk_progress.dart';
import 'walking_repository.dart';
import 'account_mode.dart';
import 'walking_chat_widgets.dart';
import 'walking_studio_components.dart';

String walkStatus(String value) => switch (value) {
  'assigned' => 'Помощник выбран',
  'in_progress' => 'На прогулке',
  'awaiting_confirmation' => 'Ждёт подтверждения',
  'completed' => 'Завершено',
  'cancelled' => 'Отменено',
  _ => 'Ищем помощника',
};

class WalksScreen extends ConsumerWidget {
  const WalksScreen({this.showHeader = true, super.key});
  final bool showHeader;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communityProvider);
    final uid = ref.read(communityRepositoryProvider).userId;
    return state.when(
      loading: () => const WalkingLoadingState(),
      error: (e, s) => Center(
        child: TextButton(
          onPressed: () => ref.invalidate(communityProvider),
          child: Text("Повторить загрузку".tr(context)),
        ),
      ),
      data: (data) => PageBody(
        children: [
          if (showHeader)
            ScreenIntro(
              "Помощь с выгулом".tr(context),
              compact: true,
              subtitle: "Попросите соседей о помощи или помогите сами.".tr(
                context,
              ),
            ),
          if (!showHeader)
            ScreenIntro(
              "На прогулку\nс хорошей компанией.".tr(context),
              compact: true,
              subtitle: "Попросите соседей о помощи или помогите сами.".tr(
                context,
              ),
            ),
          const SizedBox(height: 20),
          if (ref.watch(accountModeProvider).value?.canOwn == true)
            FilledButton.icon(
              onPressed: () => context.push('/edit/walk'),
              icon: const Icon(Icons.add),
              label: Text("Попросить о выгуле".tr(context)),
            ),
          if (rows(data, 'walk_requests').any(
            (w) => isMyActiveWalk(
              data,
              w,
              ref.read(communityRepositoryProvider).userId,
            ),
          ))
            SectionTitle("Мои договорённости".tr(context), compact: true),
          ...rows(data, 'walk_requests')
              .where(
                (w) => isMyActiveWalk(
                  data,
                  w,
                  ref.read(communityRepositoryProvider).userId,
                ),
              )
              .map(
                (w) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    "Прогулка с {p0}".tr(
                      context,
                      arguments: {
                        'p0':
                            findRow(data, 'pets', w['pet_id'])?['name'] ??
                            'питомцем',
                      },
                    ),
                  ),
                  subtitle: MetadataLine(
                    items: [
                      walkStatus(w['status']).tr(context),
                      venueTime(
                        w['starts_at'],
                        city: w['city'],
                        timeZone: w['time_zone'] as String?,
                        locale: context.languageCode,
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/walk/${w['id']}'),
                ),
              ),
          if (rows(data, 'walk_requests').any((w) => w['status'] == 'open'))
            SectionTitle("Запросы на прогулку".tr(context), compact: true)
          else
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                "Пока нет запросов на прогулку.".tr(context),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ...rows(
            data,
            'walk_requests',
          ).where((w) => w['status'] == 'open').map((w) {
            final pet = findRow(data, 'pets', w['pet_id']);
            final owner = findRow(data, 'profiles', w['owner_id']);
            final count = rows(
              data,
              'walk_applications',
            ).where((a) => a['request_id'] == w['id']).length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: StudioCard(
                padding: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IdentityPicture(
                          id: 'pet:${pet?['id']}',
                          icon: Icons.pets_outlined,
                          size: 48,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Прогулка с {p0}".tr(
                                  context,
                                  arguments: {'p0': pet?['name'] ?? 'питомцем'},
                                ),
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              MetadataLine(
                                items: [
                                  pet?['kind'] ?? "Питомец".tr(context),
                                  if (pet?['age'] != null)
                                    ageYears(
                                      pet?['age'],
                                      locale: context.languageCode,
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 14,
                      runSpacing: 8,
                      children: [
                        WalkFact(
                          Icons.event_outlined,
                          venueTime(
                            w['starts_at'],
                            city: w['city'],
                            timeZone: w['time_zone'] as String?,
                            locale: context.languageCode,
                          ),
                        ),
                        WalkFact(
                          Icons.schedule,
                          "{p0} мин".tr(
                            context,
                            arguments: {'p0': w['duration']},
                          ),
                        ),
                        WalkFact(
                          Icons.location_on_outlined,
                          owner?['district'] ?? w['city'],
                        ),
                      ],
                    ),
                    if ((pet?['temperament'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        pet!['temperament'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    if ((w['description'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        w['description'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 12),
                    MetadataLine(
                      items: [
                        walkStatus(w['status']).tr(context),
                        "{p0} откликов".tr(context, arguments: {'p0': count}),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Text(
                          owner?['display_name'] ?? "Владелец".tr(context),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        TextButton(
                          onPressed: () => context.push('/walk/${w['id']}'),
                          child: Text("Подробнее и отклики".tr(context)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          if (rows(data, 'walk_requests').any(
            (w) =>
                ['completed', 'cancelled'].contains(w['status']) &&
                isMyWalk(data, w, ref.read(communityRepositoryProvider).userId),
          ))
            SectionTitle("История прогулок".tr(context), compact: true),
          ...rows(data, 'walk_requests')
              .where(
                (w) =>
                    ['completed', 'cancelled'].contains(w['status']) &&
                    isMyWalk(
                      data,
                      w,
                      ref.read(communityRepositoryProvider).userId,
                    ),
              )
              .map(
                (w) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    "Прогулка с {p0}".tr(
                      context,
                      arguments: {
                        'p0':
                            findRow(data, 'pets', w['pet_id'])?['name'] ??
                            'питомцем',
                      },
                    ),
                  ),
                  subtitle: MetadataLine(
                    items: [
                      walkStatus(w['status']).tr(context),
                      venueTime(
                        w['starts_at'],
                        city: w['city'],
                        timeZone: w['time_zone'],
                        locale: context.languageCode,
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/walk/${w['id']}'),
                ),
              ),
          if (rows(data, 'profiles').any((p) => p['id'] != uid))
            SectionTitle("Помощники".tr(context), compact: true),
          ...rows(data, 'profiles')
              .where(
                (p) => p['id'] != ref.read(communityRepositoryProvider).userId,
              )
              .map(
                (p) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: InitialAvatar(
                    (p['display_name'] as String).substring(0, 1),
                  ),
                  title: Text(p['display_name']),
                  subtitle: HelperReputationText(
                    data: data,
                    id: p['id'],
                    demo: ref.read(communityRepositoryProvider).isDemo,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/helper/${p['id']}'),
                ),
              ),
        ],
      ),
    );
  }
}

Future<void> showWalkRequestSheet(
  BuildContext context, {
  required String id,
  bool applications = false,
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: false,
  clipBehavior: Clip.antiAlias,
  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
  sheetAnimationStyle: studioSheetAnimation(context),
  builder: (_) =>
      WalkDetailScreen(id: id, embedded: true, applicationsOnly: applications),
);

class WalkDetailScreen extends ConsumerStatefulWidget {
  const WalkDetailScreen({
    required this.id,
    this.chatCentered = false,
    this.embedded = false,
    this.applicationsOnly = false,
    super.key,
  });
  final String id;
  final bool chatCentered;
  final bool embedded, applicationsOnly;
  @override
  ConsumerState<WalkDetailScreen> createState() => _WalkDetailState();
}

class _WalkDetailState extends ConsumerState<WalkDetailScreen> {
  bool busy = false, confirming = false;
  String? redirectedConversation;
  String? actionError;
  String get id => widget.id;
  Future<void> action(
    BuildContext context,
    WidgetRef ref,
    String name,
    Json args,
  ) async {
    if (busy || confirming) {
      return;
    }
    final repository = ref.read(communityRepositoryProvider);
    final accountId = repository.userId;
    final assign = name == 'assign_walk';
    final apply = name == 'apply_walk';
    final cancel = args['next_status'] == 'cancelled';
    if (assign || apply || cancel) {
      confirming = true;
      final data = ref.read(communityProvider).value ?? {};
      final request = findRow(data, 'walk_requests', id);
      final pet = findRow(data, 'pets', request?['pet_id']);
      final helper = findRow(data, 'profiles', args['helper_in']);
      final helperName = '${helper?['display_name'] ?? 'Участник'.tr(context)}';
      final petName = '${pet?['name'] ?? 'Прогулка'.tr(context)}';
      final time = walkingShortTime(context, request ?? {}, duration: false);
      bool? accepted;
      try {
        accepted = await showStudioSelectionSheet<bool>(
          context: context,
          builder: (ctx) => StudioReviewSheet(
            title: assign
                ? 'Выбрать {p0}?'.tr(ctx, arguments: {'p0': helperName})
                : (apply ? 'Отправить отклик?' : 'Отменить заявку?').tr(ctx),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (assign || apply) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IdentityPicture(
                          id: assign
                              ? 'profile:${args['helper_in']}'
                              : 'pet:${pet?['id']}',
                          name: assign ? helperName : petName,
                          icon: assign
                              ? Icons.person_outline
                              : Icons.pets_outlined,
                          size: 48,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                assign ? helperName : petName,
                                style: studioIdentityText,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                assign
                                    ? '$petName · $time'
                                    : '${request?['city'] ?? ''} · $time',
                                style: Theme.of(ctx).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  assign
                      ? '{p0} станет помощником этой прогулки.'.tr(
                          ctx,
                          arguments: {'p0': helperName},
                        )
                      : (apply
                                ? 'Владелец увидит ваши публичные сведения о помощи.'
                                : 'Открытая заявка больше не будет принимать отклики.')
                            .tr(ctx),
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (_, bounds) {
                    final secondary = OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Отмена'.tr(ctx)),
                    );
                    final primary = FilledButton(
                      key: const Key('walk-confirm-submit'),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        (assign
                                ? 'Выбрать'
                                : apply
                                ? 'Отправить отклик'
                                : 'Отменить заявку')
                            .tr(ctx),
                      ),
                    );
                    if (MediaQuery.textScalerOf(ctx).scale(16) > 24) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          secondary,
                          const SizedBox(height: 12),
                          primary,
                        ],
                      );
                    }
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: secondary),
                          const SizedBox(width: 12),
                          Expanded(child: primary),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      } finally {
        confirming = false;
      }
      if (accepted != true || !mounted) {
        return;
      }
    }
    if (!mounted ||
        !identical(repository, ref.read(communityRepositoryProvider)) ||
        accountId != repository.userId) {
      return;
    }
    setState(() {
      busy = true;
      actionError = null;
    });
    try {
      await ref.read(communityProvider.notifier).command(name, args);
      if (context.mounted) {
        notice(context, walkActionSuccess(name, args).tr(context));
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => actionError =
              "Не удалось обновить заявку. Проверьте соединение и обновите её: статус мог измениться."
                  .tr(context),
        );
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityProvider);
    if (state.isLoading || state.hasError) {
      return Scaffold(
        appBar: AppBar(title: Text("Заявка на выгул".tr(context))),
        body: state.isLoading
            ? const WalkingLoadingState()
            : Center(
                child: TextButton(
                  onPressed: () => ref.invalidate(communityProvider),
                  child: Text("Заявка не загрузилась · повторить".tr(context)),
                ),
              ),
      );
    }
    final data = state.value ?? {};
    final request = findRow(data, 'walk_requests', id);
    if (request == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text("Заявка недоступна".tr(context))),
      );
    }
    final repository = ref.read(communityRepositoryProvider),
        uid = repository.userId;
    final owner = request['owner_id'] == uid;
    final pet = findRow(data, 'pets', request['pet_id']);
    final applications = rows(
      data,
      'walk_applications',
    ).where((a) => a['request_id'] == id).toList();
    final agreements = rows(
      data,
      'walk_agreements',
    ).where((a) => a['request_id'] == id).toList();
    final helper = agreements.firstOrNull?['helper_id'];
    final applied = applications.any((a) => a['helper_id'] == uid);
    final reviewed = rows(
      data,
      'walk_reviews',
    ).any((r) => r['request_id'] == id);
    final conversationId = walkConversationId(data, id, uid);
    if (widget.chatCentered && request['status'] != 'open') {
      if (conversationId != null) {
        if (redirectedConversation != conversationId) {
          redirectedConversation = conversationId;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted ||
                ref.read(communityRepositoryProvider).userId != uid) {
              return;
            }
            final latest = ref.read(communityProvider).value;
            if (latest == null ||
                walkConversationId(latest, id, uid) != conversationId) {
              redirectedConversation = null;
              return;
            }
            context.replace('/chat/$conversationId');
          });
        }
        return Scaffold(
          appBar: AppBar(title: Text('Детали прогулки'.tr(context))),
          body: const WalkingLoadingState(),
        );
      }
      return _ReadOnlyWalkRecord(
        request: request,
        pet: pet,
        onRefresh: () => ref.invalidate(communityProvider),
      );
    }

    if (widget.embedded) {
      return WalkingChatSheet(
        title: (widget.applicationsOnly ? 'Отклики' : 'Детали').tr(context),
        children: [
          Text(
            '${pet?['name'] ?? 'Питомец'.tr(context)}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(walkingShortTime(context, request)),
          const SizedBox(height: 8),
          if (!widget.applicationsOnly) ...[
            Text(
              timeZoneLabel(
                request['time_zone'] as String? ??
                    cityTimeZone(request['city']) ??
                    'UTC',
                locale: context.languageCode,
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    [request['city'], request['district']]
                        .whereType<String>()
                        .where((s) => s.isNotEmpty)
                        .join(' · '),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                IdentityPicture(
                  id: 'profile:${request['owner_id']}',
                  name: findRow(
                    data,
                    'profiles',
                    request['owner_id'],
                  )?['display_name'],
                  icon: Icons.person_outline,
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${findRow(data, 'profiles', request['owner_id'])?['display_name'] ?? 'Владелец'.tr(context)}',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Владелец'.tr(context),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if ('${request['description'] ?? ''}'.isNotEmpty) ...[
              const Divider(height: 32),
              Text(
                'Что нужно знать'.tr(context),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Text('${request['description']}'),
            ],
            if (request['status'] == 'open' &&
                !owner &&
                (applied ||
                    ref.watch(accountModeProvider).value?.canHelp == true)) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: busy
                    ? null
                    : () => action(
                        context,
                        ref,
                        applied ? 'withdraw_walk' : 'apply_walk',
                        {'request_in': id},
                      ),
                child: Text(
                  (applied ? 'Отменить отклик' : 'Предложить помощь').tr(
                    context,
                  ),
                ),
              ),
            ],
            if (owner && request['status'] == 'open') ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: busy
                    ? null
                    : () => action(context, ref, 'advance_walk', {
                        'request_in': id,
                        'next_status': 'cancelled',
                      }),
                child: Text('Отменить заявку'.tr(context)),
              ),
            ],
          ] else if (owner && request['status'] == 'open') ...[
            const Divider(height: 24),
            if (applications.isEmpty)
              Text('Пока никто не откликнулся.'.tr(context)),
            for (final a in applications) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: IdentityPicture(
                  id: 'profile:${a['helper_id']}',
                  name: findRow(
                    data,
                    'profiles',
                    a['helper_id'],
                  )?['display_name'],
                  icon: Icons.person_outline,
                  size: 56,
                ),
                title: Text(
                  '${findRow(data, 'profiles', a['helper_id'])?['display_name'] ?? 'Помощник'.tr(context)}',
                ),
                subtitle: Text(
                  HelperReputation.fromData(
                    data,
                    a['helper_id'],
                    demo: repository.isDemo,
                  ).localizedReviewLabel(context.languageCode),
                ),
                onTap: () => context.push('/helper/${a['helper_id']}'),
              ),
              if ('${findRow(data, 'helper_preferences', a['helper_id'])?['experience'] ?? ''}'
                  .isNotEmpty)
                Text(
                  '${findRow(data, 'helper_preferences', a['helper_id'])?['experience']}',
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: busy
                    ? null
                    : () => action(context, ref, 'assign_walk', {
                        'request_in': id,
                        'helper_in': a['helper_id'],
                      }),
                child: Text('Выбрать помощника'.tr(context)),
              ),
              const Divider(height: 32),
            ],
            if (repository.isDemo)
              TextButton(
                onPressed: busy
                    ? null
                    : () => action(context, ref, 'demo_application', {
                        'request_in': id,
                      }),
                child: Text('Добавить тестовый отклик Саши'.tr(context)),
              ),
          ] else
            Text('Заявка больше не принимает отклики'.tr(context)),
          if (busy) const LinearProgressIndicator(),
          if (actionError != null)
            Text(
              actionError!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      );
    }

    final chatIsPrimary =
        (owner && ['assigned', 'in_progress'].contains(request['status'])) ||
        (helper == uid && request['status'] == 'awaiting_confirmation') ||
        (request['status'] == 'completed' && (!owner || reviewed));
    final ownerReview = ref.watch(ownerReviewEligibilityProvider(id));
    final instructions = rows(
      data,
      'walk_details',
    ).where((d) => d['request_id'] == id).firstOrNull?['instructions'];
    return Scaffold(
      appBar: AppBar(
        title: Text("Заявка на выгул".tr(context)),
        actions: [
          IconButton(
            tooltip: "Обновить статус заявки".tr(context),
            onPressed: busy ? null : () => ref.invalidate(communityProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: WalkingActionTheme(
        child: ListView(
          key: PageStorageKey('walk-detail-$id'),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Row(
              children: [
                IdentityPicture(
                  id: 'pet:${request['pet_id']}',
                  name: pet?['name'],
                  icon: Icons.pets_outlined,
                  size: 48,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${pet?['name'] ?? "Питомец".tr(context)}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text((owner ? "Владелец" : "Помощник").tr(context)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              venueTime(
                request['starts_at'],
                city: request['city'],
                timeZone: request['time_zone'] as String?,
                locale: context.languageCode,
              ),
            ),
            if (request['duration'] != null)
              Text(
                "{p0} минут".tr(
                  context,
                  arguments: {'p0': request['duration']},
                ),
              ),
            if ('${request['district'] ?? ''}'.isNotEmpty)
              Text('${request['district']}'),
            const SizedBox(height: 8),
            if (!owner || helper != null)
              TextButton.icon(
                onPressed: () => context.push(
                  owner ? '/helper/$helper' : '/owner/${request['owner_id']}',
                ),
                icon: const Icon(Icons.person_outline, size: 20),
                label: Text(
                  '${findRow(data, 'profiles', owner ? helper : request['owner_id'])?['display_name'] ?? (owner ? "Помощник".tr(context) : "Владелец".tr(context))}',
                ),
              ),
            if ('${request['description'] ?? ''}'.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('${request['description']}'),
            ],
            const SizedBox(height: 20),
            Text(
              walkStatus(request['status']).tr(context),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (actionError != null) ...[
              Semantics(
                liveRegion: true,
                child: Text(
                  actionError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (busy) const LinearProgressIndicator(),
            if (request['status'] == 'open' &&
                !owner &&
                (applied ||
                    ref.watch(accountModeProvider).value?.canHelp == true))
              FilledButton(
                style: applied
                    ? FilledButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface,
                      )
                    : null,
                onPressed: busy
                    ? null
                    : () => action(
                        context,
                        ref,
                        applied ? 'withdraw_walk' : 'apply_walk',
                        {'request_in': id},
                      ),
                child: Text(
                  applied
                      ? "Отменить отклик".tr(context)
                      : "Предложить помощь".tr(context),
                ),
              ),
            if (owner && request['status'] == 'open') ...[
              SectionTitle("Отклики".tr(context)),
              if (applications.isEmpty)
                Text("Пока никто не откликнулся.".tr(context)),
              ...applications.map(
                (a) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: IdentityPicture(
                          id: 'profile:${a['helper_id']}',
                          name: findRow(
                            data,
                            'profiles',
                            a['helper_id'],
                          )?['display_name'],
                          icon: Icons.person_outline,
                          size: 40,
                        ),
                        title: Text(
                          findRow(
                                data,
                                'profiles',
                                a['helper_id'],
                              )?['display_name'] ??
                              "Помощник".tr(context),
                        ),
                        subtitle: Text(
                          HelperReputation.fromData(
                            data,
                            a['helper_id'],
                            demo: repository.isDemo,
                          ).localizedReviewLabel(context.languageCode),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/helper/${a['helper_id']}'),
                      ),
                      OutlinedButton(
                        onPressed: busy
                            ? null
                            : () => action(context, ref, 'assign_walk', {
                                'request_in': id,
                                'helper_in': a['helper_id'],
                              }),
                        child: Text("Выбрать помощника".tr(context)),
                      ),
                      const Divider(),
                    ],
                  ),
                ),
              ),
              if (repository.isDemo)
                TextButton(
                  onPressed: busy
                      ? null
                      : () => action(context, ref, 'demo_application', {
                          'request_in': id,
                        }),
                  child: Text("Добавить тестовый отклик Саши".tr(context)),
                ),
            ],
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (request['status'] == 'assigned' &&
                    (helper == uid || repository.isDemo))
                  FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () => action(context, ref, 'advance_walk', {
                            'request_in': id,
                            'next_status': 'in_progress',
                          }),
                    style: repository.isDemo && helper != uid
                        ? FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onSurface,
                          )
                        : null,
                    icon: const Icon(Icons.play_arrow_outlined),
                    label: Text(
                      repository.isDemo
                          ? "Демо: помощник начал прогулку".tr(context)
                          : "Начать прогулку".tr(context),
                    ),
                  ),
                if (request['status'] == 'in_progress' &&
                    (helper == uid || repository.isDemo))
                  FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () => action(context, ref, 'advance_walk', {
                            'request_in': id,
                            'next_status': 'awaiting_confirmation',
                          }),
                    style: repository.isDemo && helper != uid
                        ? FilledButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.onSurface,
                          )
                        : null,
                    icon: const Icon(Icons.flag_outlined),
                    label: Text(
                      repository.isDemo
                          ? "Демо: помощник завершил прогулку".tr(context)
                          : "Завершить прогулку".tr(context),
                    ),
                  ),
                if (request['status'] == 'awaiting_confirmation' && owner)
                  FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () => action(context, ref, 'advance_walk', {
                            'request_in': id,
                            'next_status': 'completed',
                          }),
                    icon: const Icon(Icons.check),
                    label: Text("Подтвердить завершение".tr(context)),
                  ),
                if (request['status'] == 'completed' && owner && !reviewed)
                  FilledButton(
                    onPressed: () => showWalkingReviewSheet(context, id: id),
                    child: Text("Оценить помощника".tr(context)),
                  ),
                if (request['status'] == 'completed' &&
                    helper == uid &&
                    ownerReview.value == false)
                  FilledButton(
                    onPressed: () =>
                        showWalkingReviewSheet(context, id: id, role: 'owner'),
                    child: Text("Оценить владельца".tr(context)),
                  ),
                if (request['status'] == 'completed' &&
                    helper == uid &&
                    ownerReview.hasError)
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(ownerReviewEligibilityProvider(id)),
                    child: Text(
                      "Доступность отзыва не загрузилась · повторить".tr(
                        context,
                      ),
                    ),
                  ),
                if (conversationId != null) ...[
                  chatIsPrimary
                      ? FilledButton.icon(
                          onPressed: busy
                              ? null
                              : () => context.push('/chat/$conversationId'),
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: Text("Чат договорённости".tr(context)),
                        )
                      : OutlinedButton.icon(
                          onPressed: busy
                              ? null
                              : () => context.push('/chat/$conversationId'),
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: Text("Чат договорённости".tr(context)),
                        ),
                ],
              ],
            ),
            if ((owner || helper == uid && uid != null) &&
                instructions != null &&
                '$instructions'.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(),
              SectionTitle("Передача питомца".tr(context)),
              Text(
                "Видны только участникам договорённости".tr(context),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text('$instructions'),
            ],
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: () => context.push('/report/walk/$id'),
              icon: const Icon(Icons.flag_outlined, size: 18),
              label: Text("Сообщить о проблеме".tr(context)),
            ),
            if (owner && request['status'] == 'open') ...[
              const SizedBox(height: 16),
              const Divider(),
              TextButton(
                onPressed: busy
                    ? null
                    : () => action(context, ref, 'advance_walk', {
                        'request_in': id,
                        'next_status': 'cancelled',
                      }),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text("Отменить заявку".tr(context)),
              ),
            ],
            if (repository.isDemo) const DemoCaption(),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyWalkRecord extends StatelessWidget {
  const _ReadOnlyWalkRecord({
    required this.request,
    required this.pet,
    required this.onRefresh,
  });
  final Json request;
  final Json? pet;
  final VoidCallback onRefresh;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Детали прогулки'.tr(context))),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IdentityPicture(
              id: 'pet:${request['pet_id']}',
              name: pet?['name'],
              icon: Icons.pets_outlined,
              size: 48,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '${pet?['name'] ?? 'Питомец'.tr(context)}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          venueTime(
            request['starts_at'],
            city: request['city'],
            timeZone: request['time_zone'] as String?,
            locale: context.languageCode,
          ),
        ),
        if (request['duration'] != null)
          Text(
            '{p0} минут'.tr(context, arguments: {'p0': request['duration']}),
          ),
        if ('${request['district'] ?? ''}'.isNotEmpty)
          Text('${request['district']}'),
        const SizedBox(height: 20),
        Text(
          walkStatus('${request['status']}').tr(context),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Text('Чат этой прогулки недоступен'.tr(context)),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: Text('Повторить загрузку'.tr(context)),
          ),
        ),
      ],
    ),
  );
}

class HelperScreen extends ConsumerStatefulWidget {
  const HelperScreen({this.id = demoSasha, this.showHeader = true, super.key});
  final bool showHeader;
  final String id;
  @override
  ConsumerState<HelperScreen> createState() => _HelperScreenState();
}

class _HelperScreenState extends ConsumerState<HelperScreen> {
  bool openingChat = false, blocking = false, confirmingBlock = false;
  String? contactError, blockError;
  bool get busy => openingChat || blocking || confirmingBlock;

  Future<void> openChat() async {
    if (busy || widget.id == ref.read(communityRepositoryProvider).userId) {
      return;
    }
    setState(() {
      openingChat = true;
      contactError = null;
    });
    try {
      final cid = await ref.read(communityProvider.notifier).command('direct', {
        'target': widget.id,
      });
      if (cid == null) {
        throw StateError('Conversation unavailable');
      }
      if (mounted) {
        context.push('/chat/$cid');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => contactError =
              "Не удалось открыть переписку. Проверьте соединение и попробуйте снова."
                  .tr(context),
        );
      }
    } finally {
      if (mounted) {
        setState(() => openingChat = false);
      }
    }
  }

  Future<void> blockProfile(String name) async {
    if (busy || widget.id == ref.read(communityRepositoryProvider).userId) {
      return;
    }
    setState(() {
      confirmingBlock = true;
      blockError = null;
    });
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Заблокировать пользователя?".tr(context)),
        content: Text(
          "Личные сообщения пользователю «{p0}» будут недоступны.".tr(
            context,
            arguments: {'p0': name},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text("Отмена".tr(context)),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text("Заблокировать".tr(context)),
          ),
        ],
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() => confirmingBlock = false);
    if (confirmed != true) {
      return;
    }
    setState(() => blocking = true);
    try {
      await ref.read(communityProvider.notifier).command('block', {
        'target_id': widget.id,
      });
      if (mounted) {
        notice(context, "Пользователь заблокирован".tr(context));
        if (Navigator.of(context).canPop()) {
          Navigator.pop(context);
        } else {
          context.go('/walks');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => blockError =
              "Не удалось заблокировать пользователя. Проверьте соединение и попробуйте снова."
                  .tr(context),
        );
      }
    } finally {
      if (mounted) {
        setState(() => blocking = false);
      }
    }
  }

  void leaveProfile() {
    if (Navigator.of(context).canPop()) {
      Navigator.pop(context);
    } else {
      context.go('/walks');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityProvider);
    final repository = ref.watch(communityRepositoryProvider);
    final isSelf = widget.id == repository.userId;
    final title = isSelf
        ? "Ваш профиль помощника".tr(context)
        : "Профиль помощника".tr(context);
    final appBar = AppBar(
      title: Text(title, maxLines: 2),
      toolbarHeight: MediaQuery.textScalerOf(context).scale(24) * 2 + 12,
    );
    if (!state.hasValue && (state.isLoading || state.hasError)) {
      return Scaffold(
        appBar: widget.showHeader ? appBar : null,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.isLoading) ...[
                  Semantics(
                    label: "Загружаем профиль помощника".tr(context),
                    liveRegion: true,
                    child: CircularProgressIndicator(),
                  ),
                  const SizedBox(height: 16),
                  Text("Загружаем профиль…".tr(context)),
                ] else ...[
                  Text("Профиль не загрузился".tr(context)),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => ref.invalidate(communityProvider),
                    child: Text("Повторить загрузку".tr(context)),
                  ),
                  TextButton(
                    onPressed: leaveProfile,
                    child: Text("Назад".tr(context)),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    final data = state.value ?? {};
    final profile = findRow(data, 'profiles', widget.id);
    if (profile == null) {
      return Scaffold(
        appBar: widget.showHeader ? appBar : null,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Профиль недоступен".tr(context)),
              const SizedBox(height: 12),
              TextButton(
                onPressed: leaveProfile,
                child: Text("Назад".tr(context)),
              ),
            ],
          ),
        ),
      );
    }
    final name = '${profile['display_name'] ?? ''}'.trim();
    final ownPreferences = isSelf ? ref.watch(helperProfileProvider) : null;
    final helper = ownPreferences?.value;
    final district = isSelf && helper != null
        ? [
            helper.city.trim(),
            helper.district.trim(),
          ].where((v) => v.isNotEmpty).join(' · ')
        : '${profile['district'] ?? ''}'.trim();
    final bio =
        (isSelf && helper != null
                ? helper.introduction
                : '${profile['about'] ?? ''}')
            .trim();
    final ready =
        isSelf &&
        name.isNotEmpty &&
        helper != null &&
        helper.city.trim().isNotEmpty;
    Future<void> editProfile() async {
      await context.push('/helper/preferences');
      if (mounted) {
        ref.invalidate(helperProfileProvider);
        ref.invalidate(publicHelperPreferencesProvider(widget.id));
        ref.invalidate(communityProvider);
      }
    }

    final reviews =
        rows(data, 'walk_reviews')
            .where((r) => r['helper_id'] == widget.id && r['published'] == true)
            .toList()
          ..sort((a, b) {
            final earliest = DateTime.fromMillisecondsSinceEpoch(
              0,
              isUtc: true,
            );
            final order = (DateTime.tryParse('${b['created_at']}') ?? earliest)
                .compareTo(DateTime.tryParse('${a['created_at']}') ?? earliest);
            return order != 0 ? order : '${b['id']}'.compareTo('${a['id']}');
          });
    final reputation = HelperReputation.fromData(
      data,
      widget.id,
      demo: repository.isDemo,
    );
    final identityText = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            name.isEmpty ? "Помощник".tr(context) : name,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ),
        if (district.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(district, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
    final avatar = ExcludeSemantics(
      child: IdentityPicture(
        id: 'profile:${widget.id}',
        name: name,
        icon: Icons.person_outline,
        size: 64,
      ),
    );
    final stackIdentity =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(1) > 1.3;
    return Scaffold(
      appBar: widget.showHeader ? appBar : null,
      body: WalkingActionTheme(
        child: PageBody(
          children: [
            if (state.isLoading)
              LinearProgressIndicator(
                semanticsLabel: "Обновляем профиль".tr(context),
              ),
            if (state.hasError) ...[
              Text(
                "Не удалось обновить профиль. Показаны ранее загруженные сведения."
                    .tr(context),
              ),
              TextButton(
                onPressed: () => ref.invalidate(communityProvider),
                child: Text("Повторить загрузку".tr(context)),
              ),
            ],
            if (stackIdentity)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [avatar, const SizedBox(height: 12), identityText],
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  avatar,
                  const SizedBox(width: 16),
                  Expanded(child: identityText),
                ],
              ),
            if (bio.isNotEmpty) ...[const SizedBox(height: 12), Text(bio)],
            const SizedBox(height: 20),
            Semantics(
              header: true,
              child: Text(
                "Опыт как помощника".tr(context),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            WalkingExperienceSummary(
              reputation: reputation,
              onRetry: () => ref.invalidate(communityProvider),
              compactEmpty: isSelf,
            ),
            if (!isSelf) HelperPreferences(id: widget.id),
            const SizedBox(height: 12),
            if (!isSelf)
              Text(
                "Отзывы и опыт помогают принять решение, но не гарантируют безопасность."
                    .tr(context),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 12),
            if (isSelf) ...[
              if (helper != null) ...[
                MetadataLine(
                  items: [
                    helper.accepting
                        ? "Готов обсуждать прогулки".tr(context)
                        : "Сейчас не принимает новые запросы".tr(context),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              if (ownPreferences?.hasError == true)
                Text(
                  "Ваш город и предпочтения недоступны. Повторите загрузку.".tr(
                    context,
                  ),
                ),
              if (ownPreferences?.isLoading == true)
                LinearProgressIndicator(
                  semanticsLabel: "Загружаем предпочтения помощника".tr(
                    context,
                  ),
                ),
              if (!ready &&
                  ownPreferences?.hasError != true &&
                  ownPreferences?.isLoading != true)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    "Профиль помощника ещё не заполнен. Укажите имя и город, чтобы владельцы могли познакомиться с вами."
                        .tr(context),
                  ),
                ),
              if (ready)
                FilledButton.icon(
                  key: const Key('helper-find-requests'),
                  onPressed: () => context.go('/requests'),
                  icon: const Icon(Icons.search),
                  label: Text("Посмотреть запросы".tr(context)),
                ),
              if (ownPreferences?.hasError == true)
                TextButton(
                  onPressed: () => ref.invalidate(helperProfileProvider),
                  child: Text("Повторить загрузку".tr(context)),
                ),
              if (ready ||
                  ownPreferences?.hasError == true ||
                  ownPreferences?.isLoading == true)
                TextButton.icon(
                  onPressed: editProfile,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  label: Text("Редактировать профиль".tr(context)),
                )
              else
                FilledButton(
                  onPressed: editProfile,
                  child: Text("Редактировать профиль".tr(context)),
                ),
            ] else ...[
              FilledButton(
                onPressed: busy ? null : openChat,
                child: Text(
                  openingChat
                      ? "Открываем чат…".tr(context)
                      : "Обсудить прогулку".tr(context),
                ),
              ),
              if (contactError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      contactError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: PopupMenuButton<String>(
                  tooltip: "Действия с профилем".tr(context),
                  enabled: !busy,
                  onSelected: (value) {
                    if (value == 'report') {
                      context.push('/report/profile/${widget.id}');
                    } else {
                      blockProfile(
                        name.isEmpty ? "Помощник".tr(context) : name,
                      );
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'report',
                      child: Text("Пожаловаться на профиль".tr(context)),
                    ),
                    PopupMenuItem(
                      value: 'block',
                      child: Text(
                        "Заблокировать".tr(context),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.more_horiz, size: 20),
                          SizedBox(width: 8),
                          Flexible(child: Text("Действия".tr(context))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (blocking)
                Semantics(
                  liveRegion: true,
                  child: Text("Блокируем пользователя…".tr(context)),
                ),
              if (blockError != null) ...[
                Semantics(
                  liveRegion: true,
                  child: Text(
                    blockError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: busy
                      ? null
                      : () => blockProfile(
                          name.isEmpty ? "Помощник".tr(context) : name,
                        ),
                  child: Text("Повторить блокировку".tr(context)),
                ),
              ],
            ],
            const SizedBox(height: 12),
            if (isSelf) ...[
              HelperPreferences(id: widget.id, isSelf: true, showStatus: false),
              const SizedBox(height: 12),
              Text(
                "Отзывы и опыт помогают принять решение, но не гарантируют безопасность."
                    .tr(context),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            WalkingExperienceExplanation(isSelf: isSelf),
            if (reviews.isNotEmpty || !isSelf || reputation.reviewCount == null)
              SectionTitle("Отзывы о выгуле".tr(context)),
            if (reviews.isEmpty && !isSelf)
              WalkingEmptyState(reputation: reputation, isSelf: isSelf),
            if (reviews.isEmpty && isSelf && reputation.reviewCount == 0)
              Text(
                "Первый отзыв появится после подтверждённой прогулки.".tr(
                  context,
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            for (final review in reviews)
              WalkingReviewTile(
                key: ValueKey('walking-review-${review['id']}'),
                review: review,
                author: findRow(data, 'profiles', review['author_id']),
                isSelf: isSelf,
                replyEditor: isSelf
                    ? ReplyToReview(
                        key: ValueKey('reply-${review['id']}'),
                        review: review,
                      )
                    : null,
              ),
            if (isSelf) ...[
              if (ref.watch(accountModeProvider).value?.canOwn == true)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text("Репутация как владелец".tr(context)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/owner/${widget.id}'),
                ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text("Роли и режим".tr(context)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/roles'),
              ),
            ],
            if (repository.isDemo) const DemoCaption(),
          ],
        ),
      ),
    );
  }
}

Future<void> showWalkingReviewSheet(
  BuildContext context, {
  required String id,
  String role = 'helper',
}) => showModalBottomSheet<void>(
  context: context,
  useRootNavigator: true,
  sheetAnimationStyle: studioSheetAnimation(context),
  isScrollControlled: true,
  clipBehavior: Clip.antiAlias,
  showDragHandle: false,
  useSafeArea: true,
  isDismissible: false,
  enableDrag: false,
  builder: (context) => FractionallySizedBox(
    heightFactor: MediaQuery.textScalerOf(context).scale(16) > 21 ? .92 : .74,
    child: ReviewScreen(id: id, role: role, embedded: true),
  ),
);

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({
    required this.id,
    this.role = 'helper',
    this.embedded = false,
    super.key,
  });
  final bool embedded;
  final String role;
  final String id;
  @override
  ConsumerState<ReviewScreen> createState() => _ReviewState();
}

class _ReviewState extends ConsumerState<ReviewScreen> {
  int? rating;
  bool saving = false;
  final comment = TextEditingController();
  String? draftAccount;
  String get draftKey => 'review:${widget.role}:${widget.id}';
  @override
  void initState() {
    super.initState();
    draftAccount = ref.read(communityRepositoryProvider).userId;
    final draft = ref.read(walkingFormDraftsProvider)[draftKey];
    rating = draft?.rating;
    comment.text = draft?.text ?? '';
  }

  @override
  void dispose() {
    comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(communityProvider).value ?? {};
    final uid = ref.watch(communityRepositoryProvider).userId;
    if (uid != draftAccount) {
      draftAccount = uid;
      rating = null;
      comment.clear();
    }
    final request = findRow(data, 'walk_requests', widget.id);
    final agreement = rows(
      data,
      'walk_agreements',
    ).where((a) => a['request_id'] == widget.id).firstOrNull;
    final target = widget.role == 'owner'
        ? (request?['owner_id'])
        : (agreement?['helper_id']);
    final name =
        findRow(data, 'profiles', target)?['display_name'] ??
        (widget.role == 'owner'
            ? "Владелец".tr(context)
            : "Помощник".tr(context));
    final eligible = canReviewAgreement(
      data,
      widget.id,
      uid,
      owner: widget.role == 'owner',
    );
    return PopScope(
      canPop: !saving,
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          titleSpacing: 20,
          toolbarHeight: MediaQuery.textScalerOf(context).scale(24) * 2 + 12,
          title: Text('Отзыв о прогулке'.tr(context), maxLines: 2),
          automaticallyImplyLeading: !widget.embedded,
          actions: widget.embedded
              ? [
                  IconButton(
                    tooltip: 'Закрыть'.tr(context),
                    onPressed: saving ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ]
              : null,
        ),
        body: WalkingActionTheme(
          child: PageBody(
            children: [
              if (request != null)
                Text(
                  [
                    findRow(data, 'pets', request['pet_id'])?['name'] ??
                        'Питомец'.tr(context),
                    walkingShortTime(context, request, duration: false),
                    name,
                  ].join(' · '),
                ),
              if (!eligible)
                Text(
                  "Отзыв доступен участнику после подтверждения владельца, один раз по каждой договорённости."
                      .tr(context),
                ),
              const SizedBox(height: 20),
              Semantics(
                label: 'Оценка'.tr(context),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  children: [
                    for (final n in [1, 2, 3, 4, 5])
                      IconButton(
                        key: ValueKey('walking-review-star-$n'),
                        tooltip: '$n / 5',
                        isSelected: rating != null && n <= rating!,
                        selectedIcon: const Icon(Icons.star_rounded),
                        icon: const Icon(Icons.star_outline_rounded),
                        onPressed: saving || !eligible
                            ? null
                            : () {
                                ref
                                    .read(walkingFormDraftsProvider.notifier)
                                    .keep(draftKey, rating: n);
                                setState(() => rating = n);
                              },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                textAlignVertical: TextAlignVertical.top,
                controller: comment,
                onChanged: (text) => ref
                    .read(walkingFormDraftsProvider.notifier)
                    .keep(draftKey, text: text),
                enabled: !saving && eligible,
                maxLength: 1000,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: "Комментарий".tr(context),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "Отзыв будет публичным. Не указывайте адреса и контакты.".tr(
                  context,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: saving || rating == null || !eligible
                    ? null
                    : () async {
                        final account = ref
                            .read(communityRepositoryProvider)
                            .userId;
                        setState(() => saving = true);
                        try {
                          await ref
                              .read(walkingRepositoryProvider)
                              .review(
                                widget.id,
                                rating!,
                                comment.text.trim(),
                                owner: widget.role == 'owner',
                              );
                          if (context.mounted) {
                            if (ref.read(communityRepositoryProvider).userId !=
                                account) {
                              return;
                            }
                            ref
                                .read(walkingFormDraftsProvider.notifier)
                                .clear(draftKey);
                            setState(() => saving = false);
                            Navigator.pop(context);
                          }
                        } catch (_) {
                          if (context.mounted) {
                            notice(
                              context,
                              "Не удалось опубликовать отзыв. Текст сохранён — проверьте соединение и повторите."
                                  .tr(context),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => saving = false);
                          }
                        }
                      },
                child: Text(
                  saving
                      ? "Публикуем…".tr(context)
                      : "Опубликовать".tr(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WalkFact extends StatelessWidget {
  const WalkFact(this.icon, this.text, {super.key});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16),
      const SizedBox(width: 6),
      Flexible(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
    ],
  );
}

class HelperReputationText extends StatelessWidget {
  const HelperReputationText({
    required this.data,
    required this.id,
    required this.demo,
    super.key,
  });
  final CommunityData data;
  final String id;
  final bool demo;
  @override
  Widget build(BuildContext context) {
    final r = HelperReputation.fromData(data, id, demo: demo);
    return Text(
      '${r.localizedReviewLabel(context.languageCode)}\n${r.localizedCompletedLabel(context.languageCode)}',
    );
  }
}

class ReplyToReview extends ConsumerStatefulWidget {
  const ReplyToReview({required this.review, super.key});
  final Json review;
  @override
  ConsumerState<ReplyToReview> createState() => _ReplyToReviewState();
}

class _ReplyToReviewState extends ConsumerState<ReplyToReview> {
  final text = TextEditingController();
  bool editing = false;
  String get reviewId => widget.review['id'] as String;
  @override
  void initState() {
    super.initState();
    text.text =
        ref.read(reviewReplyDraftsProvider)[reviewId]?.text ??
        widget.review['helper_reply'] ??
        '';
  }

  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  Future<void> publish() async {
    final success = await ref
        .read(reviewReplyDraftsProvider.notifier)
        .publish(reviewId, text.text);
    if (success && mounted) {
      setState(() => editing = false);
      notice(context, "Ответ опубликован".tr(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(reviewReplyDraftsProvider)[reviewId];
    final saving = draft?.pending ?? false;
    final error = draft?.error;
    if (!editing) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (error != null)
            Semantics(
              liveRegion: true,
              child: Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          WalkingRowActions(
            trailing: OutlinedButton.icon(
              icon: const Icon(Icons.reply_outlined, size: 18),
              onPressed: saving
                  ? null
                  : () {
                      text.text =
                          ref.read(reviewReplyDraftsProvider)[reviewId]?.text ??
                          widget.review['helper_reply'] ??
                          '';
                      setState(() => editing = true);
                    },
              label: Semantics(
                liveRegion: saving,
                child: Text(
                  saving
                      ? "Публикуем…".tr(context)
                      : (widget.review['helper_reply'] ?? '').toString().isEmpty
                      ? 'Ответить'.tr(context)
                      : "Изменить ответ".tr(context),
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        TextField(
          key: ValueKey('reply-input-$reviewId'),
          controller: text,
          enabled: !saving,
          minLines: 2,
          maxLines: 4,
          maxLength: 1000,
          onChanged: (value) => ref
              .read(reviewReplyDraftsProvider.notifier)
              .keep(reviewId, value),
          decoration: InputDecoration(labelText: "Ответ на отзыв".tr(context)),
        ),
        const SizedBox(height: 8),
        Text(
          "Ответ будет публичным. Не указывайте адреса и инструкции по уходу."
              .tr(context),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (error != null) ...[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
        const SizedBox(height: 12),
        FilledButton(
          onPressed: saving ? null : publish,
          child: Semantics(
            liveRegion: saving,
            child: Text(
              saving
                  ? "Публикуем…".tr(context)
                  : "Опубликовать ответ".tr(context),
            ),
          ),
        ),
        OutlinedButton(
          onPressed: saving ? null : () => setState(() => editing = false),
          child: Text("Отмена".tr(context)),
        ),
      ],
    );
  }
}

class WalkProgressView extends StatelessWidget {
  const WalkProgressView({required this.progress, super.key});
  final WalkProgress progress;

  @override
  Widget build(BuildContext context) {
    final stage = progress.stage;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (stage != null) ...[
          Semantics(
            header: true,
            label: "Этап {p0} из {p1}: {p2}".tr(
              context,
              arguments: {
                'p0': stage + 1,
                'p1': WalkProgress.stages.length,
                'p2': WalkProgress.stages[stage].tr(context),
              },
            ),
            child: ExcludeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      WalkProgress.stages[stage].tr(context),
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${stage + 1} / ${WalkProgress.stages.length}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ExcludeSemantics(
            child: Row(
              key: const Key('walk-progress-rail'),
              children: [
                for (var i = 0; i < WalkProgress.stages.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      height: i == stage ? 6 : 4,
                      decoration: BoxDecoration(
                        color: i <= stage
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(3),
                        border: i == stage
                            ? Border.all(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: .4,
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              final scale = MediaQuery.textScalerOf(context).scale(1);
              final inline = scale <= 1.2 && constraints.maxWidth >= 300;
              Widget label(int i, {required bool centered}) => Semantics(
                label:
                    '${i + 1}. ${WalkProgress.stages[i].tr(context)}, ${i < stage
                        ? 'завершён'.tr(context)
                        : i == stage
                        ? 'текущий этап'.tr(context)
                        : 'предстоит'.tr(context)}',
                child: ExcludeSemantics(
                  child: Text(
                    WalkProgress.stages[i].tr(context),
                    textAlign: centered ? TextAlign.center : TextAlign.left,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: i == stage
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: i == stage
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              );
              if (inline) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < WalkProgress.stages.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(child: label(i, centered: true)),
                    ],
                  ],
                );
              }
              final width = scale > 1.6 || constraints.maxWidth < 280
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 16) / 2;
              return Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < WalkProgress.stages.length; i++)
                    SizedBox(
                      width: width,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ExcludeSemantics(
                            child: Icon(
                              i < stage
                                  ? Icons.check
                                  : i == stage
                                  ? Icons.arrow_forward
                                  : Icons.remove,
                              size: 16,
                              color: i == stage
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(child: label(i, centered: false)),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
        ],
        Text(
          progress.instruction.tr(context),
          key: const Key('walk-next-step'),
        ),
      ],
    );
  }
}

class HelperPreferences extends ConsumerWidget {
  const HelperPreferences({
    required this.id,
    this.isSelf = false,
    this.showStatus = true,
    super.key,
  });
  final String id;
  final bool isSelf;
  final bool showStatus;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<HelperProfile?> state = isSelf
        ? ref.watch(helperProfileProvider)
        : ref
              .watch(publicHelperPreferencesProvider(id))
              .whenData(
                (data) => data == null ? null : HelperProfile.fromJson(data),
              );
    return state.when(
      loading: () => LinearProgressIndicator(
        semanticsLabel: "Загружаем предпочтения помощника".tr(context),
      ),
      error: (e, s) => TextButton(
        onPressed: () {
          if (isSelf) {
            ref.invalidate(helperProfileProvider);
          } else {
            ref.invalidate(publicHelperPreferencesProvider(id));
          }
        },
        child: Text("Предпочтения недоступны · повторить".tr(context)),
      ),
      data: (p) {
        if (p == null) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              "Предпочтения пока не указаны".tr(context),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }
        final zoneLabel = p.availability.isEmpty
            ? null
            : timeZoneLabel(p.timeZone, locale: context.languageCode);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            if (showStatus)
              MetadataLine(
                items: [
                  p.accepting
                      ? "Готов обсуждать прогулки".tr(context)
                      : "Сейчас не принимает новые запросы".tr(context),
                ],
              ),
            const SizedBox(height: 8),
            Text(
              p.serviceDistricts.isEmpty
                  ? "Районы пока не указаны".tr(context)
                  : "Районы: {p0}".tr(
                      context,
                      arguments: {'p0': p.serviceDistricts.join(', ')},
                    ),
            ),
            const SizedBox(height: 8),
            if (p.availability.isEmpty)
              Text("Время обсудим в переписке".tr(context)),
            for (final a in p.availability)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${DateFormat.E(context.languageCode).format(DateTime.utc(2026, 10, 5 + a.day))} ${(a.start ~/ 60).toString().padLeft(2, '0')}:${(a.start % 60).toString().padLeft(2, '0')}–${(a.end ~/ 60).toString().padLeft(2, '0')}:${(a.end % 60).toString().padLeft(2, '0')}',
                ),
              ),
            if (p.availability.isNotEmpty)
              Text(
                "Время в {p0}".tr(context, arguments: {'p0': zoneLabel}),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text("Предпочтения и доступность".tr(context)),
              children: [
                if (!isSelf && p.city.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      [
                        p.city,
                        p.district,
                      ].where((v) => v.isNotEmpty).join(' · '),
                    ),
                  ),
                if (p.experience.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(p.experience),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    p.dogSizes.isEmpty
                        ? "Предпочтения пока не указаны".tr(context)
                        : "Размер собак: {p0}".tr(
                            context,
                            arguments: {
                              'p0': p.dogSizes
                                  .map(
                                    (v) => switch (v) {
                                      'small' => 'Небольшие'.tr(context),
                                      'medium' => 'Средние'.tr(context),
                                      _ => 'Крупные'.tr(context),
                                    },
                                  )
                                  .join(', '),
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Доступность — предпочтение, а не обещание записи.".tr(
                      context,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
