import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/time/display_time.dart';
import '../data/community_repository.dart';

enum MeetupParticipation { upcoming, joined, organizing }

enum MeetupDate { any, today, weekend, week }

class MeetupFilters {
  const MeetupFilters({
    this.query = '',
    this.participation = MeetupParticipation.upcoming,
    this.date = MeetupDate.any,
    this.history = false,
  });
  final String query;
  final MeetupParticipation participation;
  final MeetupDate date;
  final bool history;
  MeetupFilters copyWith({
    String? query,
    MeetupParticipation? participation,
    MeetupDate? date,
    bool? history,
  }) => MeetupFilters(
    query: query ?? this.query,
    participation: participation ?? this.participation,
    date: date ?? this.date,
    history: history ?? this.history,
  );
}

bool meetupJoined(CommunityData data, String id, String? uid) =>
    uid != null &&
    rows(
      data,
      'event_members',
    ).any((row) => row['event_id'] == id && row['user_id'] == uid);
int meetupMembers(CommunityData data, String id) => rows(data, 'event_members')
    .where((row) => row['event_id'] == id)
    .map((row) => row['user_id'])
    .toSet()
    .length;
bool meetupActive(Json event, DateTime now) {
  final starts = DateTime.tryParse('${event['starts_at']}');
  return event['cancelled'] != true && starts != null && starts.isAfter(now);
}

List<Json> selectMeetups(
  CommunityData data, {
  required String city,
  required String? uid,
  required MeetupFilters filters,
  required DateTime now,
}) {
  final query = filters.query.trim().toLowerCase();
  final result = rows(data, 'events').where((event) {
    if (event['city'] != city) return false;
    final active = meetupActive(event, now);
    final capacity = event['capacity'] as num?;
    if (!filters.history &&
        capacity != null &&
        meetupMembers(data, '${event['id']}') >= capacity &&
        event['owner_id'] != uid &&
        !meetupJoined(data, '${event['id']}', uid)) {
      return false;
    }
    if (filters.history ? active : !active) return false;
    if (filters.participation == MeetupParticipation.joined &&
        !meetupJoined(data, '${event['id']}', uid)) {
      return false;
    }
    if (filters.participation == MeetupParticipation.organizing &&
        (uid == null || event['owner_id'] != uid)) {
      return false;
    }
    final owner = findRow(data, 'profiles', event['owner_id']);
    if (query.isNotEmpty &&
        ![
          event['title'],
          event['description'],
          event['location_label'],
          owner?['display_name'],
        ].any((text) => '$text'.toLowerCase().contains(query))) {
      return false;
    }
    if (filters.date != MeetupDate.any) {
      final starts = DateTime.tryParse('${event['starts_at']}');
      final zone = event['time_zone'] as String? ?? cityTimeZone(city);
      // Unknown venue zones cannot satisfy a local-date filter honestly.
      if (starts == null || !validTimeZone(zone)) return false;
      final date = venueDateTime(starts, zone!);
      final localNow = venueDateTime(now, zone);
      final day = DateTime.utc(date.year, date.month, date.day);
      final today = DateTime.utc(localNow.year, localNow.month, localNow.day);
      final difference = day.difference(today).inDays;
      if (filters.date == MeetupDate.today && difference != 0) return false;
      if (filters.date == MeetupDate.weekend) {
        final saturday = (DateTime.saturday - today.weekday + 7) % 7;
        final first = today.weekday == DateTime.sunday ? -1 : saturday;
        if (difference < first || difference > first + 1) return false;
      }
      if (filters.date == MeetupDate.week &&
          (difference < 0 || difference > 6)) {
        return false;
      }
    }
    return true;
  }).toList();
  result.sort((a, b) => '${a['starts_at']}'.compareTo('${b['starts_at']}'));
  if (filters.history) return result.reversed.toList();
  return result;
}

/// Public venue time for date badges; unknown zones retain the honest fallback.
DateTime? meetupVenueDate(Json event) {
  final instant = DateTime.tryParse('${event['starts_at']}');
  final zone =
      event['time_zone'] as String? ?? cityTimeZone(event['city'] as String?);
  return instant != null && validTimeZone(zone)
      ? venueDateTime(instant, zone!)
      : null;
}

class MeetupActions extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    ref.watch(communityRepositoryProvider);
    return {};
  }

  Future<bool> participation(String id, {required bool joined}) async {
    if (state.contains(id)) return false;
    final repository = ref.read(communityRepositoryProvider);
    final data = ref.read(communityProvider).value;
    final event = data == null ? null : findRow(data, 'events', id);
    if (event == null ||
        !meetupActive(event, DateTime.now()) ||
        repository.userId == null ||
        repository.userId == event['owner_id'] ||
        meetupJoined(data!, id, repository.userId) != joined) {
      return false;
    }
    state = {...state, id};
    try {
      await ref.read(communityProvider.notifier).command(
        joined ? 'leave_event' : 'join_event',
        {'event_in': id},
      );
      return true;
    } finally {
      if (ref.mounted && ref.read(communityRepositoryProvider) == repository) {
        state = {...state}..remove(id);
      }
    }
  }
}

final meetupActionsProvider = NotifierProvider<MeetupActions, Set<String>>(
  MeetupActions.new,
);
