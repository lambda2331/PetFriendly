import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/backend/backend.dart';
import '../../core/ui/components.dart';
import 'password_change.dart';

class PasswordScreen extends ConsumerStatefulWidget {
  const PasswordScreen({super.key});
  @override
  ConsumerState<PasswordScreen> createState() => _PasswordState();
}

class _PasswordState extends ConsumerState<PasswordScreen> {
  final password = TextEditingController(), confirm = TextEditingController();
  final nonce = TextEditingController();
  bool busy = false, confirmationRequired = false;
  @override
  void dispose() {
    password.dispose();
    confirm.dispose();
    nonce.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Новый пароль')),
    body: PageBody(
      children: [
        const ScreenIntro('Верните доступ\nк аккаунту.', compact: true),
        const SizedBox(height: 24),
        TextField(
          textAlignVertical: TextAlignVertical.top,
          controller: password,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          decoration: const InputDecoration(
            labelText: 'Новый пароль · минимум 12 символов',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          textAlignVertical: TextAlignVertical.top,
          controller: confirm,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          decoration: const InputDecoration(labelText: 'Повторите пароль'),
        ),
        const SizedBox(height: 20),
        if (confirmationRequired) ...[
          const Text('Подтвердите смену пароля кодом из письма.'),
          const SizedBox(height: 12),
          TextField(
            controller: nonce,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            decoration: const InputDecoration(labelText: 'Код подтверждения'),
          ),
          TextButton(
            onPressed: busy
                ? null
                : () async {
                    setState(() => busy = true);
                    try {
                      await ref
                          .read(passwordChangeServiceProvider)
                          .resendConfirmation();
                      if (context.mounted) notice(context, 'Код отправлен');
                    } catch (_) {
                      if (context.mounted) {
                        notice(
                          context,
                          'Не удалось отправить код. Повторите позже.',
                        );
                      }
                    } finally {
                      if (mounted) setState(() => busy = false);
                    }
                  },
            child: const Text('Отправить код ещё раз'),
          ),
          const SizedBox(height: 12),
        ],
        FilledButton(
          onPressed: busy
              ? null
              : () async {
                  final client = ref.read(backendProvider);
                  if (client == null) return;
                  if (password.text.length < 12 ||
                      password.text != confirm.text) {
                    notice(context, 'Проверьте длину и совпадение паролей');
                    return;
                  }
                  setState(() => busy = true);
                  try {
                    final result = await ref
                        .read(passwordChangeServiceProvider)
                        .update(
                          password.text,
                          nonce: confirmationRequired
                              ? nonce.text.trim()
                              : null,
                        );
                    if (result == PasswordChangeResult.mfaRequired) {
                      if (context.mounted) context.push('/mfa');
                      return;
                    }
                    if (result == PasswordChangeResult.confirmationRequired) {
                      if (mounted) setState(() => confirmationRequired = true);
                      return;
                    }
                    if (context.mounted) {
                      context.go('/auth/complete');
                      notice(context, 'Пароль изменён');
                    }
                  } catch (_) {
                    if (context.mounted) {
                      notice(
                        context,
                        'Не удалось изменить пароль. Повторите восстановление доступа.',
                      );
                    }
                  } finally {
                    if (!confirmationRequired) {
                      password.clear();
                      confirm.clear();
                    }
                    nonce.clear();
                    if (mounted) setState(() => busy = false);
                  }
                },
          child: Text(busy ? 'Сохраняем…' : 'Изменить пароль'),
        ),
      ],
    ),
  );
}
