import '../../core/ui/studio_pickers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/studio_theme.dart';
import '../../core/time/display_time.dart';
import '../../l10n/localization.dart';
import '../community/presentation/social_components.dart';

const walkingSheetTitleStyle = TextStyle(
  fontFamily: 'Manrope',
  fontSize: 20,
  fontWeight: FontWeight.w700,
  letterSpacing: -.5,
  height: 1.3,
);
const walkingIdentityStyle = TextStyle(
  fontFamily: 'Manrope',
  fontSize: 18,
  fontWeight: FontWeight.w700,
  height: 1.35,
);
TextStyle walkingMetaStyle(BuildContext context, {double size = 14}) =>
    walkingBodyStyle.copyWith(
      fontSize: size,
      height: 1.45,
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFB9C1B1)
          : const Color(0xFF636B5B),
    );

const walkingBodyStyle = TextStyle(
  fontFamily: 'Golos Text',
  fontSize: 16,
  fontWeight: FontWeight.w400,
  height: 1.4,
);

String walkingShortTime(
  BuildContext context,
  Map<String, dynamic> item, {
  bool duration = true,
}) {
  final instant = DateTime.tryParse('${item['starts_at']}');
  final zone =
      item['time_zone'] as String? ?? cityTimeZone(item['city'] as String?);
  final local = instant == null
      ? null
      : venueDateTime(instant, validTimeZone(zone) ? zone! : 'UTC');
  return [
    if (local != null)
      '${DateFormat.MMMd(context.languageCode).format(local)} · ${DateFormat.Hm(context.languageCode).format(local)}'
    else
      'Время не задано'.tr(context),
    if (duration && item['duration'] is num)
      stringsFor(
        context.languageCode,
      ).walkingDurationMinutes((item['duration'] as num).toInt()),
  ].join(' · ');
}

/// Compact, wrapping status shared by list rows and conversation context.
class WalkingStatusLabel extends StatelessWidget {
  const WalkingStatusLabel(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: StudioColors.of(context).tint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 5,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(text, style: walkingMetaStyle(context, size: 13)),
          ),
        ],
      ),
    ),
  );
}

/// Equal secondary actions; a lone action keeps the right-hand slot.
class WalkingRowActions extends StatelessWidget {
  const WalkingRowActions({this.leading, required this.trailing, super.key});
  final Widget? leading;
  final Widget trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: LayoutBuilder(
      builder: (context, constraints) {
        if (MediaQuery.textScalerOf(context).scale(16) > 24) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (leading != null) ...[leading!, const SizedBox(height: 8)],
              trailing,
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: leading ?? const SizedBox()),
            const SizedBox(width: 8),
            Expanded(child: trailing),
          ],
        );
      },
    ),
  );
}

/// Inline date and time editing. Values are wall-clock times in the venue zone;
/// conversion to an instant remains in the existing form save path.
class WalkingDateField extends StatefulWidget {
  const WalkingDateField({
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
  State<WalkingDateField> createState() => _WalkingDateFieldState();
}

class _WalkingDateFieldState extends State<WalkingDateField> {
  @override
  Widget build(BuildContext context) => StudioTemporalFields(
    value: widget.value,
    firstDate: widget.firstDate,
    enabled: widget.enabled,
    onChanged: widget.onChanged,
  );
}

class WalkingFormTheme extends StatelessWidget {
  const WalkingFormTheme({required this.child, this.enabled = true, super.key});
  final Widget child;
  final bool enabled;
  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final theme = Theme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: theme.colorScheme.outlineVariant),
    );
    return Theme(
      data: theme.copyWith(
        textTheme: theme.textTheme.copyWith(
          bodyLarge: walkingBodyStyle.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          bodyMedium: walkingBodyStyle.copyWith(
            color: theme.colorScheme.onSurface,
          ),
          titleMedium: walkingBodyStyle.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: theme.outlinedButtonTheme.style?.copyWith(
            textStyle: const WidgetStatePropertyAll(walkingBodyStyle),
          ),
        ),
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          filled: true,
          fillColor: StudioColors.of(context).tint,
          border: border,
          enabledBorder: border,
          disabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(
              color: theme.colorScheme.onSurface,
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
      child: DefaultTextStyle.merge(style: walkingBodyStyle, child: child),
    );
  }
}

class WalkingCalendar extends StatefulWidget {
  const WalkingCalendar({
    required this.value,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });
  final DateTime value, firstDate, lastDate;
  final ValueChanged<DateTime> onChanged;
  final bool enabled;
  @override
  State<WalkingCalendar> createState() => _WalkingCalendarState();
}

class _WalkingCalendarState extends State<WalkingCalendar> {
  late DateTime month = DateTime(widget.value.year, widget.value.month);
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = DateTime(month.year, month.month + 1, 0).day;
    final offset = month.weekday - 1;
    final rows = ((offset + count) / 7).ceil();
    final previous = DateTime(month.year, month.month, 0),
        next = DateTime(month.year, month.month + 1);
    return Padding(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                tooltip: MaterialLocalizations.of(context).previousMonthTooltip,
                onPressed:
                    widget.enabled && !previous.isBefore(widget.firstDate)
                    ? () => setState(
                        () => month = DateTime(month.year, month.month - 1),
                      )
                    : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  toBeginningOfSentenceCase(
                    DateFormat.yMMMM(context.languageCode).format(month),
                  ),
                  textAlign: TextAlign.center,
                  style: walkingSheetTitleStyle.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
              IconButton(
                tooltip: MaterialLocalizations.of(context).nextMonthTooltip,
                onPressed: widget.enabled && !next.isAfter(widget.lastDate)
                    ? () => setState(() => month = next)
                    : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var day = 0; day < 7; day++)
                Expanded(
                  child: Text(
                    (MediaQuery.textScalerOf(context).scale(16) > 24
                            ? DateFormat('EEEEE', context.languageCode)
                            : DateFormat.E(context.languageCode))
                        .format(DateTime(2026, 10, 12 + day)),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (var row = 0; row < rows; row++)
            Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(
                    child: Builder(
                      builder: (ctx) {
                        final number = row * 7 + col - offset + 1;
                        if (number < 1 || number > count) {
                          return const SizedBox(height: 48);
                        }
                        final d = DateTime(month.year, month.month, number);
                        final selected =
                            d.year == widget.value.year &&
                            d.month == widget.value.month &&
                            d.day == widget.value.day;
                        return Semantics(
                          selected: selected,
                          enabled:
                              widget.enabled &&
                              !d.isBefore(widget.firstDate) &&
                              !d.isAfter(widget.lastDate),
                          button: true,
                          label: DateFormat.yMMMMEEEEd(
                            context.languageCode,
                          ).format(d),
                          child: ExcludeSemantics(
                            child: TextButton(
                              key: ValueKey(
                                'walking-day-${d.year}-${d.month}-$number',
                              ),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 40),
                                tapTargetSize: MaterialTapTargetSize.padded,
                                backgroundColor: selected
                                    ? theme.colorScheme.primary
                                    : null,
                                foregroundColor: selected
                                    ? theme.colorScheme.onPrimary
                                    : theme.colorScheme.onSurface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed:
                                  widget.enabled &&
                                      !d.isBefore(widget.firstDate) &&
                                      !d.isAfter(widget.lastDate)
                                  ? () => widget.onChanged(d)
                                  : null,
                              child: Text(
                                '$number',
                                maxLines: 1,
                                softWrap: false,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontFamily: 'Golos Text',
                                  fontSize: 15,
                                  color:
                                      !widget.enabled ||
                                          d.isBefore(widget.firstDate) ||
                                          d.isAfter(widget.lastDate)
                                      ? theme.colorScheme.onSurface.withValues(
                                          alpha: .38,
                                        )
                                      : selected
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Initial loading uses the same centered state as the approved Studio mock.
class WalkingLoadingState extends StatelessWidget {
  const WalkingLoadingState({super.key});
  @override
  Widget build(BuildContext context) => SocialContentState(
    centered: true,
    loading: true,
    title: 'Загружаем прогулки…'.tr(context),
  );
}
