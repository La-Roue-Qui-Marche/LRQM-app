import 'dart:math';

/// A simplified Kalman filter for GPS tracking that works directly with lat/long coordinates
class SimpleLocationKalmanFilter {
  // State vector [lat, lng, v_lat, v_lng]
  late List<double> _state;

  // State covariance matrix (4x4)
  late List<List<double>> _P;

  // Last update timestamp in seconds
  double _lastUpdateTime = 0;

  // Process noise parameters
  static const double _positionProcessNoise = 1e-8; // Position noise (degrees²/s)
  static const double _velocityProcessNoise = 1e-7; // Velocity noise (degrees²/s³)

  // Maximum allowed uncertainty in meters
  static const double _maxUncertainty = 50.0;

  // Conversion factor from degrees to meters (approximate at equator)
  static const double _degreesToMeters = 111000.0;

  // Minimum speed to consider movement (in degrees/second)
  static const double _minSpeed = 0.00001; // Approx 1 meter/second at equator

  SimpleLocationKalmanFilter({
    double initialLat = 0.0,
    double initialLng = 0.0,
  }) {
    reset(initialLat, initialLng);
  }

  void reset(double lat, double lng) {
    // Initialize state vector [lat, lng, v_lat, v_lng]
    _state = [lat, lng, 0.0, 0.0];

    // Initialize covariance matrix
    _P = List.generate(4, (_) => List.filled(4, 0.0));

    // Convert 10 meters to degrees for initial position uncertainty
    final posUncertainty = pow(10.0 / _degreesToMeters, 2).toDouble();
    // Convert 1 m/s to degrees/s for initial velocity uncertainty
    final velUncertainty = pow(1.0 / _degreesToMeters, 2).toDouble();

    // Set initial uncertainties
    for (int i = 0; i < 2; i++) {
      _P[i][i] = posUncertainty;
      _P[i + 2][i + 2] = velUncertainty;
    }

    _lastUpdateTime = 0;
  }

  Map<String, double> update(double lat, double lng, double accuracy, double timestamp) {
    // First update or reset condition
    if (_lastUpdateTime == 0) {
      reset(lat, lng);
      _lastUpdateTime = timestamp;
      return {
        'latitude': lat,
        'longitude': lng,
        'speed': 0.0,
        'uncertainty': accuracy,
        'confidence': _calculateConfidence(accuracy)
      };
    }

    final dt = timestamp - _lastUpdateTime;
    if (dt <= 0) return _getFilteredState();

    // Predict step
    final predictedState = List<double>.from(_state);
    predictedState[0] += _state[2] * dt;
    predictedState[1] += _state[3] * dt;

    // Update process noise based on time delta
    for (int i = 0; i < 2; i++) {
      _P[i][i] += _positionProcessNoise * dt;
      _P[i + 2][i + 2] += _velocityProcessNoise * dt * dt;
    }

    // Calculate measurement noise based on GPS accuracy
    final R = pow(accuracy / _degreesToMeters, 2); // Convert accuracy to degrees²

    // Measured velocity (degrees/second)
    final v_lat = (lat - _state[0]) / dt;
    final v_lng = (lng - _state[1]) / dt;

    // Update step - position
    final k_pos = _P[0][0] / (_P[0][0] + R);
    final k_vel = _P[2][2] / (_P[2][2] + R / (dt * dt));

    // Update state
    _state[0] = predictedState[0] + k_pos * (lat - predictedState[0]);
    _state[1] = predictedState[1] + k_pos * (lng - predictedState[1]);
    _state[2] = _state[2] + k_vel * (v_lat - _state[2]);
    _state[3] = _state[3] + k_vel * (v_lng - _state[3]);

    // Update covariance with separate noise for position and velocity
    for (int i = 0; i < 2; i++) {
      _P[i][i] = (1 - k_pos) * _P[i][i];
      _P[i + 2][i + 2] = (1 - k_vel) * _P[i + 2][i + 2];
    }

    // Cap uncertainty growth
    _capUncertainty();

    _lastUpdateTime = timestamp;
    return _getFilteredState();
  }

  void _capUncertainty() {
    final maxUncertaintyDegrees = _maxUncertainty / _degreesToMeters;
    final maxUncertaintyDegrees2 = pow(maxUncertaintyDegrees, 2).toDouble();

    for (int i = 0; i < 2; i++) {
      if (_P[i][i] > maxUncertaintyDegrees2) {
        _P[i][i] = maxUncertaintyDegrees2;
      }
    }
  }

  double _calculateConfidence(double uncertainty) {
    // Convert uncertainty to meters for consistent scale
    final uncertaintyMeters = uncertainty < 1000 ? uncertainty : sqrt(_P[0][0] + _P[1][1]) * _degreesToMeters;
    // Scale confidence from 0 to 1 based on uncertainty
    // 0m = 1.0 confidence, 50m = 0.0 confidence
    return max(0.0, min(1.0, 1.0 - uncertaintyMeters / _maxUncertainty));
  }

  Map<String, double> _getFilteredState() {
    final uncertainty = sqrt(_P[0][0] + _P[1][1]) * _degreesToMeters;
    return {
      'latitude': _state[0],
      'longitude': _state[1],
      'speed': _getSpeed(),
      'uncertainty': min(uncertainty, _maxUncertainty),
      'confidence': _calculateConfidence(uncertainty)
    };
  }

  // Convert velocity components to speed in meters/second
  double _getSpeed() {
    final vLat = _state[2] * _degreesToMeters; // Convert to m/s
    final vLng = _state[3] * _degreesToMeters;
    final speed = sqrt(vLat * vLat + vLng * vLng);

    // Filter out very small speeds (likely noise)
    return speed > _minSpeed * _degreesToMeters ? speed : 0.0;
  }

  Map<String, double> getPosition() {
    return _getFilteredState();
  }
}
