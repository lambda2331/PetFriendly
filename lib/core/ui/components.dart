import '../../l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/studio_theme.dart';
import '../backend/backend.dart';
import 'studio_motion.dart';

AnimationStyle studioSheetAnimation(BuildContext context) =>
    StudioMotion.reduced(context)
    ? AnimationStyle.noAnimation
    : const AnimationStyle(
        duration: Duration(milliseconds: 250),
        reverseDuration: Duration(milliseconds: 220),
      );

/// Selection panels fill the available screen width; bodies own their padding.
Future<T?> showStudioSelectionSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  useRootNavigator: true,
  useSafeArea: true,
  isScrollControlled: true,
  showDragHandle: false,
  sheetAnimationStyle: studioSheetAnimation(context),
  constraints: BoxConstraints.tightFor(width: MediaQuery.sizeOf(context).width),
  clipBehavior: Clip.antiAlias,
  builder: builder,
);

void notice(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message.tr(context))));
}

/// Shared heading for modal sheets; the sheet body owns its safe-area padding.
class StudioSheetHeader extends StatelessWidget {
  const StudioSheetHeader({
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.onClose,
    this.closeEnabled = true,
    super.key,
  });
  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final VoidCallback? onClose;
  final bool closeEnabled;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 20,
                    height: 1.3,
                    letterSpacing: -.2,
                  ),
                ),
              ),
            ),
          ),
          ...actions,
          IconButton(
            tooltip: closeEnabled
                ? "Закрыть".tr(context)
                : "Сначала дождитесь завершения сохранения".tr(context),
            onPressed: closeEnabled
                ? onClose ?? () => Navigator.of(context).maybePop()
                : null,
            icon: const Icon(Icons.close, size: 20),
          ),
        ],
      ),
      if (subtitle?.trim().isNotEmpty == true) ...[
        const SizedBox(height: 4),
        Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
      ],
    ],
  );
}

class ScreenIntro extends StatelessWidget {
  const ScreenIntro(
    this.title, {
    this.subtitle,
    this.eyebrow,
    this.compact = false,
    super.key,
  });
  final String title;
  final String? subtitle, eyebrow;
  final bool compact;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (eyebrow != null) ...[
        Text(eyebrow!, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 10),
      ],
      Semantics(
        header: true,
        child: Text(
          title,
          style: compact
              ? Theme.of(context).textTheme.headlineSmall
              : Theme.of(context).textTheme.headlineLarge,
        ),
      ),
      if (subtitle != null) ...[
        SizedBox(height: compact ? 8 : 12),
        Text(
          subtitle!,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ],
  );
}

/// Shared caption treatment for dates, districts, counts and durations.
class MetadataLine extends StatelessWidget {
  const MetadataLine({required this.items, super.key});
  final List<String> items;
  @override
  Widget build(BuildContext context) {
    final visible = items.where((item) => item.trim().isNotEmpty).toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return Text(
      visible.join(' · '),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

class StudioCard extends StatelessWidget {
  const StudioCard({
    required this.child,
    this.hero = false,
    this.padding = 22,
    this.outlined = false,
    super.key,
  });
  final Widget child;
  final bool hero, outlined;
  final double padding;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: hero
          ? StudioColors.of(context).hero
          : Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      border: outlined
          ? Border.all(color: StudioColors.of(context).line)
          : null,
    ),
    child: child,
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(
    this.title, {
    this.trailing,
    this.compact = false,
    super.key,
  });
  final String title;
  final Widget? trailing;
  final bool compact;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: compact ? 18 : 26, bottom: compact ? 8 : 14),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: compact
                  ? Theme.of(context).textTheme.titleMedium
                  : Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class InitialAvatar extends StatelessWidget {
  const InitialAvatar(
    this.letter, {
    this.accent = false,
    this.icon,
    this.size = 48,
    super.key,
  });
  final String letter;
  final bool accent;
  final IconData? icon;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: accent ? StudioColors.lime : StudioColors.of(context).tint,
      borderRadius: BorderRadius.circular(icon != null ? 16 : size),
    ),
    child: Center(
      child: icon == null
          ? Text(
              letter,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: size * .4,
                fontWeight: FontWeight.w600,
                color: accent ? StudioColors.onLime : null,
              ),
            )
          : Icon(icon, color: accent ? StudioColors.onLime : null, size: 22),
    ),
  );
}

class DemoCaption extends StatelessWidget {
  const DemoCaption({super.key});
  @override
  Widget build(BuildContext context) => AppConfig.backendEnabled
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text(
            "Демонстрационные данные · PetFriendly 0.1".tr(context),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
}

class PageBody extends StatelessWidget {
  const PageBody({required this.children, super.key});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
    children: children,
  );
}

class PressButton extends StatefulWidget {
  const PressButton({required this.child, required this.onTap, super.key});
  final Widget child;
  final VoidCallback onTap;
  @override
  State<PressButton> createState() => _PressButtonState();
}

class _PressButtonState extends State<PressButton> {
  bool pressed = false;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown: (_) => setState(() => pressed = true),
    onTapCancel: () => setState(() => pressed = false),
    onTapUp: (_) {
      setState(() => pressed = false);
      widget.onTap();
    },
    child: AnimatedScale(
      scale: pressed && !MediaQuery.disableAnimationsOf(context) ? .97 : 1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 100),
      child: widget.child,
    ),
  );
}

String ageYears(dynamic value, {String locale = 'ru'}) {
  final age = int.tryParse('$value');
  return age == null
      ? translateForLanguage('Возраст не указан', locale: locale)
      : stringsFor(locale).ageYears(age);
}

String memberCount(int count, {String locale = 'ru'}) =>
    stringsFor(locale).memberCount(count);

/// A visible caption stays neutral when its control receives focus.
class StudioFieldLabel extends StatelessWidget {
  const StudioFieldLabel({required this.label, required this.child, super.key});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 8),
      Semantics(label: label, child: child),
    ],
  );
}

/// Shared underlined segments keep localized labels whole at large text sizes.
class StudioSegmentTabs<T> extends StatefulWidget {
  const StudioSegmentTabs({
    required this.entries,
    required this.value,
    required this.onChanged,
    this.selectedWeight = FontWeight.w600,
    super.key,
  });
  final Map<T, String> entries;
  final T value;
  final ValueChanged<T> onChanged;
  final FontWeight selectedWeight;
  @override
  State<StudioSegmentTabs<T>> createState() => _StudioSegmentTabsState<T>();
}

class _StudioSegmentTabsState<T> extends State<StudioSegmentTabs<T>> {
  final nodes = <T, FocusNode>{};
  final keys = <T, GlobalKey>{};
  @override
  void didUpdateWidget(StudioSegmentTabs<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    for (final key in nodes.keys.toList()) {
      if (!widget.entries.containsKey(key)) {
        nodes.remove(key)!.dispose();
        keys.remove(key);
      }
    }
    if (oldWidget.value != widget.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = keys[widget.value]?.currentContext;
        if (mounted && target != null) {
          Scrollable.ensureVisible(target, duration: Duration.zero);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final node in nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (widget.entries.isEmpty) return const SizedBox.shrink();
      final style = Theme.of(context).textTheme.bodyMedium!;
      var width = constraints.maxWidth / widget.entries.length;
      for (final entry in widget.entries.entries) {
        nodes.putIfAbsent(entry.key, FocusNode.new);
        keys.putIfAbsent(entry.key, GlobalKey.new);
        final painter = TextPainter(
          text: TextSpan(
            text: entry.value,
            style: style.copyWith(fontWeight: widget.selectedWeight),
          ),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();
        if (painter.width + 16 > width) width = painter.width + 16;
        painter.dispose();
      }
      final scrolling =
          width * widget.entries.length > constraints.maxWidth + .1;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: scrolling ? null : const NeverScrollableScrollPhysics(),
        child: Row(
          children: widget.entries.entries
              .map(
                (entry) => Semantics(
                  selected: widget.value == entry.key,
                  button: true,
                  child: Focus(
                    skipTraversal: true,
                    canRequestFocus: false,
                    onKeyEvent: (node, event) {
                      if (event is! KeyDownEvent) return KeyEventResult.ignored;
                      final values = widget.entries.keys.toList();
                      final index = values.indexOf(entry.key);
                      final key = event.logicalKey;
                      final target = key == LogicalKeyboardKey.arrowRight
                          ? (index + 1) % values.length
                          : key == LogicalKeyboardKey.arrowLeft
                          ? (index + values.length - 1) % values.length
                          : key == LogicalKeyboardKey.home
                          ? 0
                          : key == LogicalKeyboardKey.end
                          ? values.length - 1
                          : null;
                      if (target == null) return KeyEventResult.ignored;
                      widget.onChanged(values[target]);
                      nodes[values[target]]!.requestFocus();
                      return KeyEventResult.handled;
                    },
                    child: InkWell(
                      key: keys[entry.key],
                      focusNode: nodes[entry.key],
                      onTap: () => widget.onChanged(entry.key),
                      onFocusChange: (focused) {
                        final target = keys[entry.key]?.currentContext;
                        if (focused && target != null) {
                          Scrollable.ensureVisible(
                            target,
                            duration: Duration.zero,
                          );
                        }
                      },
                      child: Container(
                        width: width,
                        constraints: const BoxConstraints(minHeight: 48),
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              width: widget.value == entry.key ? 2 : 1,
                              color: widget.value == entry.key
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
                        child: Text(
                          entry.value,
                          style: style.copyWith(
                            fontWeight: widget.value == entry.key
                                ? widget.selectedWeight
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          softWrap: false,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      );
    },
  );
}
