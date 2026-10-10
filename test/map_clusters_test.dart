import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:petfriendly/features/nearby/map_clusters.dart';
import 'package:petfriendly/features/nearby/place_repository.dart';

void main() {
  test(
    'Clustering preserves every place and separates distant places when zooming',
    () {
      final places = List.generate(
        20,
        (i) => Place(
          '$i',
          'Place $i',
          'Парк',
          '',
          null,
          0,
          '',
          '',
          Icons.park,
          latitude: 53.9 + i * .002,
          longitude: 27.56 + i * .003,
        ),
      );
      final overview = clusterPlaces(places, 10);
      final detail = clusterPlaces(places, 17);
      expect(overview.length, lessThan(detail.length));
      for (final groups in [overview, detail]) {
        expect(
          groups.expand((g) => g.places).map((p) => p.id).toSet(),
          places.map((p) => p.id).toSet(),
        );
        expect(groups.fold(0, (n, g) => n + g.places.length), places.length);
      }
      expect(detail.length, places.length);
    },
  );
}
