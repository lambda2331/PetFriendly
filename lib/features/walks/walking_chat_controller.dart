import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../community/data/community_repository.dart';
import 'personal_walking_controller.dart';
import 'walking_repository.dart';

class WalkingChatRecord {
  const WalkingChatRecord({
    this.item,
    this.instructions,
    this.loading = false,
    this.pending = false,
    this.error,
    this.actionError,
  });
  final Json? item;
  final String? instructions;
  final bool loading, pending;
  final Object? error, actionError;
}

class WalkingReportDraft {
  const WalkingReportDraft({
    this.reason = '',
    this.note = '',
    this.pending = false,
    this.sent = false,
    this.error,
  });
  final String reason, note;
  final bool pending, sent;
  final Object? error;
  String get body =>
      [reason.trim(), note.trim()].where((v) => v.isNotEmpty).join('\n\n');
}

class WalkingChatState {
  const WalkingChatState({this.records = const {}, this.reports = const {}});
  final Map<String, WalkingChatRecord> records;
  final Map<String, WalkingReportDraft> reports;
}

final walkingChatProvider =
    NotifierProvider<WalkingChatController, WalkingChatState>(
      WalkingChatController.new,
    );

/// Account-scoped memory only. No private agreement fields are cached to disk.
class WalkingChatController extends Notifier<WalkingChatState> {
  int _generation = 0;
  @override
  WalkingChatState build() {
    ref.watch(communityRepositoryProvider);
    ++_generation;
    ref.onDispose(() => ++_generation);
    return const WalkingChatState();
  }

  bool _current(int generation) => ref.mounted && generation == _generation;
  void _record(String id, WalkingChatRecord value) => state = WalkingChatState(
    records: {...state.records, id: value},
    reports: state.reports,
  );
  void _report(String id, WalkingReportDraft value) => state = WalkingChatState(
    records: state.records,
    reports: {...state.reports, id: value},
  );

  Future<void> load(String conversationId, {bool afterCommand = false}) async {
    if (state.records[conversationId]?.loading == true ||
        (!afterCommand && state.records[conversationId]?.pending == true)) {
      return;
    }
    final generation = _generation;
    final previous = state.records[conversationId];
    // Old rights/private information must not survive a refresh failure.
    _record(
      conversationId,
      WalkingChatRecord(loading: true, pending: previous?.pending ?? false),
    );
    try {
      final repo = ref.read(communityRepositoryProvider);
      final data = await repo.load();
      if (!_current(generation)) return;
      final uid = repo.userId;
      final conversation = findRow(data, 'conversations', conversationId);
      if (!walkingChatMember(data, conversationId, uid) ||
          conversation?['kind'] != 'walk') {
        _record(conversationId, const WalkingChatRecord());
        return;
      }
      final requestId = conversation!['context_id'] as String?;
      if (requestId == null) {
        _record(conversationId, const WalkingChatRecord());
        return;
      }
      Json? item;
      final request = findRow(data, 'walk_requests', requestId);
      final view = ['completed', 'cancelled'].contains(request?['status'])
          ? 'history'
          : 'active';
      for (var offset = 0; ; offset += 40) {
        final page = await ref
            .read(walkingRepositoryProvider)
            .list(view: view, offset: offset);
        if (!_current(generation)) return;
        item = page.where((row) => row['id'] == requestId).firstOrNull;
        if (item != null || page.length < 40) break;
      }
      if (item == null || !['owner', 'helper'].contains(item['my_role'])) {
        _record(conversationId, const WalkingChatRecord());
        return;
      }
      if (repo.isDemo) item = demoPersonalWalkingCard(item, data, uid);
      // Require both agreement participation and active chat membership, even
      // when a demo repository returns a broad snapshot.
      final agreement = rows(
        data,
        'walk_agreements',
      ).where((a) => a['request_id'] == requestId).firstOrNull;
      if (uid == null ||
          agreement == null ||
          (item['owner_id'] != uid && agreement['helper_id'] != uid)) {
        _record(conversationId, const WalkingChatRecord());
        return;
      }
      final instructions =
          rows(data, 'walk_details')
                  .where((d) => d['request_id'] == requestId)
                  .firstOrNull?['instructions']
              as String?;
      _record(
        conversationId,
        WalkingChatRecord(
          item: item,
          instructions: instructions,
          pending: previous?.pending ?? false,
        ),
      );
    } catch (error) {
      if (_current(generation)) {
        _record(
          conversationId,
          WalkingChatRecord(error: error, pending: previous?.pending ?? false),
        );
      }
    }
  }

  Future<void> advance(String id, String action) async {
    final record = state.records[id];
    final item = record?.item;
    if (item == null ||
        record!.pending ||
        record.loading ||
        !walkingChatPermittedActions(item).contains(action)) {
      return;
    }
    final next = {
      'start': 'in_progress',
      'finish': 'awaiting_confirmation',
      'confirm': 'completed',
    }[action];
    if (next == null) return;
    final generation = _generation;
    _record(
      id,
      WalkingChatRecord(
        item: item,
        instructions: record.instructions,
        pending: true,
      ),
    );
    Object? failure;
    try {
      await ref.read(communityProvider.notifier).command('advance_walk', {
        'request_in': item['id'],
        'next_status': next,
      });
    } catch (error) {
      failure = error;
    }
    if (!_current(generation)) return;
    await load(id, afterCommand: true);
    if (!_current(generation)) return;
    final refreshed = state.records[id]!;
    _record(
      id,
      WalkingChatRecord(
        item: refreshed.item,
        instructions: refreshed.instructions,
        error: refreshed.error,
        actionError: failure,
      ),
    );
  }

  void editReport(String id, {String? reason, String? note}) {
    final draft = state.reports[id] ?? const WalkingReportDraft();
    if (draft.pending || draft.sent) return;
    _report(
      id,
      WalkingReportDraft(
        reason: reason ?? draft.reason,
        note: note ?? draft.note,
      ),
    );
  }

  Future<void> report(String id) async {
    final draft = state.reports[id] ?? const WalkingReportDraft();
    final item = state.records[id]?.item;
    if (item == null ||
        draft.pending ||
        draft.sent ||
        draft.reason.trim().isEmpty ||
        draft.body.runes.length > 1000) {
      return;
    }
    final generation = _generation;
    _report(
      id,
      WalkingReportDraft(reason: draft.reason, note: draft.note, pending: true),
    );
    try {
      // Report success follows the write itself; a failed unrelated snapshot
      // refresh must not invite resubmitting an already accepted report.
      await ref.read(communityRepositoryProvider).command('report', {
        'target_kind': 'walk',
        'target_id': item['id'],
        'reason': draft.body,
      });
      if (_current(generation)) _report(id, WalkingReportDraft(sent: true));
    } catch (error) {
      if (_current(generation)) {
        _report(
          id,
          WalkingReportDraft(
            reason: draft.reason,
            note: draft.note,
            error: error,
          ),
        );
      }
    }
  }
}

bool walkingChatMember(CommunityData data, String id, String? uid) =>
    uid != null &&
    rows(data, 'conversation_members').any(
      (m) =>
          m['conversation_id'] == id &&
          m['user_id'] == uid &&
          m['left_at'] == null &&
          m['active'] != false,
    );

List<String> walkingChatPermittedActions(Json item) {
  final role = item['my_role'], status = item['status'];
  final eligible = <String>{
    if (role == 'helper' && status == 'assigned') 'start',
    if (role == 'helper' && status == 'in_progress') 'finish',
    if (role == 'owner' && status == 'awaiting_confirmation') 'confirm',
    if (status == 'completed' && role == 'owner') 'review_helper',
    if (status == 'completed' && role == 'helper') 'review_owner',
  };
  return walkingActions(item).where(eligible.contains).toList();
}

String? walkingChatNextAction(Json item) {
  final allowed = walkingChatPermittedActions(item);
  return [
    'confirm',
    'finish',
    'start',
    'review_helper',
    'review_owner',
  ].where(allowed.contains).firstOrNull;
}
