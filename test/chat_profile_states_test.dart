import 'package:petfriendly/features/notifications/notifications_screen.dart';
import 'package:petfriendly/features/notifications/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/core/storage/prototype_store.dart';
import 'package:petfriendly/core/theme/studio_theme.dart';
import 'package:petfriendly/features/community/data/community_repository.dart';
import 'package:petfriendly/features/profiles/profile_screen.dart';
import 'package:petfriendly/features/chat/chat_info_sheet.dart';
import 'package:petfriendly/features/notifications/notification_preferences.dart';
import 'widget_test.dart' show MemoryPreferences;

class PendingProfile extends CommunityController {
  PendingProfile(this.future);
  @override
  final Future<CommunityData> future;
  @override
  Future<CommunityData> build() => future;
}

class PermissionService extends NotificationService {
  PermissionService(this.granted);
  final bool granted;
  int requests = 0;
  @override
  Future<bool> enable(SupabaseClient? client) async {
    requests++;
    return granted;
  }

  @override
  Future<void> dispose() async {}
}

void main() {
  for (final granted in [false, true]) {
    testWidgets(
      'Notification permission is requested explicitly and denial is respected granted=$granted',
      (tester) async {
        final service = PermissionService(granted);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              preferencesProvider.overrideWithValue(MemoryPreferences()),
              notificationServiceProvider.overrideWithValue(service),
            ],
            child: MaterialApp(
              theme: studioTheme(Brightness.light),
              home: const Scaffold(body: NotificationSettingsSheet()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(service.requests, 0);
        expect(find.text('Настроить уведомления'), findsNothing);
        await tester.ensureVisible(find.text('Включить на устройстве'));
        await tester.tap(find.text('Включить на устройстве'));
        await tester.pumpAndSettle();
        expect(service.requests, 1);
        expect(
          find.text('Проверить локальное уведомление'),
          granted ? findsOneWidget : findsNothing,
        );
        expect(
          find.text(
            'Разрешение не получено. Уведомления можно включить в настройках устройства.',
          ),
          granted ? findsNothing : findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'Recent events never duplicate notification preferences or mask loading as empty',
    (tester) async {
      final future = Completer<CommunityData>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesProvider.overrideWithValue(MemoryPreferences()),
            communityProvider.overrideWith(() => PendingProfile(future.future)),
          ],
          child: MaterialApp(
            theme: studioTheme(Brightness.light),
            home: const NotificationsScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Загружаем уведомления…'), findsOneWidget);
      expect(find.byType(Switch), findsNothing);
      expect(find.text('Включить на устройстве'), findsNothing);
      expect(find.text('Пока нет новых событий.'), findsNothing);
      future.complete({'notifications': []});
      await tester.pumpAndSettle();
      expect(find.text('Пока нет новых событий.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Profile loading and errors never announce empty content', (
    tester,
  ) async {
    final future = Completer<CommunityData>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesProvider.overrideWithValue(MemoryPreferences()),
          communityRepositoryProvider.overrideWithValue(
            DemoCommunityRepository(seedSamples: false),
          ),
          communityProvider.overrideWith(() => PendingProfile(future.future)),
        ],
        child: MaterialApp(
          theme: studioTheme(Brightness.light),
          home: const Scaffold(body: ProfileScreen()),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Загружаем профиль…'), findsOneWidget);
    expect(find.text('Пока нет избранных мест'), findsNothing);
    future.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(find.text('Не удалось загрузить'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
    expect(find.text('Добавьте своего питомца'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  test(
    'Community participants come from community membership, not an absent direct-chat list',
    () {
      final data = <String, List<Map<String, dynamic>>>{
        'group_members': [
          {'group_id': 'group', 'user_id': 'member'},
          {'group_id': 'other', 'user_id': 'stranger'},
        ],
        'conversation_members': [],
      };
      expect(
        chatMemberRows(data, {
          'id': 'chat',
          'kind': 'group',
          'context_id': 'group',
        }).single['user_id'],
        'member',
      );
    },
  );
  test(
    'Notification feed category preferences persist on device without payloads',
    () async {
      final memory = MemoryPreferences();
      final first = ProviderContainer(
        overrides: [preferencesProvider.overrideWithValue(memory)],
      );
      await first
          .read(notificationPreferencesProvider.notifier)
          .setEnabled('message', false);
      first.dispose();
      final second = ProviderContainer(
        overrides: [preferencesProvider.overrideWithValue(memory)],
      );
      addTearDown(second.dispose);
      expect(second.read(notificationPreferencesProvider)['message'], false);
      expect(second.read(notificationPreferencesProvider)['walk'], true);
      expect(memory.values['notifications.message'], 'false');
      expect(notificationCategory('walk_assigned'), 'walk');
    },
  );
}
