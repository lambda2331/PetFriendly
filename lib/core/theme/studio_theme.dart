import 'package:flutter/material.dart';

@immutable
class StudioColors extends ThemeExtension<StudioColors> {
  const StudioColors({
    required this.tint,
    required this.hero,
    required this.line,
  });
  final Color tint, hero, line;
  static const lime = Color(0xFFD6ED8A);
  static const onLime = Color(0xFF253314);
  static StudioColors of(BuildContext context) =>
      Theme.of(context).extension<StudioColors>()!;
  @override
  StudioColors copyWith({Color? tint, Color? hero, Color? line}) =>
      StudioColors(
        tint: tint ?? this.tint,
        hero: hero ?? this.hero,
        line: line ?? this.line,
      );
  @override
  StudioColors lerp(StudioColors? other, double t) => other == null
      ? this
      : StudioColors(
          tint: Color.lerp(tint, other.tint, t)!,
          hero: Color.lerp(hero, other.hero, t)!,
          line: Color.lerp(line, other.line, t)!,
        );
}

ThemeData studioTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final ink = Color(dark ? 0xFFF4F5EF : 0xFF20251E);
  final muted = Color(dark ? 0xFFBBC2B4 : 0xFF62695C);
  final bg = Color(dark ? 0xFF141614 : 0xFFF9F9F6);
  final surface = Color(dark ? 0xFF20231F : 0xFFFFFFFF);
  final sheet = Color(dark ? 0xFF272C25 : 0xFFFFFFFF);
  final colors = StudioColors(
    tint: Color(dark ? 0xFF292F25 : 0xFFEEF1E7),
    hero: Color(dark ? 0xFF293121 : 0xFFE7EDDA),
    line: Color(dark ? 0xFF41483C : 0xFFE4E7DD),
  );
  final scheme =
      ColorScheme.fromSeed(
        seedColor: StudioColors.lime,
        brightness: brightness,
      ).copyWith(
        primary: StudioColors.lime,
        onPrimary: StudioColors.onLime,
        surface: surface,
        onSurface: ink,
        onSurfaceVariant: muted,
        outlineVariant: colors.line,
        outline: muted,
        surfaceContainerLowest: bg,
        surfaceContainerLow: surface,
        surfaceContainer: sheet,
        surfaceContainerHigh: colors.tint,
        surfaceContainerHighest: colors.hero,
        secondaryContainer: colors.tint,
        onSecondaryContainer: ink,
        error: Color(dark ? 0xFFFFB4AB : 0xFFB3261E),
      );
  final actionButtonStyle = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    ),
    shape: const WidgetStatePropertyAll(StadiumBorder()),
    textStyle: const WidgetStatePropertyAll(
      TextStyle(
        fontFamily: 'Golos Text',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
    ),
    iconSize: const WidgetStatePropertyAll(20),
    elevation: const WidgetStatePropertyAll(0),
    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    overlayColor: const WidgetStatePropertyAll(Colors.transparent),
    visualDensity: VisualDensity.standard,
    tapTargetSize: MaterialTapTargetSize.padded,
    animationDuration: const Duration(milliseconds: 100),
  );
  final primaryButtonStyle = actionButtonStyle.copyWith(
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) =>
          states.contains(WidgetState.disabled) ? muted : StudioColors.onLime,
    ),
    backgroundColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) return colors.tint;
      if (states.contains(WidgetState.pressed) ||
          states.contains(WidgetState.hovered)) {
        return const Color(0xFFCBE578);
      }
      return StudioColors.lime;
    }),
    side: WidgetStateProperty.resolveWith(
      (states) =>
          states.contains(WidgetState.focused) &&
              !states.contains(WidgetState.disabled)
          ? const BorderSide(color: StudioColors.onLime, width: 2)
          : BorderSide.none,
    ),
  );
  final secondaryButtonStyle = actionButtonStyle.copyWith(
    foregroundColor: WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.disabled) ? muted : ink,
    ),
    backgroundColor: WidgetStateProperty.resolveWith(
      (states) =>
          !states.contains(WidgetState.disabled) &&
              (states.contains(WidgetState.pressed) ||
                  states.contains(WidgetState.hovered))
          ? colors.tint
          : Colors.transparent,
    ),
    side: WidgetStateProperty.resolveWith(
      (states) =>
          states.contains(WidgetState.focused) &&
              !states.contains(WidgetState.disabled)
          ? BorderSide(color: ink, width: 2)
          : BorderSide(color: colors.line),
    ),
  );
  return ThemeData(
    useMaterial3: true,
    buttonTheme: const ButtonThemeData(alignedDropdown: true),
    brightness: brightness,
    scaffoldBackgroundColor: bg,
    colorScheme: scheme,
    fontFamily: 'Golos Text',
    extensions: [colors],
    textTheme: TextTheme(
      headlineLarge: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 32,
        height: 1.12,
        letterSpacing: -.9,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 26,
        height: 1.16,
        letterSpacing: -.8,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 24,
        height: 1.2,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 18,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: ink,
      ),
      displayLarge: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 48,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: -1.2,
        color: ink,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 40,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -1,
        color: ink,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 1.2,
        letterSpacing: -.9,
        color: ink,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Golos Text',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: ink,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Golos Text',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: ink,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Golos Text',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.4,
        color: ink,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Golos Text',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: muted,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Golos Text',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: ink,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Golos Text',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: ink,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Golos Text',
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.4,
        color: muted,
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: ink,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -.5,
        height: 1.35,
        color: ink,
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: surface,
      headerForegroundColor: ink,
      headerHeadlineStyle: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
      weekdayStyle: TextStyle(
        fontFamily: 'Golos Text',
        fontSize: 12,
        color: muted,
      ),
      dayForegroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled)
            ? muted.withValues(alpha: .45)
            : states.contains(WidgetState.selected)
            ? StudioColors.onLime
            : ink,
      ),
      todayForegroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? StudioColors.onLime : ink,
      ),
      todayBorder: BorderSide(color: muted),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: surface,
      hourMinuteColor: colors.tint,
      hourMinuteTextColor: ink,
      dialBackgroundColor: colors.tint,
      dialHandColor: StudioColors.lime,
      dialTextColor: ink,
    ),
    chipTheme: ChipThemeData(
      shape: const StadiumBorder(),
      side: BorderSide.none,
      backgroundColor: colors.tint,
      selectedColor: ink,
      labelStyle: TextStyle(fontFamily: 'Golos Text', fontSize: 12, color: ink),
    ),
    dividerTheme: DividerThemeData(color: colors.line, thickness: 1),
    dialogTheme: DialogThemeData(
      backgroundColor: sheet,
      surfaceTintColor: Colors.transparent,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: sheet,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.all(12),
        foregroundColor: ink,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ink,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: const StadiumBorder(),
        textStyle: const TextStyle(
          inherit: false,
          fontFamily: 'Golos Text',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(style: secondaryButtonStyle),
    filledButtonTheme: FilledButtonThemeData(style: primaryButtonStyle),
    elevatedButtonTheme: ElevatedButtonThemeData(style: primaryButtonStyle),
    inputDecorationTheme: InputDecorationTheme(
      labelStyle: TextStyle(color: muted),
      floatingLabelStyle: TextStyle(color: muted),
      alignLabelWithHint: true,
      filled: true,
      fillColor: colors.tint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      indicatorColor: StudioColors.lime,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'Golos Text',
          fontSize: 11,
          color: states.contains(WidgetState.selected) ? ink : muted,
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: ink,
      contentTextStyle: TextStyle(color: bg, fontFamily: 'Golos Text'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
