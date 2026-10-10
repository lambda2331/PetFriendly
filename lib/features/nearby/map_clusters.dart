import 'dart:math' as math;
import 'place_repository.dart';

class MapCluster {
  MapCluster(this.places);
  final List<Place> places;
  double get latitude =>
      places.fold(0.0, (n, p) => n + p.latitude!) / places.length;
  double get longitude =>
      places.fold(0.0, (n, p) => n + p.longitude!) / places.length;
}

// Group in Web Mercator screen units so clusters split when zooming in.
List<MapCluster> clusterPlaces(List<Place> places, double zoom) {
  final cells = <(int, int), List<Place>>{};
  final scale = 512 * math.pow(2, zoom);
  for (final place in places) {
    if (place.latitude == null || place.longitude == null) continue;
    final latitude = place.latitude!.clamp(-85.0511, 85.0511) * math.pi / 180;
    final x = (place.longitude! + 180) / 360 * scale;
    final y =
        (1 - math.log(math.tan(latitude) + 1 / math.cos(latitude)) / math.pi) /
        2 *
        scale;
    final key = ((x / 56).floor(), (y / 56).floor());
    (cells[key] ??= []).add(place);
  }
  return cells.values.map(MapCluster.new).toList();
}
