import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/backend/backend.dart';
import 'place_repository.dart';

class PlaceContributions extends AsyncNotifier<List<Place>> {
  @override
  Future<List<Place>> build() async {
    final client = ref.watch(backendProvider);
    if (client == null) return [];
    final own = await client
        .from('place_submissions')
        .select()
        .eq('status', 'pending')
        .limit(1000);
    final published = await client
        .from('places')
        .select()
        .eq('source', 'community')
        .eq('published', true)
        .limit(1000);
    return [
      ...own.map((p) => contributionPlace(p, pending: true)),
      ...published.map((p) => contributionPlace(p, pending: false)),
    ];
  }

  Future<void> submit({
    required String id,
    required String name,
    required String category,
    required String city,
    required String description,
    required double latitude,
    required double longitude,
  }) async {
    if (name.trim().isEmpty ||
        name.length > 120 ||
        city.trim().isEmpty ||
        city.length > 120 ||
        description.length > 1000 ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude.abs() > 90 ||
        longitude.abs() > 180 ||
        ![
          'Парк',
          'Кафе',
          'Ресторан',
          'Площадка',
          'Зоомагазин',
          'Ветклиника',
        ].contains(category)) {
      throw StateError('Invalid place');
    }
    final client = ref.read(backendProvider);
    if (client != null) {
      await client.rpc(
        'submit_place',
        params: {
          'client_id': id,
          'name_in': name.trim(),
          'category_in': category,
          'city_in': city.trim(),
          'description_in': description.trim(),
          'latitude_in': latitude,
          'longitude_in': longitude,
        },
      );
      state = AsyncData(await build());
    } else {
      if ((state.value ?? []).any((p) => p.id == id)) return;
      state = AsyncData([
        ...(state.value ?? []),
        contributionPlace({
          'id': id,
          'name': name.trim(),
          'category': category,
          'city': city.trim(),
          'description': description.trim(),
          'latitude': latitude,
          'longitude': longitude,
        }, pending: true),
      ]);
    }
  }
}

final placeContributionsProvider =
    AsyncNotifierProvider<PlaceContributions, List<Place>>(
      PlaceContributions.new,
    );
String newPlaceId() => const Uuid().v4();
Place contributionPlace(
  Map<String, dynamic> data, {
  required bool pending,
}) => Place(
  data['id'],
  data['name'],
  data['category'],
  data['city'],
  null,
  0,
  '${pending ? 'Предложено вами · ожидает проверки. ' : 'Место добавлено сообществом. '}\n${data['description'] ?? data['source_tags']?['description'] ?? ''}',
  'Допуск питомцев не уточнён',
  switch (data['category']) {
    'Парк' => Icons.park_outlined,
    'Площадка' => Icons.pets_outlined,
    'Зоомагазин' => Icons.storefront_outlined,
    'Ветклиника' => Icons.local_hospital_outlined,
    'Ресторан' => Icons.restaurant_outlined,
    _ => Icons.local_cafe_outlined,
  },
  latitude: (data['latitude'] as num).toDouble(),
  longitude: (data['longitude'] as num).toDouble(),
  sourceId: pending ? null : data['source_id'],
  city: data['city'],
  pending: pending,
);
