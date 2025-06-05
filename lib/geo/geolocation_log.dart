import 'package:geolocator/geolocator.dart' as geo;

String formatPositionComparison({
  required int elapsedTime,
  required Map<String, double> filteredPosition,
  required double lat,
  required double lng,
  required double rawSpeed,
  required double rawAccuracy,
  required int dist,
  required int rawDist,
  required DateTime timestamp,
  required double uncertainty,
  required double confidence,
}) {
  final latDelta = (filteredPosition['latitude']! - lat).abs();
  final lngDelta = (filteredPosition['longitude']! - lng).abs();
  final speedDelta = (filteredPosition['speed']! - rawSpeed).abs();

  String logOutput = '''[GEO] Position update:
    Time: $elapsedTime s
    GPS Accuracy: ${rawAccuracy.toStringAsFixed(1)}m
    Speed: ${filteredPosition['speed']!.toStringAsFixed(1)} m/s (raw: ${rawSpeed.toStringAsFixed(1)}, Δ: ${speedDelta.toStringAsFixed(2)})
    Distance: $dist m (raw: $rawDist) m}
    Timestamp: ${timestamp.toIso8601String()}
    lat: ${filteredPosition['latitude']!.toStringAsFixed(6)} (raw: ${lat.toStringAsFixed(6)}, Δ: ${latDelta.toStringAsFixed(6)})
    lon: ${filteredPosition['longitude']!.toStringAsFixed(6)} (raw: ${lng.toStringAsFixed(6)}, Δ: ${lngDelta.toStringAsFixed(6)})
    uncertainty: ${uncertainty.toStringAsFixed(2)}
    confidence: ${confidence.toStringAsFixed(2)}''';

  return logOutput;
}

Map<String, dynamic> computePositionDeltas({
  required double prevLat,
  required double prevLng,
  required DateTime prevTimestamp,
  required double currLat,
  required double currLng,
  required DateTime currTimestamp,
  required Map<String, double> filteredPosition,
}) {
  final dist =
      geo.Geolocator.distanceBetween(prevLat, prevLng, filteredPosition['latitude']!, filteredPosition['longitude']!)
          .round();

  final rawDist = geo.Geolocator.distanceBetween(prevLat, prevLng, currLat, currLng).round();
  final timeDiffSec = currTimestamp.difference(prevTimestamp).inMilliseconds / 1000;
  double rawSpeed = 0.0;
  if (timeDiffSec > 0.5) {
    rawSpeed = geo.Geolocator.distanceBetween(prevLat, prevLng, currLat, currLng) / timeDiffSec;
  }
  return {
    'dist': dist,
    'rawDist': rawDist,
    'rawSpeed': rawSpeed,
    'timeDiffSec': timeDiffSec,
  };
}
