import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/backend/backend.dart';
import '../../core/ui/components.dart';
import '../../core/time/display_time.dart';
import '../../core/storage/prototype_store.dart';
import '../community/data/community_repository.dart';
import '../community/data/form_drafts.dart';
import '../chat/chat_repository.dart';
import '../chat/inbox_repository.dart';
import '../auth/reauthentication.dart';
import '../auth/account_actions.dart';
import '../notifications/notification_service.dart';

class AccountSecurityScreen extends ConsumerStatefulWidget {
  const AccountSecurityScreen({super.key});
  @override
  ConsumerState<AccountSecurityScreen> createState() => _SecurityState();
}

class _SecurityState extends ConsumerState<AccountSecurityScreen> {
  bool busy = false;
  Future<bool> reauthenticate() async {
    final client = ref.read(backendProvider);
    if (client == null) return false;
    final originalUser = client.auth.currentUser?.id;
    final identities = client.auth.currentUser?.identities ?? [];
    final passwordAvailable = identities.any(
      (identity) => identity.provider == 'email',
    );
    final providers = ReauthProvider.values
        .where(
          (p) => p.enabled && identities.any((i) => i.provider == p.identity),
        )
        .toList();
    ReauthProvider? selected = providers.length == 1 && !passwordAvailable
        ? providers.first
        : null;
    if (providers.isNotEmpty && (passwordAvailable || providers.length > 1)) {
      final method = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Подтвердите вход'),
          children: [
            for (final provider in providers)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, provider.name),
                child: Text('Через ${provider.label}'),
              ),
            if (passwordAvailable)
              SimpleDialogOption(
                onPressed: () => Navigator.pop(ctx, 'password'),
                child: const Text('С паролем'),
              ),
          ],
        ),
      );
      if (method == null || !mounted) return false;
      selected = providers.where((p) => p.name == method).firstOrNull;
    }
    if (selected != null) {
      final confirmed =
          await context.push<bool>('/reauth/${selected.name}') ?? false;
      return confirmed &&
          originalUser != null &&
          client.auth.currentUser?.id == originalUser;
    }
    final email = client.auth.currentUser?.email;
    if (email == null) {
      notice(context, 'Повторно войдите через связанный провайдер');
      return false;
    }
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => const _ReauthenticationDialog(),
    );
    if (result == null) return false;
    try {
      await client.auth.signInWithPassword(
        email: email,
        password: result['password']!,
      );
      if (client.auth.currentUser?.id != originalUser) return false;
      final factors = await client.auth.mfa.listFactors();
      if (factors.totp.isNotEmpty) {
        await client.auth.mfa.challengeAndVerify(
          factorId: factors.totp.first.id,
          code: result['code'] ?? '',
        );
      }
      return true;
    } catch (_) {
      if (mounted) notice(context, 'Повторная проверка не пройдена');
      return false;
    }
  }

  void clearAccount() {
    ref.invalidate(formDraftsProvider);
    ref.invalidate(communityProvider);
    ref.invalidate(chatProvider);
    ref.invalidate(chatInboxProvider);
    ref.invalidate(chatReadProvider);
    ref.invalidate(chatRepositoryProvider);
    ref.invalidate(chatMessagesProvider);
    ref.read(prototypeProvider.notifier).clearAccount();
  }

  Future<void> run(String kind) async {
    final client = ref.read(backendProvider);
    if (client == null) {
      notice(context, 'Эта функция доступна после подключения аккаунта');
      return;
    }
    if (!await reauthenticate() || !mounted) return;
    setState(() => busy = true);
    try {
      if (kind == 'export') {
        final data = await client.rpc('export_my_data');
        if (mounted) {
          await showDialog<void>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Ваши данные'),
              content: SingleChildScrollView(
                child: SelectableText(
                  const JsonEncoder.withIndent('  ').convert(data),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Закрыть'),
                ),
              ],
            ),
          );
        }
      }
      if (kind == 'sessions') {
        await ref.read(notificationServiceProvider).unregister(client);
        await client.rpc('revoke_my_sessions');
        await ref
            .read(accountActionsProvider.notifier)
            .signOut(scope: SignOutScope.global);
        if (mounted) context.go('/login');
      }
      if (kind == 'delete') {
        await ref.read(notificationServiceProvider).unregister(client);
        final result = await client.functions.invoke('delete-account');
        if (result.status != 200) throw StateError('Deletion not completed');
        await ref.read(accountActionsProvider.notifier).signOut();
        if (mounted) context.go('/login');
      }
    } catch (_) {
      if (mounted) {
        notice(context, 'Не удалось завершить операцию. Повторите позже.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(backendProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Безопасность')),
      body: PageBody(
        children: [
          const ScreenIntro('Личное\nостаётся личным.', compact: true),
          const SizedBox(height: 20),
          const Text(
            'Публично показывается только район. Точные инструкции выгула доступны участникам договорённости.',
          ),
          const SectionTitle('Аккаунт'),
          if (client == null)
            const Text('Сейчас используется демонстрационный профиль.'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Двухфакторная защита'),
            subtitle: const Text('Код из приложения-аутентификатора'),
            trailing: const Icon(Icons.chevron_right),
            onTap: client == null
                ? null
                : () => context.push('/mfa?enroll=true'),
          ),
          if (client != null)
            FutureBuilder(
              builder: (context, snapshot) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle('Активные сессии'),
                  if (snapshot.hasData)
                    ...(snapshot.data as List).map(
                      (s) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.devices_outlined),
                        title: Text(
                          s['current_session'] == true
                              ? 'Текущая сессия'
                              : 'Другая сессия',
                        ),
                        subtitle: MetadataLine(
                          items: [readableLocalDateTime(s['created_at'])],
                        ),
                      ),
                    ),
                  if (snapshot.hasError)
                    const Text('Не удалось загрузить сессии'),
                ],
              ),
              future: client.rpc('my_sessions'),
            ),
          OutlinedButton(
            onPressed: busy ? null : () => run('sessions'),
            child: const Text('Выйти со всех устройств'),
          ),
          const SectionTitle('Ваши данные'),
          OutlinedButton(
            onPressed: busy ? null : () => run('export'),
            child: const Text('Посмотреть экспорт данных'),
          ),
          const SizedBox(height: 10),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: busy
                ? null
                : () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Удалить аккаунт?'),
                        content: const Text(
                          'Профиль и связанные личные данные будут удалены. Отменить это действие нельзя.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Отмена'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Удалить'),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) run('delete');
                  },
            child: const Text('Удалить аккаунт'),
          ),
          if (client != null) ...[
            const SizedBox(height: 20),
            TextButton(
              onPressed: () async {
                try {
                  await ref.read(accountActionsProvider.notifier).signOut();
                  if (context.mounted) context.go('/login');
                } catch (_) {
                  if (context.mounted) {
                    notice(context, 'Не удалось выйти. Повторите попытку.');
                  }
                }
              },
              child: const Text('Выйти на этом устройстве'),
            ),
          ],
          if (busy) const LinearProgressIndicator(),
        ],
      ),
    );
  }
}

class _ReauthenticationDialog extends StatefulWidget {
  const _ReauthenticationDialog();
  @override
  State<_ReauthenticationDialog> createState() => _ReauthenticationState();
}

class _ReauthenticationState extends State<_ReauthenticationDialog> {
  final password = TextEditingController(), code = TextEditingController();
  @override
  void dispose() {
    password.dispose();
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Подтвердите действие'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          textAlignVertical: TextAlignVertical.top,
          controller: password,
          obscureText: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: const InputDecoration(labelText: 'Пароль'),
        ),
        const SizedBox(height: 12),
        TextField(
          textAlignVertical: TextAlignVertical.top,
          controller: code,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Код MFA, если включена',
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Отмена'),
      ),
      TextButton(
        onPressed: () => Navigator.pop(context, {
          'password': password.text,
          'code': code.text.trim(),
        }),
        child: const Text('Подтвердить'),
      ),
    ],
  );
}
