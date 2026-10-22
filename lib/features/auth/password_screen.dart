import '../../l10n/localization.dart';
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
    appBar: AppBar(title: Text("Новый пароль".tr(context))),
    body: PageBody(
      children: [
        ScreenIntro("Верните доступ\nк аккаунту.".tr(context), compact: true),
        const SizedBox(height: 24),
        TextField(
          textAlignVertical: TextAlignVertical.top,
          controller: password,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: "Новый пароль · минимум 12 символов".tr(context),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          textAlignVertical: TextAlignVertical.top,
          controller: confirm,
          obscureText: true,
          enableSuggestions: false,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: "Повторите пароль".tr(context),
          ),
        ),
        const SizedBox(height: 20),
        if (confirmationRequired) ...[
          Text("Подтвердите смену пароля кодом из письма.".tr(context)),
          const SizedBox(height: 12),
          TextField(
            controller: nonce,
            keyboardType: TextInputType.number,
            autofillHints: const [AutofillHints.oneTimeCode],
            decoration: InputDecoration(
              labelText: "Код подтверждения".tr(context),
            ),
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
                      if (context.mounted) {
                        notice(context, "Код отправлен".tr(context));
                      }
                    } catch (_) {
                      if (context.mounted) {
                        notice(
                          context,
                          "Не удалось отправить код. Повторите позже.".tr(
                            context,
                          ),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() => busy = false);
                      }
                    }
                  },
            child: Text("Отправить код ещё раз".tr(context)),
          ),
          const SizedBox(height: 12),
        ],
        FilledButton(
          onPressed: busy
              ? null
              : () async {
                  final client = ref.read(backendProvider);
                  if (client == null) {
                    return;
                  }
                  if (password.text.length < 12 ||
                      password.text != confirm.text) {
                    notice(
                      context,
                      "Проверьте длину и совпадение паролей".tr(context),
                    );
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
                      if (context.mounted) {
                        context.push('/mfa');
                      }
                      return;
                    }
                    if (result == PasswordChangeResult.confirmationRequired) {
                      if (mounted) {
                        setState(() => confirmationRequired = true);
                      }
                      return;
                    }
                    if (context.mounted) {
                      context.go('/auth/complete');
                      notice(context, "Пароль изменён".tr(context));
                    }
                  } catch (_) {
                    if (context.mounted) {
                      notice(
                        context,
                        "Не удалось изменить пароль. Повторите восстановление доступа."
                            .tr(context),
                      );
                    }
                  } finally {
                    if (!confirmationRequired) {
                      password.clear();
                      confirm.clear();
                    }
                    nonce.clear();
                    if (mounted) {
                      setState(() => busy = false);
                    }
                  }
                },
          child: Text(
            busy ? "Сохраняем…".tr(context) : "Изменить пароль".tr(context),
          ),
        ),
      ],
    ),
  );
}
