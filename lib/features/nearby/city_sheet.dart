import 'onboarding_manual_city_sheet.dart';
import '../../core/ui/studio_review.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../l10n/localization.dart';
import 'package:flutter/material.dart';
import '../../core/theme/studio_theme.dart';
import '../../core/ui/components.dart';
import 'city_search.dart';

class CitySheet extends StatefulWidget {
  const CitySheet({
    super.key,
    required this.city,
    required this.onSelected,
    required this.onLocate,
    this.onboarding = false,
    this.locating = false,
    this.locationError,
  });
  final String city;
  final ValueChanged<String> onSelected;
  final VoidCallback onLocate;
  final bool onboarding, locating;
  final String? locationError;
  @override
  State<CitySheet> createState() => CitySheetState();
}

class CitySheetState extends State<CitySheet> {
  final input = TextEditingController();
  bool ready = false;
  bool unavailable = false;
  @override
  void initState() {
    super.initState();
    ready = worldCitiesLoaded;
    if (ready) return;
    loadWorldCities()
        .then((_) {
          if (mounted) setState(() => ready = true);
        })
        .catchError((Object _) {
          if (mounted) setState(() => unavailable = true);
        });
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  void choose(String city) {
    final selected = canonicalCity(city);
    if (selected.isNotEmpty) {
      FocusScope.of(context).unfocus();
      widget.onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = input.text.trim();
    final current = knownCity(canonicalCity(widget.city));
    final suggestions = query.isEmpty
        ? <CitySuggestion>[
            ?current,
            ...['Минск', 'Варшава', 'Вильнюс', 'Лондон']
                .map(knownCity)
                .whereType<CitySuggestion>()
                .where((c) => c.name != current?.name),
          ].take(4).toList()
        : suggestCities(query).take(12).toList();
    Future<void> manual() async {
      final result = await showStudioSelectionSheet<String>(
        context: context,
        builder: (_) => OnboardingManualCitySheet(initialCity: query),
      );
      if (mounted && result != null) choose(result);
    }

    return StudioReviewSheet(
      title: 'Выберите город'.tr(context),
      fixedContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: const Key('city-input'),
                  controller: input,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  decoration: InputDecoration(
                    hintText: 'Название города'.tr(context),
                    prefixIcon: const Icon(LucideIcons.search, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                key: Key(
                  widget.onboarding ? 'onboarding-detect-city' : 'city-nearby',
                ),
                tooltip: 'Определить мой город'.tr(context),
                onPressed: widget.locating ? null : widget.onLocate,
                style: IconButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: widget.locating
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.locateFixed, size: 20),
              ),
            ],
          ),
          if (widget.locationError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                widget.locationError!.tr(context),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!ready && !unavailable)
            StudioReviewState(title: 'Загружаем…'.tr(context), loading: true)
          else if (unavailable)
            StudioReviewState(
              title: 'Не удалось загрузить'.tr(context),
              action: OutlinedButton(
                onPressed: manual,
                child: Text('Указать вручную'.tr(context)),
              ),
            )
          else ...[
            for (var i = 0; i < suggestions.length; i++) ...[
              if (i > 0)
                Divider(height: 1, color: StudioColors.of(context).line),
              KeyedSubtree(
                key: ValueKey('city-suggestion-${suggestions[i].name}'),
                child: onboardingRow(suggestions[i]),
              ),
            ],
            if (query.isNotEmpty && suggestions.isEmpty && query.contains(','))
              ListTile(
                key: const Key('city-custom'),
                title: Text(
                  'Выбрать «{p0}»'.tr(context, arguments: {'p0': query}),
                ),
                subtitle: Text('Другой город'.tr(context)),
                trailing: const Icon(LucideIcons.chevronRight, size: 20),
                onTap: () => choose(query),
              ),
            if (query.isNotEmpty && suggestions.isEmpty)
              StudioReviewState(
                title: 'Город не найден'.tr(context),
                message:
                    'Попробуйте другое название или добавьте населённый пункт вручную.'
                        .tr(context),
                action: OutlinedButton(
                  key: const Key('onboarding-manual'),
                  onPressed: manual,
                  child: Text('Указать вручную'.tr(context)),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget onboardingRow(CitySuggestion city) => KeyedSubtree(
    key: city.name == canonicalCity(widget.city) && input.text.isEmpty
        ? const Key('city-current')
        : null,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => choose(city.name),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      city.displayName,
                      style: studioIdentityText.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [
                        countryName(city.isoCountry, context.languageCode),
                        if (city.region.isNotEmpty) city.region,
                      ].join(' · '),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(LucideIcons.chevronRight, size: 22),
            ],
          ),
        ),
      ),
    ),
  );
}
