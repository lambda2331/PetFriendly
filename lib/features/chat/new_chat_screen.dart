import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/ui/components.dart';
import '../community/data/community_repository.dart';

class NewChatScreen extends ConsumerStatefulWidget {
  const NewChatScreen({super.key});
  @override
  ConsumerState<NewChatScreen> createState() => _NewChatState();
}

class _NewChatState extends ConsumerState<NewChatScreen> {
  String query = '';
  String? opening;
  Future<void> open(String id) async {
    if (opening != null) return;
    setState(() => opening = id);
    try {
      final chat = await ref.read(communityProvider.notifier).command(
        'direct',
        {'target': id},
      );
      if (mounted && chat != null) {
        context.pushReplacement('/chat/$chat');
      }
    } catch (_) {
      if (mounted) {
        notice(context, 'Не удалось открыть переписку. Повторите попытку.');
      }
    } finally {
      if (mounted) setState(() => opening = null);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Новая переписка')),
    body: ref
        .watch(communityProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(communityProvider),
              child: const Text('Повторить загрузку'),
            ),
          ),
          data: (data) {
            final repository = ref.read(communityRepositoryProvider);
            final blocked = rows(data, 'blocks')
                .where((b) => b['user_id'] == repository.userId)
                .map((b) => b['target_id'])
                .toSet();
            final people = rows(data, 'profiles')
                .where(
                  (p) =>
                      p['id'] != repository.userId &&
                      !blocked.contains(p['id']) &&
                      (p['display_name'] as String? ?? '')
                          .toLowerCase()
                          .contains(query.trim().toLowerCase()),
                )
                .toList();
            return PageBody(
              children: [
                TextField(
                  onChanged: (value) => setState(() => query = value),
                  decoration: const InputDecoration(
                    labelText: 'Поиск по имени',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 20),
                if (people.isEmpty)
                  const Text(
                    'Пока некого выбрать. Другой участник появится здесь после регистрации.',
                  ),
                for (final person in people)
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(
                      person['display_name'] as String? ?? 'Участник',
                    ),
                    subtitle: (person['district'] as String? ?? '').isEmpty
                        ? null
                        : Text(person['district'] as String),
                    trailing: opening == person['id']
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chat_bubble_outline),
                    enabled: opening == null,
                    onTap: () => open(person['id'] as String),
                  ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: opening == null
                      ? () => context.push('/edit/group')
                      : null,
                  icon: const Icon(Icons.group_add_outlined),
                  label: const Text('Создать сообщество'),
                ),
              ],
            );
          },
        ),
  );
}
