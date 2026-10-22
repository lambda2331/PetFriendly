import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/prototype_store.dart';

/// Device-local preferences for the in-app notification feed; no private payloads.
class NotificationPreferences extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() {
    final prefs = ref.watch(preferencesProvider);
    return {
      for (final k in ['message', 'meeting', 'walk'])
        k: prefs.read('notifications.$k') != 'false',
    };
  }

  Future<void> setEnabled(String key, bool value) async {
    await ref.read(preferencesProvider).write('notifications.$key', '$value');
    state = {...state, key: value};
  }
}

final notificationPreferencesProvider =
    NotifierProvider<NotificationPreferences, Map<String, bool>>(
      NotificationPreferences.new,
    );
String notificationCategory(String? kind) => kind == 'message'
    ? 'message'
    : kind?.startsWith('walk') == true
    ? 'walk'
    : 'meeting';
