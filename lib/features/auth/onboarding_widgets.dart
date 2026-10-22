import 'package:flutter/material.dart';
import '../../core/theme/studio_theme.dart';

const onboardingHeading = TextStyle(
  fontFamily: 'Manrope',
  fontSize: 32,
  height: 1.12,
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
      child: PopScope(
        canPop: onBack == null,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) onBack?.call();
        },
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
      ),
    );
  }
}
