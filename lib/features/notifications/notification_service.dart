import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'device_push_registration.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  ref.onDispose(() => unawaited(service.dispose()));
  return service;
});

class NotificationService {
  final local = FlutterLocalNotificationsPlugin();
  bool initialized = false;
  final push = DevicePushRegistration(FirebasePushDevice());
  Future<bool> enable(SupabaseClient? client) async {
    if (!initialized) {
      await local.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      initialized = true;
    }
    bool? permission;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      permission = await local
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      permission = await local
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    }
    if (permission != true) return false;
    if (client != null) {
      await push.enable(
        client,
        () => unawaited(
          show(
            'Новое уведомление',
            'Откройте PetFriendly, чтобы посмотреть подробности.',
          ),
        ),
      );
    }
    return true;
  }

  Future<void> show(String title, String body) async {
    if (!initialized) return;
    await local.show(
      id: 1,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'petfriendly',
          'PetFriendly',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> dispose() async {
    await push.dispose();
  }

  Future<void> unregister(SupabaseClient? client) async {
    await push.unregister(client);
    if (initialized) await local.cancelAll();
  }
}
