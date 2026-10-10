import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/backend/backend.dart';
import '../../core/storage/prototype_store.dart';
import 'city_catalog.dart';
import 'place_filters.dart';
import 'place_repository.dart';

class PlacePage {
  const PlacePage(this.items, this.total);
  final List<Place> items;
  final int total;
  bool get hasMore => items.length < total;
}

class PlacePages extends AsyncNotifier<PlacePage> {
  bool loadingMore = false;
  int generation = 0;
  late String city;
  late PlaceFilter filters;
  late Set<String> favorites;
  @override
  Future<PlacePage> build() async {
    final current = ++generation;
    ref.watch(authStateProvider);
    city = ref.watch(prototypeProvider.select((v) => v.city));
    filters = ref.watch(placeFiltersProvider);
    favorites = ref.watch(prototypeProvider.select((v) => v.favorites));
    // Debounce typing, and discard obsolete city/filter requests.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!ref.mounted || current != generation) return const PlacePage([], 0);
    await ref.watch(catalogReadyProvider(city).future);
    if (!ref.mounted || current != generation) return const PlacePage([], 0);
    return fetch(0);
  }

  Future<PlacePage> fetch(int offset) async {
    final requestedCity = city;
    final client = ref.read(backendProvider);
    if (client == null) return const PlacePage([], 0);
    final result = await client.rpc(
      'search_places',
      params: {
        'city_in': requestedCity,
        'query_in': filters.query.trim().substring(
          0,
          filters.query.trim().length.clamp(0, 120),
        ),
        'category_in': filters.category,
        'access_in': filters.access.name,
        'favorites_in': filters.favoritesOnly ? favorites.toList() : null,
        'offset_in': offset,
      },
    );
    return PlacePage([
      for (final raw in result['items'])
        catalogPlace(Map<String, dynamic>.from(raw), requestedCity),
    ], (result['total'] as num).toInt());
  }

  Future<void> nextPage() async {
    final previous = state.value;
    if (loadingMore || previous == null || !previous.hasMore) return;
    loadingMore = true;
    final current = generation;
    try {
      final next = await fetch(previous.items.length);
      if (ref.mounted && current == generation) {
        state = AsyncData(
          PlacePage([...previous.items, ...next.items], next.total),
        );
      }
    } catch (_) {
      // Preserve the loaded page; the footer offers an explicit retry.
    } finally {
      loadingMore = false;
    }
  }
}

final placePagesProvider = AsyncNotifierProvider<PlacePages, PlacePage>(
  PlacePages.new,
);
