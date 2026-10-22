import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/ui/components.dart';
import '../core/ui/studio_review.dart';
import '../core/theme/studio_theme.dart';
import 'localization.dart';

Future<void> chooseAppLanguage(BuildContext context, WidgetRef ref) async {
  final current = ref.read(languageProvider)?.languageCode ?? 'system';
  final choice = await showStudioSelectionSheet<String>(
    context: context,
    builder: (sheetContext) => _LanguageSheet(current: current),
  );
  if (choice != null) {
    await ref
        .read(languageProvider.notifier)
        .select(choice == 'system' ? null : choice);
  }
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet({required this.current});
  final String current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final deviceLocale = resolveAppLocale(
      WidgetsBinding.instance.platformDispatcher.locales,
      AppLocalizations.supportedLocales,
    );
    final android = theme.platform == TargetPlatform.android;
    final entries = {
      'system': 'Как на устройстве'.tr(context),
      ...appLanguages,
    }.entries.toList();
    return StudioReviewSheet(
      title: 'Язык приложения'.tr(context),
      bottomPadding: 12,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final entry in entries) ...[
            if (entry.key == appLanguages.keys.first) const Divider(height: 16),
            Semantics(
              selected: entry.key == current,
              inMutuallyExclusiveGroup: true,
              child: ListTile(
                key: ValueKey('language-${entry.key}'),
                minTileHeight: 48,
                minVerticalPadding: 4,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                selected: entry.key == current,
                selectedColor: colors.onSurface,
                selectedTileColor: StudioColors.of(context).tint,
                title: Text(
                  entry.value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                    fontWeight: entry.key == current
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
                subtitle: entry.key == 'system'
                    ? Text(
                        appLanguages[deviceLocale.languageCode]!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      )
                    : null,
                trailing: android
                    ? Icon(
                        entry.key == current
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: entry.key == current
                            ? colors.onSurface
                            : colors.onSurfaceVariant,
                      )
                    : entry.key == current
                    ? Icon(
                        Icons.check_rounded,
                        size: 20,
                        color: colors.onSurface,
                      )
                    : null,
                onTap: () => Navigator.of(context).pop(entry.key),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class LanguageButton extends ConsumerWidget {
  const LanguageButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => IconButton(
    tooltip: 'Язык приложения'.tr(context),
    icon: const Icon(Icons.translate_outlined),
    onPressed: () => chooseAppLanguage(context, ref),
  );
}
