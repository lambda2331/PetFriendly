import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'notification_preferences.dart';
import '../../core/ui/studio_review.dart';
import '../../l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../core/backend/backend.dart';
import '../../core/ui/components.dart';
import '../community/data/community_repository.dart';
import 'notification_service.dart';

/// Recent events only. Notification preferences live in Settings.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({this.embedded = false, super.key});
  final bool embedded;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communityProvider);
    final prefs = ref.watch(notificationPreferencesProvider);
    final events =
        rows(state.value ?? {}, 'notifications')
            .where(
              (n) => prefs[notificationCategory(n['kind'] as String?)] == true,
            )
            .toList()
          ..sort(
            (a, b) => '${b['created_at']}'.compareTo('${a['created_at']}'),
          );
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.isLoading && !state.hasValue)
          StudioReviewState(
            title: 'Загружаем уведомления…'.tr(context),
            loading: true,
          )
        else if (state.hasError && !state.hasValue)
          StudioReviewState(
            title: 'Не удалось загрузить'.tr(context),
            message: 'Проверьте соединение и попробуйте снова.'.tr(context),
            icon: LucideIcons.cloudOff,
            action: OutlinedButton(
              onPressed: () => ref.invalidate(communityProvider),
              child: Text('Повторить'.tr(context)),
            ),
          )
        else if (events.isEmpty)
          StudioReviewState(
            title: 'Пока нет новых событий.'.tr(context),
            icon: LucideIcons.bell,
          )
        else
          for (var i = 0; i < events.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 12, endIndent: 12),
            StudioReviewRow(
              title: switch (events[i]['kind']) {
                'message' => 'Новое сообщение'.tr(context),
                'walk_assigned' => 'Вас выбрали для выгула'.tr(context),
                'walk_application' => 'Новый отклик на выгул'.tr(context),
                'walk_status' => 'Статус прогулки изменился'.tr(context),
                _ => 'Обновление встречи'.tr(context),
              },
              subtitle: _eventTime(context, events[i]['created_at']),
              leading: const Icon(LucideIcons.bell),
              trailing: const SizedBox.shrink(),
              onTap: () {
                final item = events[i],
                    id =
                        item['context_id'] ??
                        item['target_id'] ??
                        item['target'];
                final kind = '${item['kind']}';
                if (id == null || '$id'.isEmpty) {
                  notice(context, 'Запись недоступна'.tr(context));
                  return;
                }
                final route = kind == 'message'
                    ? '/chat/$id'
                    : kind.startsWith('walk_')
                    ? '/walk/$id'
                    : kind.startsWith('event_')
                    ? '/event/$id'
                    : null;
                if (route == null) {
                  notice(context, 'Запись недоступна'.tr(context));
                  return;
                }
                final router = GoRouter.of(context);
                if (embedded) Navigator.pop(context);
                router.push(route);
              },
            ),
          ],
      ],
    );
    if (embedded) {
      return StudioReviewSheet(
        title: 'Последние события'.tr(context),
        child: content,
      );
    }
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text('Последние события'.tr(context), style: studioSheetText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: content,
      ),
    );
  }
}

String _eventTime(BuildContext context, dynamic raw) {
  final date = DateTime.tryParse('$raw')?.toLocal();
  return date == null
      ? ''
      : DateFormat.yMMMd(context.languageCode).add_Hm().format(date);
}

class NotificationSettingsSheet extends ConsumerStatefulWidget {
  const NotificationSettingsSheet({super.key});
  @override
  ConsumerState<NotificationSettingsSheet> createState() =>
      _NotificationSettingsState();
}

class _NotificationSettingsState
    extends ConsumerState<NotificationSettingsSheet> {
  bool busy = false, enabled = false, denied = false;
  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(notificationPreferencesProvider);
    Future<void> change(String key, bool value) async {
      try {
        await ref
            .read(notificationPreferencesProvider.notifier)
            .setEnabled(key, value);
      } catch (_) {
        if (context.mounted) {
          notice(context, 'Не удалось изменить настройку'.tr(context));
        }
      }
    }

    return StudioReviewSheet(
      title: 'Уведомления'.tr(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(LucideIcons.bell, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Текст сообщений скрыт в уведомлениях.'.tr(context),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final (index, key, label, hint) in [
            (0, 'message', 'Сообщения', 'Новые сообщения в ваших чатах'),
            (
              1,
              'meeting',
              'Встречи и сообщества',
              'Приглашения и изменения встреч',
            ),
            (2, 'walk', 'Прогулки', 'Отклики и изменения прогулок'),
          ]) ...[
            if (index > 0) const Divider(height: 1),
            StudioReviewRow(
              title: label.tr(context),
              subtitle: hint.tr(context),
              onTap: () => change(key, !prefs[key]!),
              trailing: Switch(
                value: prefs[key]!,
                onChanged: (value) => change(key, value),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Категории действуют для списка событий в приложении.'.tr(context),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: busy
                ? null
                : () async {
                    setState(() => busy = true);
                    try {
                      final granted = await ref
                          .read(notificationServiceProvider)
                          .enable(ref.read(backendProvider));
                      if (mounted) {
                        setState(() {
                          enabled = granted;
                          denied = !granted;
                        });
                      }
                    } catch (_) {
                      if (context.mounted) {
                        notice(
                          context,
                          'Не удалось включить уведомления'.tr(context),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => busy = false);
                    }
                  },
            child: busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('Включить на устройстве'.tr(context)),
          ),
          if (denied) ...[
            const SizedBox(height: 12),
            Text(
              'Разрешение не получено. Уведомления можно включить в настройках устройства.'
                  .tr(context),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (enabled)
            TextButton(
              onPressed: () => ref
                  .read(notificationServiceProvider)
                  .show(
                    'PetFriendly',
                    'Тестовое уведомление без личных данных.'.tr(context),
                  ),
              child: Text('Проверить локальное уведомление'.tr(context)),
            ),
          if (Firebase.apps.isEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Облачные push ещё не подключены. Внутренние уведомления доступны в приложении.'
                  .tr(context),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
