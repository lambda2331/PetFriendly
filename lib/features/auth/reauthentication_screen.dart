import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/backend/backend.dart';
import '../../core/ui/components.dart';
import 'reauthentication.dart';

class ProviderReauthenticationScreen extends ConsumerStatefulWidget {
  const ProviderReauthenticationScreen({required this.provider, super.key});
  final ReauthProvider provider;
  @override
  ConsumerState<ProviderReauthenticationScreen> createState() => _ReauthState();
}

class _ReauthState extends ConsumerState<ProviderReauthenticationScreen> {
  final code = TextEditingController();
  bool busy = false, started = false;
  Timer? expiryTimer;
  @override
  void dispose() {
    code.dispose();
    expiryTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(authSessionProvider);
    final service = ref.watch(
      providerReauthenticationProvider(widget.provider),
    );
    final status = service.status;
    return Scaffold(
      appBar: AppBar(title: const Text('Подтвердите действие')),
      body: PageBody(
        children: [
          ScreenIntro(
            'Повторный вход\nчерез ${widget.provider.label}.',
            compact: true,
          ),
          const SizedBox(height: 16),
          Text(
            'Выберите тот же аккаунт ${widget.provider.label}, с которым вошли в PetFriendly.',
          ),
          const SizedBox(height: 24),
          if (status == ReauthStatus.wrongAccount)
            const Text('Выбран другой аккаунт. Действие не будет выполнено.'),
          if (status == ReauthStatus.expired)
            const Text(
              'Проверка истекла. Вернитесь и начните действие заново.',
            ),
          if (status == ReauthStatus.needsMfa) ...[
            TextField(
              controller: code,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Код из приложения-аутентификатора',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (busy) return;
                      setState(() => busy = true);
                      try {
                        await service.verifyMfa(code.text.trim());
                      } catch (_) {
                        if (context.mounted) {
                          notice(context, 'Проверьте код и повторите попытку.');
                        }
                      } finally {
                        code.clear();
                        if (mounted) setState(() => busy = false);
                      }
                    },
              child: const Text('Подтвердить код'),
            ),
          ] else if (status == ReauthStatus.ready)
            FilledButton(
              onPressed: () {
                if (busy) return;
                if (service.status == ReauthStatus.ready) {
                  busy = true;
                  context.pop(true);
                } else {
                  setState(() {});
                }
              },
              child: const Text('Продолжить действие'),
            )
          else if (!started)
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (busy) return;
                      setState(() => busy = true);
                      try {
                        await service.begin();
                        expiryTimer?.cancel();
                        expiryTimer = Timer(const Duration(minutes: 3), () {
                          if (mounted) setState(() {});
                        });
                        if (mounted) setState(() => started = true);
                      } catch (_) {
                        if (context.mounted) {
                          notice(
                            context,
                            'Не удалось открыть ${widget.provider.label}. Попробуйте позже.',
                          );
                        }
                      } finally {
                        if (mounted) setState(() => busy = false);
                      }
                    },
              child: Text('Войти через ${widget.provider.label}'),
            )
          else if (status == ReauthStatus.waiting)
            Text(
              'Завершите вход на странице ${widget.provider.label} и вернитесь в приложение.',
            ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: busy ? null : () => context.pop(false),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }
}
