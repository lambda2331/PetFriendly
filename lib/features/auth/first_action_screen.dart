import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/studio_theme.dart';
import '../../l10n/localization.dart';
import '../walks/account_mode.dart';
import 'onboarding_widgets.dart';

class FirstActionScreen extends ConsumerWidget {
  const FirstActionScreen({this.onBack, super.key});
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final helper = ref.watch(accountModeProvider).value?.isHelper == true;
    void openMap() => context.go(helper ? '/requests' : '/nearby');
    final actions = helper
        ? [('Посмотреть запросы', LucideIcons.listFilter, '/requests')]
        : [
            ('Найти место для прогулки', LucideIcons.trees, '/places'),
            ('Познакомиться с соседями', LucideIcons.usersRound, '/people'),
            ('Найти помощь с выгулом', LucideIcons.pawPrint, '/walks'),
          ];
    return OnboardingFrame(
      onBack: onBack,
      footer: FilledButton(
        onPressed: openMap,
        child: Text(
          (helper ? 'Посмотреть запросы' : 'Перейти к карте').tr(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: StudioColors.lime,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                LucideIcons.check,
                color: StudioColors.onLime,
                size: 28,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            (helper ? 'Профиль помощника готов' : 'Вы готовы к прогулке').tr(
              context,
            ),
            style: onboardingHeading,
          ),
          const SizedBox(height: 12),
          Text(
            'Начните с того, что вам интересно. Остальные разделы всегда рядом.'
                .tr(context),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 12, endIndent: 12),
            _OnboardingActionRow(
              title: actions[i].$1.tr(context),
              subtitle: helper
                  ? 'Вы сможете откликнуться на подходящую прогулку'.tr(context)
                  : null,
              leading: Icon(actions[i].$2, size: 22),
              onTap: () {
                if (actions[i].$3 == '/places') {
                  context.go('/nearby');
                  context.push('/places');
                } else {
                  context.go(actions[i].$3);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _OnboardingActionRow extends StatelessWidget {
  const _OnboardingActionRow({
    required this.title,
    required this.leading,
    required this.onTap,
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final Widget leading;
  final VoidCallback onTap;
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
            leading,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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
            const Icon(LucideIcons.chevronRight, size: 22),
          ],
        ),
      ),
    ),
  );
}
