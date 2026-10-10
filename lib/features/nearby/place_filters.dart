import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' as geo;
import '../../core/storage/prototype_store.dart';
import 'location_service.dart';
import 'place_repository.dart';
import 'place_contributions.dart';
import 'city_catalog.dart';
import 'pet_access.dart';

enum AccessFilter { all, taggedAllowed, unknown, forbidden }

enum PlaceSort { name, nearby }

class PlaceFilter {
  const PlaceFilter({
    this.query = '',
    this.category = 'Все',
    this.access = AccessFilter.all,
    this.favoritesOnly = false,
    this.sort = PlaceSort.name,
  });
  final String query, category;
  final AccessFilter access;
  final bool favoritesOnly;
  final PlaceSort sort;
  PlaceFilter copy({
    String? query,
    String? category,
    AccessFilter? access,
    bool? favoritesOnly,
    PlaceSort? sort,
  }) => PlaceFilter(
    query: query ?? this.query,
    category: category ?? this.category,
    access: access ?? this.access,
    favoritesOnly: favoritesOnly ?? this.favoritesOnly,
    sort: sort ?? this.sort,
  );
  bool get active =>
      query.isNotEmpty ||
      category != 'Все' ||
      access != AccessFilter.all ||
      favoritesOnly;
}

class PlaceFilters extends Notifier<PlaceFilter> {
  @override
  PlaceFilter build() => const PlaceFilter();
  void update(PlaceFilter filter) => state = filter;
  void reset() => state = const PlaceFilter();
}

final placeFiltersProvider = NotifierProvider<PlaceFilters, PlaceFilter>(
  PlaceFilters.new,
);

double? placeDistance(Place place, geo.Position? position) =>
    position == null || place.latitude == null || place.longitude == null
    ? null
    : geo.Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        place.latitude!,
        place.longitude!,
      );
List<Place> filterPlaces(
  List<Place> places,
  PlaceFilter filter,
  Set<String> favorites,
  geo.Position? position,
) {
  final query = filter.query.trim().toLowerCase().replaceAll('ё', 'е');
  final result = places.where((p) {
    if (filter.category != 'Все' && p.category != filter.category) return false;
    if (!('${p.name} ${p.category}'.toLowerCase().replaceAll(
      'ё',
      'е',
    )).contains(query)) {
      return false;
    }
    if (filter.favoritesOnly && !favorites.contains(p.id)) return false;
    return switch (filter.access) {
      AccessFilter.all => true,
      AccessFilter.taggedAllowed =>
        p.accessEvidence?.policy != PetAccessPolicy.forbidden &&
            [
              PetAccessPolicy.allowed,
              PetAccessPolicy.onLeash,
            ].contains(catalogPetPolicy(p.petAccess)),
      AccessFilter.unknown => p.accessEvidence == null,
      AccessFilter.forbidden =>
        p.accessEvidence == null &&
            catalogPetPolicy(p.petAccess) == PetAccessPolicy.forbidden,
    };
  }).toList();
  result.sort((a, b) {
    if (filter.sort == PlaceSort.nearby && position != null) {
      final diff = (placeDistance(a, position) ?? double.infinity).compareTo(
        placeDistance(b, position) ?? double.infinity,
      );
      if (diff != 0) return diff;
    }
    return a.name.compareTo(b.name);
  });
  return result;
}

List<Place> mergeCityPlaces(
  List<Place> catalog,
  List<Place> contributions,
  String city,
) {
  final byId = {for (final place in catalog) place.id: place};
  for (final place in contributions.where((p) => p.city == city)) {
    // The server catalog carries moderated evidence; never replace it with
    // the less detailed contribution preview.
    byId.putIfAbsent(place.id, () => place);
  }
  return byId.values.toList();
}

final filteredPlacesProvider = Provider<List<Place>>((ref) {
  final state = ref.watch(prototypeProvider);
  final places = mergeCityPlaces(
    ref.watch(selectedCityCatalogProvider).value ?? <Place>[],
    ref.watch(placeContributionsProvider).value ?? <Place>[],
    state.city,
  );
  return filterPlaces(
    places,
    ref.watch(placeFiltersProvider),
    state.favorites,
    ref.read(locationServiceProvider).lastPosition,
  );
});
