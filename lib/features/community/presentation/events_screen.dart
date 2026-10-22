import '../../../core/media/preview_photos.dart';
import '../../nearby/live_map.dart';
import '../../nearby/place_repository.dart';
import '../../chat/shared_content.dart';
import '../../nearby/city_field.dart';
import '../../../core/ui/studio_pickers.dart';
import '../../../l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ui/components.dart';
import '../../../core/ui/studio_motion.dart';
import '../../../core/theme/studio_theme.dart';
import '../../../core/storage/prototype_store.dart';
import '../../../core/time/display_time.dart';
import '../../walks/account_mode.dart';
import '../data/community_repository.dart';
import '../data/event_location.dart';
import 'event_location_widgets.dart';
import 'meetup_controller.dart';

String eventTime(
  dynamic value, {
  String? city,
  String? timeZone,
  String locale = 'ru',
}) => venueTime(value, city: city, timeZone: timeZone, locale: locale);

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({
    this.focusedEventId,
    this.communityId,
    this.embedded = false,
    super.key,
  });
  final bool embedded;
  final String? communityId;
  // Retain existing deep links; browsing expands details without pushing here.
  final String? focusedEventId;
  @override
  ConsumerState<EventsScreen> createState() => _EventsState();
}

class _EventsState extends ConsumerState<EventsScreen> {
  final search = TextEditingController();
  MeetupFilters filters = const MeetupFilters();
  bool openingChat = false;
  final cityInput = TextEditingController();
  Future<void> chooseFilters() async {
    final value = await showStudioChoice<MeetupDate>(
      context: context,
      title: 'Фильтры'.tr(context),
      value: filters.date,
      resetValue: MeetupDate.any,
      options: [
        for (final d in MeetupDate.values)
          (value: d, label: dateLabel(d).tr(context)),
      ],
    );
    if (value != null && mounted) {
      setState(() => filters = filters.copyWith(date: value));
    }
  }

  void resetFilters() {
    search.clear();
    setState(() => filters = filters.copyWith(query: '', date: MeetupDate.any));
  }

  String dateLabel(MeetupDate value) => switch (value) {
    MeetupDate.any => 'Любая дата',
    MeetupDate.today => 'Сегодня',
    MeetupDate.weekend => 'На выходных',
    MeetupDate.week => 'Ближайшие 7 дней',
  };
  @override
  void dispose() {
    search.dispose();
    cityInput.dispose();
    super.dispose();
  }

  Future<void> changeParticipation(String id, bool joined) async {
    try {
      final changed = await ref
          .read(meetupActionsProvider.notifier)
          .participation(id, joined: joined);
      if (mounted && changed) {
        notice(
          context,
          (joined ? 'Участие отменено' : 'Вы присоединились к встрече').tr(
            context,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        notice(
          context,
          'Не удалось изменить участие. Проверьте соединение и наличие свободных мест.'
              .tr(context),
        );
      }
    }
  }

  Future<void> openChat(CommunityData data, String id) async {
    if (openingChat) return;
    final chat = rows(
      data,
      'conversations',
    ).where((c) => c['kind'] == 'event' && c['context_id'] == id).firstOrNull;
    if (chat == null) {
      notice(
        context,
        'Чат встречи пока недоступен. Повторите попытку.'.tr(context),
      );
      return;
    }
    openingChat = true;
    try {
      await context.push('/chat/${chat['id']}');
    } finally {
      openingChat = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityProvider);
    final data = state.value ?? <String, List<Json>>{};
    final uid = ref.watch(communityRepositoryProvider).userId;
    final detail = widget.focusedEventId != null;
    final city = detail
        ? ''
        : ref.watch(prototypeProvider.select((s) => s.city));
    cityInput.text = city;
    final canCreate =
        ref.watch(accountModeProvider).value?.canOwn == true &&
        (widget.communityId == null ||
            rows(data, 'group_members').any(
              (m) => m['group_id'] == widget.communityId && m['user_id'] == uid,
            ));
    final events =
        selectMeetups(
              data,
              city: city,
              uid: uid,
              filters: filters,
              now: DateTime.now(),
            )
            .where(
              (e) =>
                  widget.communityId == null ||
                  e['group_id'] == widget.communityId,
            )
            .toList();
    final event = detail
        ? findRow(data, 'events', widget.focusedEventId)
        : null;
    final create = IconButton.filled(
      key: const ValueKey('meetup-create'),
      tooltip: 'Создать встречу'.tr(context),
      style: IconButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        minimumSize: const Size(48, 48),
      ),
      onPressed: () => context.push(
        '/edit/event${widget.communityId == null ? '' : '?group=${widget.communityId}'}',
      ),
      icon: const Icon(Icons.add),
    );
    Widget body;
    if (detail && event != null) {
      body = _MeetingDetails(
        event: event,
        data: data,
        uid: uid,
        pending: ref.watch(meetupActionsProvider).contains(event['id']),
        onParticipation: (joined) => changeParticipation(event['id'], joined),
        onChat: () => openChat(data, event['id']),
        onShare: () => shareMeeting(context, ref, event['id']),
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!detail)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                children: [
                  if (widget.communityId == null)
                    CityField(
                      controller: cityInput,
                      onChanged: (v) =>
                          ref.read(prototypeProvider.notifier).setCity(v),
                    ),
                  if (widget.communityId == null) const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const ValueKey('meetup-search'),
                          controller: search,
                          onChanged: (v) => setState(
                            () => filters = filters.copyWith(query: v),
                          ),
                          decoration: InputDecoration(
                            hintText: 'Название или место'.tr(context),
                            prefixIcon: const Icon(Icons.search),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        key: const ValueKey('meetup-date-filter'),
                        tooltip: 'Фильтры'.tr(context),
                        onPressed: chooseFilters,
                        icon: Badge(
                          isLabelVisible: filters.date != MeetupDate.any,
                          child: const Icon(Icons.filter_list),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(communityProvider.notifier).refresh(),
              child: ListView(
                key: const PageStorageKey('meetup-list'),
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  if (state.hasError && data.isNotEmpty)
                    MeetupContentState(
                      title: 'Встречи сейчас недоступны'.tr(context),
                      actionLabel: 'Повторить загрузку'.tr(context),
                      onAction: () =>
                          ref.read(communityProvider.notifier).refresh(),
                    ),
                  if (state.isLoading && data.isNotEmpty)
                    const LinearProgressIndicator(),
                  if (state.isLoading && data.isEmpty)
                    MeetupContentState(
                      title: 'Загружаем встречи…'.tr(context),
                      loading: true,
                    )
                  else if (state.hasError && data.isEmpty)
                    MeetupContentState(
                      title: 'Встречи сейчас недоступны'.tr(context),
                      actionLabel: 'Повторить загрузку'.tr(context),
                      onAction: () =>
                          ref.read(communityProvider.notifier).refresh(),
                    )
                  else if (detail)
                    MeetupContentState(
                      title: 'Встреча недоступна. Возможно, её больше нет.'.tr(
                        context,
                      ),
                      icon: Icons.event_busy_outlined,
                      actionLabel: 'К списку встреч'.tr(context),
                      onAction: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/events');
                        }
                      },
                    )
                  else if (events.isEmpty)
                    MeetupContentState(
                      title: 'Подходящих встреч пока нет'.tr(context),
                      message: 'Попробуйте другую дату или измените поиск.'.tr(
                        context,
                      ),
                      actionLabel: 'Сбросить фильтры'.tr(context),
                      onAction: resetFilters,
                    )
                  else
                    for (final e in events) ...[
                      ListTile(
                        key: ValueKey('meetup-${e['id']}'),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                        leading: const Icon(Icons.calendar_month_outlined),
                        title: Text(
                          '${e['title']}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          '${eventTime(e['starts_at'], city: e['city'], timeZone: e['time_zone'], locale: context.languageCode)}\n${e['location_label'] ?? ''}',
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push('/event/${e['id']}'),
                      ),
                      if (e != events.last) const Divider(height: 1),
                    ],
                ],
              ),
            ),
          ),
        ],
      );
    }
    if (widget.embedded) return body;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          (detail
                  ? 'Встреча'
                  : widget.communityId != null
                  ? 'Встречи сообщества'
                  : 'Встречи')
              .tr(context),
        ),
        actions: [
          if (!detail && canCreate)
            Padding(padding: const EdgeInsets.only(right: 12), child: create),
        ],
      ),
      body: body,
    );
  }
}

class _MeetingDetails extends StatelessWidget {
  const _MeetingDetails({
    required this.event,
    required this.data,
    required this.uid,
    required this.pending,
    required this.onParticipation,
    required this.onChat,
    required this.onShare,
  });
  final Json event;
  final CommunityData data;
  final String? uid;
  final bool pending;
  final ValueChanged<bool> onParticipation;
  final VoidCallback onChat, onShare;
  @override
  Widget build(BuildContext context) {
    final id = '${event['id']}';
    final joined = meetupJoined(data, id, uid),
        owner = event['owner_id'] == uid;
    final active = meetupActive(event, DateTime.now());
    final capacity = event['capacity'] as num?;
    final count = meetupMembers(data, id);
    final full = capacity != null && count >= capacity;
    final location = EventLocation.fromRow(event);
    final group = findRow(data, 'groups', event['group_id']);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                '${event['title']}',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                (full
                        ? 'Регистрация закрыта. Можно прийти без регистрации.'
                        : 'Открытая встреча')
                    .tr(context),
              ),
              if (group != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('${group['title']}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/group/${group['id']}'),
                ),
              const SizedBox(height: 20),
              Text(
                eventTime(
                  event['starts_at'],
                  city: event['city'],
                  timeZone: event['time_zone'],
                  locale: context.languageCode,
                ),
              ),
              const SizedBox(height: 4),
              Text('${event['duration'] ?? 60} ${'мин'.tr(context)}'),
              const SizedBox(height: 20),
              if (location != null) ...[
                ListTile(
                  key: ValueKey('meetup-map-$id'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.location_on_outlined, size: 22),
                  title: Text(
                    location.displayLabel,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  subtitle: event['location_label'] == null
                      ? null
                      : Text('${event['location_label']}'),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EventLocationMapScreen(
                        location: location,
                        city: '${event['city']}',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 132,
                    child: IgnorePointer(
                      child: LiveMap(
                        places: [
                          Place(
                            'meeting-$id',
                            location.displayLabel,
                            'Место встречи'.tr(context),
                            '${event['city']}',
                            null,
                            0,
                            '',
                            '',
                            Icons.groups_outlined,
                            latitude: location.latitude,
                            longitude: location.longitude,
                            city: '${event['city']}',
                          ),
                        ],
                        focusPlace: Place(
                          'meeting-$id',
                          location.displayLabel,
                          '',
                          '',
                          null,
                          0,
                          '',
                          '',
                          Icons.groups_outlined,
                          latitude: location.latitude,
                          longitude: location.longitude,
                        ),
                        onPlace: (_) {},
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text('${event['description'] ?? ''}'),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: IdentityPicture(
                  id: 'profile:${event['owner_id']}',
                  name: findRow(
                    data,
                    'profiles',
                    event['owner_id'],
                  )?['display_name'],
                  icon: Icons.person_outline,
                  size: 48,
                ),
                title: Text(
                  '${findRow(data, 'profiles', event['owner_id'])?['display_name'] ?? ''}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                subtitle: Text('Организатор'.tr(context)),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.people_outline, size: 22),
                title: Text(
                  '$count${capacity == null ? '' : ' / $capacity'} ${'участников'.tr(context)}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                subtitle: Text('Присоединение добровольное'.tr(context)),
              ),
              if (joined && !owner && active)
                TextButton(
                  onPressed: pending ? null : () => onParticipation(true),
                  child: Text('Отменить участие'.tr(context)),
                ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (ctx, constraints) {
                final actions = [
                  if (active && (joined || owner))
                    FilledButton(
                      key: ValueKey('meetup-chat-$id'),
                      onPressed: pending ? null : onChat,
                      child: Text('Открыть чат'.tr(ctx)),
                    )
                  else if (active && !full)
                    FilledButton(
                      onPressed: pending ? null : () => onParticipation(false),
                      child: Text('Присоединиться'.tr(ctx)),
                    ),
                  OutlinedButton.icon(
                    onPressed: onShare,
                    icon: const Icon(Icons.share_outlined, size: 20),
                    label: Text('Поделиться'.tr(ctx)),
                  ),
                ];
                if (MediaQuery.textScalerOf(ctx).scale(16) > 22) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final a in actions)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: a,
                        ),
                    ],
                  );
                }
                return Row(
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: actions[i]),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class MeetupContentState extends StatelessWidget {
  const MeetupContentState({
    required this.title,
    this.message,
    this.icon = Icons.event_outlined,
    this.loading = false,
    this.actionLabel,
    this.onAction,
    super.key,
  });
  final String title;
  final String? message, actionLabel;
  final IconData icon;
  final bool loading;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: loading,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 56, 16, 48),
      child: Column(
        children: [
          if (loading)
            SizedBox(
              width: 28,
              height: 28,
              child: StudioMotion.reduced(context)
                  ? Icon(Icons.hourglass_empty_outlined, semanticLabel: title)
                  : const CircularProgressIndicator(strokeWidth: 2),
            )
          else
            ExcludeSemantics(
              child: Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (message != null) ...[
            const SizedBox(height: 10),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (onAction != null && actionLabel != null) ...[
            const SizedBox(height: 12),
            TextButton(
              key: actionLabel == 'Сбросить фильтры'.tr(context)
                  ? const ValueKey('meetup-reset-filters')
                  : null,
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    ),
  );
}

class MeetupCard extends StatefulWidget {
  const MeetupCard({
    required this.event,
    required this.data,
    required this.uid,
    this.detail = false,
    this.pending = false,
    this.onOpen,
    this.onParticipation,
    this.onChat,
    super.key,
  });
  final Json event;
  final CommunityData data;
  final String? uid;
  final bool detail, pending;
  final VoidCallback? onOpen, onChat;
  final ValueChanged<bool>? onParticipation;
  @override
  State<MeetupCard> createState() => _MeetupCardState();
}

class _MeetupCardState extends State<MeetupCard> {
  bool expanded = false;
  @override
  void initState() {
    super.initState();
    expanded = widget.detail;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final event = widget.event;
    final id = '${event['id']}';
    final joined = meetupJoined(widget.data, id, widget.uid);
    final owner = widget.uid != null && event['owner_id'] == widget.uid;
    final active = meetupActive(event, DateTime.now());
    final count = meetupMembers(widget.data, id);
    final capacity = event['capacity'] as num?;
    final full = capacity != null && count >= capacity;
    final organizer = findRow(widget.data, 'profiles', event['owner_id']);
    final location = EventLocation.fromRow(event);
    final hasDetails =
        '${event['description'] ?? ''}'.trim().isNotEmpty || location != null;
    final city = '${event['city'] ?? ''}';
    final date = meetupVenueDate(event);
    final canChat = active && (joined || owner);
    final shortTime = date == null
        ? eventTime(
            event['starts_at'],
            city: city,
            timeZone: event['time_zone'],
            locale: context.languageCode,
          )
        : '${DateFormat.Hm(context.languageCode).format(date)} · ${timeZoneLabel(event['time_zone'] as String? ?? cityTimeZone(city)!, at: DateTime.parse('${event['starts_at']}'), locale: context.languageCode)}';
    final status = event['cancelled'] == true
        ? 'Встреча отменена'
        : DateTime.tryParse('${event['starts_at']}') == null
        ? 'Дата не указана'
        : !active
        ? 'Встреча прошла'
        : joined && !owner
        ? 'Вы участвуете'
        : full && !owner
        ? 'Мест нет'
        : null;
    final detailsButton = Semantics(
      expanded: expanded,
      child: OutlinedButton.icon(
        key: ValueKey('meetup-details-$id'),
        onPressed: () => setState(() => expanded = !expanded),
        icon: Icon(expanded ? Icons.expand_less : Icons.expand_more, size: 20),
        label: Text((expanded ? 'Скрыть' : 'Детали').tr(context)),
      ),
    );
    final otherAction = canChat
        ? OutlinedButton.icon(
            key: ValueKey('meetup-chat-$id'),
            onPressed: widget.pending ? null : widget.onChat,
            icon: const Icon(Icons.chat_bubble_outline, size: 20),
            label: Text('Чат'.tr(context)),
          )
        : active && !owner && !joined
        ? FilledButton(
            key: ValueKey('meetup-participation-$id'),
            onPressed: widget.pending || full
                ? null
                : () => widget.onParticipation?.call(false),
            child: Text(
              (widget.pending
                      ? 'Сохраняем…'
                      : full
                      ? 'Мест нет'
                      : 'Присоединиться')
                  .tr(context),
            ),
          )
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (date != null)
                Container(
                  width: 52,
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: StudioColors.of(context).tint,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat.MMM(context.languageCode).format(date),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall,
                      ),
                      Text(
                        NumberFormat.decimalPattern(
                          context.languageCode,
                        ).format(date.day),
                        style: theme.textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              if (date != null) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${event['title'] ?? ''}',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      shortTime,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            location?.label.trim().isNotEmpty == true
                ? location!.label
                : '${event['location_label'] ?? ''}'.trim().isNotEmpty
                ? '${event['location_label']}'
                : 'Место уточнит организатор'.tr(context),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, box) {
              final name = Text(
                owner
                    ? 'Вы организатор'.tr(context)
                    : 'Организатор: {p0}'.tr(
                        context,
                        arguments: {
                          'p0':
                              organizer?['display_name'] ??
                              'Имя не указано'.tr(context),
                        },
                      ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
              final members = Text(
                capacity == null
                    ? 'Участников: {p0}'.tr(context, arguments: {'p0': count})
                    : '{p0} из {p1} участников'.tr(
                        context,
                        arguments: {'p0': count, 'p1': capacity},
                      ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              );
              return box.maxWidth < 300 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.3
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [name, const SizedBox(height: 4), members],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: name),
                        const SizedBox(width: 12),
                        members,
                      ],
                    );
            },
          ),
          if (status != null) ...[
            const SizedBox(height: 8),
            Text(status.tr(context), style: theme.textTheme.labelMedium),
          ],
          if (hasDetails || otherAction != null) ...[
            const SizedBox(height: 12),
            if (!hasDetails)
              Align(alignment: Alignment.centerRight, child: otherAction!)
            else
              LayoutBuilder(
                builder: (context, box) =>
                    box.maxWidth < 300 ||
                        MediaQuery.textScalerOf(context).scale(1) > 1.3
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          detailsButton,
                          if (otherAction != null) ...[
                            const SizedBox(height: 8),
                            otherAction,
                          ],
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(child: detailsButton),
                          if (otherAction != null) ...[
                            const SizedBox(width: 8),
                            Expanded(child: otherAction),
                          ],
                        ],
                      ),
              ),
          ],
          if (hasDetails && expanded) ...[
            const SizedBox(height: 12),
            if ('${event['description'] ?? ''}'.trim().isNotEmpty)
              Text('${event['description']}'),
            if (location != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: OutlinedButton.icon(
                  key: ValueKey('meetup-map-$id'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => EventLocationMapScreen(
                        location: location,
                        city: city,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.map_outlined, size: 20),
                  label: Text('Показать место на карте'.tr(context)),
                ),
              ),
          ],
          if (!hasDetails || expanded) ...[
            if (active && joined && !owner)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  key: ValueKey('meetup-participation-$id'),
                  onPressed: widget.pending
                      ? null
                      : () => widget.onParticipation?.call(true),
                  child: Text(
                    (widget.pending ? 'Сохраняем…' : 'Отменить участие').tr(
                      context,
                    ),
                  ),
                ),
              ),
          ],
          const SizedBox(height: 20),
          const Divider(height: 1),
        ],
      ),
    );
  }
}
