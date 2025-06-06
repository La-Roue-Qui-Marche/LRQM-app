import 'package:lrqm/data/measure_data.dart';
import 'package:lrqm/utils/log_helper.dart';

Future<void> saveMeasurementData({
  required double distance,
  required double speed,
  required double acc,
  required DateTime timestamp,
  required double lat,
  required double lng,
  required int duration,
}) async {
  LogHelper.staticLogInfo('''[MEASURE] Saving measurement:
    Distance: ${distance.toStringAsFixed(1)} m
    Speed: ${speed.toStringAsFixed(1)} m/s
    Accuracy: ${acc.toStringAsFixed(1)} m
    Time: ${timestamp.toIso8601String()}
    Position: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}
    Duration: $duration s''');

  await MeasureData.addMeasurePoint(
    distance: distance,
    speed: speed,
    acc: acc,
    timestamp: timestamp,
    lat: lat,
    lng: lng,
    duration: duration,
  );
}
