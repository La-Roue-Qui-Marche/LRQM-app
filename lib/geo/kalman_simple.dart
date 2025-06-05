// ignore_for_file: non_constant_identifier_names

import 'dart:math';
import 'package:lrqm/utils/log_helper.dart';

class SimpleLocationKalmanFilter2D {
  // State vector: [lat, lng, v_lat, v_lng]
  late List<double> _state;

  // Covariance matrix (4x4)
  late List<List<double>> _P;

  static const double positionProcessNoise = 0.001;
  static const double velocityProcessNoise = 0.001;

  static const double maxAcceptableJumpMeters = 20.0;
  static const double minDeltaT = 0.1;

  static const double minMovingSpeedMetersPerSecond = 0.5;

  static const double maxUncertaintyMeters = 100.0;
  static const double degreesToMeters = 111000.0;

  double _lastTimestamp = 0;

  SimpleLocationKalmanFilter2D({double initialLat = 0.0, double initialLng = 0.0}) {
    reset(initialLat, initialLng);
  }

  void reset(double lat, double lng) {
    LogHelper.staticClearKalmanCsv();
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
    if (accuracy > maxUncertaintyMeters) {
      LogHelper.staticLogWarn("[KALMAN] Received high accuracy value: $accuracy m");
    }

    if (_lastTimestamp == 0) {
      reset(lat, lng);
      _lastTimestamp = timestamp;
      return _getFilteredState();
    }

    final dt = timestamp - _lastTimestamp;
    if (dt <= 0) {
      LogHelper.staticLogWarn("[KALMAN] Non-positive time delta: dt=$dt (timestamp=$timestamp, last=$_lastTimestamp)");
      return _getFilteredState();
    }
    if (dt < minDeltaT) {
      LogHelper.staticLogInfo("[KALMAN] Ignored update: dt trop court ($dt s)");
      return _getFilteredState();
    }

    final F = [
      [1.0, 0.0, dt, 0.0],
      [0.0, 1.0, 0.0, dt],
      [0.0, 0.0, 1.0, 0.0],
      [0.0, 0.0, 0.0, 1.0],
    ];

    final q_pos = positionProcessNoise * dt;
    final q_vel = velocityProcessNoise * dt * dt;
    final Q = [
      [q_pos, 0.0, 0.0, 0.0],
      [0.0, q_pos, 0.0, 0.0],
      [0.0, 0.0, q_vel, 0.0],
      [0.0, 0.0, 0.0, q_vel],
    ];

    _state = _matrixVectorMultiply(F, _state);
    _P = _matrixAdd(_matrixMultiply(F, _matrixMultiply(_P, _transpose(F))), Q);

    final H = [
      [1.0, 0.0, 0.0, 0.0],
      [0.0, 1.0, 0.0, 0.0],
    ];

    final acc = accuracy.clamp(1.0, maxUncertaintyMeters);
    final r = pow(acc / degreesToMeters, 2).toDouble();
    final R = [
      [r, 0.0],
      [0.0, r],
    ];

    final z = [lat, lng];
    List<double> y = _vectorSubtract(z, _matrixVectorMultiply(H, _state));
    y = _limitInnovationJump(y);

    final HT = _transpose(H);
    final S = _matrixAdd(_matrixMultiply(H, _matrixMultiply(_P, HT)), R);
    final K = _matrixMultiply(_P, _matrixMultiply(HT, _inverse2x2(S)));

    final Ky = _matrixVectorMultiply(K, y);
    for (int i = 0; i < _state.length; i++) {
      _state[i] += Ky[i];
    }

    _P = _matrixMultiply(_matrixSubtract(_identityMatrix(4), _matrixMultiply(K, H)), _P);

    final filtered = _getFilteredState();

    if (filtered['confidence'] != null && filtered['confidence']! < 0.4) {
      LogHelper.staticLogWarn(
          "[KALMAN] Low confidence: ${filtered['confidence']!.toStringAsFixed(2)} — result may be unreliable.");
    }

    if (filtered['speed'] != null && filtered['speed']! < minMovingSpeedMetersPerSecond) {
      LogHelper.staticLogInfo(
          "[KALMAN] User is nearly static (speed=${filtered['speed']!.toStringAsFixed(2)} m/s), skipping update");
      return _getFilteredState();
    }

    LogHelper.staticAppendKalmanCsv(
      timestamp: timestamp,
      origLat: lat,
      origLng: lng,
      gpsAcc: accuracy,
      filteredLat: filtered['latitude'] ?? 0.0,
      filteredLng: filtered['longitude'] ?? 0.0,
      speed: filtered['speed'] ?? 0.0,
      uncertainty: filtered['uncertainty'] ?? 0.0,
      confidence: filtered['confidence'] ?? 0.0,
    );

    _lastTimestamp = timestamp;
    return filtered;
  }

  /// Limite les sauts GPS irréalistes en lissant l’innovation si elle dépasse un seuil.
  /// Si la différence entre la prédiction et la mesure est trop grande, on la réduit proportionnellement.
  List<double> _limitInnovationJump(List<double> y) {
    final innovationMeters = sqrt(
      pow(y[0] * degreesToMeters, 2) + pow(y[1] * degreesToMeters, 2),
    );

    if (innovationMeters > maxAcceptableJumpMeters) {
      LogHelper.staticLogWarn("[KALMAN] Large GPS jump detected: ${innovationMeters.toStringAsFixed(2)} m");

      // Lissage proportionnel
      final scale = maxAcceptableJumpMeters / innovationMeters;
      for (int i = 0; i < y.length; i++) {
        y[i] *= scale;
      }

      final smoothedMeters = sqrt(
        pow(y[0] * degreesToMeters, 2) + pow(y[1] * degreesToMeters, 2),
      );
      LogHelper.staticLogInfo(
          "[KALMAN] Smoothed jump to ${smoothedMeters.toStringAsFixed(2)} m (scale=${scale.toStringAsFixed(2)})");
    }

    return y;
  }

  Map<String, double> _getFilteredState() {
    final uncertainty = sqrt(_P[0][0] + _P[1][1]) * degreesToMeters;
    final vLat = _state[2] * degreesToMeters;
    final vLng = _state[3] * degreesToMeters;
    final speed = sqrt(vLat * vLat + vLng * vLng);

    if (uncertainty > 50.0) {
      LogHelper.staticLogWarn("[KALMAN] High uncertainty in filtered result: ${uncertainty.toStringAsFixed(2)} m");
    }

    final confidence = max(0.0, min(1.0, 1.0 - uncertainty / maxUncertaintyMeters));
    if (confidence < 0.5) {
      LogHelper.staticLogWarn("[KALMAN] Poor confidence in filtered result: ${confidence.toStringAsFixed(2)}");
    }

    return {
      'latitude': _state[0],
      'longitude': _state[1],
      'speed': speed,
      'uncertainty': min(uncertainty, maxUncertaintyMeters),
      'confidence': confidence,
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
    for (int i = 0; i < size; i++) {
      result[i][i] = 1.0;
    }
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
