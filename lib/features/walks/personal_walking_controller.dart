import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/time/display_time.dart';
import '../community/data/community_repository.dart';
import 'walking_repository.dart';
import 'walk_progress.dart';
import 'account_mode.dart';

enum PersonalWalkingTab { current, history, profile }

class WalkingPeriod {
  const WalkingPeriod(this.start, this.end);
  final DateTime start, end;
  bool includes(Json item) {
    final instant = DateTime.tryParse('${item['starts_at']}');
    if (instant == null) return false;
    final zone =
        item['time_zone'] as String? ?? cityTimeZone(item['city'] as String?);
    final local = validTimeZone(zone)
        ? venueDateTime(instant, zone!)
        : instant.toUtc();
    final date = DateTime.utc(local.year, local.month, local.day);
    return !date.isBefore(DateTime.utc(start.year, start.month, start.day)) &&
        !date.isAfter(DateTime.utc(end.year, end.month, end.day));
  }
}

class WalkingPage {
  const WalkingPage({
    this.items = const [],
    this.loading = false,
    this.loaded = false,
    this.hasMore = false,
    this.error,
    this.offset = 0,
  });
  final List<Json> items;
  final bool loading, loaded, hasMore;
  final Object? error;
  final int offset;
}

class PersonalWalkingState {
  const PersonalWalkingState({
    this.tab = PersonalWalkingTab.current,
    this.profileRole,
    this.period,
    this.pages = const {},
    this.pending = const {},
    this.actionErrors = const {},
  });
  final PersonalWalkingTab tab;
  final String? profileRole;
  final WalkingPeriod? period;
  final Map<String, WalkingPage> pages;
  final Set<String> pending;
  final Map<String, Object> actionErrors;
  PersonalWalkingState copyWith({
    PersonalWalkingTab? tab,
    String? profileRole,
    WalkingPeriod? period,
    bool clearPeriod = false,
    Map<String, WalkingPage>? pages,
    Set<String>? pending,
    Map<String, Object>? actionErrors,
  }) => PersonalWalkingState(
    tab: tab ?? this.tab,
    profileRole: profileRole ?? this.profileRole,
    period: clearPeriod ? null : period ?? this.period,
    pages: pages ?? this.pages,
    pending: pending ?? this.pending,
    actionErrors: actionErrors ?? this.actionErrors,
  );
}

/// Memory belongs to the account, independently of owner/helper presentation.
final personalWalkingHistoryExpansionProvider = Provider<Map<String, bool>>((
  ref,
) {
  ref.watch(communityRepositoryProvider.select((repo) => repo.userId));
  return {};
});

DateTime? walkingVenueDate(Json item) {
  final instant = DateTime.tryParse('${item['starts_at']}');
  if (instant == null) return null;
  final zone =
      item['time_zone'] as String? ?? cityTimeZone(item['city'] as String?);
  return validTimeZone(zone) ? venueDateTime(instant, zone!) : instant.toUtc();
}

final personalWalkingScrollProvider = Provider<Map<PersonalWalkingTab, double>>(
  (ref) {
    ref.watch(communityRepositoryProvider.select((repo) => repo.userId));
    return {};
  },
);

final personalWalkingProvider =
    NotifierProvider<PersonalWalkingController, PersonalWalkingState>(
      PersonalWalkingController.new,
    );

class PersonalWalkingController extends Notifier<PersonalWalkingState> {
  int _generation = 0;
  @override
  PersonalWalkingState build() {
    ref.watch(communityRepositoryProvider.select((repo) => repo.userId));
    ref.watch(walkingRepositoryProvider);
    final generation = ++_generation;
    ref.onDispose(() => _generation++);
    Future.microtask(() {
      if (!ref.mounted || generation != _generation) return;
      for (final view in ['active', 'applications', 'history']) {
        load(view);
      }
    });
    return const PersonalWalkingState();
  }

  void select(PersonalWalkingTab tab) => state = state.copyWith(tab: tab);
  void selectRole(String role) => state = state.copyWith(profileRole: role);
  void setPeriod(WalkingPeriod? value) =>
      state = state.copyWith(period: value, clearPeriod: value == null);

  Future<void> load(String view, {bool refresh = false}) async {
    final previous = state.pages[view] ?? const WalkingPage();
    if (previous.loading ||
        (!refresh && previous.loaded && !previous.hasMore)) {
      return;
    }
    final generation = _generation;
    state = state.copyWith(
      pages: {
        ...state.pages,
        view: WalkingPage(
          items: previous.items,
          loaded: previous.loaded,
          loading: true,
          hasMore: previous.hasMore,
          offset: previous.offset,
        ),
      },
    );
    try {
      final items = await ref
          .read(walkingRepositoryProvider)
          .list(view: view, offset: refresh ? 0 : previous.offset);
      if (generation != _generation) return;
      final repo = ref.read(communityRepositoryProvider);
      final source = repo.isDemo ? await repo.load() : <String, List<Json>>{};
      if (generation != _generation) return;
      final enriched = repo.isDemo
          ? items
                .map(
                  (item) => demoPersonalWalkingCard(item, source, repo.userId),
                )
                .toList()
          : items;
      final combined = refresh ? enriched : [...previous.items, ...enriched];
      final unique = <String, Json>{
        for (final item in combined) '${item['id']}': item,
      };
      state = state.copyWith(
        pages: {
          ...state.pages,
          view: WalkingPage(
            items: unique.values.toList(),
            loaded: true,
            hasMore: items.length == 40,
            offset: (refresh ? 0 : previous.offset) + items.length,
          ),
        },
      );
    } catch (error) {
      if (generation != _generation) return;
      state = state.copyWith(
        pages: {
          ...state.pages,
          view: WalkingPage(
            items: previous.items,
            loaded: previous.loaded,
            hasMore: previous.hasMore,
            offset: previous.offset,
            error: error,
          ),
        },
      );
    }
  }

  Future<void> refresh() async {
    for (final view in ['active', 'applications', 'history']) {
      if (state.pages[view]?.loaded == true) await load(view, refresh: true);
    }
  }

  Future<void> advance(Json item, String action) async {
    final id = '${item['id']}';
    if (state.pending.contains(id) || !walkingActions(item).contains(action)) {
      return;
    }
    final next = {
      'start': 'in_progress',
      'finish': 'awaiting_confirmation',
      'confirm': 'completed',
    }[action];
    if (next == null) return;
    final generation = _generation;
    state = state.copyWith(
      pending: {...state.pending, id},
      actionErrors: {...state.actionErrors}..remove(id),
    );
    try {
      await ref.read(communityProvider.notifier).command('advance_walk', {
        'request_in': id,
        'next_status': next,
      });
      if (generation == _generation) await refresh();
    } catch (error) {
      if (generation == _generation) {
        state = state.copyWith(
          actionErrors: {...state.actionErrors, id: error},
        );
      }
    } finally {
      if (generation == _generation) {
        state = state.copyWith(pending: {...state.pending}..remove(id));
      }
    }
  }
}

List<String> walkingActions(Json item) =>
    (item['allowed_actions'] as List? ?? const []).whereType<String>().toList();

List<Json> personalAgreements(List<Json> items) =>
    items
        .where(
          (item) =>
              ['owner', 'helper'].contains(item['my_role']) &&
              item['status'] != 'open',
        )
        .toList()
      ..sort((a, b) {
        int priority(Json row) => walkingActions(row).contains('confirm')
            ? 0
            : walkingActions(row).contains('finish')
            ? 1
            : 2;
        final urgent = priority(a).compareTo(priority(b));
        return urgent != 0
            ? urgent
            : '${a['starts_at']}'.compareTo('${b['starts_at']}');
      });

Json demoPersonalWalkingCard(Json item, CommunityData data, String? uid) {
  final id = item['id'];
  final agreement = rows(
    data,
    'walk_agreements',
  ).where((a) => a['request_id'] == id).firstOrNull;
  final owner = item['owner_id'] == uid && uid != null;
  final helper = agreement?['helper_id'] == uid && uid != null;
  final helperReviewed = rows(
    data,
    'walk_reviews',
  ).any((r) => r['request_id'] == id);
  final ownerReviewed = rows(
    data,
    'walk_owner_reviews',
  ).any((r) => r['request_id'] == id);
  return {
    ...item,
    if (agreement != null)
      'helper': findRow(data, 'profiles', agreement['helper_id']),
    'conversation_id': walkConversationId(data, '$id', uid),
    'helper_review_written': helperReviewed,
    'owner_review_written': ownerReviewed,
    'application_count': rows(
      data,
      'walk_applications',
    ).where((a) => a['request_id'] == id).length,
    'allowed_actions': [
      if (helper && item['status'] == 'assigned') 'start',
      if (helper && item['status'] == 'in_progress') 'finish',
      if (owner && item['status'] == 'awaiting_confirmation') 'confirm',
      if (canReviewAgreement(data, '$id', uid, owner: false)) 'review_helper',
      if (canReviewAgreement(data, '$id', uid, owner: true)) 'review_owner',
    ],
  };
}

class WalkingScheduleRange {
  const WalkingScheduleRange(this.firstDay, this.lastDay, this.start, this.end);
  final int firstDay, lastDay, start, end;
}

List<WalkingScheduleRange> compactWalkingSchedule(
  List<WeeklyAvailability> slots,
) {
  final sorted = List<WeeklyAvailability>.of(slots)
    ..sort((a, b) {
      final time = a.start.compareTo(b.start);
      return time != 0
          ? time
          : a.end != b.end
          ? a.end.compareTo(b.end)
          : a.day.compareTo(b.day);
    });
  final ranges = <WalkingScheduleRange>[];
  for (final slot in sorted) {
    final last = ranges.lastOrNull;
    if (last != null &&
        last.lastDay + 1 == slot.day &&
        last.start == slot.start &&
        last.end == slot.end) {
      ranges[ranges.length - 1] = WalkingScheduleRange(
        last.firstDay,
        slot.day,
        slot.start,
        slot.end,
      );
    } else {
      ranges.add(
        WalkingScheduleRange(slot.day, slot.day, slot.start, slot.end),
      );
    }
  }
  ranges.sort(
    (a, b) => a.firstDay != b.firstDay
        ? a.firstDay.compareTo(b.firstDay)
        : a.start.compareTo(b.start),
  );
  return ranges;
}
