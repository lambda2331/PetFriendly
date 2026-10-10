import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class PushDevice {
  bool get available;
  Future<bool> authorize();
  Future<void> autoInit(bool enabled);
  Future<String?> currentToken();
  Future<void> deleteToken();
  Stream<String> get tokenChanges;
  Stream<void> get foregroundMessages;
}

class FirebasePushDevice implements PushDevice {
  @override
  bool get available => Firebase.apps.isNotEmpty;
  @override
  Future<bool> authorize() async {
    final permission = await FirebaseMessaging.instance.requestPermission();
    return permission.authorizationStatus == AuthorizationStatus.authorized ||
        permission.authorizationStatus == AuthorizationStatus.provisional;
  }

  @override
  Future<void> autoInit(bool enabled) =>
      FirebaseMessaging.instance.setAutoInitEnabled(enabled);
  @override
  Future<String?> currentToken() async {
    if (defaultTargetPlatform == TargetPlatform.iOS &&
        await FirebaseMessaging.instance.getAPNSToken() == null) {
      return null;
    }
    return FirebaseMessaging.instance.getToken();
  }

  @override
  Future<void> deleteToken() => FirebaseMessaging.instance.deleteToken();
  @override
  Stream<String> get tokenChanges => FirebaseMessaging.instance.onTokenRefresh;
  @override
  Stream<void> get foregroundMessages =>
      FirebaseMessaging.onMessage.map<void>((_) {});
}

/// One registration owner at a time. Logout waits for in-flight writes before
/// removing registrations, so a late token refresh cannot reattach the device.
class DevicePushRegistration {
  DevicePushRegistration(this.device);
  final PushDevice device;
  StreamSubscription<String>? _tokens;
  StreamSubscription<void>? _messages;
  Future<void> _enabling = Future.value(), _writing = Future.value();
  final _registered = <String>{};
  int _generation = 0;
  bool _detached = false;

  Future<void> enable(SupabaseClient client, void Function() onMessage) {
    _detached = false;
    _enabling = _enable(client, onMessage, ++_generation);
    return _enabling;
  }

  Future<void> _enable(
    SupabaseClient client,
    void Function() onMessage,
    int generation,
  ) async {
    await _cancelListeners();
    if (!device.available) return;
    final owner = client.auth.currentUser?.id;
    if (owner == null) {
      throw StateError('Sign in before registering notifications');
    }
    bool current() =>
        generation == _generation && client.auth.currentUser?.id == owner;
    if (!await device.authorize()) {
      throw StateError('Notifications not authorized');
    }
    if (!current()) return;
    await device.autoInit(true);
    final token = await device.currentToken();
    if (!current()) return;
    Future<void> save(String token) {
      final write = _writing.then((_) async {
        if (!current()) return;
        await client.from('device_tokens').upsert({
          'token': token,
          'user_id': owner,
          'platform': defaultTargetPlatform.name,
        });
        _registered.add(token);
      });
      // Keep the queue usable after a failed write; the initial caller still
      // receives the error, and refresh errors never escape a stream callback.
      _writing = write.catchError((Object _) {});
      return write;
    }

    if (token != null) await save(token);
    if (!current()) return;
    _tokens = device.tokenChanges.listen((token) {
      unawaited(save(token).catchError((Object _) {}));
    });
    _messages = device.foregroundMessages.listen((_) {
      if (current()) onMessage();
    });
  }

  Future<void> unregister(SupabaseClient? client) async {
    if (_detached) return;
    ++_generation;
    await _cancelListeners();
    try {
      await _enabling;
    } catch (_) {
      // Failed setup may still have registered an earlier token.
    }
    await _writing;
    final owner = client?.auth.currentUser?.id;
    if (device.available) {
      await device.autoInit(false);
      final token = await device.currentToken();
      if (token != null) _registered.add(token);
    }
    if (client != null && owner != null) {
      for (final token in _registered) {
        await client
            .from('device_tokens')
            .delete()
            .eq('user_id', owner)
            .eq('token', token);
      }
    }
    // Do not complete logout if registration removal or token invalidation
    // failed; retain the session so the user can retry safely.
    if (device.available) await device.deleteToken();
    _registered.clear();
    _detached = true;
  }

  Future<void> _cancelListeners() async {
    await _tokens?.cancel();
    await _messages?.cancel();
    _tokens = null;
    _messages = null;
  }

  Future<void> dispose() async {
    ++_generation;
    await _cancelListeners();
  }
}
