import '../../l10n/localization.dart';
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
      appBar: AppBar(title: Text("Подтвердите действие".tr(context))),
      body: PageBody(
        children: [
          ScreenIntro(
            "Повторный вход\nчерез {p0}.".tr(
              context,
              arguments: {'p0': widget.provider.label},
            ),
            compact: true,
          ),
          const SizedBox(height: 16),
          Text(
            "Выберите тот же аккаунт {p0}, с которым вошли в PetFriendly.".tr(
              context,
              arguments: {'p0': widget.provider.label},
            ),
          ),
          const SizedBox(height: 24),
          if (status == ReauthStatus.wrongAccount)
            Text(
              "Выбран другой аккаунт. Действие не будет выполнено.".tr(context),
            ),
          if (status == ReauthStatus.expired)
            Text(
              "Проверка истекла. Вернитесь и начните действие заново.".tr(
                context,
              ),
            ),
          if (status == ReauthStatus.needsMfa) ...[
            TextField(
              controller: code,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Код из приложения-аутентификатора".tr(context),
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
                          notice(
                            context,
                            "Проверьте код и повторите попытку.".tr(context),
                          );
                        }
                      } finally {
                        code.clear();
                        if (mounted) setState(() => busy = false);
                      }
                    },
              child: Text("Подтвердить код".tr(context)),
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
              child: Text("Продолжить действие".tr(context)),
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
                            "Не удалось открыть {p0}. Попробуйте позже.".tr(
                              context,
                              arguments: {'p0': widget.provider.label},
                            ),
                          );
                        }
                      } finally {
                        if (mounted) setState(() => busy = false);
                      }
                    },
              child: Text(
                "Войти через {p0}".tr(
                  context,
                  arguments: {'p0': widget.provider.label},
                ),
              ),
            )
          else if (status == ReauthStatus.waiting)
            Text(
              "Завершите вход на странице {p0} и вернитесь в приложение.".tr(
                context,
                arguments: {'p0': widget.provider.label},
              ),
            ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: busy ? null : () => context.pop(false),
            child: Text("Отмена".tr(context)),
          ),
        ],
      ),
    );
  }
}
