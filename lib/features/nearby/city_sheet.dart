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
  });
  final String city;
  final ValueChanged<String> onSelected;
  final VoidCallback onLocate;
  @override
  State<CitySheet> createState() => CitySheetState();
}

class CitySheetState extends State<CitySheet> {
  final input = TextEditingController();
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
    final suggestions = suggestCities(query)
        .where((city) => query.isNotEmpty || city.name != current)
        .take(query.isEmpty ? 3 : 6)
        .toList();
    final custom = query.isNotEmpty && knownCity(query) == null;
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
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const StudioSheetHeader(title: 'Выберите город'),
                const SizedBox(height: 16),
                TextField(
                  textAlignVertical: TextAlignVertical.top,
                  key: const Key('city-input'),
                  controller: input,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => setState(() {}),
                  onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  decoration: InputDecoration(
                    labelText: 'Найти город',
                    counterText: '',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: input.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Очистить поиск',
                            onPressed: () => setState(input.clear),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                if (query.isEmpty) ...[
                  _cityRow(
                    context,
                    current,
                    country: knownCity(current)?.country,
                    selected: true,
                    key: const Key('city-current'),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Другие города',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                ],
                for (final city in suggestions)
                  _cityRow(
                    context,
                    city.name,
                    country: city.country,
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
                    title: Text('Выбрать «${canonicalCity(query)}»'),
                    subtitle: const Text('Другой город'),
                    onTap: () => choose(query),
                  ),
                ],
                const Divider(height: 28),
                OutlinedButton.icon(
                  key: const Key('city-nearby'),
                  onPressed: widget.onLocate,
                  icon: const Icon(Icons.my_location_outlined),
                  label: const Text('Рядом со мной'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
    title: Text(name),
    subtitle: country?.trim().isNotEmpty == true || selected
        ? MetadataLine(items: [?country, if (selected) 'Выбран сейчас'])
        : null,
    trailing: selected ? const Icon(Icons.check) : null,
    onTap: () => choose(name),
  );
}
