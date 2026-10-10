import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../core/backend/backend.dart';
import '../../core/ui/components.dart';
import '../community/data/community_repository.dart';
import 'notification_service.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});
  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsState();
}

class _NotificationsState extends ConsumerState<NotificationsScreen> {
  NotificationService get service => ref.read(notificationServiceProvider);
  bool enabled = false, busy = false;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(communityProvider).value ?? {};
    return Scaffold(
      appBar: AppBar(title: const Text('Уведомления')),
      body: PageBody(
        children: [
          const ScreenIntro('Всё важное\nпод рукой.', compact: true),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    setState(() => busy = true);
                    try {
                      await service.enable(ref.read(backendProvider));
                      if (mounted) setState(() => enabled = true);
                    } catch (_) {
                      if (context.mounted) {
                        notice(context, 'Не удалось включить уведомления');
                      }
                    } finally {
                      if (mounted) setState(() => busy = false);
                    }
                  },
            child: const Text('Настроить уведомления'),
          ),
          if (enabled)
            TextButton(
              onPressed: () => service.show(
                'PetFriendly',
                'Тестовое уведомление без личных данных.',
              ),
              child: const Text('Проверить локальное уведомление'),
            ),
          if (Firebase.apps.isEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Облачные push ещё не подключены. Внутренние уведомления доступны в приложении.',
            ),
          ],
          const SectionTitle('Последние события'),
          if (rows(data, 'notifications').isEmpty)
            const Text('Пока нет новых событий.'),
          ...rows(data, 'notifications').map(
            (n) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications_outlined),
              title: Text(switch (n['kind']) {
                'message' => 'Новое сообщение',
                'walk_assigned' => 'Вас выбрали для выгула',
                'walk_application' => 'Новый отклик на выгул',
                'walk_status' => 'Статус прогулки изменился',
                _ => 'Обновление встречи',
              }),
              subtitle: Text('${n['created_at']}'),
            ),
          ),
        ],
      ),
    );
  }
}
