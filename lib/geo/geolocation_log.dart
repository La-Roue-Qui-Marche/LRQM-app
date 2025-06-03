String formatPositionComparison({
  required int elapsedTime,
  required Map<String, double> smoothedPosition,
  required double lat,
  required double lng,
  required double rawSpeed,
  required double rawAccuracy,
  required int dist,
  required int rawDist,
  required DateTime timestamp,
  required double uncertainty,
  required double confidence,
  bool? filtered,
  bool? transition,
}) {
  final latDelta = (smoothedPosition['latitude']! - lat).abs();
  final lngDelta = (smoothedPosition['longitude']! - lng).abs();
  final speedDelta = (smoothedPosition['speed']! - rawSpeed).abs();

  String stateIndicator = "";
  if (filtered == true) {
    stateIndicator = " [FILTERED]";
  } else if (transition == true) {
    stateIndicator = " [TRANSITION]";
  }

  String logOutput = '''[GEO] Position update:$stateIndicator
    Time: $elapsedTime s
    GPS Accuracy: ${rawAccuracy.toStringAsFixed(1)}m
    Speed: ${smoothedPosition['speed']!.toStringAsFixed(1)} m/s (raw: ${rawSpeed.toStringAsFixed(1)}, Δ: ${speedDelta.toStringAsFixed(2)})
    Distance: $dist m (raw: $rawDist)${(filtered == true || transition == true) ? " [NOT ACCUMULATED]" : ""}
    Timestamp: ${timestamp.toIso8601String()}
    lat: ${smoothedPosition['latitude']!.toStringAsFixed(6)} (raw: ${lat.toStringAsFixed(6)}, Δ: ${latDelta.toStringAsFixed(6)})
    lon: ${smoothedPosition['longitude']!.toStringAsFixed(6)} (raw: ${lng.toStringAsFixed(6)}, Δ: ${lngDelta.toStringAsFixed(6)})
    uncertainty: ${uncertainty.toStringAsFixed(2)}
    confidence: ${confidence.toStringAsFixed(2)}''';

  return logOutput;
}
