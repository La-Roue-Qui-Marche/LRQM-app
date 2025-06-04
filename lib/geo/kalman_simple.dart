// ignore_for_file: non_constant_identifier_names

import 'dart:math';

class SimpleLocationKalmanFilter2D {
  // State vector: [lat, lng, v_lat, v_lng]
  late List<double> _state;

  // Covariance matrix (4x4)
  late List<List<double>> _P;

  // Process noise matrix (4x4)
  static const double positionProcessNoise = 1e-6;
  static const double velocityProcessNoise = 1e-3;

  // Measurement noise (R) in meters (then converted to degrees² during update)
  static const double measurementNoiseMeters = 5.0;

  // Max uncertainty in meters (capped for stability)
  static const double maxUncertaintyMeters = 100.0;

  static const double degreesToMeters = 111000.0;

  // Timestamp of last update (in seconds)
  double _lastTimestamp = 0;

  SimpleLocationKalmanFilter2D({double initialLat = 0.0, double initialLng = 0.0}) {
    reset(initialLat, initialLng);
  }

  void reset(double lat, double lng) {
    _state = [lat, lng, 0.0, 0.0];

    final posUncertainty = pow(10.0 / degreesToMeters, 2).toDouble();
    final velUncertainty = pow(1.0 / degreesToMeters, 2).toDouble();

    _P = List.generate(4, (_) => List.filled(4, 0.0));
    _P[0][0] = posUncertainty;
    _P[1][1] = posUncertainty;
    _P[2][2] = velUncertainty;
    _P[3][3] = velUncertainty;

    _lastTimestamp = 0;
  }

  Map<String, double> update(double lat, double lng, double accuracy, double timestamp) {
    if (_lastTimestamp == 0) {
      reset(lat, lng);
      _lastTimestamp = timestamp;
      return _getFilteredState();
    }

    final dt = timestamp - _lastTimestamp;
    if (dt <= 0) return _getFilteredState();

    // Transition matrix F
    final F = [
      [1.0, 0.0, dt, 0.0],
      [0.0, 1.0, 0.0, dt],
      [0.0, 0.0, 1.0, 0.0],
      [0.0, 0.0, 0.0, 1.0],
    ];

    // Process noise Q
    final q_pos = positionProcessNoise * dt;
    final q_vel = velocityProcessNoise * dt * dt;
    final Q = [
      [q_pos, 0.0, 0.0, 0.0],
      [0.0, q_pos, 0.0, 0.0],
      [0.0, 0.0, q_vel, 0.0],
      [0.0, 0.0, 0.0, q_vel],
    ];

    // Predict step
    _state = _matrixVectorMultiply(F, _state);
    _P = _matrixAdd(_matrixMultiply(F, _matrixMultiply(_P, _transpose(F))), Q);

    // Measurement matrix H (2x4)
    final H = [
      [1.0, 0.0, 0.0, 0.0],
      [0.0, 1.0, 0.0, 0.0],
    ];

    // Measurement noise R (2x2) in degrees²
    final r = pow((accuracy < 1000 ? accuracy : measurementNoiseMeters) / degreesToMeters, 2).toDouble();
    final R = [
      [r, 0.0],
      [0.0, r],
    ];

    // Measurement vector z
    final z = [lat, lng];

    // Innovation y = z - Hx
    final y = _vectorSubtract(z, _matrixVectorMultiply(H, _state));

    // Innovation covariance S = HPH' + R
    final HT = _transpose(H);
    final S = _matrixAdd(_matrixMultiply(H, _matrixMultiply(_P, HT)), R);

    // Kalman Gain K = P H' S⁻¹
    final K = _matrixMultiply(_P, _matrixMultiply(HT, _inverse2x2(S)));

    // Update state x = x + K * y
    final Ky = _matrixVectorMultiply(K, y);
    for (int i = 0; i < _state.length; i++) {
      _state[i] += Ky[i];
    }

    // Update covariance P = (I - KH)P
    final I = _identityMatrix(4);
    final KH = _matrixMultiply(K, H);
    final I_KH = _matrixSubtract(I, KH);
    _P = _matrixMultiply(I_KH, _P);

    _lastTimestamp = timestamp;

    return _getFilteredState();
  }

  Map<String, double> _getFilteredState() {
    final uncertainty = sqrt(_P[0][0] + _P[1][1]) * degreesToMeters;
    final vLat = _state[2] * degreesToMeters;
    final vLng = _state[3] * degreesToMeters;
    final speed = sqrt(vLat * vLat + vLng * vLng);

    return {
      'latitude': _state[0],
      'longitude': _state[1],
      'speed': speed,
      'uncertainty': min(uncertainty, maxUncertaintyMeters),
      'confidence': max(0.0, min(1.0, 1.0 - uncertainty / maxUncertaintyMeters)),
    };
  }

  Map<String, double> getPosition() => _getFilteredState();

  // ========== Matrix Helpers ==========

  List<List<double>> _matrixMultiply(List<List<double>> A, List<List<double>> B) {
    final result = List.generate(A.length, (_) => List.filled(B[0].length, 0.0));
    for (int i = 0; i < A.length; i++) {
      for (int j = 0; j < B[0].length; j++) {
        for (int k = 0; k < A[0].length; k++) {
          result[i][j] += A[i][k] * B[k][j];
        }
      }
    }
    return result;
  }

  List<double> _matrixVectorMultiply(List<List<double>> A, List<double> x) {
    final result = List.filled(A.length, 0.0);
    for (int i = 0; i < A.length; i++) {
      for (int j = 0; j < x.length; j++) {
        result[i] += A[i][j] * x[j];
      }
    }
    return result;
  }

  List<List<double>> _matrixAdd(List<List<double>> A, List<List<double>> B) {
    final result = List.generate(A.length, (i) => List.filled(A[0].length, 0.0));
    for (int i = 0; i < A.length; i++) {
      for (int j = 0; j < A[0].length; j++) {
        result[i][j] = A[i][j] + B[i][j];
      }
    }
    return result;
  }

  List<List<double>> _matrixSubtract(List<List<double>> A, List<List<double>> B) {
    final result = List.generate(A.length, (i) => List.filled(A[0].length, 0.0));
    for (int i = 0; i < A.length; i++) {
      for (int j = 0; j < A[0].length; j++) {
        result[i][j] = A[i][j] - B[i][j];
      }
    }
    return result;
  }

  List<List<double>> _transpose(List<List<double>> A) {
    final result = List.generate(A[0].length, (_) => List.filled(A.length, 0.0));
    for (int i = 0; i < A.length; i++) {
      for (int j = 0; j < A[0].length; j++) {
        result[j][i] = A[i][j];
      }
    }
    return result;
  }

  List<List<double>> _identityMatrix(int size) {
    final result = List.generate(size, (i) => List.filled(size, 0.0));
    for (int i = 0; i < size; i++) result[i][i] = 1.0;
    return result;
  }

  List<double> _vectorSubtract(List<double> a, List<double> b) {
    return List.generate(a.length, (i) => a[i] - b[i]);
  }

  List<List<double>> _inverse2x2(List<List<double>> m) {
    final a = m[0][0], b = m[0][1], c = m[1][0], d = m[1][1];
    final det = a * d - b * c;
    if (det.abs() < 1e-12) throw Exception('Matrix not invertible');
    final invDet = 1.0 / det;
    return [
      [d * invDet, -b * invDet],
      [-c * invDet, a * invDet],
    ];
  }
}
