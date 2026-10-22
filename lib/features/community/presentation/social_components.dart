import 'package:flutter/material.dart';
import '../../../core/theme/studio_theme.dart';
import '../../../core/ui/studio_motion.dart';

/// Flat, shared feedback for community and meetup content.
/// Copy stays with the feature so unavailable data is never described as empty.
class SocialContentState extends StatelessWidget {
  const SocialContentState({
    required this.title,
    this.message,
    this.icon = Icons.info_outline,
    this.actionLabel,
    this.onAction,
    this.loading = false,
    this.centered = false,
    super.key,
  });
  final String title;
  final String? message, actionLabel;
  final IconData icon;
  final VoidCallback? onAction;
  final bool loading, centered;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: centered
          ? const EdgeInsets.symmetric(vertical: 48, horizontal: 12)
          : const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: centered
            ? CrossAxisAlignment.center
            : CrossAxisAlignment.start,
        children: [
          if (loading) ...[
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.onSurface,
                backgroundColor: theme.colorScheme.outlineVariant,
                value: StudioMotion.reduced(context) ? .7 : null,
                semanticsLabel: title,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (centered) ...[
            if (!loading) ...[
              Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
            ],
            Semantics(
              header: true,
              liveRegion: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(
                    icon,
                    size: 24,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Semantics(
                    header: true,
                    liveRegion: true,
                    child: Text(title, style: theme.textTheme.titleMedium),
                  ),
                ),
              ],
            ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              textAlign: centered ? TextAlign.center : TextAlign.start,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: loading ? null : onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact, anchored selection used by social browsing controls.
/// Selection is drawn inside the row rather than using Material's grey highlight.
class StudioFilterMenu<T> extends StatelessWidget {
  const StudioFilterMenu({
    required this.value,
    required this.options,
    required this.onSelected,
    required this.tooltip,
    this.icon = const Icon(Icons.filter_list),
    super.key,
  });
  final T value;
  final List<({T value, String label})> options;
  final ValueChanged<T> onSelected;
  final String tooltip;
  final Widget icon;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final width = (MediaQuery.sizeOf(context).width - 48).clamp(160.0, 288.0);
    return PopupMenuButton<T>(
      tooltip: tooltip,
      icon: icon,
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      color: theme.scaffoldBackgroundColor,
      menuPadding: const EdgeInsets.all(6),
      constraints: BoxConstraints(minWidth: width, maxWidth: width),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      popUpAnimationStyle: AnimationStyle(
        duration: StudioMotion.duration(context, StudioMotion.navigation),
      ),
      style: IconButton.styleFrom(
        fixedSize: const Size(48, 48),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      itemBuilder: (_) => [
        for (final option in options)
          PopupMenuItem<T>(
            value: option.value,
            padding: EdgeInsets.zero,
            child: Semantics(
              selected: option.value == value,
              child: Container(
                constraints: const BoxConstraints(minHeight: 48),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: option.value == value
                      ? StudioColors.of(context).tint
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option.label,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: option.value == value
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (option.value == value)
                      const Icon(Icons.check, size: 20)
                    else
                      const SizedBox(width: 20),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
