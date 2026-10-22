import '../../l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'place_contributions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/storage/prototype_store.dart';
import '../../core/ui/components.dart';
import 'place_filters.dart';
import 'location_service.dart';
import 'place_row.dart';
import 'city_catalog.dart';
import 'place_pages.dart';
import '../../core/backend/backend.dart';
import 'place_repository.dart';

class PlacesListScreen extends ConsumerStatefulWidget {
  const PlacesListScreen({super.key});
  @override
  ConsumerState<PlacesListScreen> createState() => _PlacesListState();
}

class _PlacesListState extends ConsumerState<PlacesListScreen> {
  late final TextEditingController search = TextEditingController(
    text: ref.read(placeFiltersProvider).query,
  );
  final scroll = ScrollController();
  int visibleCount = 40;
  @override
  void initState() {
    super.initState();
    scroll.addListener(() {
      if (scroll.position.extentAfter < 300 &&
          ref.read(backendProvider) != null &&
          ref.read(placeFiltersProvider).sort == PlaceSort.name) {
        ref.read(placePagesProvider.notifier).nextPage();
      } else if (scroll.position.extentAfter < 300 &&
          visibleCount < ref.read(filteredPlacesProvider).length) {
        setState(() => visibleCount += 40);
      }
    });
  }

  void restartPages() {
    setState(() => visibleCount = 40);
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  @override
  void dispose() {
    scroll.dispose();
    search.dispose();
    super.dispose();
  }

  void reset() {
    search.clear();
    ref.read(placeFiltersProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(placeFiltersProvider, (_, _) => restartPages());
    ref.listen(
      prototypeProvider.select((s) => s.city),
      (_, _) => restartPages(),
    );
    final filter = ref.watch(placeFiltersProvider);
    final server =
        ref.watch(backendProvider) != null && filter.sort == PlaceSort.name;
    final pages = server ? ref.watch(placePagesProvider) : null;
    final publicPlaces = server
        ? (pages?.value?.items ?? [])
        : ref.watch(filteredPlacesProvider);
    final contributions = ref.watch(placeContributionsProvider);
    final state = ref.watch(prototypeProvider);
    final pending = server
        ? filterPlaces(
            (contributions.value ?? <Place>[])
                .where((p) => p.pending && p.city == state.city)
                .toList(),
            filter,
            state.favorites,
            ref.read(locationServiceProvider).lastPosition,
          )
        : <Place>[];
    final places = server
        ? mergeCityPlaces(publicPlaces, pending, state.city)
        : publicPlaces;
    if (server && pending.isNotEmpty) {
      places.sort((a, b) => a.name.compareTo(b.name));
    }
    final catalog = ref.watch(selectedCityCatalogProvider);
    final loading = server ? pages?.isLoading == true : catalog.isLoading;
    final unavailable = server ? pages?.hasError == true : catalog.hasError;
    final hasResult = server ? pages?.hasValue == true : catalog.hasValue;
    final total = server
        ? (pages?.value?.total ?? 0) + pending.length
        : places.length;
    final more = server
        ? (pages?.value?.hasMore ?? false)
        : visibleCount < places.length;
    final city = ref.watch(prototypeProvider).city;
    final shown = server ? places.length : visibleCount.clamp(0, places.length);
    void update(PlaceFilter value) =>
        ref.read(placeFiltersProvider.notifier).update(value);
    return Scaffold(
      appBar: AppBar(
        title: Text("Места · {p0}".tr(context, arguments: {'p0': city})),
        actions: [
          IconButton(
            tooltip: "Добавить место".tr(context),
            onPressed: () => context.push('/add-place'),
            icon: const Icon(Icons.add_location_alt_outlined),
          ),
          if (activePlaceFilterCount(filter) > 0 || filter.query.isNotEmpty)
            TextButton(onPressed: reset, child: Text("Сбросить".tr(context))),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, bounds) {
          final content = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
                child: TextField(
                  textAlignVertical: TextAlignVertical.top,
                  key: const Key('places-search'),
                  controller: search,
                  onChanged: (value) => update(filter.copy(query: value)),
                  decoration: InputDecoration(
                    hintText: "Название или категория".tr(context),
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: "Очистить поиск".tr(context),
                            onPressed: () {
                              search.clear();
                              update(filter.copy(query: ''));
                            },
                            icon: const Icon(Icons.close),
                          ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final category = PlaceSelect<String>(
                      label: "Категория".tr(context),
                      value: filter.category,
                      choices: placeCategoryChoices,
                      onChanged: (v) => update(filter.copy(category: v)),
                    );
                    final filters = IconButton.outlined(
                      tooltip: "Фильтры мест".tr(context),
                      key: const Key('place-more-filters'),
                      icon: const Icon(Icons.tune, size: 18),
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        var draft = filter;
                        showStudioSelectionSheet<void>(
                          context: context,
                          builder: (context) => Consumer(
                            builder: (context, ref, _) => StatefulBuilder(
                              builder: (context, change) => SafeArea(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight:
                                        MediaQuery.sizeOf(context).height * .8,
                                  ),
                                  child: SingleChildScrollView(
                                    padding: const EdgeInsets.fromLTRB(
                                      24,
                                      0,
                                      24,
                                      12,
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        StudioSheetHeader(
                                          title: "Фильтры мест".tr(context),
                                        ),
                                        const SizedBox(height: 16),
                                        PlaceFilterControls(
                                          filter: draft,
                                          onChanged: (value) =>
                                              change(() => draft = value),
                                          singleColumn: true,
                                          includeCategory: false,
                                        ),
                                        const SizedBox(height: 20),
                                        TextButton(
                                          onPressed: () => change(
                                            () => draft = const PlaceFilter(),
                                          ),
                                          child: Text(
                                            'Сбросить фильтры'.tr(context),
                                          ),
                                        ),
                                        FilledButton(
                                          onPressed: () {
                                            search.text = draft.query;
                                            update(draft);
                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                            "Показать места".tr(context),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                    final favorites = FilterChip(
                      label: Text('Избранные'.tr(context)),
                      selected: filter.favoritesOnly,
                      onSelected: (value) =>
                          update(filter.copy(favoritesOnly: value)),
                      avatar: const Icon(Icons.favorite_border, size: 18),
                    );
                    if (constraints.maxWidth < 320 ||
                        MediaQuery.textScalerOf(context).scale(1) > 1.3) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          category,
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [favorites, filters],
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: category),
                        const SizedBox(width: 12),
                        Flexible(child: favorites),
                        const SizedBox(width: 8),
                        filters,
                      ],
                    );
                  },
                ),
              ),
              if (filter.access != AccessFilter.all ||
                  filter.favoritesOnly ||
                  filter.sort != PlaceSort.name)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (filter.access != AccessFilter.all)
                        InputChip(
                          label: Text(accessLabel(filter.access)),
                          deleteButtonTooltipMessage: "Убрать фильтр допуска"
                              .tr(context),
                          onDeleted: () =>
                              update(filter.copy(access: AccessFilter.all)),
                        ),
                      if (filter.favoritesOnly)
                        InputChip(
                          label: Text("Избранное".tr(context)),
                          deleteButtonTooltipMessage: "Убрать избранное".tr(
                            context,
                          ),
                          onDeleted: () =>
                              update(filter.copy(favoritesOnly: false)),
                        ),
                      if (filter.sort != PlaceSort.name)
                        InputChip(
                          label: Text("Ближе ко мне".tr(context)),
                          deleteButtonTooltipMessage: "Сортировать по названию"
                              .tr(context),
                          onDeleted: () =>
                              update(filter.copy(sort: PlaceSort.name)),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    !hasResult && loading
                        ? "Загружаем места…".tr(context)
                        : !hasResult && unavailable
                        ? "Количество мест недоступно".tr(context)
                        : "{p0} мест".tr(context, arguments: {'p0': total}),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              if (!server) const CityCatalogStatus(),
              if (pages?.isLoading == true) const LinearProgressIndicator(),
              if (pages?.hasError == true)
                TextButton(
                  onPressed: () {
                    ref.invalidate(catalogReadyProvider(city));
                    ref.invalidate(placePagesProvider);
                  },
                  child: Text("Места не загрузились · повторить".tr(context)),
                ),
              if (contributions.hasError)
                TextButton(
                  onPressed: () => ref.invalidate(placeContributionsProvider),
                  child: Text(
                    "Мои места не загрузились · повторить".tr(context),
                  ),
                ),
              Expanded(
                child: places.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.search_off, size: 36),
                              const SizedBox(height: 12),
                              Text(
                                loading
                                    ? "Загружаем места".tr(context)
                                    : unavailable
                                    ? "Попробуйте загрузить места ещё раз".tr(
                                        context,
                                      )
                                    : filter.active
                                    ? "Ничего не нашлось".tr(context)
                                    : "Пока нет мест — добавьте первое".tr(
                                        context,
                                      ),
                              ),
                              if (filter.active)
                                TextButton(
                                  onPressed: reset,
                                  child: Text("Сбросить фильтры".tr(context)),
                                ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        key: const Key('places-paged-list'),
                        controller: scroll,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: shown + 1,
                        itemBuilder: (_, i) => i == shown
                            ? more
                                  ? TextButton(
                                      onPressed: () {
                                        if (server) {
                                          ref
                                              .read(placePagesProvider.notifier)
                                              .nextPage();
                                        } else {
                                          setState(() => visibleCount += 40);
                                        }
                                      },
                                      child: Text("Показать ещё".tr(context)),
                                    )
                                  : Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      child: Text(
                                        "© OpenStreetMap contributors · ODbL. Отметки допуска из OSM требуют уточнения перед визитом."
                                            .tr(context),
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    )
                            : PlaceRow(place: places[i]),
                      ),
              ),
            ],
          );
          return bounds.maxHeight < 360 ||
                  MediaQuery.textScalerOf(context).scale(16) > 24
              ? SingleChildScrollView(
                  child: SizedBox(height: 1000, child: content),
                )
              : content;
        },
      ),
    );
  }
}

const placeCategoryChoices = {
  'Все': 'Все места',
  'Парк': 'Парки',
  'Кафе': 'Кафе',
  'Площадка': 'Площадки',
  'Ресторан': 'Рестораны',
  'Зоомагазин': 'Зоомагазины',
  'Ветклиника': 'Ветклиники',
};

int activePlaceFilterCount(PlaceFilter filter) =>
    (filter.category != 'Все' ? 1 : 0) +
    (filter.access != AccessFilter.all ? 1 : 0) +
    (filter.favoritesOnly ? 1 : 0) +
    (filter.sort != PlaceSort.name ? 1 : 0);

String accessLabel(AccessFilter access) => switch (access) {
  AccessFilter.all => 'Любой допуск',
  AccessFilter.taggedAllowed => 'Разрешено по OSM',
  AccessFilter.unknown => 'Нет подтверждения',
  AccessFilter.forbidden => 'Запрещено по OSM',
};

/// Uses the built-in Material select, inheriting the app's light/dark tokens.
class PlaceSelect<T> extends StatelessWidget {
  const PlaceSelect({
    required this.label,
    required this.value,
    required this.choices,
    required this.onChanged,
    this.disabled = const {},
    super.key,
  });
  final String label;
  final T value;
  final Map<T, String> choices;
  final Set<T> disabled;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(14);
    final caption = label.tr(context);
    return StudioFieldLabel(
      label: caption,
      child: LayoutBuilder(
        builder: (context, bounds) {
          final viewportWidth = MediaQuery.sizeOf(context).width;
          final availableWidth =
              (viewportWidth > 40 ? viewportWidth - 40 : bounds.maxWidth).clamp(
                0.0,
                420.0,
              );
          final menuWidth = (bounds.maxWidth < 240 ? 240.0 : bounds.maxWidth)
              .clamp(0.0, availableWidth)
              .toDouble();
          return PopupMenuButton<T>(
            key: ValueKey('$label:$value'),
            tooltip: caption,
            position: PopupMenuPosition.under,
            color: theme.colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            constraints: BoxConstraints(
              minWidth: menuWidth,
              maxWidth: menuWidth,
              maxHeight: 420,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: radius,
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            onSelected: onChanged,
            // Do not set initialValue: Material paints a persistent selected
            // background. Current selection is conveyed by check and weight;
            // the native menu retains keyboard focus and Escape handling.
            itemBuilder: (_) => [
              for (final entry in choices.entries)
                PopupMenuItem<T>(
                  value: entry.key,
                  enabled: !disabled.contains(entry.key),
                  height: 48,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.value.tr(context),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: entry.key == value
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              color: disabled.contains(entry.key)
                                  ? theme.disabledColor
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (entry.key == value) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check, size: 20),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
            child: Builder(
              builder: (context) => InputDecorator(
                isFocused: Focus.of(context).hasFocus,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: theme.colorScheme.secondaryContainer,
                  contentPadding: const EdgeInsets.all(12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: radius,
                    borderSide: BorderSide(
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: radius,
                    borderSide: BorderSide(color: theme.colorScheme.onSurface),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        (choices[value] ?? '').tr(context),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.expand_more, size: 18),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class PlaceFilterControls extends ConsumerWidget {
  const PlaceFilterControls({
    required this.filter,
    required this.onChanged,
    this.singleColumn = false,
    this.includeCategory = true,
    super.key,
  });
  final PlaceFilter filter;
  final ValueChanged<PlaceFilter> onChanged;
  final bool singleColumn, includeCategory;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controls = <Widget>[
      if (includeCategory)
        PlaceSelect<String>(
          label: "Категория".tr(context),
          value: filter.category,
          choices: placeCategoryChoices,
          onChanged: (v) => onChanged(filter.copy(category: v)),
        ),
      PlaceSelect<AccessFilter>(
        label: "С питомцем".tr(context),
        value: filter.access,
        choices: {for (final v in AccessFilter.values) v: accessLabel(v)},
        onChanged: (v) => onChanged(filter.copy(access: v)),
      ),
      PlaceSelect<bool>(
        label: "Подборка".tr(context),
        value: filter.favoritesOnly,
        choices: {
          false: "Все места".tr(context),
          true: "Избранное".tr(context),
        },
        onChanged: (v) => onChanged(filter.copy(favoritesOnly: v)),
      ),
      PlaceSelect<PlaceSort>(
        label: "Сортировка".tr(context),
        value: filter.sort,
        choices: {
          PlaceSort.name: "По названию".tr(context),
          PlaceSort.nearby: "Ближе ко мне".tr(context),
        },
        disabled: ref.watch(locationServiceProvider).lastPosition == null
            ? const {PlaceSort.nearby}
            : const {},
        onChanged: (v) => onChanged(filter.copy(sort: v)),
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 12,
        runSpacing: 12,
        children: controls
            .map(
              (control) => SizedBox(
                width: singleColumn
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 12) / 2,
                child: control,
              ),
            )
            .toList(),
      ),
    );
  }
}
