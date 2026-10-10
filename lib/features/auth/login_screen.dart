import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/backend/backend.dart';
import 'account_entry_screen.dart';
import 'email_confirmation_panel.dart';
import '../../core/ui/components.dart';
import '../community/data/community_repository.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginState();
}

class _LoginState extends ConsumerState<LoginScreen> {
  final email = TextEditingController(), password = TextEditingController();
  final form = GlobalKey<FormState>();
  bool register = false, busy = false;
  bool awaitingConfirmation = false;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy) return;
    final client = ref.read(backendProvider);
    if (client == null) {
      notice(context, 'Предпросмотр: Auth не подключён');
      return;
    }
    if (!form.currentState!.validate()) return;
    setState(() => busy = true);
    try {
      if (register) {
        final result = await client.auth.signUp(
          email: email.text.trim(),
          password: password.text,
          emailRedirectTo: AppConfig.callback,
        );
        if (result.session == null) {
          if (mounted) setState(() => awaitingConfirmation = true);
          return;
        }
      } else {
        await client.auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
      ref.invalidate(communityProvider);
      ref.invalidate(accountEntryProvider);
      if (mounted) context.go('/auth/complete');
    } on AuthException catch (e) {
      if (mounted) {
        notice(
          context,
          e.statusCode == '429'
              ? 'Слишком много попыток. Попробуйте позже.'
              : 'Не удалось войти. Проверьте данные и подтверждение почты.',
        );
      }
    } catch (_) {
      if (mounted) {
        notice(context, 'Сервис входа недоступен. Попробуйте позже.');
      }
    } finally {
      password.clear();
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> oauth(String name) async {
    final client = ref.read(backendProvider);
    if (client == null) {
      notice(context, 'Предпросмотр: $name не подключён');
      return;
    }
    final enabled = switch (name) {
      'Google' => AppConfig.googleEnabled,
      'Apple' => AppConfig.appleEnabled,
      _ => AppConfig.telegramEnabled,
    };
    if (!enabled) {
      notice(context, '$name ещё не подключён');
      return;
    }
    try {
      final provider = switch (name) {
        'Google' => OAuthProvider.google,
        'Apple' => OAuthProvider.apple,
        _ => const OAuthProvider('custom:telegram'),
      };
      await client.auth.signInWithOAuth(
        provider,
        redirectTo: AppConfig.callback,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } catch (_) {
      if (mounted) notice(context, 'Провайдер ещё не настроен на сервере');
    }
  }

  @override
  Widget build(BuildContext context) {
    final configured = ref.watch(backendProvider) != null;
    if (awaitingConfirmation) {
      return Scaffold(
        appBar: AppBar(),
        body: PageBody(
          children: [
            Center(
              child: Icon(
                Icons.mark_email_read_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Подтвердите email',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            EmailConfirmationPanel(
              email: email.text.trim(),
              onLogin: () => setState(() {
                awaitingConfirmation = false;
                register = false;
              }),
              onChangeEmail: () => setState(() => awaitingConfirmation = false),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(),
      body: Form(
        key: form,
        child: PageBody(
          children: [
            const SizedBox(height: 8),
            Center(
              child: Icon(
                Icons.pets_outlined,
                color: Theme.of(context).colorScheme.onSurface,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              register ? 'Создать аккаунт' : 'Войти в PetFriendly',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Ваша компания для прогулок.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            if (!configured) ...[
              Text(
                'Демо входа · не вводите реальные пароли.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
            ],
            TextFormField(
              textAlignVertical: TextAlignVertical.top,
              controller: email,
              readOnly: !configured,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline),
              ),
              validator: (v) =>
                  v != null &&
                      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v.trim())
                  ? null
                  : 'Введите email',
            ),
            const SizedBox(height: 12),
            TextFormField(
              textAlignVertical: TextAlignVertical.top,
              controller: password,
              readOnly: !configured,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Пароль',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (v) =>
                  (v?.length ?? 0) >= 12 ? null : 'Не менее 12 символов',
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: busy ? null : submit,
              child: Text(
                busy
                    ? 'Подождите…'
                    : register
                    ? 'Создать аккаунт'
                    : 'Войти',
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => setState(() => register = !register),
                    child: Text(
                      register ? 'Уже есть аккаунт' : 'Создать аккаунт',
                    ),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      if (!configured) return;
                      final value = email.text.trim();
                      if (value.isEmpty) {
                        notice(context, 'Введите email');
                        return;
                      }
                      try {
                        await ref
                            .read(backendProvider)!
                            .auth
                            .resetPasswordForEmail(
                              value,
                              redirectTo: AppConfig.callback,
                            );
                      } catch (_) {}
                      if (context.mounted) {
                        notice(
                          context,
                          'Если аккаунт существует, письмо отправлено',
                        );
                      }
                    },
                    child: const Text('Забыли пароль?'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'или войти через',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...['Google', 'Apple', 'Telegram'].map(
                  (name) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 56,
                          height: 52,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: busy ? null : () => oauth(name),
                            child: Semantics(
                              label: 'Войти через $name',
                              child: name == 'Google'
                                  ? const Text(
                                      'G',
                                      style: TextStyle(
                                        fontFamily: 'Manrope',
                                        fontWeight: FontWeight.w800,
                                        fontSize: 24,
                                      ),
                                    )
                                  : Icon(
                                      name == 'Apple'
                                          ? Icons.apple
                                          : Icons.send_rounded,
                                      size: 25,
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          name,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (configured &&
                !(AppConfig.googleEnabled &&
                    AppConfig.appleEnabled &&
                    AppConfig.telegramEnabled)) ...[
              const SizedBox(height: 16),
              Text(
                'Внешние способы входа подключаются в тестовом окружении.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (!configured)
              DefaultTextStyle.merge(
                textAlign: TextAlign.center,
                child: const DemoCaption(),
              ),
          ],
        ),
      ),
    );
  }
}

class MfaScreen extends ConsumerStatefulWidget {
  const MfaScreen({this.enroll = false, super.key});
  final bool enroll;
  @override
  ConsumerState<MfaScreen> createState() => _MfaState();
}

class _MfaState extends ConsumerState<MfaScreen> {
  final code = TextEditingController();
  String? factorId, secret;
  bool busy = false;
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  Future<void> prepare() async {
    final client = ref.read(backendProvider);
    if (client == null) return;
    try {
      if (widget.enroll) {
        final result = await client.auth.mfa.enroll(
          factorType: FactorType.totp,
        );
        if (mounted) {
          setState(() {
            factorId = result.id;
            secret = result.totp?.secret;
          });
        }
      } else {
        final factors = await client.auth.mfa.listFactors();
        if (mounted) setState(() => factorId = factors.totp.firstOrNull?.id);
      }
    } catch (_) {
      if (mounted) {
        notice(context, 'Не удалось подготовить двухфакторную проверку');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => prepare());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Двухфакторная защита')),
    body: PageBody(
      children: [
        const ScreenIntro('Подтвердите вход.', compact: true),
        const SizedBox(height: 20),
        if (secret != null) ...[
          const Text(
            'Добавьте этот ключ в приложение-аутентификатор. Никому его не передавайте.',
          ),
          const SizedBox(height: 12),
          SelectableText(secret!),
          const SizedBox(height: 20),
        ],
        TextField(
          textAlignVertical: TextAlignVertical.top,
          controller: code,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: 'Код из аутентификатора',
          ),
        ),
        FilledButton(
          onPressed: busy || factorId == null
              ? null
              : () async {
                  setState(() => busy = true);
                  try {
                    await ref
                        .read(backendProvider)!
                        .auth
                        .mfa
                        .challengeAndVerify(
                          factorId: factorId!,
                          code: code.text.trim(),
                        );
                    ref.invalidate(communityProvider);
                    ref.invalidate(accountEntryProvider);
                    if (mounted) this.context.go('/auth/complete');
                  } catch (_) {
                    if (context.mounted) {
                      notice(context, 'Код не подошёл. Попробуйте ещё раз.');
                    }
                  } finally {
                    code.clear();
                    if (mounted) setState(() => busy = false);
                  }
                },
          child: Text(busy ? 'Проверяем…' : 'Подтвердить'),
        ),
      ],
    ),
  );
}
