import 'dart:math' as math;

/// Great-circle distance helpers used for "near me" discovery.
class Geo {
  Geo._();

  static const double _earthRadiusKm = 6371.0;

  /// Haversine distance between two coordinates, in kilometres.
  static double distanceKm(double lat1, double lng1, double lat2, double lng2) {
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = math.pow(math.sin(dLat / 2), 2) + math.cos(_rad(lat1)) * math.cos(_rad(lat2)) * math.pow(math.sin(dLng / 2), 2);
    return 2 * _earthRadiusKm * math.asin(math.sqrt(a));
  }

  static double _rad(double deg) => deg * math.pi / 180;

  static String format(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    if (km < 10) return '${km.toStringAsFixed(1)} km';
    return '${km.round()} km';
  }
}
