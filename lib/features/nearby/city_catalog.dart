import '../../l10n/localization.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/backend/backend.dart';
import '../../core/storage/prototype_store.dart';
import 'location_service.dart';
import 'place_repository.dart';
import 'pet_access.dart';

bool automaticPlace(String category) =>
    ['Парк', 'Площадка', 'Зоомагазин', 'Ветклиника'].contains(category);

Place catalogPlace(Map<String, dynamic> p, String city) => Place(
  p['id'],
  p['name'],
  p['category'],
  city,
  null,
  0,
  'Уточните правила посещения перед прогулкой.',
  switch (p['pet_access']) {
    'yes' => 'Собаки разрешены · отметка OSM',
    'leashed' => 'Собаки на поводке · отметка OSM',
    'no' => 'Собаки запрещены · отметка OSM',
    _ => 'Допуск питомцев не уточнён',
  },
  switch (p['category']) {
    'Парк' => Icons.park_outlined,
    'Площадка' => Icons.pets_outlined,
    'Зоомагазин' => Icons.storefront_outlined,
    'Ветклиника' => Icons.local_hospital_outlined,
    'Ресторан' => Icons.restaurant_outlined,
    _ => Icons.local_cafe_outlined,
  },
  latitude: (p['latitude'] as num).toDouble(),
  longitude: (p['longitude'] as num).toDouble(),
  sourceId: p['source_id'],
  city: city,
  accessEvidence: p['pet_access_evidence'] is Map
      ? PetAccessEvidence.fromJson(
          Map<String, dynamic>.from(p['pet_access_evidence']),
        )
      : null,
);

List<Place> parseCityOsm(Map<String, dynamic> raw, String city) {
  if (raw['remark'] != null) throw StateError('Incomplete OSM response');
  final result = <String, Place>{};
  for (final item in (raw['elements'] as List).cast<Map<String, dynamic>>()) {
    final tags = Map<String, dynamic>.from(item['tags'] ?? {});
    final category = switch (tags['leisure']) {
      'park' => 'Парк',
      'dog_park' => 'Площадка',
      _ =>
        tags['amenity'] == 'veterinary'
            ? 'Ветклиника'
            : tags['shop'] == 'pet'
            ? 'Зоомагазин'
            : null,
    };
    if (category == null ||
        !['node', 'way', 'relation'].contains(item['type'])) {
      continue;
    }
    final name = tags['name:ru'] ?? tags['name'] ?? tags['name:be'];
    final point = item['lat'] != null ? item : item['center'];
    if (name is! String || name.trim().isEmpty || point == null) continue;
    final lat = point['lat'], lon = point['lon'];
    if (lat is! num ||
        lon is! num ||
        !lat.isFinite ||
        !lon.isFinite ||
        lat.abs() > 90 ||
        lon.abs() > 180) {
      continue;
    }
    final sourceId = '${item['type']}/${item['id']}';
    result[sourceId] = catalogPlace({
      'id': const Uuid().v5(
        Namespace.url.value,
        'https://www.openstreetmap.org/$sourceId',
      ),
      'name': name.trim(),
      'category': category,
      'latitude': lat,
      'longitude': lon,
      'source_id': sourceId,
      'pet_access': tags['dog'],
    }, city);
  }
  return result.values.toList();
}

class CityCatalogService {
  CityCatalogService(this.location);
  final LocationService location;
  final cached = <String, List<Place>>{};
  // Public city centres only. Never use lastPosition/GPS for catalog requests.
  Future<List<Place>> load(String city) async {
    if (cached.containsKey(city)) return cached[city]!;
    final center = await location.cityCenter(city);
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final request = await client.postUrl(
        Uri.parse('https://overpass-api.de/api/interpreter'),
      );
      request.headers.set(
        HttpHeaders.userAgentHeader,
        'PetFriendly-prototype/0.3 (pet places catalog)',
      );
      request.headers.contentType = ContentType(
        'application',
        'x-www-form-urlencoded',
      );
      final query =
          '[out:json][timeout:25];(nwr["leisure"~"^(park|dog_park)\$"](around:15000,${center.latitude},${center.longitude});nwr["shop"="pet"](around:15000,${center.latitude},${center.longitude});nwr["amenity"="veterinary"](around:15000,${center.latitude},${center.longitude}););out center meta;';
      final body = utf8.encode('data=${Uri.encodeQueryComponent(query)}');
      request.contentLength = body.length;
      request.add(body);
      final response = await request.close().timeout(
        const Duration(seconds: 35),
      );
      if (response.statusCode != 200) {
        throw StateError('Catalog unavailable (${response.statusCode})');
      }
      final bytes = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 10))) {
        bytes.addAll(chunk);
        if (bytes.length > 8000000) throw StateError('Catalog too large');
      }
      return cached[city] = parseCityOsm(
        jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
        city,
      );
    } finally {
      client.close(force: true);
    }
  }
}

final cityCatalogServiceProvider = Provider(
  (ref) => CityCatalogService(ref.read(locationServiceProvider)),
);

final catalogReadyProvider = FutureProvider.family<void, String>((
  ref,
  city,
) async {
  ref.watch(authStateProvider);
  final client = ref.watch(backendProvider);
  if (client == null) return;
  try {
    final response = await client.functions.invoke(
      'city-catalog',
      body: {'city': city},
    );
    if (response.data is Map && response.data['status'] == 'ready') return;
    if (response.status != 202) {
      throw StateError('Catalog loading is temporarily unavailable');
    }
  } on FunctionException catch (error) {
    // Authorization failures must never fall back to another access path.
    if (error.status < 500) rethrow;
  }
  // Existing published places remain available while an import is busy or
  // temporarily unavailable. This RPC independently checks the active session.
  final existing = await client.rpc('search_places', params: {'city_in': city});
  if ((existing['total'] as num) == 0) {
    throw StateError('Catalog loading is temporarily unavailable');
  }
});

final cityCatalogProvider = FutureProvider.family<List<Place>, String>((
  ref,
  city,
) async {
  final client = ref.watch(backendProvider);
  ref.watch(authStateProvider);
  if (client == null) {
    final bundled = ref
        .watch(placesProvider)
        .all()
        .where((p) => p.city == city && automaticPlace(p.category))
        .toList();
    if (bundled.isNotEmpty || city == 'Минск') return bundled;
    return ref.read(cityCatalogServiceProvider).load(city);
  }
  // Read pages from the shared catalog; the server imports once per city/cache period.
  await ref.watch(catalogReadyProvider(city).future);
  final records = <Place>[];
  for (var offset = 0; ; offset += 40) {
    final page = await client.rpc(
      'search_places',
      params: {'city_in': city, 'offset_in': offset},
    );
    final items = page['items'] as List;
    records.addAll(
      items.map((p) => catalogPlace(Map<String, dynamic>.from(p), city)),
    );
    if (items.isEmpty || offset + items.length >= (page['total'] as num)) break;
  }
  return records;
});
final selectedCityCatalogProvider = Provider<AsyncValue<List<Place>>>(
  (ref) => ref.watch(
    cityCatalogProvider(ref.watch(prototypeProvider.select((s) => s.city))),
  ),
);

final favoriteCatalogProvider = FutureProvider<List<Place>>((ref) async {
  final favorites = ref.watch(prototypeProvider.select((s) => s.favorites));
  final client = ref.watch(backendProvider);
  ref.watch(selectedCityCatalogProvider);
  if (client == null) {
    return [
      ...ref
          .watch(placesProvider)
          .all()
          .where((p) => automaticPlace(p.category)),
      ...ref.read(cityCatalogServiceProvider).cached.values.expand((p) => p),
    ].where((p) => favorites.contains(p.id)).toList();
  }
  if (favorites.isEmpty) return [];
  final records = await client
      .from('places')
      .select()
      .inFilter('id', favorites.toList())
      .eq('published', true);
  return records.map((p) => catalogPlace(p, p['city'])).toList();
});

class CatalogRefreshController extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  Future<void> retry(String city) async {
    if (state.contains(city)) return;
    state = {...state, city};
    try {
      ref.invalidate(catalogReadyProvider(city));
      ref.invalidate(cityCatalogProvider(city));
      await ref.read(cityCatalogProvider(city).future);
    } catch (_) {
      // The city-scoped provider exposes the failure to its inline state.
    } finally {
      if (ref.mounted) state = {...state}..remove(city);
    }
  }
}

final catalogRefreshProvider =
    NotifierProvider<CatalogRefreshController, Set<String>>(
      CatalogRefreshController.new,
    );

class CityCatalogStatus extends ConsumerWidget {
  const CityCatalogStatus({
    this.inset = true,
    this.linearLoading = false,
    super.key,
  });
  final bool inset, linearLoading;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(selectedCityCatalogProvider);
    final city = ref.watch(prototypeProvider.select((s) => s.city));
    final pending = ref.watch(catalogRefreshProvider).contains(city);
    final colors = Theme.of(context).colorScheme;
    if (!state.isLoading && !state.hasError) {
      if (state.hasValue && state.value!.isEmpty) {
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: inset ? 24 : 0,
            vertical: 8,
          ),
          child: Text(
            'В каталоге этого города пока нет мест.'.tr(context),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        );
      }
      return const SizedBox.shrink();
    }
    final title = state.isLoading
        ? 'Загружаем места города…'.tr(context)
        : (state.hasValue && state.value!.isNotEmpty
                  ? 'Не удалось обновить места.'
                  : 'Не удалось загрузить места.')
              .tr(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: inset ? 24 : 0, vertical: 8),
      child: Semantics(
        liveRegion: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: state.isLoading
                      ? linearLoading
                            ? const SizedBox.shrink()
                            : const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                      : Icon(
                          Icons.cloud_off_outlined,
                          size: 20,
                          color: colors.error,
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            if (state.isLoading && linearLoading) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(semanticsLabel: title),
            ],
            if (!state.isLoading) ...[
              const SizedBox(height: 6),
              Text(
                (state.hasValue && state.value!.isNotEmpty
                        ? 'Показаны ранее загруженные места.'
                        : 'Попробуйте загрузить места ещё раз.')
                    .tr(context),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  key: const Key('catalog-retry'),
                  onPressed: pending
                      ? null
                      : () => ref
                            .read(catalogRefreshProvider.notifier)
                            .retry(city),
                  child: Text('Повторить загрузку'.tr(context)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
