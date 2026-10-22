import 'package:flutter/material.dart';
import '../../l10n/localization.dart';
import 'components.dart';
import 'studio_review.dart';

/// Temporary selection belongs to the sheet; only Done/Apply returns a value.
Future<T?> showStudioChoice<T>({
  required BuildContext context,
  required String title,
  required T value,
  required List<({T value, String label})> options,
  T? resetValue,
}) => showStudioSelectionSheet<T>(
  context: context,
  builder: (ctx) {
    var draft = value;
    return StatefulBuilder(
      builder: (ctx, update) => StudioReviewSheet(
        title: title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RadioGroup<T>(
              groupValue: draft,
              onChanged: (v) {
                if (v != null) update(() => draft = v);
              },
              child: Column(
                children: [
                  for (final option in options)
                    RadioListTile<T>(
                      value: option.value,
                      title: Text(option.label),
                      contentPadding: EdgeInsets.zero,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                if (resetValue != null) ...[
                  OutlinedButton(
                    onPressed: () => update(() => draft = resetValue),
                    child: Text('Сбросить'.tr(ctx)),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx, draft),
                    child: Text('Применить'.tr(ctx)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  },
);

Future<DateTime?> showStudioDatePicker({
  required BuildContext context,
  DateTime? initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
  String? cancelText,
  String? confirmText,
  DatePickerEntryMode? initialEntryMode,
}) {
  var draft = DateUtils.dateOnly(initialDate ?? firstDate);
  final first = DateUtils.dateOnly(firstDate),
      last = DateUtils.dateOnly(lastDate);
  if (draft.isBefore(first)) draft = first;
  if (draft.isAfter(last)) draft = last;
  return showStudioSelectionSheet<DateTime>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, update) => StudioReviewSheet(
        title: helpText ?? 'Дата'.tr(ctx),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CalendarDatePicker(
              initialDate: draft,
              firstDate: first,
              lastDate: last,
              onDateChanged: (v) => update(() => draft = v),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, draft),
              child: Text('Готово'.tr(ctx)),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<TimeOfDay?> showStudioTimePicker({
  required BuildContext context,
  required TimeOfDay initialTime,
  String? helpText,
  String? cancelText,
  String? confirmText,
  TransitionBuilder? builder,
}) async {
  var hours = initialTime.hour, minutes = initialTime.minute;
  final form = GlobalKey<FormState>();
  final result = await showStudioSelectionSheet<TimeOfDay>(
    context: context,
    builder: (ctx) => StudioReviewSheet(
      title: helpText ?? 'Время'.tr(ctx),
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final part in [
                  (true, 'Часы', 23),
                  (false, 'Минуты', 59),
                ]) ...[
                  if (!part.$1) const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(part.$2.tr(ctx)),
                        const SizedBox(height: 8),
                        TextFormField(
                          key: ValueKey(
                            part.$1
                                ? 'shared-time-hours'
                                : 'shared-time-minutes',
                          ),
                          initialValue: (part.$1 ? hours : minutes)
                              .toString()
                              .padLeft(2, '0'),
                          onSaved: (v) {
                            if (part.$1) {
                              hours = int.parse(v!);
                            } else {
                              minutes = int.parse(v!);
                            }
                          },
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          validator: (v) {
                            final n = int.tryParse(v ?? '');
                            return n != null && n >= 0 && n <= part.$3
                                ? null
                                : 'Выберите время'.tr(ctx);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (form.currentState!.validate()) {
                  form.currentState!.save();
                  Navigator.pop(ctx, TimeOfDay(hour: hours, minute: minutes));
                }
              },
              child: Text('Готово'.tr(ctx)),
            ),
          ],
        ),
      ),
    ),
  );
  return result;
}

class StudioTemporalFields extends StatelessWidget {
  const StudioTemporalFields({
    required this.value,
    required this.firstDate,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });
  final DateTime value, firstDate;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (ctx, bounds) {
      Widget field(bool date) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text((date ? 'Дата' : 'Время').tr(ctx)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.secondaryContainer,
              side: BorderSide(color: Theme.of(ctx).colorScheme.outlineVariant),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(12),
              alignment: Alignment.centerLeft,
            ),
            key: ValueKey(
              date ? 'walking-date-trigger' : 'shared-time-trigger',
            ),
            onPressed: !enabled
                ? null
                : () async {
                    if (date) {
                      final day = await showStudioDatePicker(
                        context: ctx,
                        initialDate: value,
                        firstDate: firstDate,
                        lastDate: firstDate.add(const Duration(days: 365)),
                      );
                      if (day != null && ctx.mounted) {
                        onChanged(
                          DateTime.utc(
                            day.year,
                            day.month,
                            day.day,
                            value.hour,
                            value.minute,
                          ),
                        );
                      }
                    } else {
                      final time = await showStudioTimePicker(
                        context: ctx,
                        initialTime: TimeOfDay.fromDateTime(value),
                      );
                      if (time != null && ctx.mounted) {
                        onChanged(
                          DateTime.utc(
                            value.year,
                            value.month,
                            value.day,
                            time.hour,
                            time.minute,
                          ),
                        );
                      }
                    }
                  },
            icon: Icon(
              date ? Icons.calendar_month_outlined : Icons.schedule_outlined,
              size: 20,
            ),
            label: Text(
              date
                  ? MaterialLocalizations.of(ctx).formatCompactDate(value)
                  : '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
              maxLines: 1,
            ),
          ),
        ],
      );
      if (bounds.maxWidth < 340 ||
          MediaQuery.textScalerOf(ctx).scale(16) > 22) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [field(true), const SizedBox(height: 16), field(false)],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: field(true)),
          const SizedBox(width: 12),
          Expanded(child: field(false)),
        ],
      );
    },
  );
}
