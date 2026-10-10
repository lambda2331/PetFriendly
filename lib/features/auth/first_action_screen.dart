import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/ui/components.dart';

/// Shown once after the user completes their first profile, with no new
/// persisted preference and no additional personal-data collection.
class FirstActionScreen extends StatelessWidget {
  const FirstActionScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Начнём с прогулки')),
    body: PageBody(
      children: [
        const ScreenIntro(
          'Что вам сейчас нужно?',
          compact: true,
          subtitle:
              'Профиль готов. Выберите первый шаг — остальные разделы всегда рядом.',
        ),
        const SizedBox(height: 24),
        ListTile(
          leading: const Icon(Icons.park_outlined),
          title: const Text('Найти место для прогулки'),
          subtitle: const Text('Парки и площадки в выбранном городе'),
          trailing: const Icon(Icons.arrow_forward),
          onTap: () {
            context.go('/nearby');
            context.push('/places');
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.people_outline),
          title: const Text('Познакомиться с владельцами'),
          subtitle: const Text('Люди рядом и сообщества по интересам'),
          trailing: const Icon(Icons.arrow_forward),
          onTap: () => context.go('/people'),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.pets_outlined),
          title: const Text('Найти помощь с выгулом'),
          subtitle: const Text('Посмотреть раздел и создать заявку'),
          trailing: const Icon(Icons.arrow_forward),
          onTap: () => context.go('/walks'),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => context.go('/nearby'),
          child: const Text('Перейти к карте'),
        ),
      ],
    ),
  );
}
