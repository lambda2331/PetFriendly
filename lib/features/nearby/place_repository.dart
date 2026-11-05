import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'pet_access.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class Place {
  const Place(
    this.id,
    this.name,
    this.category,
    this.distance,
    this.rating,
    this.reviewCount,
    this.description,
    this.petAccess,
    this.icon, {
    this.latitude,
    this.longitude,
    this.sourceId,
    this.city = 'Минск',
    this.pending = false,
    this.accessEvidence,
  });
  final String id, name, category, distance, description, petAccess;
  final double? rating;
  final double? latitude, longitude;
  final String? sourceId;
  final int reviewCount;
  final String city;
  final bool pending;
  final IconData icon;
  final PetAccessEvidence? accessEvidence;
}

abstract class PlaceRepository {
  List<Place> all();
  Place byId(String id);
}

class DemoPlaceRepository implements PlaceRepository {
  static const places = [
    Place(
      'park',
      'Зелёный парк',
      'Парк',
      '600 м',
      4.8,
      24,
      'Тихие дорожки, много тени и место для долгой прогулки. Встречаемся у главного входа.',
      'Допуск питомцев не уточнён',
      Icons.park_outlined,
      latitude: 53.9104,
      longitude: 27.5542,
    ),
    Place(
      'cafe',
      'Кофе & лапы',
      'Кафе',
      '900 м',
      4.9,
      18,
      'Небольшое кафе с уютным двориком и мисками с водой. Хорошее место, чтобы познакомиться после прогулки.',
      'Можно с собаками · демо',
      Icons.local_cafe_outlined,
      latitude: 53.9068,
      longitude: 27.5625,
    ),
    Place(
      'play',
      'Площадка у дома',
      'Площадка',
      '1,2 км',
      4.6,
      9,
      'Огороженная площадка для игр. Подойдёт для знакомства активных собак.',
      'Для собак · демо',
      Icons.pets_outlined,
      latitude: 53.9021,
      longitude: 27.5491,
    ),
  ];
  @override
  List<Place> all() => places;
  @override
  Place byId(String id) => places.firstWhere((p) => p.id == id);
}

final placesProvider = Provider<PlaceRepository>(
  (ref) => DemoPlaceRepository(),
);

class OsmPlaceRepository implements PlaceRepository {
  OsmPlaceRepository(this.places);
  final List<Place> places;
  static Future<OsmPlaceRepository> load() async {
    final raw =
        jsonDecode(await rootBundle.loadString('assets/data/minsk_places.json'))
            as Map<String, dynamic>;
    final records = (raw['places'] as List).cast<Map<String, dynamic>>();
    final result = records
        .map(
          (p) => Place(
            p['id'],
            p['name'],
            p['category'],
            'Минск',
            null,
            0,
            'Правила посещения могут измениться. Уточните допуск животных перед визитом.',
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
            sourceId: p['source_id'] as String,
          ),
        )
        .toList();
    result.sort((a, b) {
      int rank(Place p) => switch (p.category) {
        'Площадка' => 0,
        'Парк' => 1,
        'Кафе' => 2,
        _ => 3,
      };
      final diff = rank(a) - rank(b);
      return diff != 0 ? diff : a.name.compareTo(b.name);
    });
    return OsmPlaceRepository(result);
  }

  @override
  List<Place> all() => places;
  @override
  Place byId(String id) => places.firstWhere((p) => p.id == id);
}
