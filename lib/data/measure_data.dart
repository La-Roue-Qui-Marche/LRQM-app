// ignore_for_file: prefer_const_declarations

import 'dart:convert';
import 'package:lrqm/data/management_data.dart';
import 'package:lrqm/utils/log_helper.dart';

/// Class to manage measure-related data.
class MeasureData {
  static final ManagementData _managementData = ManagementData();

  /// Save the measure ID in the shared preferences.
  static Future<bool> saveMeasureId(String measureId) async {
    return _managementData.saveString('measure_id', measureId);
  }

  /// Retrieve the measure ID from the shared preferences.
  static Future<String?> getMeasureId() async {
    return _managementData.getString('measure_id');
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
    LogHelper.staticLogInfo(
        "[MEASURE] Added point: distance=${distance.toStringAsFixed(2)}m, speed=${speed.toStringAsFixed(2)}m/s, accuracy=${acc.toStringAsFixed(2)}m, lat=${lat.toStringAsFixed(6)}, lng=${lng.toStringAsFixed(6)}, duration=${duration}s, timestamp=${timestamp.toString()}");

    points.add(pointData);
    await _managementData.saveString(key, jsonEncode(points));
  }

  /// Retrieve all points for the current measure.
  static Future<List<Map<String, dynamic>>> getMeasurePoints() async {
    const String key = 'measure_points';
    String? jsonStr = await _managementData.getString(key);
    try {
      final List<dynamic> decoded = jsonDecode(jsonStr);
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  static Future<bool> clearMeasurePoints() async {
    return _managementData.removeData('measure_points');
  }

  /// Clear the measure ID and points from the shared preferences.
  static Future<bool> clearMeasureId() async {
    final bool idCleared = await _managementData.removeData('measure_id');
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
