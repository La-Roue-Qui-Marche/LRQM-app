import 'dart:math';

class LowPassLocationFilter {
  double? _lastLat;
  double? _lastLng;
  double? _lastTimestamp;

  final double minAlpha; // très lissé (ex: 0.05)
  final double maxAlpha; // plus réactif (ex: 0.9)
  final double jumpThresholdMeters; // au-delà de cette distance, on considère que c’est un "gros changement"

  LowPassLocationFilter({
    this.minAlpha = 0.05,
    this.maxAlpha = 0.3,
    this.jumpThresholdMeters = 5.0,
  });

  Map<String, double> filter({
    required double latitude,
    required double longitude,
    required double timestamp,
  }) {
    if (_lastLat == null || _lastLng == null) {
      _lastLat = latitude;
      _lastLng = longitude;
      _lastTimestamp = timestamp;
      return {
        'latitude': latitude,
        'longitude': longitude,
        'delta': 0.0,
      };
    }

    final rawDelta = _haversineDistance(_lastLat!, _lastLng!, latitude, longitude);

    // Définir alpha dynamiquement : plus delta est grand, plus alpha augmente
    double adaptiveAlpha = minAlpha + (maxAlpha - minAlpha) * (rawDelta / jumpThresholdMeters).clamp(0.0, 1.0);

    final filteredLat = adaptiveAlpha * latitude + (1 - adaptiveAlpha) * _lastLat!;
    final filteredLng = adaptiveAlpha * longitude + (1 - adaptiveAlpha) * _lastLng!;

    final delta = _haversineDistance(_lastLat!, _lastLng!, filteredLat, filteredLng);

    _lastLat = filteredLat;
    _lastLng = filteredLng;
    _lastTimestamp = timestamp;

    return {
      'latitude': filteredLat,
      'longitude': filteredLng,
      'delta': delta,
    };
  }

  double _haversineDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000; // rayon terrestre en mètres
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) + cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);
}
