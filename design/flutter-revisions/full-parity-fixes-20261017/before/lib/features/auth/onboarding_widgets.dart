import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/theme/studio_theme.dart';
import '../../l10n/localization.dart';

const onboardingHeading = TextStyle(
  fontFamily: 'Manrope',
  fontSize: 28,
  height: 1.2,
  fontWeight: FontWeight.w700,
  letterSpacing: -.7,
);

class OnboardingFrame extends StatelessWidget {
  const OnboardingFrame({
    required this.child,
    this.footer,
    this.scroll,
    this.step,
    this.total = 3,
    this.onBack,
    super.key,
  });
  final Widget child;
  final Widget? footer;
  final ScrollController? scroll;
  final int? step;
  final int total;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context),
        error = base.brightness == Brightness.dark
            ? const Color(0xFFFFB4AB)
            : const Color(0xFFB3261E);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: StudioColors.of(context).line),
    );
    return Theme(
      data: base.copyWith(
        colorScheme: base.colorScheme.copyWith(error: error),
        filledButtonTheme: FilledButtonThemeData(
          style: base.filledButtonTheme.style?.copyWith(
            textStyle: const WidgetStatePropertyAll(
              TextStyle(
                fontFamily: 'Golos Text',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        inputDecorationTheme: base.inputDecorationTheme.copyWith(
          filled: true,
          fillColor: StudioColors.of(context).tint,
          contentPadding: const EdgeInsets.all(12),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: BorderSide(color: base.colorScheme.onSurface, width: 2),
          ),
          errorBorder: border.copyWith(
            borderSide: BorderSide(color: error, width: 1),
          ),
          focusedErrorBorder: border.copyWith(
            borderSide: BorderSide(color: error, width: 2),
          ),
          helperStyle: base.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            height: 1.5,
          ),
        ),
      ),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      letterSpacing: -1,
                      color: base.colorScheme.onSurface,
                    ),
                    children: [
                      const TextSpan(text: 'petfriendly'),
                      TextSpan(
                        text: '.',
                        style: TextStyle(
                          color: base.brightness == Brightness.dark
                              ? StudioColors.lime
                              : const Color(0xFF638122),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 40),
                  child: Row(
                    children: [
                      if (onBack != null)
                        SizedBox(
                          width: 28,
                          height: 40,
                          child: OverflowBox(
                            maxWidth: 40,
                            alignment: Alignment.centerRight,
                            child: IconButton(
                              constraints: const BoxConstraints.tightFor(
                                width: 40,
                                height: 40,
                              ),
                              padding: const EdgeInsets.all(9),
                              iconSize: 22,
                              tooltip: 'Назад'.tr(context),
                              onPressed: onBack,
                              icon: const Icon(LucideIcons.arrowLeft),
                            ),
                          ),
                        ),
                      if (onBack != null) const SizedBox(width: 12),
                      if (step != null)
                        Expanded(
                          child: Text(
                            'Шаг {p0} из {p1}'.tr(
                              context,
                              arguments: {'p0': step! + 1, 'p1': total},
                            ),
                            style: base.textTheme.bodySmall?.copyWith(
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (step != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    children: [
                      for (var i = 0; i < total; i++)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: i < total - 1 ? 4 : 0,
                            ),
                            child: Container(
                              height: 2,
                              color: i <= step!
                                  ? base.colorScheme.onSurface
                                  : StudioColors.of(context).line,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scroll,
                  padding: const EdgeInsets.all(20),
                  child: child,
                ),
              ),
              if (footer != null)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: StudioColors.of(context).line),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: footer,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
