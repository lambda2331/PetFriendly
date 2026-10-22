import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/material.dart';
import '../../l10n/localization.dart';
import 'components.dart';

const studioIdentityText = TextStyle(
  fontFamily: 'Manrope',
  fontSize: 18,
  fontWeight: FontWeight.w700,
  height: 1.35,
);
const studioSheetText = TextStyle(
  fontFamily: 'Manrope',
  fontSize: 20,
  fontWeight: FontWeight.w700,
  height: 1.35,
  letterSpacing: -.5,
);

/// Approved Studio sheets keep their heading outside the scrolling body.
class StudioReviewSheet extends StatelessWidget {
  const StudioReviewSheet({
    required this.title,
    required this.child,
    this.onBack,
    this.actions = const [],
    this.bottomPadding = 20,
    super.key,
  });
  final String title;
  final Widget child;
  final List<Widget> actions;
  final VoidCallback? onBack;
  final double bottomPadding;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StudioReviewSheetHeader(
            title: title,
            onBack: onBack,
            actions: actions,
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                0,
                20,
                bottomPadding + MediaQuery.viewPaddingOf(context).bottom,
              ),
              child: child,
            ),
          ),
        ],
      ),
    ),
  );
}

double studioSheetHeaderHeight(BuildContext context, String title) {
  final painter = TextPainter(
    text: TextSpan(text: title, style: studioSheetText),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout(maxWidth: MediaQuery.sizeOf(context).width - 88);
  final titleHeight = 10 + painter.height;
  return 32 + (titleHeight > 48 ? titleHeight : 48);
}

class StudioReviewSheetHeader extends StatelessWidget {
  const StudioReviewSheetHeader({
    required this.title,
    this.onBack,
    this.onClose,
    this.actions = const [],
    super.key,
  });
  final String title;
  final VoidCallback? onBack, onClose;
  final List<Widget> actions;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onBack != null)
          IconButton(
            tooltip: 'Назад'.tr(context),
            onPressed: onBack,
            icon: const Icon(LucideIcons.arrowLeft),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(title, style: studioSheetText),
          ),
        ),
        ...actions,
        IconButton(
          tooltip: 'Закрыть'.tr(context),
          onPressed: onClose ?? () => Navigator.pop(context),
          icon: const Icon(LucideIcons.x),
        ),
      ],
    ),
  );
}

class StudioReviewState extends StatelessWidget {
  const StudioReviewState({
    required this.title,
    this.message,
    this.icon = LucideIcons.search,
    this.loading = false,
    this.action,
    super.key,
  });
  final String title;
  final String? message;
  final IconData icon;
  final bool loading;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 48),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (loading)
          const SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(
            icon,
            size: 28,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        const SizedBox(height: 16),
        Text(title, textAlign: TextAlign.center, style: studioIdentityText),
        if (message != null) ...[
          const SizedBox(height: 8),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (action != null) ...[const SizedBox(height: 20), action!],
      ],
    ),
  );
}

class StudioReviewRow extends StatelessWidget {
  const StudioReviewRow({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.leading,
    this.trailing,
    super.key,
  });
  final String title;
  final String? subtitle;
  final Widget? leading, trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Golos Text',
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ?? const Icon(LucideIcons.chevronRight, size: 18),
          ],
        ),
      ),
    ),
  );
}

Future<void> showStudioConfirmation(
  BuildContext context, {
  required String title,
  required Future<void> Function() onConfirm,
}) => showStudioSelectionSheet<void>(
  context: context,
  builder: (ctx) => StudioReviewSheet(
    title: title,
    bottomPadding: 16,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$title?', style: Theme.of(ctx).textTheme.bodyMedium),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            onConfirm();
          },
          child: Text(title),
        ),
      ],
    ),
  ),
);

/// Brand header for a secondary page outside the tab shell.
class StudioReviewBrand extends StatelessWidget implements PreferredSizeWidget {
  const StudioReviewBrand({required this.mode, super.key});
  final String mode;
  @override
  Size get preferredSize => const Size.fromHeight(48);
  @override
  Widget build(BuildContext context) => AppBar(
    centerTitle: false,
    automaticallyImplyLeading: false,
    titleSpacing: 20,
    toolbarHeight: 48,
    title: RichText(
      text: TextSpan(
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        children: [
          const TextSpan(text: 'petfriendly'),
          TextSpan(
            text: '.',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFFD7EF89)
                  : const Color(0xFF638122),
            ),
          ),
        ],
      ),
    ),
    actions: [
      Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Center(
          child: Text(mode, style: Theme.of(context).textTheme.bodySmall),
        ),
      ),
    ],
  );
}
