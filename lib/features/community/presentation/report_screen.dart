import '../../../l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ui/components.dart';
import '../data/community_repository.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({required this.kind, required this.id, super.key});
  final String kind, id;
  @override
  ConsumerState<ReportScreen> createState() => _ReportState();
}

class _ReportState extends ConsumerState<ReportScreen> {
  final reason = TextEditingController();
  bool saving = false;
  @override
  void dispose() {
    reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text("Сообщить о проблеме".tr(context))),
    body: PageBody(
      children: [
        ScreenIntro(
          "Помогите сделать\nсообщество безопаснее.".tr(context),
          compact: true,
        ),
        const SizedBox(height: 20),
        Text(
          "Жалобу увидит модератор. Не добавляйте лишние личные данные.".tr(
            context,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          textAlignVertical: TextAlignVertical.top,
          controller: reason,
          maxLines: 5,
          maxLength: 1000,
          decoration: InputDecoration(labelText: "Что произошло?".tr(context)),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: saving
              ? null
              : () async {
                  if (reason.text.trim().isEmpty) {
                    notice(context, "Опишите проблему".tr(context));
                    return;
                  }
                  setState(() => saving = true);
                  try {
                    await ref
                        .read(communityProvider.notifier)
                        .command('report', {
                          'target_kind': widget.kind,
                          'target_id': widget.id,
                          'reason': reason.text.trim(),
                        });
                    if (context.mounted) {
                      Navigator.pop(context);
                      notice(context, "Жалоба отправлена".tr(context));
                    }
                  } catch (_) {
                    if (context.mounted) {
                      notice(
                        context,
                        "Не удалось отправить жалобу".tr(context),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => saving = false);
                  }
                },
          child: saving
              ? _ReportBusyLabel()
              : Text("Отправить жалобу".tr(context)),
        ),
      ],
    ),
  );
}

class _ReportBusyLabel extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ExcludeSemantics(
        child: SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: .38),
          ),
        ),
      ),
      const SizedBox(width: 8),
      Flexible(child: Text("Отправляем жалобу…".tr(context))),
    ],
  );
}
