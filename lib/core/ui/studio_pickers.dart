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
  required String? timeZone,
  String? helpText,
  String? cancelText,
  String? confirmText,
  TransitionBuilder? builder,
}) async {
  var hours = initialTime.hour, minutes = initialTime.minute;
  final form = GlobalKey<FormState>();
  final zone = timeZone?.trim();
  final result = await showStudioSelectionSheet<TimeOfDay>(
    context: context,
    builder: (ctx) => StudioReviewSheet(
      title: helpText ?? 'Время'.tr(ctx),
      bottomPadding: 16,
      footer: FilledButton(
        key: const ValueKey('shared-time-done'),
        onPressed: () {
          if (form.currentState!.validate()) {
            form.currentState!.save();
            Navigator.pop(ctx, TimeOfDay(hour: hours, minute: minutes));
          }
        },
        child: Text('Готово'.tr(ctx)),
      ),
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, bounds) {
                final scaler = MediaQuery.textScalerOf(context);
                final width = ((bounds.maxWidth - 32) / 2)
                    .clamp(0.0, 100 * scaler.scale(16) / 16)
                    .toDouble();
                final controlHeight = (scaler.scale(16) * 1.4 + 24)
                    .clamp(64.0, double.infinity)
                    .toDouble();
                final digits = Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontSize: 16,
                  height: 1.4,
                  fontFeatures: const [FontFeature.tabularFigures()],
                );
                InputBorder? rounded(InputBorder? border) =>
                    border is OutlineInputBorder
                    ? border.copyWith(borderRadius: BorderRadius.circular(12))
                    : border;
                final decoration = InputDecoration(
                  isDense: true,
                  constraints: BoxConstraints(minHeight: controlHeight),
                  contentPadding: const EdgeInsets.all(12),
                  errorMaxLines: 3,
                ).applyDefaults(Theme.of(context).inputDecorationTheme);
                Widget field(bool hour) => SizedBox(
                  width: width,
                  child: Semantics(
                    label: (hour ? 'Часы' : 'Минуты').tr(ctx),
                    child: TextFormField(
                      key: ValueKey(
                        hour ? 'shared-time-hours' : 'shared-time-minutes',
                      ),
                      initialValue: (hour ? hours : minutes).toString().padLeft(
                        2,
                        '0',
                      ),
                      onSaved: (v) {
                        if (hour) {
                          hours = int.parse(v!);
                        } else {
                          minutes = int.parse(v!);
                        }
                      },
                      keyboardType: TextInputType.number,
                      textInputAction: hour
                          ? TextInputAction.next
                          : TextInputAction.done,
                      onFieldSubmitted: (_) => hour
                          ? FocusScope.of(ctx).nextFocus()
                          : FocusScope.of(ctx).unfocus(),
                      textAlign: TextAlign.center,
                      style: digits,
                      // InputDecorator sizes its fill from the editable line,
                      // independently of the outer FormField constraints.
                      strutStyle: StrutStyle.fromTextStyle(
                        digits.copyWith(
                          height:
                              (controlHeight - 24) /
                              scaler.scale(16).clamp(1.0, double.infinity),
                        ),
                        forceStrutHeight: true,
                      ),
                      decoration: decoration.copyWith(
                        border: rounded(decoration.border),
                        enabledBorder: rounded(decoration.enabledBorder),
                        focusedBorder: rounded(decoration.focusedBorder),
                        errorBorder: rounded(decoration.errorBorder),
                        focusedErrorBorder: rounded(
                          decoration.focusedErrorBorder,
                        ),
                        disabledBorder: rounded(decoration.disabledBorder),
                      ),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return n != null && n >= 0 && n <= (hour ? 23 : 59)
                            ? null
                            : 'Выберите время'.tr(ctx);
                      },
                    ),
                  ),
                );
                return Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    key: const ValueKey('shared-time-pair'),
                    width: width * 2 + 32,
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(width: width, child: Text('Часы'.tr(ctx))),
                            const SizedBox(width: 32),
                            SizedBox(
                              width: width,
                              child: Text('Минуты'.tr(ctx)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            field(true),
                            SizedBox(
                              width: 32,
                              height: controlHeight,
                              child: ExcludeSemantics(
                                child: Center(child: Text(':', style: digits)),
                              ),
                            ),
                            field(false),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              '24-часовой формат'.tr(ctx),
              key: const ValueKey('shared-time-format'),
              style: Theme.of(ctx).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              zone == null || zone.isEmpty
                  ? 'Часовой пояс не выбран'.tr(ctx)
                  : zone,
              key: const ValueKey('shared-time-zone'),
              style: Theme.of(ctx).textTheme.bodySmall,
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
    required this.timeZone,
    this.enabled = true,
    super.key,
  });
  final DateTime value, firstDate;
  final String? timeZone;
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
                        timeZone: timeZone,
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
