import 'package:geocoding/geocoding.dart';
import 'city_search.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

class LocationService extends ChangeNotifier {
  Position? _lastPosition;
  Position? get lastPosition => _lastPosition;
  set lastPosition(Position? value) {
    if (_lastPosition == value) return;
    _lastPosition = value;
    // A city lookup and a mounted map share fixes immediately, even while
    // reverse geocoding is pending. Coordinates remain in memory only.
    notifyListeners();
  }

  Future<bool> hasPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) return false;
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  final _centers = <String, Future<({double latitude, double longitude})>>{};

  Future<Position> currentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
  }) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      lastPosition = null;
      throw const LocationIssue(
        'Геолокация выключена. Выберите город вручную.',
      );
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      lastPosition = null;
      throw const LocationIssue(
        'Доступ к геолокации не разрешён. Город можно выбрать вручную.',
      );
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        timeLimit: Duration(seconds: 8),
      ),
    );
    lastPosition = position;
    return position;
  }

  Stream<Position> positions() => Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    ),
  );

  Future<({double latitude, double longitude})> cityCenter(String city) {
    return _centers.putIfAbsent(
      city,
      () => _resolveCity(city).catchError((Object e) {
        _centers.remove(city);
        throw e;
      }),
    );
  }

  Future<({double latitude, double longitude})> _resolveCity(
    String city,
  ) async {
    final known = knownCity(city);
    if (known?.latitude != null && known?.longitude != null) {
      return (latitude: known!.latitude!, longitude: known.longitude!);
    }
    final locations = await locationFromAddress(
      cityGeocodingQuery(city),
    ).timeout(const Duration(seconds: 8));
    if (locations.isEmpty) {
      throw const LocationIssue('Не удалось найти выбранный город.');
    }
    return (
      latitude: locations.first.latitude,
      longitude: locations.first.longitude,
    );
  }

  Future<String> nearbyCity() async {
    final position = await currentPosition(accuracy: LocationAccuracy.low);
    final places = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    ).timeout(const Duration(seconds: 8));
    final city = places.isNotEmpty ? places.first.locality : null;
    if (city == null || city.isEmpty) {
      throw const LocationIssue(
        'Не удалось определить город. Выберите его вручную.',
      );
    }
    final place = places.first;
    return detectedCity(
      city,
      place.isoCountryCode,
      position.latitude,
      position.longitude,
      region: place.administrativeArea,
    );
  }
}

class LocationIssue implements Exception {
  const LocationIssue(this.message);
  final String message;
}

final locationServiceProvider = Provider((ref) {
  final service = LocationService();
  ref.onDispose(service.dispose);
  return service;
});

final cityCenterProvider =
    FutureProvider.family<({double latitude, double longitude}), String>(
      (ref, city) => ref.read(locationServiceProvider).cityCenter(city),
    );
