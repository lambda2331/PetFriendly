import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ui/components.dart';
import '../../l10n/localization.dart';
import 'walking_chat_controller.dart';
import 'walking_chat_widgets.dart';

const walkingReportReasons = [
  'Неприемлемое поведение',
  'Проблема с сообщениями или фото',
  'Другое',
];

Future<void> showWalkingChatReport(BuildContext context, String id) =>
    showStudioSelectionSheet<void>(
      context: context,
      builder: (context) => WalkingChatReport(id: id),
    );

class WalkingChatReport extends ConsumerStatefulWidget {
  const WalkingChatReport({required this.id, super.key});
  final String id;
  @override
  ConsumerState<WalkingChatReport> createState() => _WalkingChatReportState();
}

class _WalkingChatReportState extends ConsumerState<WalkingChatReport> {
  late final TextEditingController note;
  @override
  void initState() {
    super.initState();
    note = TextEditingController(
      text: ref.read(walkingChatProvider).reports[widget.id]?.note ?? '',
    );
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(walkingChatProvider);
    final draft = state.reports[widget.id] ?? const WalkingReportDraft();
    final available = state.records[widget.id]?.item != null;
    final fits = draft.body.runes.length <= 1000;
    return WalkingChatSheet(
      title: 'Сообщить о проблеме'.tr(context),
      children: [
        if (draft.sent) ...[
          const Icon(Icons.check_circle_outline),
          Text(
            'Жалоба отправлена'.tr(context),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ] else if (!available)
          Text('Прогулка недоступна'.tr(context))
        else ...[
          Text(
            'Что произошло?'.tr(context),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final reason in walkingReportReasons)
            // The backend has free-text reasons. These choices are presentation;
            // the existing walk report receives one bounded reason + optional note.
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                draft.reason == reason
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
              ),
              title: Text(reason.tr(context)),
              selected: draft.reason == reason,
              selectedColor: Theme.of(context).colorScheme.onSurface,
              enabled: !draft.pending,
              onTap: draft.pending
                  ? null
                  : () => ref
                        .read(walkingChatProvider.notifier)
                        .editReport(widget.id, reason: reason),
            ),
          TextField(
            key: const Key('walking-report-note'),
            controller: note,
            enabled: !draft.pending,
            maxLines: 4,
            minLines: 2,
            maxLength: 1000,
            decoration: InputDecoration(
              labelText: 'Комментарий · необязательно'.tr(context),
            ),
            onChanged: (value) => ref
                .read(walkingChatProvider.notifier)
                .editReport(widget.id, note: value),
          ),
          Text(
            'Жалобу увидит модератор. Не добавляйте лишние личные данные.'.tr(
              context,
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (!fits)
            Text(
              'Причина и комментарий — не более 1000 символов'.tr(context),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          if (draft.error != null)
            Semantics(
              liveRegion: true,
              child: Text(
                'Не удалось отправить жалобу'.tr(context),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            key: const Key('walking-report-submit'),
            onPressed: draft.pending || draft.reason.isEmpty || !fits
                ? null
                : () =>
                      ref.read(walkingChatProvider.notifier).report(widget.id),
            child: draft.pending
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    (draft.error == null ? 'Отправить жалобу' : 'Повторить').tr(
                      context,
                    ),
                  ),
          ),
        ],
      ],
    );
  }
}
