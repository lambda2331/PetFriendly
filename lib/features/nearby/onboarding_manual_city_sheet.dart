import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/location/city_directory.dart';
import '../../core/theme/studio_theme.dart';
import '../../core/ui/studio_review.dart';
import '../../l10n/localization.dart';

/// Public, country-qualified settlement only; never stores device coordinates.
class OnboardingManualCitySheet extends StatefulWidget {
  const OnboardingManualCitySheet({this.initialCity = '', super.key});
  final String initialCity;
  @override
  State<OnboardingManualCitySheet> createState() => _ManualCityState();
}

class _ManualCityState extends State<OnboardingManualCitySheet> {
  late final city = TextEditingController(text: widget.initialCity);
  final country = TextEditingController();
  final cityFocus = FocusNode(), countryFocus = FocusNode();
  bool submitted = false;
  String? countryCode() {
    final value = country.text.trim().toLowerCase();
    final codes = <String>{
      ...availableCountries,
      for (var first = 65; first <= 90; first++)
        for (var second = 65; second <= 90; second++)
          if (countryName(String.fromCharCodes([first, second]), 'en') !=
              String.fromCharCodes([first, second]))
            String.fromCharCodes([first, second]),
    };
    return codes
        .where(
          (code) =>
              code.toLowerCase() == value ||
              ['ru', 'en', 'be', 'pl'].any(
                (language) =>
                    countryName(code, language).toLowerCase() == value,
              ),
        )
        .firstOrNull;
  }

  String? get cityError =>
      submitted && (city.text.trim().isEmpty || city.text.trim().length > 100)
      ? 'Укажите название населённого пункта.'
      : null;
  String? get countryError =>
      submitted && countryCode() == null ? 'Укажите страну.' : null;
  @override
  void dispose() {
    city.dispose();
    country.dispose();
    cityFocus.dispose();
    countryFocus.dispose();
    super.dispose();
  }

  void save() {
    setState(() => submitted = true);
    if (cityError != null) {
      cityFocus.requestFocus();
      return;
    }
    if (countryError != null) {
      countryFocus.requestFocus();
      return;
    }
    final code = countryCode()!;
    final name = city.text.trim();
    final exact = suggestCities(name, countryCode: code)
        .where(
          (candidate) =>
              candidate.displayName.toLowerCase() == name.toLowerCase() ||
              candidate.aliases.any(
                (alias) => alias.toLowerCase() == name.toLowerCase(),
              ),
        )
        .firstOrNull;
    Navigator.pop(context, exact?.name ?? '$name, $code');
  }

  Widget field(
    String label,
    TextEditingController input,
    FocusNode focus,
    String? message,
    String key,
  ) {
    final color = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xffffb4ab)
        : const Color(0xffb3261e);
    OutlineInputBorder border(double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: message == null ? StudioColors.of(context).line : color,
        width: width,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label.tr(context)),
        const SizedBox(height: 8),
        TextField(
          key: ValueKey(key),
          controller: input,
          focusNode: focus,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            filled: true,
            fillColor: StudioColors.of(context).tint,
            contentPadding: const EdgeInsets.all(12),
            enabledBorder: border(1),
            focusedBorder: border(2),
          ),
        ),
        if (message != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Semantics(
              liveRegion: true,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(LucideIcons.circleAlert, size: 16, color: color),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      message.tr(context),
                      style: TextStyle(
                        fontFamily: 'Golos Text',
                        fontSize: 12,
                        height: 1.5,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => StudioReviewSheet(
    title: 'Указать вручную'.tr(context),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        field('Город', city, cityFocus, cityError, 'onboarding-manual-city'),
        const SizedBox(height: 20),
        field(
          'Страна',
          country,
          countryFocus,
          countryError,
          'onboarding-manual-country',
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('onboarding-manual-save'),
          style: FilledButton.styleFrom(
            textStyle: const TextStyle(
              fontFamily: 'Golos Text',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          onPressed: save,
          child: Text('Сохранить'.tr(context)),
        ),
      ],
    ),
  );
}
