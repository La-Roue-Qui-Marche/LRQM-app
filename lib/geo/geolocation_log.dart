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
