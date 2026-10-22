import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'community_repository.dart';
import '../../../core/backend/backend.dart';
import 'event_location.dart';

/// Account-scoped, memory-only drafts. No preferences, database or disk writes.
class FormDraft {
  const FormDraft(
    this.values,
    this.when,
    this.zone,
    this.petId,
    this.photo, {
    this.eventLocation,
  });
  final Map<String, String> values;
  final DateTime when;
  final String? zone, petId;
  final Uint8List? photo;
  final EventLocation? eventLocation;
}

class FormDrafts {
  final _values = <String, FormDraft>{};
  FormDraft? read(String key) => _values[key];
  void keep(String key, FormDraft draft) => _values[key] = draft;
  void discard(String key) => _values.remove(key);
  void clear() => _values.clear();
}

final formDraftsProvider = Provider<FormDrafts>((ref) {
  ref.watch(authStateProvider.select((state) => state.value?.id));
  ref.watch(communityRepositoryProvider.select((repo) => repo.userId));
  final drafts = FormDrafts();
  ref.onDispose(drafts.clear);
  return drafts;
});

String formActionLabel(
  String kind, {
  bool editing = false,
  bool welcome = false,
}) => welcome
    ? 'Сохранить и продолжить'
    : switch (kind) {
        'event' => 'Создать встречу',
        'walk' => 'Опубликовать заявку',
        'group' => 'Создать сообщество',
        'pet' => editing ? 'Сохранить питомца' : 'Добавить питомца',
        _ => 'Сохранить профиль',
      };
