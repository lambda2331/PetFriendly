import '../../nearby/city_field.dart';
import '../../nearby/city_catalog.dart';
import '../../../core/ui/studio_review.dart';
import '../../../l10n/localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../nearby/add_place_screen.dart';
import '../../nearby/live_map.dart';
import '../../nearby/place_repository.dart';
import '../data/event_location.dart';

typedef EventPointPicker =
    Future<(double, double)?> Function(
      BuildContext context,
      String city,
      EventLocation? initial,
    );

final eventPointPickerProvider = Provider<EventPointPicker>(
  (ref) =>
      (context, city, initial) => Navigator.of(context).push<(double, double)>(
        MaterialPageRoute(
          builder: (_) => PlacePositionPicker(
            city: city,
            initialPoint: initial == null
                ? null
                : (initial.latitude, initial.longitude),
            title: "Место встречи".tr(context),
            instructions:
                "Переместите карту и выберите точку сбора в публичном месте."
                    .tr(context),
          ),
        ),
      ),
);

class EventLocationMapScreen extends StatelessWidget {
  const EventLocationMapScreen({
    required this.location,
    required this.city,
    super.key,
  });
  final EventLocation location;
  final String city;
  @override
  Widget build(BuildContext context) {
    final point = Place(
      'meeting-point',
      location.displayLabel,
      "Место встречи".tr(context),
      city,
      null,
      0,
      '',
      '',
      Icons.groups_outlined,
      latitude: location.latitude,
      longitude: location.longitude,
      city: city,
    );
    return Scaffold(
      appBar: AppBar(title: Text("Место встречи".tr(context))),
      body: Stack(
        children: [
          Positioned.fill(
            child: LiveMap(
              places: [point],
              focusPlace: point,
              fullscreen: true,
              onPlace: (_) {},
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 84,
            child: SafeArea(
              top: false,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.displayLabel,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(city, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EventVenueSelection {
  const EventVenueSelection(this.city, this.location);
  final String city;
  final EventLocation? location;
}

/// The venue search area owns its city; it never changes Nearby's manual city.
class EventVenuePicker extends ConsumerStatefulWidget {
  const EventVenuePicker({required this.city, this.initial, super.key});
  final String city;
  final EventLocation? initial;
  @override
  ConsumerState<EventVenuePicker> createState() => _EventVenuePickerState();
}

class _EventVenuePickerState extends ConsumerState<EventVenuePicker> {
  late final city = TextEditingController(text: widget.city);
  final search = TextEditingController();
  EventLocation? selected;
  @override
  void initState() {
    super.initState();
    selected = widget.initial;
  }

  @override
  void dispose() {
    city.dispose();
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(cityCatalogProvider(city.text));
    final places = (catalog.value ?? <Place>[])
        .where(
          (p) =>
              !p.pending &&
              p.latitude != null &&
              p.longitude != null &&
              p.name.toLowerCase().contains(search.text.trim().toLowerCase()),
        )
        .toList();
    void finish(EventLocation? point) =>
        Navigator.pop(context, EventVenueSelection(city.text, point));
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Место встречи'.tr(context)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              children: [
                CityField(
                  controller: city,
                  onChanged: (_) => setState(() => selected = null),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Парк или публичное место'.tr(context),
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    final point = await ref.read(eventPointPickerProvider)(
                      context,
                      city.text,
                      selected,
                    );
                    if (point != null && mounted) {
                      setState(
                        () => selected = EventLocation(point.$1, point.$2),
                      );
                    }
                  },
                  icon: const Icon(Icons.map_outlined),
                  label: Text('Выбрать место на карте'.tr(context)),
                ),
                if (catalog.isLoading)
                  StudioReviewState(
                    title: 'Загружаем…'.tr(context),
                    loading: true,
                  ),
                if (catalog.hasError)
                  StudioReviewState(
                    title: 'Не удалось загрузить'.tr(context),
                    action: OutlinedButton(
                      onPressed: () =>
                          ref.invalidate(cityCatalogProvider(city.text)),
                      child: Text('Повторить'.tr(context)),
                    ),
                  ),
                if (!catalog.isLoading && !catalog.hasError && places.isEmpty)
                  StudioReviewState(title: 'Ничего не найдено'.tr(context)),
                for (final p in places)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    leading: Icon(p.icon),
                    title: Text(p.name),
                    subtitle: Text(p.category),
                    selected:
                        selected?.latitude == p.latitude &&
                        selected?.longitude == p.longitude,
                    trailing: Icon(
                      selected?.latitude == p.latitude &&
                              selected?.longitude == p.longitude
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                    ),
                    onTap: () => setState(
                      () => selected = EventLocation(
                        p.latitude!,
                        p.longitude!,
                        label: p.name,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: selected == null ? null : () => finish(selected),
                    child: Text('Выбрать место'.tr(context)),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => finish(null),
                    child: Text('Без места'.tr(context)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
