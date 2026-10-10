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
        'Откройте письмо для ${widget.email} и подтвердите адрес.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      const Text(
        'После подтверждения вернитесь в приложение. Если открыли письмо на другом устройстве, войдите с email и паролем.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: busy ? null : widget.onLogin,
        child: const Text('Адрес подтверждён — войти'),
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
                      'Если адрес ожидает подтверждения, письмо будет отправлено.',
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    notice(
                      context,
                      'Повторная отправка недоступна. Попробуйте позже.',
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
              ? 'Отправить повторно через $seconds с'
              : 'Отправить письмо повторно',
        ),
      ),
      TextButton(
        onPressed: busy ? null : widget.onChangeEmail,
        child: const Text('Изменить email'),
      ),
    ],
  );
}
