import '../../l10n/localization.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/backend/backend.dart';
import '../../core/ui/components.dart';

final emailConfirmationServiceProvider = Provider(
  (ref) => EmailConfirmationService(ref.read(backendProvider)),
);

class EmailConfirmationService {
  EmailConfirmationService(this.client);
  final SupabaseClient? client;
  Future<void> resend(String email) async {
    if (client == null) throw StateError('Auth unavailable');
    try {
      await client!.auth.resend(
        type: OtpType.signup,
        email: email,
        emailRedirectTo: AppConfig.callback,
      );
    } on AuthException catch (error) {
      final status = int.tryParse(error.statusCode ?? '500') ?? 500;
      // Account-specific failures must not reveal whether an address exists.
      if (status == 429 || status >= 500) rethrow;
    }
  }
}

class EmailConfirmationPanel extends ConsumerStatefulWidget {
  const EmailConfirmationPanel({
    required this.email,
    required this.onLogin,
    required this.onChangeEmail,
    super.key,
  });
  final String email;
  final VoidCallback onLogin, onChangeEmail;
  @override
  ConsumerState<EmailConfirmationPanel> createState() => _ConfirmationState();
}

class _ConfirmationState extends ConsumerState<EmailConfirmationPanel> {
  int seconds = 60;
  bool busy = false;
  Timer? timer;
  void cooldown() {
    timer?.cancel();
    seconds = 60;
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => seconds--);
      if (seconds == 0) timer.cancel();
    });
  }

  @override
  void initState() {
    super.initState();
    cooldown();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: 24),
      Text(
        "Откройте письмо для {p0} и подтвердите адрес.".tr(
          context,
          arguments: {'p0': widget.email},
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      Text(
        "После подтверждения вернитесь в приложение. Если открыли письмо на другом устройстве, войдите с email и паролем."
            .tr(context),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: busy ? null : widget.onLogin,
        child: Text("Адрес подтверждён — войти".tr(context)),
      ),
      TextButton(
        onPressed: busy || seconds > 0
            ? null
            : () async {
                if (busy || seconds > 0) return;
                setState(() => busy = true);
                try {
                  await ref
                      .read(emailConfirmationServiceProvider)
                      .resend(widget.email);
                  if (context.mounted) {
                    notice(
                      context,
                      "Если адрес ожидает подтверждения, письмо будет отправлено."
                          .tr(context),
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    notice(
                      context,
                      "Повторная отправка недоступна. Попробуйте позже.".tr(
                        context,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      busy = false;
                      cooldown();
                    });
                  }
                }
              },
        child: Text(
          seconds > 0
              ? "Отправить повторно через {p0} с".tr(
                  context,
                  arguments: {'p0': seconds},
                )
              : "Отправить письмо повторно".tr(context),
        ),
      ),
      TextButton(
        onPressed: busy ? null : widget.onChangeEmail,
        child: Text("Изменить email".tr(context)),
      ),
    ],
  );
}
