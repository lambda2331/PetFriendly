import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/time/display_time.dart';
import '../../core/ui/components.dart';
import 'pet_access_repository.dart';
import 'place_repository.dart';

class PetAccessReviewSheet extends ConsumerStatefulWidget {
  const PetAccessReviewSheet({required this.place, super.key});
  final Place place;
  @override
  ConsumerState<PetAccessReviewSheet> createState() => _PetAccessReviewState();
}

class _PetAccessReviewState extends ConsumerState<PetAccessReviewSheet> {
  final form = GlobalKey<FormState>();
  final basis = TextEditingController(),
      conditions = TextEditingController(),
      reference = TextEditingController();
  String? confirmation, policy, error;
  DateTime? observed;
  bool busy = false, needsMfa = false;
  @override
  void dispose() {
    basis.dispose();
    conditions.dispose();
    reference.dispose();
    super.dispose();
  }

  Future<void> publish() async {
    if (busy || !form.currentState!.validate()) return;
    if (observed == null) {
      setState(() => error = 'Выберите дату реального подтверждения.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
      needsMfa = false;
    });
    try {
      await ref.read(petAccessPublisherProvider)(
        widget.place.id,
        PetAccessPublication(
          confirmation: confirmation!,
          policy: policy!,
          observedAt: observed!,
          basis: basis.text,
          conditions: conditions.text,
          referenceUrl: reference.text,
        ),
      );
      if (mounted) {
        Navigator.pop(context);
        notice(context, 'Сведения о допуске опубликованы.');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          needsMfa = e is PostgrestException && e.code == '42501';
          error = needsMfa
              ? 'Для модерации нужен действующий вход с MFA и роль модератора.'
              : 'Не удалось опубликовать сведения. Проверьте дату, основание и соединение.';
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> withdraw() async {
    if (busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Отозвать подтверждение?'),
        content: const Text(
          'Место снова будет показываться без подтверждения допуска.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Оставить'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Отозвать'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(petAccessWithdrawalProvider)(widget.place.id);
      if (mounted) {
        Navigator.pop(context);
        notice(context, 'Подтверждение отозвано.');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Не удалось отозвать подтверждение. Проверьте вход с MFA и соединение.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                StudioSheetHeader(
                  title: 'Правила для питомцев',
                  subtitle: widget.place.name,
                  closeEnabled: !busy,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Только для модераторов. Нужны реальные сведения сообщества или заведения. Не публикуйте личные адреса и инструкции по уходу.',
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Кто подтвердил правила',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'community',
                      child: Text('Сообщество'),
                    ),
                    DropdownMenuItem(value: 'venue', child: Text('Заведение')),
                  ],
                  validator: (v) => v == null ? 'Выберите источник' : null,
                  onChanged: busy
                      ? null
                      : (v) => setState(() => confirmation = v),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Правило для собак',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'allowed',
                      child: Text('С собаками можно'),
                    ),
                    DropdownMenuItem(
                      value: 'on_leash',
                      child: Text('Только на поводке'),
                    ),
                    DropdownMenuItem(
                      value: 'forbidden',
                      child: Text('С собаками нельзя'),
                    ),
                  ],
                  validator: (v) => v == null ? 'Выберите правило' : null,
                  onChanged: busy ? null : (v) => setState(() => policy = v),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  icon: const Icon(Icons.event_outlined),
                  onPressed: busy
                      ? null
                      : () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: observed ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                            helpText: 'Дата реального подтверждения',
                          );
                          if (picked != null && mounted) {
                            setState(() => observed = picked);
                          }
                        },
                  label: Text(
                    observed == null
                        ? 'Выбрать дату подтверждения'
                        : readableDate(observed),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: basis,
                  enabled: !busy,
                  maxLength: 1000,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Основание подтверждения',
                  ),
                  validator: (v) => v?.trim().isNotEmpty == true
                      ? null
                      : 'Опишите подтверждающие сведения',
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: conditions,
                  enabled: !busy,
                  maxLength: 1000,
                  minLines: 1,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Условия, если подтверждены',
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: reference,
                  enabled: !busy,
                  maxLength: 2000,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                    labelText: confirmation == 'venue'
                        ? 'Публичное подтверждение заведения · https'
                        : 'Публичная ссылка · необязательно',
                  ),
                  validator: (v) {
                    if (v?.trim().isEmpty != false) {
                      return confirmation == 'venue'
                          ? 'Добавьте подтверждение заведения'
                          : null;
                    }
                    final uri = Uri.tryParse(v!.trim());
                    return uri?.scheme == 'https' && uri!.host.isNotEmpty
                        ? null
                        : 'Нужна полная ссылка https';
                  },
                ),
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Semantics(liveRegion: true, child: Text(error!)),
                ],
                if (needsMfa)
                  TextButton(
                    onPressed: busy ? null : () => context.push('/mfa'),
                    child: const Text('Подтвердить вход с MFA'),
                  ),
                const SizedBox(height: 18),
                if (busy) ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      'Сохраняем сведения. Поля временно недоступны.',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 12),
                ],
                FilledButton(
                  onPressed: busy ? null : publish,
                  child: Text(
                    busy ? 'Сохраняем…' : 'Опубликовать подтверждение',
                  ),
                ),
                if (ref
                        .watch(petAccessEvidenceProvider(widget.place.id))
                        .value !=
                    null) ...[
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: busy ? null : withdraw,
                    child: const Text('Отозвать подтверждение'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
