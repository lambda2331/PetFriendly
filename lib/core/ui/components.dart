import 'package:flutter/material.dart';
import '../theme/studio_theme.dart';
import '../backend/backend.dart';

AnimationStyle studioSheetAnimation(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
    ? AnimationStyle.noAnimation
    : const AnimationStyle(
        duration: Duration(milliseconds: 250),
        reverseDuration: Duration(milliseconds: 220),
      );

void notice(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
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
                ? 'Закрыть'
                : 'Сначала дождитесь завершения сохранения',
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
            'Демонстрационные данные · PetFriendly 0.1',
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

String ageYears(dynamic value) {
  final age = int.tryParse('$value');
  if (age == null) return 'Возраст не указан';
  if (AppConfig.portfolio) return '$age ${age == 1 ? 'year' : 'years'}';
  final suffix = age % 100 >= 11 && age % 100 <= 14
      ? 'лет'
      : age % 10 == 1
      ? 'год'
      : age % 10 >= 2 && age % 10 <= 4
      ? 'года'
      : 'лет';
  return '$age $suffix';
}

String memberCount(int count) {
  if (AppConfig.portfolio) return '$count ${count == 1 ? 'member' : 'members'}';
  final word = count % 100 >= 11 && count % 100 <= 14
      ? 'участников'
      : count % 10 == 1
      ? 'участник'
      : count % 10 >= 2 && count % 10 <= 4
      ? 'участника'
      : 'участников';
  return '$count $word';
}
