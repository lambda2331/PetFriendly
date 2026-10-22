import '../../core/ui/components.dart';
import '../../core/ui/studio_review.dart';
import '../../core/ui/studio_pickers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/studio_theme.dart';
import '../community/presentation/forms.dart';
import '../community/presentation/social_components.dart';
import 'walking_chat_widgets.dart';
import 'walking_chat_controller.dart';
import 'walking_studio_components.dart';
import 'walking_conditions_screen.dart';
import '../../core/media/preview_photos.dart';
import '../../core/time/display_time.dart';
import '../../l10n/localization.dart';
import '../community/data/community_repository.dart';
import 'account_mode.dart';
import 'helper_reputation.dart';
import 'owner_profile_screen.dart' show OwnerReviewReply;
import 'personal_walking_controller.dart';
import 'walking_repository.dart';
import 'walks_screen.dart'
    show
        walkStatus,
        ReplyToReview,
        showWalkingReviewSheet,
        showWalkRequestSheet;

export 'personal_walking_controller.dart' show PersonalWalkingTab;

class PersonalWalkingHub extends ConsumerStatefulWidget {
  const PersonalWalkingHub({
    this.initialTab,
    this.initialProfileRole,
    super.key,
  });
  final PersonalWalkingTab? initialTab;
  final String? initialProfileRole;
  @override
  ConsumerState<PersonalWalkingHub> createState() => _PersonalWalkingHubState();
}

class _PersonalWalkingHubState extends ConsumerState<PersonalWalkingHub> {
  final bucket = PageStorageBucket();
  String historySearch = "";
  final currentSearch = TextEditingController();
  String currentKind = 'all', currentDate = 'all', historyDate = 'all';
  bool matchesDate(Json item, String filter) {
    if (filter == 'all' || filter == 'range') return true;
    final date = walkingVenueDate(item);
    final zone =
        item['time_zone'] as String? ?? cityTimeZone(item['city'] as String?);
    if (date == null || !validTimeZone(zone)) return false;
    final now = venueDateTime(DateTime.now(), zone!);
    final day = DateTime.utc(date.year, date.month, date.day),
        today = DateTime.utc(now.year, now.month, now.day);
    if (filter == 'today') return day == today;
    if (filter == 'week') {
      final delta = day.difference(today).inDays;
      return delta >= 0 && delta < 7;
    }
    final month = DateTime.utc(
      now.year,
      now.month - (filter == 'last' ? 1 : 0),
    );
    return date.year == month.year && date.month == month.month;
  }

  Future<void> filtersSheet({bool history = false}) async {
    var kind = currentKind, date = history ? historyDate : currentDate;
    var period = ref.read(personalWalkingProvider).period;
    await showStudioSelectionSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, update) => StudioReviewSheet(
          title: 'Фильтры'.tr(ctx),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!history) ...[
                Text('Показать'.tr(ctx), style: studioIdentityText),
                RadioGroup<String>(
                  groupValue: kind,
                  onChanged: (v) {
                    if (v != null) update(() => kind = v);
                  },
                  child: Column(
                    children: [
                      for (final option in [
                        ('all', 'Все'),
                        ('agreements', 'Прогулки'),
                        ('requests', 'Мои запросы'),
                        ('applications', 'Мои отклики'),
                      ])
                        RadioListTile<String>(
                          value: option.$1,
                          title: Text(option.$2.tr(ctx)),
                          contentPadding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text('Дата'.tr(ctx), style: studioIdentityText),
              RadioGroup<String>(
                groupValue: date,
                onChanged: (v) {
                  if (v != null) update(() => date = v);
                },
                child: Column(
                  children: [
                    for (final option
                        in history
                            ? [
                                ('all', 'Все даты'),
                                ('month', 'В этом месяце'),
                                ('last', 'В прошлом месяце'),
                                ('range', 'Выбрать период'),
                              ]
                            : [
                                ('all', 'Все даты'),
                                ('today', 'Сегодня'),
                                ('week', 'Ближайшие 7 дней'),
                              ])
                      RadioListTile<String>(
                        value: option.$1,
                        title: Text(option.$2.tr(ctx)),
                        contentPadding: EdgeInsets.zero,
                      ),
                  ],
                ),
              ),
              if (history && date == 'range')
                OutlinedButton(
                  onPressed: () async {
                    final start = await showStudioDatePicker(
                      context: ctx,
                      initialDate: period?.start ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 366)),
                    );
                    if (start == null || !ctx.mounted) return;
                    final end = await showStudioDatePicker(
                      context: ctx,
                      initialDate: period?.end ?? start,
                      firstDate: start,
                      lastDate: DateTime.now().add(const Duration(days: 366)),
                    );
                    if (end != null && ctx.mounted) {
                      update(() => period = WalkingPeriod(start, end));
                    }
                  },
                  child: Text(
                    period == null
                        ? 'Выбрать период'.tr(ctx)
                        : '${DateFormat.yMd(ctx.languageCode).format(period!.start)} – ${DateFormat.yMd(ctx.languageCode).format(period!.end)}',
                  ),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => update(() {
                      kind = 'all';
                      date = 'all';
                      period = null;
                    }),
                    child: Text('Сбросить'.tr(ctx)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: history && date == 'range' && period == null
                          ? null
                          : () {
                              setState(() {
                                if (history) {
                                  historyDate = date;
                                } else {
                                  currentKind = kind;
                                  currentDate = date;
                                }
                              });
                              if (history) {
                                ref
                                    .read(personalWalkingProvider.notifier)
                                    .setPeriod(date == 'range' ? period : null);
                              }
                              Navigator.pop(ctx);
                            },
                      child: Text('Применить'.tr(ctx)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  final historySearchController = TextEditingController();
  final scrollControllers = <PersonalWalkingTab, ScrollController>{};
  @override
  void initState() {
    super.initState();
    final offsets = ref.read(personalWalkingScrollProvider);
    for (final tab in PersonalWalkingTab.values) {
      final controller = ScrollController(
        initialScrollOffset: offsets[tab] ?? 0,
        keepScrollOffset: false,
      );
      controller.addListener(() => offsets[tab] = controller.offset);
      scrollControllers[tab] = controller;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = ref.read(personalWalkingProvider.notifier);
      if (widget.initialTab != null) controller.select(widget.initialTab!);
      if (widget.initialProfileRole != null) {
        controller.selectRole(widget.initialProfileRole!);
      }
      for (final view in ['active', 'applications', 'history']) {
        if (ref.read(personalWalkingProvider).pages[view]?.loaded != true) {
          controller.load(view);
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant PersonalWalkingHub oldWidget) {
    super.didUpdateWidget(oldWidget);
    final tab = widget.initialTab != oldWidget.initialTab
        ? widget.initialTab
        : null;
    final role = widget.initialProfileRole != oldWidget.initialProfileRole
        ? widget.initialProfileRole
        : null;
    if (tab == null && role == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = ref.read(personalWalkingProvider.notifier);
      if (tab != null && widget.initialTab == tab) controller.select(tab);
      if (role != null && widget.initialProfileRole == role) {
        controller.selectRole(role);
      }
    });
  }

  @override
  void dispose() {
    historySearchController.dispose();
    currentSearch.dispose();
    for (final controller in scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(personalWalkingProvider);
    final mode = ref.watch(accountModeProvider).value;
    final repository = ref.watch(communityRepositoryProvider);
    final data = ref.watch(communityProvider);
    final uid = repository.userId;
    final profile = findRow(data.value ?? {}, 'profiles', uid);
    final helper = mode?.isHelper == true;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  (helper ? 'Мои прогулки' : 'Выгул').tr(context),
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
              ),
              if (mode?.canOwn == true && !helper)
                IconButton(
                  key: const ValueKey('walking-create'),
                  tooltip: 'Попросить о выгуле'.tr(context),
                  onPressed: _create,
                  icon: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      size: 22,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: PersonalWalkingTabs(
            value: state.tab,
            onChanged: ref.read(personalWalkingProvider.notifier).select,
          ),
        ),
        if (state.tab == PersonalWalkingTab.current) _currentTools(),
        if (state.tab == PersonalWalkingTab.history) _historyTools(),
        Expanded(
          child: PageStorage(
            bucket: bucket,
            child: RefreshIndicator(
              onRefresh: ref.read(personalWalkingProvider.notifier).refresh,
              child: ListView(
                controller: scrollControllers[state.tab],
                key: PageStorageKey('personal-walking-$uid-${state.tab.name}'),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  if (state.tab == PersonalWalkingTab.profile) ...[
                    _HubIdentity(id: uid, profile: profile),
                    const SizedBox(height: 16),
                  ],
                  if (state.tab == PersonalWalkingTab.current)
                    ..._current(state, mode)
                  else if (state.tab == PersonalWalkingTab.history)
                    ..._history(state)
                  else if (uid != null)
                    _WalkingOwnProfile(
                      id: uid,
                      role: state.profileRole ?? (helper ? 'helper' : 'owner'),
                    )
                  else
                    Text('Профиль сейчас недоступен'.tr(context)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _currentTools() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('walking-current-search'),
                controller: currentSearch,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Питомец, участник'.tr(context),
                  prefixIcon: const Icon(Icons.search),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              tooltip: 'Фильтры'.tr(context),
              onPressed: filtersSheet,
              icon: const Icon(Icons.filter_list),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    ),
  );

  List<Widget> _current(PersonalWalkingState state, AccountMode? mode) {
    final page = state.pages['active'] ?? const WalkingPage();
    bool visible(Json item) =>
        matchesDate(item, currentDate) &&
        '${item['pet']} ${item['owner']} ${item['helper']} ${item['district']}'
            .toLowerCase()
            .contains(currentSearch.text.trim().toLowerCase());
    final agreements = personalAgreements(page.items).where(visible).toList();
    final own = page.items
        .where(
          (w) => w['my_role'] == 'owner' && w['status'] == 'open' && visible(w),
        )
        .toList();
    final applications = state.pages['applications'] ?? const WalkingPage();
    return [
      if (page.loaded &&
          (currentSearch.text.isNotEmpty ||
              currentKind != 'all' ||
              currentDate != 'all') &&
          ![
            if (currentKind == 'all' || currentKind == 'agreements')
              ...agreements,
            if (currentKind == 'all' || currentKind == 'requests') ...own,
            if (currentKind == 'all' || currentKind == 'applications')
              ...applications.items.where(visible),
          ].any((_) => true))
        SocialContentState(
          centered: true,
          title: 'Прогулки не найдены'.tr(context),
          actionLabel: 'Сбросить'.tr(context),
          onAction: () => setState(() {
            currentSearch.clear();
            currentKind = 'all';
            currentDate = 'all';
          }),
        ),
      _PageStatus(
        page: page,
        onRetry: () => ref
            .read(personalWalkingProvider.notifier)
            .load('active', refresh: true),
      ),
      if (currentKind == 'all' || currentKind == 'agreements')
        ...agreements.map((item) => _PersonalWalkRow(item: item)),
      if (page.loaded &&
          page.error == null &&
          !page.hasMore &&
          agreements.isEmpty &&
          own.isEmpty)
        SocialContentState(
          centered: true,
          icon: Icons.pets_outlined,
          title: 'Пока нет прогулок'.tr(context),
          message:
              (mode?.isHelper == true
                      ? 'Выберите запрос, чтобы помочь с прогулкой.'
                      : 'Попросите соседей о помощи с прогулкой.')
                  .tr(context),
          actionLabel:
              (mode?.isHelper == true
                      ? 'Найти запрос на выгул'
                      : 'Попросить о выгуле')
                  .tr(context),
          onAction: mode?.isHelper == true
              ? () => context.go('/requests')
              : mode?.canOwn == true
              ? _create
              : null,
        ),
      if ((currentKind == 'all' || currentKind == 'requests') &&
          mode?.canOwn == true &&
          mode?.isHelper != true) ...[
        const SizedBox(height: 20),
        if (own.isNotEmpty) _heading('Мои запросы'),
        ...own.map((item) => _PersonalWalkRow(item: item)),
      ],
      _MoreWalking(
        page: page,
        onMore: () => ref.read(personalWalkingProvider.notifier).load('active'),
      ),
      if ((currentKind == 'all' || currentKind == 'applications') &&
          mode?.isHelper == true &&
          (applications.items.isNotEmpty ||
              applications.error != null ||
              !applications.loaded)) ...[
        const SizedBox(height: 20),
        _heading('Мои отклики'),

        _PageStatus(
          page: applications,
          onRetry: () => ref
              .read(personalWalkingProvider.notifier)
              .load('applications', refresh: true),
        ),
        ...applications.items
            .where((w) => w['my_role'] == 'applicant' && visible(w))
            .map((item) => _PersonalWalkRow(item: item)),
        if (applications.loaded &&
            !applications.items.any((w) => w['my_role'] == 'applicant'))
          SocialContentState(
            centered: true,
            icon: Icons.chat_bubble_outline,
            title: 'Пока нет отправленных откликов'.tr(context),
            message: 'Отклики на запросы появятся здесь.'.tr(context),
          ),
        _MoreWalking(
          page: applications,
          onMore: () =>
              ref.read(personalWalkingProvider.notifier).load('applications'),
        ),
        OutlinedButton(
          onPressed: () => context.go('/requests'),
          child: Text('Найти запрос на выгул'.tr(context)),
        ),
      ],
    ];
  }

  Future<void> _create() async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      clipBehavior: Clip.antiAlias,
      sheetAnimationStyle: studioSheetAnimation(context),
      showDragHandle: false,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => const FractionallySizedBox(
        heightFactor: .88,
        child: EditScreen(kind: 'walk', embedded: true),
      ),
    );
    if (mounted) {
      ref.read(personalWalkingProvider.notifier).load('active', refresh: true);
    }
  }

  Widget _historyTools() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('walking-history-search'),
                controller: historySearchController,
                onChanged: (text) => setState(() => historySearch = text),
                decoration: InputDecoration(
                  hintText: 'Питомец, участник'.tr(context),
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: StudioColors.of(context).tint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              tooltip: 'Фильтры'.tr(context),
              onPressed: () => filtersSheet(history: true),
              icon: const Icon(Icons.filter_list),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    ),
  );

  List<Widget> _history(PersonalWalkingState state) {
    final page = state.pages['history'] ?? const WalkingPage();
    final items =
        page.items
            .where(
              (item) =>
                  (state.period?.includes(item) ?? true) &&
                  matchesDate(item, historyDate) &&
                  [item['pet'], item['owner'], item['helper'], item['district']]
                      .join(' ')
                      .toLowerCase()
                      .contains(historySearch.trim().toLowerCase()),
            )
            .toList()
          ..sort((a, b) => '${b['starts_at']}'.compareTo('${a['starts_at']}'));
    return [
      _PageStatus(
        page: page,
        onRetry: () => ref
            .read(personalWalkingProvider.notifier)
            .load('history', refresh: !page.loaded),
      ),
      ...items.map((item) => _PersonalWalkRow(item: item, history: true)),
      if (page.loaded && page.error == null && items.isEmpty)
        page.items.isEmpty &&
                state.period == null &&
                historySearch.trim().isEmpty
            ? SocialContentState(
                centered: true,
                icon: Icons.history,
                title: 'Пока нет прогулок'.tr(context),
                message: 'Завершённые и отменённые прогулки появятся здесь.'.tr(
                  context,
                ),
              )
            : SocialContentState(
                centered: true,
                icon: Icons.search_off,
                title: 'Прогулки не найдены'.tr(context),
                message: 'Измените поиск или фильтр даты'.tr(context),
                actionLabel: 'Сбросить'.tr(context),
                onAction: () {
                  historySearchController.clear();
                  setState(() {
                    historySearch = '';
                    historyDate = 'all';
                  });
                  ref.read(personalWalkingProvider.notifier).setPeriod(null);
                },
              ),
      _MoreWalking(
        page: page,
        onMore: () =>
            ref.read(personalWalkingProvider.notifier).load('history'),
      ),
    ];
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 12),
    child: Text(text.tr(context), style: walkingIdentityStyle),
  );
}

class PersonalWalkingTabs extends StatelessWidget {
  const PersonalWalkingTabs({
    required this.value,
    required this.onChanged,
    super.key,
  });
  final PersonalWalkingTab value;
  final ValueChanged<PersonalWalkingTab> onChanged;
  @override
  Widget build(BuildContext context) => StudioSegmentTabs<PersonalWalkingTab>(
    entries: {
      PersonalWalkingTab.current: 'Текущие'.tr(context),
      PersonalWalkingTab.history: 'История'.tr(context),
      PersonalWalkingTab.profile: 'Отзывы'.tr(context),
    },
    value: value,
    onChanged: onChanged,
  );
}

class _HubIdentity extends StatelessWidget {
  const _HubIdentity({required this.id, required this.profile});
  final String? id;
  final Json? profile;
  @override
  Widget build(BuildContext context) => Row(
    key: const ValueKey('walking-review-identity'),
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      IdentityPicture(
        id: 'profile:$id',
        name: '${profile?['display_name'] ?? ''}',
        icon: Icons.person_outline,
        size: 56,
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          '${profile?['display_name'] ?? '…'}',
          style: walkingIdentityStyle,
        ),
      ),
      const _WalkingConditionsLink(),
    ],
  );
}

class _WalkingConditionsLink extends ConsumerWidget {
  const _WalkingConditionsLink();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      key: const ValueKey('walking-conditions-link'),
      tooltip: 'Условия прогулок'.tr(context),
      icon: const Icon(Icons.edit_outlined, size: 22),
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        useRootNavigator: true,
        useSafeArea: true,
        showDragHandle: false,
        clipBehavior: Clip.antiAlias,
        sheetAnimationStyle: studioSheetAnimation(context),
        isScrollControlled: true,
        builder: (_) => const WalkingConditionsScreen(embedded: true),
      ),
    );
  }
}

class _PageStatus extends StatelessWidget {
  const _PageStatus({required this.page, required this.onRetry});
  final WalkingPage page;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (page.loading && !page.loaded) const WalkingLoadingState(),
      if (page.error != null && !page.loaded) ...[
        Text('Не удалось загрузить прогулки.'.tr(context)),
        TextButton(
          onPressed: onRetry,
          child: Text('Повторить загрузку'.tr(context)),
        ),
      ],
    ],
  );
}

class _MoreWalking extends StatelessWidget {
  const _MoreWalking({required this.page, required this.onMore});
  final WalkingPage page;
  final VoidCallback onMore;
  @override
  Widget build(BuildContext context) =>
      page.hasMore || (page.loaded && page.error != null)
      ? Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (page.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text('Не удалось загрузить прогулки.'.tr(context)),
                ),
              if (page.loading) const LinearProgressIndicator(),
              OutlinedButton(
                onPressed: page.loading ? null : onMore,
                child: Text(
                  (page.error == null ? 'Загрузить ещё' : 'Повторить загрузку')
                      .tr(context),
                ),
              ),
            ],
          ),
        )
      : const SizedBox.shrink();
}

class _PersonalWalkRow extends ConsumerWidget {
  const _PersonalWalkRow({required this.item, this.history = false});
  final Json item;
  final bool history;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(personalWalkingProvider);
    final id = '${item['id']}';
    final pet = item['pet'] as Map?;
    final person =
        (item['my_role'] == 'helper' ? item['owner'] : item['helper']) as Map?;
    final actions = walkingActions(item);
    final review = item['status'] == 'completed'
        ? ['review_helper', 'review_owner'].where(actions.contains).firstOrNull
        : null;
    final chat = item['conversation_id'] as String?;
    Future<void> detail() async {
      if (chat != null && chat.isNotEmpty && item['my_role'] != 'applicant') {
        ref.read(walkingChatProvider.notifier).load(chat);
        await showWalkingChatDetails(context, chat, chatEntry: true);
      } else {
        await showWalkRequestSheet(context, id: id);
      }
      if (context.mounted) {
        await ref.read(personalWalkingProvider.notifier).refresh();
      }
    }

    Future<void> leaveReview() async {
      await showWalkingReviewSheet(
        context,
        id: id,
        role: review == 'review_owner' ? 'owner' : 'helper',
      );
      await ref.read(personalWalkingProvider.notifier).refresh();
    }

    if (history) {
      return _PersonalHistoryRow(
        item: item,
        review: review,
        onReview: leaveReview,
        onDetail: detail,
      );
    }

    return Padding(
      key: ValueKey('current-entry-$id'),
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IdentityPicture(
                id: 'pet:${pet?['id'] ?? item['pet_id']}',
                name: '${pet?['name'] ?? ''}',
                icon: Icons.pets_outlined,
                size: 56,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${pet?['name'] ?? 'Питомец'.tr(context)}',
                      style: walkingIdentityStyle,
                    ),
                    const SizedBox(height: 4),
                    _WalkingTimeFacts(item: item, showLocation: person == null),
                    if (person != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '${(item['my_role'] == 'helper' ? 'Владелец' : 'Помощник').tr(context)} · ${person['display_name'] ?? ''}',
                          style: walkingMetaStyle(context),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          WalkingStatusLabel(
            item['my_role'] == 'applicant'
                ? 'Отклик отправлен · ждём решения'.tr(context)
                : walkStatus('${item['status']}').tr(context),
          ),
          WalkingRowActions(
            leading: chat != null || item['my_role'] == 'owner'
                ? OutlinedButton(
                    onPressed: detail,
                    child: Text('Детали'.tr(context)),
                  )
                : null,
            trailing: chat != null && item['my_role'] != 'applicant'
                ? OutlinedButton.icon(
                    onPressed: () async {
                      await context.push('/chat/$chat');
                      await ref
                          .read(personalWalkingProvider.notifier)
                          .refresh();
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 20),
                    label: Text('Чат'.tr(context)),
                  )
                : item['my_role'] == 'owner'
                ? OutlinedButton(
                    onPressed: () async {
                      await showWalkRequestSheet(
                        context,
                        id: id,
                        applications: true,
                      );
                      await ref
                          .read(personalWalkingProvider.notifier)
                          .refresh();
                    },
                    child: Text('Отклики'.tr(context)),
                  )
                : OutlinedButton(
                    onPressed: detail,
                    child: Text('Детали'.tr(context)),
                  ),
          ),
          if (state.actionErrors.containsKey(id))
            Text(
              'Не удалось обновить заявку. Проверьте соединение и обновите её: статус мог измениться.'
                  .tr(context),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          const Divider(height: 40),
        ],
      ),
    );
  }
}

class _WalkingOwnProfile extends ConsumerWidget {
  const _WalkingOwnProfile({required this.id, required this.role});
  final String id, role;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final helper = role == 'helper';
    final state = helper
        ? ref.watch(communityProvider)
        : ref.watch(ownerProfileProvider(id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final view in ['helper', 'owner'])
              Expanded(
                child: Semantics(
                  selected: view == role,
                  child: InkWell(
                    key: ValueKey('walking-role-$view'),
                    onTap: () => ref
                        .read(personalWalkingProvider.notifier)
                        .selectRole(view),
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            width: role == view ? 2 : 1,
                            color: role == view
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                      ),
                      child: Text(
                        (view == 'helper' ? 'Как помощник' : 'Как владелец').tr(
                          context,
                        ),
                        textAlign: TextAlign.center,
                        style: walkingBodyStyle.copyWith(
                          fontSize: 14,
                          fontWeight: view == role
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        state.when(
          loading: () => const WalkingLoadingState(),
          error: (_, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Репутация недоступна'.tr(context)),
              TextButton(
                onPressed: () => helper
                    ? ref.invalidate(communityProvider)
                    : ref.invalidate(ownerProfileProvider(id)),
                child: Text('Повторить загрузку'.tr(context)),
              ),
            ],
          ),
          data: (data) {
            final stats = findRow(data, 'owner_ratings', id);
            final reputation = helper
                ? HelperReputation.fromData(
                    data,
                    id,
                    demo: ref.watch(communityRepositoryProvider).isDemo,
                  )
                : HelperReputation(
                    (stats?['rating'] as num?)?.toDouble(),
                    (stats?['review_count'] as num?)?.toInt(),
                    (stats?['completed'] as num?)?.toInt(),
                  );
            final reviews =
                rows(data, helper ? 'walk_reviews' : 'walk_owner_reviews')
                    .where(
                      (r) =>
                          r[helper ? 'helper_id' : 'owner_id'] == id &&
                          r['published'] == true,
                    )
                    .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _OwnExperienceSummary(
                  reputation: reputation,
                  onRetry: () => helper
                      ? ref.invalidate(communityProvider)
                      : ref.invalidate(ownerProfileProvider(id)),
                ),
                if (reviews.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  ...reviews.map(
                    (review) => _OwnWalkingReview(
                      key: ValueKey('$role-${review['id']}'),
                      review: review,
                      data: data,
                      helper: helper,
                      account: id,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _OwnWalkingReview extends ConsumerStatefulWidget {
  const _OwnWalkingReview({
    required this.review,
    required this.data,
    required this.helper,
    required this.account,
    super.key,
  });
  final Json review;
  final CommunityData data;
  final bool helper;
  final String account;
  @override
  ConsumerState<_OwnWalkingReview> createState() => _OwnWalkingReviewState();
}

class _OwnWalkingReviewState extends ConsumerState<_OwnWalkingReview> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    final body = '${review['body'] ?? ''}';
    final reply =
        '${review[widget.helper ? 'helper_reply' : 'owner_reply'] ?? ''}';
    final date = DateTime.tryParse('${review['created_at'] ?? ''}');
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IdentityPicture(
                id: '${review['author_id']}',
                icon: Icons.person_outline,
                name:
                    '${findRow(widget.data, 'profiles', review['author_id'])?['display_name'] ?? ''}',
                size: 36,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${findRow(widget.data, 'profiles', review['author_id'])?['display_name'] ?? '…'}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (date != null)
                      Text(
                        DateFormat.yMMMd(
                          context.languageCode,
                        ).format(date.toLocal()),
                        style: walkingMetaStyle(context),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.star_outline, size: 18),
              const SizedBox(width: 4),
              Text('${review['rating']}'),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            body,
            maxLines: expanded ? null : 4,
            overflow: expanded ? null : TextOverflow.ellipsis,
          ),
          if (body.length > 160)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(48, 48),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () => setState(() => expanded = !expanded),
                child: Text(
                  (expanded ? 'Свернуть' : 'Читать полностью').tr(context),
                ),
              ),
            ),
          if (reply.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                (widget.helper
                        ? 'Ответ помощника: {p0}'
                        : 'Ответ владельца: {p0}')
                    .tr(context, arguments: {'p0': reply}),
              ),
            ),
          if (widget.helper)
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: ReplyToReview(review: review),
            )
          else
            OwnerReviewReply(
              review: review,
              onSaved: () =>
                  ref.invalidate(ownerProfileProvider(widget.account)),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.push('/report/review/${review['id']}'),
              child: Text('Пожаловаться на отзыв'.tr(context)),
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }
}

class _OwnExperienceSummary extends StatelessWidget {
  const _OwnExperienceSummary({
    required this.reputation,
    required this.onRetry,
  });
  final HelperReputation reputation;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    final count = reputation.reviewCount;
    final theme = Theme.of(context);
    final rating = reputation.rating;
    final unavailable =
        count == null ||
        reputation.completed == null ||
        (count > 0 && rating == null);
    final completed = reputation.completed == null
        ? 'Опыт недоступен'.tr(context)
        : reputation.localizedCompletedLabel(context.languageCode);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (count == null)
          Text(
            'Отзывы недоступны'.tr(context),
            style: theme.textTheme.titleMedium,
          )
        else if (count == 0) ...[
          SocialContentState(
            centered: true,
            icon: Icons.pets_outlined,
            title: 'Пока нет отзывов'.tr(context),
            message: 'Отзывы появляются после подтверждённых прогулок.'.tr(
              context,
            ),
          ),
        ] else if (rating != null)
          Semantics(
            label: 'Средняя оценка {p0} из 5'.tr(
              context,
              arguments: {
                'p0': NumberFormat('0.0', context.languageCode).format(rating),
              },
            ),
            excludeSemantics: true,
            child: Row(
              children: [
                Text(
                  NumberFormat('0.0', context.languageCode).format(rating),
                  style: theme.textTheme.headlineMedium,
                ),
                const SizedBox(width: 8),
                const Icon(Icons.star_outline_rounded, size: 24),
              ],
            ),
          )
        else
          Text('Оценка недоступна'.tr(context)),
        if (count != 0) ...[
          const SizedBox(height: 8),
          Text(
            [
              if (count != null && count > 0)
                stringsFor(context.languageCode).reviewCount(count),
              completed,
            ].join(' · '),
            style: theme.textTheme.bodySmall,
          ),
        ],
        if (unavailable)
          TextButton(
            onPressed: onRetry,
            child: Text('Повторить загрузку опыта'.tr(context)),
          ),
      ],
    );
  }
}

class _WalkingTimeFacts extends StatelessWidget {
  const _WalkingTimeFacts({required this.item, this.showLocation = true});
  final Json item;
  final bool showLocation;
  @override
  Widget build(BuildContext context) {
    final local = walkingVenueDate(item);
    final zone =
        item['time_zone'] as String? ?? cityTimeZone(item['city'] as String?);
    final clock = local == null
        ? 'Время не задано'.tr(context)
        : '${DateFormat.MMMMd(context.languageCode).format(local)} · ${DateFormat.Hm(context.languageCode).format(local)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tooltip(
          message: validTimeZone(zone)
              ? timeZoneLabel(zone!, locale: context.languageCode)
              : 'UTC',
          child: Text(
            [
              clock,
              if (item['duration'] != null)
                '{p0} минут'.tr(context, arguments: {'p0': item['duration']}),
            ].join(' · '),
            style: walkingMetaStyle(context),
          ),
        ),
        if (showLocation &&
            [
              item['city'],
              item['district'],
            ].any((v) => v != null && '$v'.isNotEmpty))
          Text(
            [
              item['city'],
              item['district'],
            ].where((v) => v != null && '$v'.isNotEmpty).join(' · '),
            style: walkingMetaStyle(context),
          ),
      ],
    );
  }
}

class _PersonalHistoryRow extends ConsumerWidget {
  const _PersonalHistoryRow({
    required this.item,
    required this.review,
    required this.onReview,
    required this.onDetail,
  });
  final Json item;
  final String? review;
  final VoidCallback onReview, onDetail;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pet = item['pet'] as Map?;
    final helper = item['my_role'] == 'helper';
    final counterpart = (helper ? item['owner'] : item['helper']) as Map?;
    final id = '${item['id']}';
    final completed = item['status'] == 'completed';
    final reviewed = helper
        ? item['owner_review_written'] == true
        : item['helper_review_written'] == true;
    final local = walkingVenueDate(item);
    return Column(
      key: ValueKey('history-entry-$id'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IdentityPicture(
              id: 'pet:${pet?['id'] ?? item['pet_id']}',
              name: '${pet?['name'] ?? ''}',
              icon: Icons.pets_outlined,
              size: 56,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${pet?['name'] ?? 'Питомец'.tr(context)}',
                    style: walkingIdentityStyle,
                  ),
                  const SizedBox(height: 4),
                  if (local != null)
                    Text(
                      '${DateFormat.MMMMd(context.languageCode).format(local)} · ${DateFormat.Hm(context.languageCode).format(local)} · ${(helper ? 'Как помощник' : 'Как владелец').tr(context)}',
                      style: walkingMetaStyle(context),
                    ),
                  if (counterpart != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${(helper ? 'Владелец' : 'Помощник').tr(context)} · ${counterpart['display_name'] ?? ''}',
                        style: walkingMetaStyle(context),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        WalkingStatusLabel(walkStatus('${item['status']}').tr(context)),
        WalkingRowActions(
          leading: OutlinedButton(
            style: OutlinedButton.styleFrom(
              textStyle: walkingBodyStyle.copyWith(
                fontSize: 14.4,
                fontWeight: FontWeight.w500,
              ),
              side: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF3E4638)
                    : const Color(0xFFDCE1D3),
              ),
            ),
            onPressed: onDetail,
            child: Text('Детали'.tr(context)),
          ),
          trailing: completed && review != null && !reviewed
              ? OutlinedButton(
                  onPressed: onReview,
                  child: Text('Оставить отзыв'.tr(context)),
                )
              : completed && reviewed
              ? OutlinedButton(
                  onPressed: null,
                  style: OutlinedButton.styleFrom(
                    textStyle: walkingBodyStyle.copyWith(
                      fontSize: 14.4,
                      fontWeight: FontWeight.w500,
                    ),
                    disabledForegroundColor: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: .6),
                    side: BorderSide(
                      color:
                          (Theme.of(context).brightness == Brightness.dark
                                  ? const Color(0xFF3E4638)
                                  : const Color(0xFFDCE1D3))
                              .withValues(alpha: .6),
                    ),
                  ),
                  child: Text('Отзыв опубликован'.tr(context)),
                )
              : const SizedBox(),
        ),
        if (completed && item['conversation_id'] != null)
          OutlinedButton.icon(
            key: ValueKey('history-chat-$id'),
            onPressed: () => context.push('/chat/${item['conversation_id']}'),
            icon: const Icon(Icons.chat_bubble_outline, size: 20),
            label: Text('Чат'.tr(context)),
          ),
        const Divider(height: 40),
      ],
    );
  }
}
