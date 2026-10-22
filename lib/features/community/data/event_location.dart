/// A deliberately selected public meeting point, never a device position.
class EventLocation {
  const EventLocation(this.latitude, this.longitude, {this.label = ''});
  final double latitude, longitude;
  final String label;

  bool get valid =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
  String get displayLabel =>
      label.trim().isEmpty ? 'Место встречи' : label.trim();

  static EventLocation? fromRow(Map<String, dynamic> row) {
    final lat = row['latitude'], lng = row['longitude'];
    if (lat is! num || lng is! num) return null;
    final location = EventLocation(
      lat.toDouble(),
      lng.toDouble(),
      label: row['location_label'] as String? ?? '',
    );
    return location.valid ? location : null;
  }
}
