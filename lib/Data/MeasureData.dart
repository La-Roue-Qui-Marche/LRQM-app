import 'DataManagement.dart';
import 'dart:convert'; // Add for JSON encoding/decoding
import '../Utils/LogHelper.dart'; // Import LogHelper

/// Class to manage measure-related data.
class MeasureData {
  /// Singleton instance of the DataManagement class.
  static final DataManagement _dataManagement = DataManagement();

  /// Save the measure ID in the shared preferences.
  static Future<bool> saveMeasureId(String measureId) async {
    return _dataManagement.saveString('measure_id', measureId);
  }

  /// Retrieve the measure ID from the shared preferences.
  static Future<String?> getMeasureId() async {
    return _dataManagement.getString('measure_id');
  }

  /// Save a point (distance, speed, accuracy, timestamp, lat, lng, duration) for the current measure.
  static Future<void> addMeasurePoint({
    required double distance,
    required double speed,
    required double acc,
    required DateTime timestamp,
    required double lat,
    required double lng,
    required int duration,
  }) async {
    final String key = 'measure_points';
    List<Map<String, dynamic>> points = await getMeasurePoints();

    // Create the point data
    Map<String, dynamic> pointData = {
      'distance': distance,
      'speed': speed,
      'accuracy': acc,
      'timestamp': timestamp.toIso8601String(),
      'lat': lat,
      'lng': lng,
      'duration': duration,
    };

    // Log the point details
    LogHelper.logInfo("[MEASURE] Added point: distance=${distance.toStringAsFixed(2)}m, " +
        "speed=${speed.toStringAsFixed(2)}m/s, " +
        "accuracy=${acc.toStringAsFixed(2)}m, " +
        "lat=${lat.toStringAsFixed(6)}, " +
        "lng=${lng.toStringAsFixed(6)}, " +
        "duration=${duration}s, " +
        "timestamp=${timestamp.toString()}");

    points.add(pointData);
    await _dataManagement.saveString(key, jsonEncode(points));
  }

  /// Retrieve all points for the current measure.
  static Future<List<Map<String, dynamic>>> getMeasurePoints() async {
    const String key = 'measure_points';
    String? jsonStr = await _dataManagement.getString(key);
    if (jsonStr == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> clearMeasurePoints() async {
    return _dataManagement.removeData('measure_points');
  }

  /// Clear the measure ID and points from the shared preferences.
  static Future<bool> clearMeasureId() async {
    final bool idCleared = await _dataManagement.removeData('measure_id');
    return idCleared;
  }

  static Future<bool> clearMeasureData() async {
    final bool pointsCleared = await clearMeasurePoints();
    final bool idCleared = await clearMeasureId();
    return pointsCleared && idCleared;
  }

  /// Check if a measure is ongoing by checking if the measure ID exists and is not empty.
  static Future<bool> isMeasureOngoing() async {
    String? measureId = await getMeasureId();
    return measureId != null && measureId.isNotEmpty; // Ensure measureId is not null or empty
  }
}
