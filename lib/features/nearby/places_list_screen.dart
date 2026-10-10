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
    final places = server
        ? (pages?.value?.items ?? [])
        : ref.watch(filteredPlacesProvider);
    final catalog = ref.watch(selectedCityCatalogProvider);
    final loading = server ? pages?.isLoading == true : catalog.isLoading;
    final unavailable = server ? pages?.hasError == true : catalog.hasError;
    final hasResult = server ? pages?.hasValue == true : catalog.hasValue;
    final total = server ? (pages?.value?.total ?? 0) : places.length;
    final more = server
        ? (pages?.value?.hasMore ?? false)
        : visibleCount < places.length;
    final city = ref.watch(prototypeProvider).city;
    final shown = server ? places.length : visibleCount.clamp(0, places.length);
    final contributions = ref.watch(placeContributionsProvider);
    void update(PlaceFilter value) =>
        ref.read(placeFiltersProvider.notifier).update(value);
    return Scaffold(
      appBar: AppBar(
        title: Text('Места · $city'),
        actions: [
          IconButton(
            tooltip: 'Добавить место',
            onPressed: () => context.push('/add-place'),
            icon: const Icon(Icons.add_location_alt_outlined),
          ),
          if (activePlaceFilterCount(filter) > 0 || filter.query.isNotEmpty)
            TextButton(onPressed: reset, child: const Text('Сбросить')),
        ],
      ),
      body: Column(
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
                hintText: 'Название или категория',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: search.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Очистить поиск',
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
                  label: 'Категория',
                  value: filter.category,
                  choices: placeCategoryChoices,
                  onChanged: (v) => update(filter.copy(category: v)),
                );
                final count = activePlaceFilterCount(filter);
                final filters = OutlinedButton.icon(
                  key: const Key('place-more-filters'),
                  icon: const Icon(Icons.tune, size: 18),
                  label: Text(
                    count == 0 ? 'Фильтры мест' : 'Фильтры мест · $count',
                  ),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    showModalBottomSheet<void>(
                      context: context,
                      sheetAnimationStyle: studioSheetAnimation(context),
                      useRootNavigator: true,
                      isScrollControlled: true,
                      builder: (context) => Consumer(
                        builder: (context, ref, _) => SafeArea(
                          child: SizedBox(
                            height: MediaQuery.sizeOf(context).height * .8,
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const StudioSheetHeader(
                                    title: 'Фильтры мест',
                                  ),
                                  const SizedBox(height: 16),
                                  PlaceFilterControls(
                                    filter: ref.watch(placeFiltersProvider),
                                    onChanged: update,
                                    singleColumn: true,
                                    includeCategory: false,
                                  ),
                                  const SizedBox(height: 20),
                                  if (activePlaceFilterCount(
                                            ref.watch(placeFiltersProvider),
                                          ) >
                                          0 ||
                                      ref
                                          .watch(placeFiltersProvider)
                                          .query
                                          .isNotEmpty)
                                    TextButton(
                                      onPressed: reset,
                                      child: const Text('Сбросить фильтры'),
                                    ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Показать места'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
                if (constraints.maxWidth < 320 ||
                    MediaQuery.textScalerOf(context).scale(1) > 1.3) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [category, const SizedBox(height: 10), filters],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: category),
                    const SizedBox(width: 12),
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
                      deleteButtonTooltipMessage: 'Убрать фильтр допуска',
                      onDeleted: () =>
                          update(filter.copy(access: AccessFilter.all)),
                    ),
                  if (filter.favoritesOnly)
                    InputChip(
                      label: const Text('Избранное'),
                      deleteButtonTooltipMessage: 'Убрать избранное',
                      onDeleted: () =>
                          update(filter.copy(favoritesOnly: false)),
                    ),
                  if (filter.sort != PlaceSort.name)
                    InputChip(
                      label: const Text('Ближе ко мне'),
                      deleteButtonTooltipMessage: 'Сортировать по названию',
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
                    ? 'Загружаем места…'
                    : !hasResult && unavailable
                    ? 'Количество мест недоступно'
                    : '$total мест',
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
              child: const Text('Места не загрузились · повторить'),
            ),
          if (server)
            for (final pending in contributions.value ?? <Place>[])
              if (pending.pending && pending.city == city)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: PlaceRow(place: pending),
                ),
          if (contributions.hasError)
            TextButton(
              onPressed: () => ref.invalidate(placeContributionsProvider),
              child: const Text('Мои места не загрузились · повторить'),
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
                                ? 'Загружаем места'
                                : unavailable
                                ? 'Попробуйте загрузить места ещё раз'
                                : filter.active
                                ? 'Ничего не нашлось'
                                : 'Пока нет мест — добавьте первое',
                          ),
                          if (filter.active)
                            TextButton(
                              onPressed: reset,
                              child: const Text('Сбросить фильтры'),
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
                                  child: const Text('Показать ещё'),
                                )
                              : const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Text(
                                    '© OpenStreetMap contributors · ODbL. Отметки допуска из OSM требуют уточнения перед визитом.',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                )
                        : PlaceRow(place: places[i]),
                  ),
          ),
        ],
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
    final radius = BorderRadius.circular(16);
    Text choiceLabel(MapEntry<T, String> entry) => Text(
      entry.value,
      maxLines: 2,
      style: disabled.contains(entry.key)
          ? TextStyle(color: theme.disabledColor)
          : null,
    );
    return DropdownButtonFormField<T>(
      key: ValueKey('$label:$value'),
      initialValue: value,
      isExpanded: true,
      menuMaxHeight: 420,
      itemHeight: null,
      borderRadius: radius,
      dropdownColor: theme.colorScheme.surface,
      icon: const Icon(Icons.expand_more, size: 18),
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: theme.colorScheme.secondaryContainer,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: theme.colorScheme.onSurface),
        ),
      ),
      selectedItemBuilder: (_) => choices.entries
          .map(
            (entry) => Align(
              alignment: Alignment.centerLeft,
              child: choiceLabel(entry),
            ),
          )
          .toList(),
      items: choices.entries
          .map(
            (entry) => DropdownMenuItem<T>(
              value: entry.key,
              enabled: !disabled.contains(entry.key),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: choiceLabel(entry),
                  ),
                ),
              ),
            ),
          )
          .toList(),
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
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
          label: 'Категория',
          value: filter.category,
          choices: placeCategoryChoices,
          onChanged: (v) => onChanged(filter.copy(category: v)),
        ),
      PlaceSelect<AccessFilter>(
        label: 'С питомцем',
        value: filter.access,
        choices: {for (final v in AccessFilter.values) v: accessLabel(v)},
        onChanged: (v) => onChanged(filter.copy(access: v)),
      ),
      PlaceSelect<bool>(
        label: 'Подборка',
        value: filter.favoritesOnly,
        choices: const {false: 'Все места', true: 'Избранное'},
        onChanged: (v) => onChanged(filter.copy(favoritesOnly: v)),
      ),
      PlaceSelect<PlaceSort>(
        label: 'Сортировка',
        value: filter.sort,
        choices: const {
          PlaceSort.name: 'По названию',
          PlaceSort.nearby: 'Ближе ко мне',
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
