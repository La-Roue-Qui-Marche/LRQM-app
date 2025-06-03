import 'dart:math';
import 'package:lrqm/utils/log_helper.dart';

/// A filter that detects and prevents unrealistic accelerations in GPS data
/// without applying constant smoothing to all data points.
class AccelerationFilter {
  double? _lastLat;
  double? _lastLng;
  double? _lastSpeed;
  double? _lastTime;

  // Maximum realistic acceleration (m/s²)
  final double accelerationThreshold;

  AccelerationFilter({
    this.accelerationThreshold = 3.0,
  });

  /// Detects and filters out unrealistic accelerations
  Map<String, dynamic> filter({
    required double lat,
    required double lng,
    required double speed,
    required double timestamp,
  }) {
    // First update case
    if (_lastLat == null) {
      _lastLat = lat;
      _lastLng = lng;
      _lastSpeed = speed;
      _lastTime = timestamp;

      return {
        'latitude': lat,
        'longitude': lng,
        'speed': speed,
        'filtered': false,
      };
    }

    final dt = timestamp - (_lastTime ?? 0.0);
    if (dt <= 0.0) {
      return {
        'latitude': _lastLat!,
        'longitude': _lastLng!,
        'speed': _lastSpeed!,
        'filtered': false,
      };
    }

    // Calculate speed change and acceleration
    final speedChange = speed - _lastSpeed!;
    final acceleration = speedChange / dt;

    // Output values (default to input values)
    double outputLat = lat;
    double outputLng = lng;
    double outputSpeed = speed;
    bool filtered = false;

    // Check for unrealistic acceleration
    bool unrealisticAcceleration = acceleration.abs() > accelerationThreshold;

    // Handle unrealistic acceleration - this is the only filter we apply
    if (unrealisticAcceleration) {
      filtered = true;

      // Cap the speed change to what's realistic
      final maxDv = accelerationThreshold * dt;
      final sign = speedChange >= 0 ? 1.0 : -1.0;
      outputSpeed = _lastSpeed! + sign * min(maxDv, speedChange.abs());

      // When acceleration is unrealistic, don't update position either
      outputLat = _lastLat!;
      outputLng = _lastLng!;

      LogHelper.staticLogWarn(
          "[ACCEL] Acceleration filter: ${acceleration.toStringAsFixed(2)} m/s² -> ${((outputSpeed - _lastSpeed!) / dt).toStringAsFixed(2)} m/s² | Speed: ${_lastSpeed!.toStringAsFixed(2)} -> ${speed.toStringAsFixed(2)} -> ${outputSpeed.toStringAsFixed(2)} m/s | Position update IGNORED");
    }

    // Update state with the original input values for future reference if not filtered,
    // otherwise keep the current position but update the speed
    if (!filtered) {
      _lastLat = lat;
      _lastLng = lng;
    }
    _lastSpeed = outputSpeed; // Always use filtered speed for next acceleration calculation
    _lastTime = timestamp;

    return {
      'latitude': outputLat,
      'longitude': outputLng,
      'speed': outputSpeed,
      'filtered': filtered,
    };
  }
}
