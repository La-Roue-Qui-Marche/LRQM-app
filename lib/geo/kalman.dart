import 'dart:math';
import 'package:coordinate_converter/coordinate_converter.dart';
import 'package:lrqm/utils/log_helper.dart';

/// A Kalman filter optimized for GPS tracking using UTM coordinates
class LocationKalmanFilter {
  // State vector [x, y, z, vx, vy, vz] in UTM+height coordinates
  late List<double> _state;

  // State covariance matrix (6x6)
  late List<List<double>> _P;

  // Time since last update in seconds
  double _lastUpdateTime = 0;

  // Base process noise (in m²/s⁴ for acceleration)
  static const double _baseProcessNoise = 0.25; // Increased to better track actual movement

  // Process noise multiplier when moving
  static const double _movingNoiseMultiplier = 1.5; // Reduced to avoid over-dampening
  // Measurement noise factor
  static const double _measurementNoiseFactor = 0.75; // Trust measurements more for better velocity tracking

  // Maximum velocity (m/s)
  static const double _maxVelocity = 12.0; // ~43 km/h (sprint speed + margin)

  // Maximum time gap for predictions (seconds)
  static const double _maxTimeDelta = 5.0; // Increased to handle longer gaps

  // Minimum speed to be considered moving (m/s)
  static const double _minMovingSpeed = 0.3; // ~1.08 km/h (very slow walking)

  // Maximum allowed position jump (meters)
  static const double _maxPositionJump = 20.0; // Stricter jump detection

  // Filter confidence (0.0 to 1.0)
  double _confidence = 0.0;

  // Previous measurement for jump detection
  List<double>? _lastMeasurement;

  // Current UTM coordinates
  late UTMCoordinates _utmCoordinates;

  LocationKalmanFilter({
    double initialLat = 0.0,
    double initialLng = 0.0,
    double initialHeight = 0.0,
  }) {
    final ddCoords = DDCoordinates(latitude: initialLat, longitude: initialLng);
    _utmCoordinates = ddCoords.toUTM();
    reset(initialLat, initialLng, initialHeight);
  }

  void update(double lat, double lng, double accuracy, double timestamp, {double height = 0.0}) {
    // Initialize on first update
    if (_lastUpdateTime == 0) {
      reset(lat, lng, height);
      _lastUpdateTime = timestamp;
      return;
    }

    final dt = timestamp - _lastUpdateTime;
    if (dt <= 0 || dt > _maxTimeDelta) {
      reset(lat, lng, height);
      _lastUpdateTime = timestamp;
      return;
    }

    // Convert incoming lat/lng to UTM coordinates
    final ddCoords = DDCoordinates(latitude: lat, longitude: lng);
    final utmCoords = ddCoords.toUTM();

    // Measured state vector [x, y, z]
    final measuredState = [utmCoords.x, utmCoords.y, height];

    // Calculate measurement noise based on accuracy
    // Higher accuracy (lower value) = lower noise
    final R = accuracy * accuracy * _measurementNoiseFactor;

    // Predict state
    final predictedState = List<double>.from(_state);
    for (int i = 0; i < 3; i++) {
      predictedState[i] += _state[i + 3] * dt;
    }

    // Compute velocities from position change
    final velocities = List<double>.filled(3, 0.0);
    for (int i = 0; i < 3; i++) {
      // Instantaneous velocity from position change
      velocities[i] = (measuredState[i] - _state[i]) / dt;
    }

    // Calculate current speed for process noise adjustment
    final speed = sqrt(velocities.sublist(0, 2).fold(0.0, (sum, v) => sum + v * v));

    // Determine if moving and adjust process noise
    final isMoving = speed >= _minMovingSpeed;
    final processNoise = _baseProcessNoise * (isMoving ? _movingNoiseMultiplier : 1.0);

    // Calculate Kalman gains
    final kPos = List<double>.filled(3, 0.0);
    final kVel = List<double>.filled(3, 0.0);
    for (int i = 0; i < 3; i++) {
      final denom1 = _P[i][i] + R;
      final denom2 = _P[i + 3][i + 3] + R / (dt * dt);
      kPos[i] = denom1 > 0 ? _P[i][i] / denom1 : 0.0;
      kVel[i] = denom2 > 0 ? _P[i + 3][i + 3] / denom2 : 0.0;
    }

    // Update state with measured position and computed velocity
    for (int i = 0; i < 3; i++) {
      // Update position
      _state[i] = predictedState[i] + kPos[i] * (measuredState[i] - predictedState[i]);

      // Update velocity - weighted average of predicted and measured velocity
      final velocityInnovation = velocities[i] - _state[i + 3];
      _state[i + 3] += kVel[i] * velocityInnovation;
    }

    // Velocity constraints - use smooth limiting
    final currentSpeed = sqrt(_state.sublist(3, 5).fold(0.0, (sum, v) => sum + v * v));
    if (currentSpeed > _maxVelocity) {
      final scale = _maxVelocity / currentSpeed;
      for (int i = 3; i < 5; i++) {
        _state[i] *= scale;
      }
    }

    // Update covariances
    final dt2 = dt * dt;
    for (int i = 0; i < 3; i++) {
      // Position variance
      _P[i][i] = (1 - kPos[i]) * _P[i][i] + processNoise * dt2;
      _P[i][i] = max(_P[i][i], 1e-6); // Numerical stability

      // Velocity variance
      _P[i + 3][i + 3] = (1 - kVel[i]) * _P[i + 3][i + 3] + processNoise;
      _P[i + 3][i + 3] = max(_P[i + 3][i + 3], 1e-6);

      // Cross-covariance
      _P[i][i + 3] = _P[i + 3][i] = 0.5 * (_P[i][i] / dt + _P[i + 3][i + 3] * dt);
    }

    // Update UTM coordinates and timestamp
    _utmCoordinates = UTMCoordinates(
        x: _state[0],
        y: _state[1],
        zoneNumber: utmCoords.zoneNumber,
        isSouthernHemisphere: utmCoords.isSouthernHemisphere);
    _lastUpdateTime = timestamp;
    _increaseConfidence();
  }

  Map<String, double> getFilteredPosition() {
    // Convert current UTM coordinates back to lat/lng
    final ddCoords = _utmCoordinates.toDD();

    // Calculate speed in m/s
    final speed = sqrt(_state.sublist(3).fold(0.0, (sum, v) => sum + v * v));

    // UTM velocities are already in east/north orientation
    final vEast = _state[3]; // x velocity is east-oriented
    final vNorth = _state[4]; // y velocity is north-oriented

    // Calculate position uncertainty in meters
    final uncertainty = sqrt(_P[0][0] + _P[1][1] + _P[2][2]);

    return {
      'latitude': ddCoords.latitude,
      'longitude': ddCoords.longitude,
      'height': _state[2],
      'velocity_x': vEast,
      'velocity_y': vNorth,
      'speed': speed,
      'uncertainty': uncertainty,
      'confidence': _confidence
    };
  }

  void reset(double lat, double lng, double height) {
    // Initialize coordinates
    final ddCoords = DDCoordinates(latitude: lat, longitude: lng);
    _utmCoordinates = ddCoords.toUTM();

    // Initialize state vector [x, y, z, vx, vy, vz]
    _state = [
      _utmCoordinates.x, // UTM X
      _utmCoordinates.y, // UTM Y
      height, // Height
      0.0, // X velocity
      0.0, // Y velocity
      0.0 // Z velocity
    ];

    // Initialize covariance matrix (6x6)
    _P = List.generate(6, (_) => List.filled(6, 0.0));
    for (int i = 0; i < 3; i++) {
      _P[i][i] = 25.0; // Position uncertainty (25m)² - reduced for better position tracking
      _P[i + 3][i + 3] = 2.0; // Velocity uncertainty (2m/s)² - increased to allow quicker velocity changes

      // Initialize cross-covariance terms
      for (int j = 0; j < 3; j++) {
        if (i != j) {
          _P[i][j] = _P[j][i] = 0.0;
          _P[i + 3][j + 3] = _P[j + 3][i + 3] = 0.0;
        }
      }
    }

    _lastUpdateTime = 0;
    _confidence = 0.2; // Initial confidence
    _lastMeasurement = null;
  }

  void _increaseConfidence() {
    _confidence = min(_confidence + 0.1, 1.0);
  }

  void _decreaseConfidence() {
    _confidence = max(_confidence - 0.2, 0.0);
  }
}
