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
  String? countryFilter;
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
    final current = canonicalCity(widget.city);
    final suggestions = suggestCities(query, countryCode: countryFilter)
        .where((city) => query.isNotEmpty || city.name != current)
        .take(query.isEmpty ? 3 : 6)
        .toList();
    final custom =
        query.isNotEmpty &&
        suggestions.isEmpty &&
        knownCity(query) == null &&
        (countryFilter != null || query.contains(','));
    final manualQuery = countryFilter == null
        ? query
        : '$query, $countryFilter';
    if (widget.onboarding) {
      final initial = query.isEmpty
          ? ['Минск', 'Варшава', 'Вильнюс']
                .map(knownCity)
                .whereType<CitySuggestion>()
                .where((city) => city.name != current)
                .toList()
          : suggestions;
      return onboardingBody(query, current, initial);
    }
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSheetHeader(title: 'Выберите город'.tr(context)),
        const SizedBox(height: 16),
        if (ready) ...[
          StudioFieldLabel(
            label: 'Страна'.tr(context),
            child: DropdownButtonFormField<String>(
              key: const Key('city-country'),
              initialValue: countryFilter ?? '',
              isExpanded: true,
              isDense: false,
              itemHeight: null,
              menuMaxHeight: 420,
              decoration: const InputDecoration(),
              // Size the trigger from the selected country, not the longest
              // hidden menu option. Open options still wrap their full names.
              selectedItemBuilder: (_) => [
                for (final _ in ['', ...availableCountries])
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      countryFilter == null
                          ? 'Все страны'.tr(context)
                          : countryName(countryFilter!, context.languageCode),
                    ),
                  ),
              ],
              items: [
                DropdownMenuItem(
                  value: '',
                  child: Text('Все страны'.tr(context)),
                ),
                for (final code
                    in (availableCountries..sort(
                      (a, b) => countryName(
                        a,
                        context.languageCode,
                      ).compareTo(countryName(b, context.languageCode)),
                    )))
                  DropdownMenuItem(
                    value: code,
                    child: Text(countryName(code, context.languageCode)),
                  ),
              ],
              onChanged: (value) =>
                  setState(() => countryFilter = value == '' ? null : value),
            ),
          ),
          const SizedBox(height: 16),
        ],
        StudioFieldLabel(
          label: 'Город, регион или страна'.tr(context),
          child: TextField(
            textAlignVertical: TextAlignVertical.top,
            key: const Key('city-input'),
            controller: input,
            maxLength: 100,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.search,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              counterText: '',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: input.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: "Очистить поиск".tr(context),
                      onPressed: () => setState(input.clear),
                      icon: const Icon(Icons.close, size: 18),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (query.isEmpty && current.isNotEmpty) ...[
          _cityRow(
            context,
            current,
            country: knownCity(current) == null
                ? null
                : countryName(
                    knownCity(current)!.isoCountry,
                    context.languageCode,
                  ),
            selected: true,
            key: const Key('city-current'),
          ),
          const SizedBox(height: 12),
          Text(
            "Другие города".tr(context),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
        ],
        for (final city in suggestions)
          _cityRow(
            context,
            city.name,
            country: [
              countryName(city.isoCountry, context.languageCode),
              if (city.region.isNotEmpty) city.region,
            ].join(' · '),
            selected: city.name == current,
            key: ValueKey('city-suggestion-${city.name}'),
          ),
        if (custom) ...[
          if (suggestions.isNotEmpty) const Divider(height: 24),
          ListTile(
            key: const Key('city-custom'),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            minTileHeight: 56,
            leading: const Icon(Icons.location_city_outlined),
            title: Text(
              "Выбрать «{p0}»".tr(context, arguments: {'p0': manualQuery}),
            ),
            subtitle: Text("Другой город".tr(context)),
            onTap: () => choose(manualQuery),
          ),
        ],
        if (!ready && !unavailable) const LinearProgressIndicator(),
        if (query.isNotEmpty && suggestions.isEmpty && !custom)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('Введите город и страну'.tr(context)),
          ),
        if (query.isNotEmpty && suggestions.isEmpty)
          Text(
            'Меньшие населённые пункты можно указать вручную, добавив страну.'
                .tr(context),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        const Divider(height: 28),
        OutlinedButton.icon(
          key: const Key('city-nearby'),
          onPressed: widget.onLocate,
          icon: const Icon(Icons.my_location_outlined),
          label: Text("Рядом со мной".tr(context)),
        ),
      ],
    );
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 12,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .8,
          ),
          child: SingleChildScrollView(child: body),
        ),
      ),
    );
  }

  Widget onboardingBody(
    String query,
    String current,
    List<CitySuggestion> suggestions,
  ) {
    Future<void> manual() async {
      final result = await showStudioSelectionSheet<String>(
        context: context,
        builder: (_) => OnboardingManualCitySheet(initialCity: query),
      );
      if (mounted && result != null) choose(result);
    }

    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: StudioColors.of(context).line),
    );
    return StudioReviewSheet(
      title: 'Выберите город'.tr(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilledButton.icon(
            key: const Key('onboarding-detect-city'),
            style: FilledButton.styleFrom(
              disabledBackgroundColor: StudioColors.lime,
              disabledForegroundColor: StudioColors.onLime,
              textStyle: const TextStyle(
                fontFamily: 'Golos Text',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: widget.locating ? null : widget.onLocate,
            icon: widget.locating
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: StudioColors.onLime,
                    ),
                  )
                : const Icon(LucideIcons.locateFixed, size: 22),
            label: Text(
              (widget.locating ? 'Определяем город…' : 'Определить мой город')
                  .tr(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Используем геопозицию только для выбора города. Точные координаты не публикуются.'
                .tr(context),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (widget.locationError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Semantics(
                liveRegion: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(LucideIcons.circleAlert, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.locationError!.tr(context),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 20),
          TextField(
            key: const Key('city-input'),
            controller: input,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              hintText: 'Название города'.tr(context),
              prefixIcon: const Icon(LucideIcons.search, size: 22),
              filled: true,
              fillColor: StudioColors.of(context).tint,
              contentPadding: const EdgeInsets.all(12),
              enabledBorder: border,
              focusedBorder: border.copyWith(
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!ready && !unavailable)
            StudioReviewState(title: 'Загружаем…'.tr(context), loading: true)
          else if (unavailable)
            StudioReviewState(
              title: 'Не удалось загрузить'.tr(context),
              message: 'Проверьте соединение и попробуйте снова.'.tr(context),
              icon: LucideIcons.cloudOff,
              action: OutlinedButton(
                onPressed: manual,
                child: Text('Указать вручную'.tr(context)),
              ),
            )
          else ...[
            if (query.isEmpty && knownCity(current) != null)
              onboardingRow(knownCity(current)!),
            for (final city in suggestions) onboardingRow(city),
            if (query.isNotEmpty && suggestions.isEmpty)
              StudioReviewState(
                title: 'Город не найден'.tr(context),
                message:
                    'Попробуйте другое название или добавьте населённый пункт вручную.'
                        .tr(context),
                icon: LucideIcons.search,
                action: OutlinedButton(
                  key: const Key('onboarding-manual'),
                  onPressed: manual,
                  style: OutlinedButton.styleFrom(
                    textStyle: const TextStyle(
                      fontFamily: 'Golos Text',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: Text('Указать вручную'.tr(context)),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget onboardingRow(CitySuggestion city) => Material(
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
  );

  Widget _cityRow(
    BuildContext context,
    String name, {
    String? country,
    required bool selected,
    required Key key,
  }) => ListTile(
    key: key,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    minTileHeight: 56,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    selected: selected,
    selectedColor: Theme.of(context).colorScheme.onSurface,
    selectedTileColor: StudioColors.of(context).tint,
    leading: const Icon(Icons.location_city_outlined),
    title: Text(knownCity(name)?.displayName ?? name),
    subtitle: country?.trim().isNotEmpty == true || selected
        ? MetadataLine(
            items: [?country, if (selected) "Выбран сейчас".tr(context)],
          )
        : null,
    trailing: selected ? const Icon(Icons.check) : null,
    onTap: () => choose(name),
  );
}
