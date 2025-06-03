import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:background_location/background_location.dart' as bg;
import 'package:maps_toolkit/maps_toolkit.dart' as mp;

import 'package:lrqm/api/measure_controller.dart';
import 'package:lrqm/utils/log_helper.dart';
import 'package:lrqm/utils/permission_helper.dart';
import 'package:lrqm/data/event_data.dart';
import 'package:lrqm/data/measure_data.dart';
import 'package:lrqm/geo/kalman_simple.dart';
import 'package:lrqm/geo/acceleration_filter.dart'; // Update import to new file
import 'package:lrqm/geo/geolocation_log.dart';

/// Configuration for the geolocation controller
class GeolocationConfig {
  final int locationDistanceFilter;
  final geo.LocationAccuracy locationAccuracy;
  final Duration apiInterval;
  final int outsideCounterMax;
  final String notificationTitle;
  final String notificationText;
  final String notificationIconName;
  final String notificationIconType;
  final double maxAcceleration;

  GeolocationConfig({
    this.locationDistanceFilter = 5,
    this.locationAccuracy = geo.LocationAccuracy.bestForNavigation,
    this.apiInterval = const Duration(seconds: 10),
    this.outsideCounterMax = 5,
    this.notificationTitle = "La RQM Background Tracking",
    this.notificationText = "Tracking in progress...",
    this.notificationIconName = 'launcher_icon',
    this.notificationIconType = 'mipmap',
    this.maxAcceleration = 3.0,
  });
}

/// Helper class to group filtered position data
class FilteredPosition {
  final double latitude;
  final double longitude;
  final double speed;
  final double uncertainty;
  final double confidence;
  final bool filtered;
  final bool transitionState;
  final int distance;

  FilteredPosition({
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.uncertainty,
    required this.confidence,
    required this.filtered,
    required this.transitionState,
    required this.distance,
  });
}

/// Controller for handling geolocation tracking
///
/// This class manages the tracking of user's location, applies filtering,
/// handles zone boundaries, and communicates with the server.
class GeolocationController with WidgetsBindingObserver {
  //
  // === PUBLIC API ===
  //

  GeolocationController({required this.config}) {
    _settings = _getSettings();
    WidgetsBinding.instance.addObserver(this);
    _initZone();
  }

  final GeolocationConfig config;

  Stream<Map<String, int>> get stream => _streamController.stream;

  int get currentDistance => _distance;

  int get elapsedTimeInSeconds {
    if (_isCountingInZone && _lastActiveTimestamp != null) {
      return (_accumulatedActiveDuration + DateTime.now().difference(_lastActiveTimestamp!)).inSeconds;
    }
    return _accumulatedActiveDuration.inSeconds;
  }

  bool get isCountingInZone => _isCountingInZone;

  Future<geo.Position?> get currentPosition async {
    if (!await PermissionHelper.requestLocationWhenInUsePermission()) {
      LogHelper.staticLogError("[GEO] Location permission not granted.");
      return null;
    }
    try {
      return await geo.Geolocator.getCurrentPosition();
    } catch (e) {
      LogHelper.staticLogError("[GEO] Failed to get current position: $e");
      return null;
    }
  }

  Future<void> startListening() async {
    LogHelper.staticLogInfo("[GEO] Starting geolocation...");

    if (_positionStreamStarted) {
      LogHelper.staticLogError("[GEO] Geolocation already started.");
      return;
    }

    if (!(await PermissionHelper.isProperLocationPermissionGranted())) {
      LogHelper.staticLogError("[GEO] Location permission not granted.");
      _streamController.sink.add({"time": -1, "distance": -1});
      return;
    }

    await MeasureData.clearMeasurePoints();
    _positionStreamStarted = true;
    _distance = 0;
    _outsideCounter = 0;
    _accumulatedActiveDuration = Duration.zero;
    _lastActiveTimestamp = DateTime.now();
    _lastPositionWasFiltered = false;

    final initialPos = await geo.Geolocator.getCurrentPosition();
    _kalmanFilter = SimpleLocationKalmanFilter(initialLat: initialPos.latitude, initialLng: initialPos.longitude);
    _accelerationFilter = AccelerationFilter(accelerationThreshold: config.maxAcceleration); // Rename the instance
    _oldPos = initialPos;
    _resetPosition = false;

    _startPositionStream();
    _startTimers();

    LogHelper.staticLogInfo("[GEO] Geolocation started successfully.");
  }

  Future<bool> stopListening() async {
    if (!_positionStreamStarted) return false;
    LogHelper.staticLogInfo("[GEO] Stopping geolocation...");

    try {
      await _sendFinalDistance();
    } catch (e) {
      LogHelper.staticLogError("[GEO] Error during sending final distance: $e");
      return false;
    }

    try {
      final result = await MeasureController.stopMeasure();
      if (result.value != true) {
        LogHelper.staticLogError("[GEO] Failed to stop measure: ${result.error}");
        return false;
      }
      LogHelper.staticLogInfo("[GEO] Measure stopped successfully.");
    } catch (e) {
      LogHelper.staticLogError("[GEO] Error during stopMeasure: $e");
      return false;
    }

    await _cleanupResources();
    return true;
  }

  Future<void> forceStopListening() async {
    LogHelper.staticLogInfo("[GEO] Force stopping geolocation...");
    try {
      await _sendFinalDistance();
    } catch (e) {
      LogHelper.staticLogError("[GEO] Error during sending final distance: $e");
    }

    try {
      await MeasureController.stopMeasure();
    } catch (e) {
      LogHelper.staticLogError("[GEO] Error during stopMeasure: $e");
    }

    await _cleanupResources();
    LogHelper.staticLogInfo("[GEO] Force stop completed.");
  }

  Future<bool> isLocationInZone(double lat, double lng) async {
    final pos = mp.LatLng(lat, lng);
    final zone = _zonePoints;
    if (zone == null) return false;
    return mp.PolygonUtil.containsLocation(pos, zone, false);
  }

  Future<bool> isInZone() async {
    final pos = await geo.Geolocator.getCurrentPosition();
    return await isLocationInZone(pos.latitude, pos.longitude);
  }

  Future<double> distanceToZone() async {
    final pos = await geo.Geolocator.getCurrentPosition();
    final zone = _zonePoints;
    if (zone == null) return -1;

    if (await isLocationInZone(pos.latitude, pos.longitude)) return -1;

    final currentPoint = mp.LatLng(pos.latitude, pos.longitude);
    double minDistance = double.infinity;

    for (int i = 0; i < zone.length; i++) {
      final p1 = zone[i];
      final p2 = zone[(i + 1) % zone.length];
      final dist = mp.PolygonUtil.distanceToLine(currentPoint, p1, p2).toDouble();
      if (dist < minDistance) minDistance = dist;
    }

    // Return distance in kilometers, formatted to 1 decimal place
    return double.parse((minDistance / 1000).toStringAsFixed(1));
  }

  /// Clean up all resources used by this controller
  void cleanup() {
    WidgetsBinding.instance.removeObserver(this);
    stopListening();
  }

  //
  // === PRIVATE IMPLEMENTATION ===
  //

  // Core state
  late geo.LocationSettings _settings;
  late SimpleLocationKalmanFilter _kalmanFilter;
  late AccelerationFilter _accelerationFilter; // Rename the variable
  geo.Position? _oldPos;

  StreamSubscription<geo.Position>? _positionStream;
  Timer? _apiTimer;
  Timer? _streamTimer;
  final StreamController<Map<String, int>> _streamController = StreamController<Map<String, int>>.broadcast();

  bool _positionStreamStarted = false;
  int _distance = 0;
  int _outsideCounter = 0;
  bool _resetPosition = false;
  bool _isSending = false;
  bool _isCountingInZone = true;
  bool _lastPositionWasFiltered = false;

  Duration _accumulatedActiveDuration = Duration.zero;
  DateTime? _lastActiveTimestamp;

  // Geofencing
  List<mp.LatLng>? _zonePoints;

  Future<void> _initZone() async {
    _zonePoints = await EventData.getSiteCoordLatLngList();
  }

  geo.LocationSettings _getSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return geo.AndroidSettings(
        accuracy: config.locationAccuracy,
        distanceFilter: config.locationDistanceFilter,
        forceLocationManager: true,
        foregroundNotificationConfig: geo.ForegroundNotificationConfig(
          notificationText: config.notificationText,
          notificationTitle: config.notificationTitle,
          enableWakeLock: true,
          notificationIcon: geo.AndroidResource(
            name: config.notificationIconName,
            defType: config.notificationIconType,
          ),
        ),
      );
    } else {
      return geo.LocationSettings(
        accuracy: config.locationAccuracy,
        distanceFilter: config.locationDistanceFilter,
      );
    }
  }

  void _startPositionStream() {
    _positionStream =
        geo.Geolocator.getPositionStream(locationSettings: _settings).listen(_handleForegroundUpdate, onError: (error) {
      LogHelper.staticLogError("[GEO] Position stream error: $error");
    });
  }

  void _startTimers() {
    _apiTimer = Timer.periodic(config.apiInterval, (_) {
      _sendCurrentDistance();
    });

    _streamTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_streamController.isClosed) {
        _streamController.sink.add({
          "time": elapsedTimeInSeconds,
          "distance": _distance,
        });
      }
    });
  }

  void _handleForegroundUpdate(geo.Position position) {
    _processPositionUpdate(
      position.latitude,
      position.longitude,
      position.accuracy,
      position.timestamp,
    );
  }

  void _handleBackgroundUpdate(bg.Location location) {
    _processPositionUpdate(
      location.latitude ?? 0,
      location.longitude ?? 0,
      location.accuracy ?? 0,
      DateTime.now(),
    );
  }

  void _processPositionUpdate(double lat, double lng, double acc, DateTime timestamp) async {
    final currentTimestampSec = timestamp.millisecondsSinceEpoch / 1000.0;

    if (_resetPosition || _oldPos == null) {
      LogHelper.staticLogInfo("[GEO] First update or reset position. Acc=${acc.toStringAsFixed(1)}m");
      _saveOldPos(lat, lng, acc, timestamp, speed: 0);
      _resetPosition = false;
      _lastPositionWasFiltered = false;
      return;
    }

    final FilteredPosition filteredPosition = await _applyFilters(lat, lng, acc, currentTimestampSec, timestamp);

    // Calculate raw values for logging
    final rawDist = geo.Geolocator.distanceBetween(_oldPos!.latitude, _oldPos!.longitude, lat, lng).round();
    final timeDiffSec = (timestamp.difference(_oldPos!.timestamp).inMilliseconds) / 1000.0;
    double rawSpeed = 0.0;
    if (timeDiffSec > 0.5) {
      rawSpeed = geo.Geolocator.distanceBetween(_oldPos!.latitude, _oldPos!.longitude, lat, lng) / timeDiffSec;
    }

    LogHelper.staticLogInfo(formatPositionComparison(
      elapsedTime: elapsedTimeInSeconds,
      smoothedPosition: {
        'latitude': filteredPosition.latitude,
        'longitude': filteredPosition.longitude,
        'speed': filteredPosition.speed,
      },
      lat: lat,
      lng: lng,
      rawSpeed: rawSpeed,
      rawAccuracy: acc,
      dist: filteredPosition.distance,
      rawDist: rawDist,
      timestamp: timestamp,
      uncertainty: filteredPosition.uncertainty,
      confidence: filteredPosition.confidence,
      filtered: filteredPosition.filtered,
      transition: filteredPosition.transitionState,
    ));

    await MeasureData.addMeasurePoint(
      distance: _distance.toDouble(),
      speed: filteredPosition.speed,
      acc: filteredPosition.uncertainty,
      timestamp: timestamp,
      lat: filteredPosition.latitude,
      lng: filteredPosition.longitude,
      duration: elapsedTimeInSeconds,
    );

    _saveOldPos(
      filteredPosition.latitude,
      filteredPosition.longitude,
      filteredPosition.uncertainty,
      timestamp,
      speed: filteredPosition.speed,
    );
    _lastPositionWasFiltered = filteredPosition.filtered;
  }

  Future<FilteredPosition> _applyFilters(
    double lat,
    double lng,
    double acc,
    double currentTimestampSec,
    DateTime timestamp,
  ) async {
    double finalLat = lat;
    double finalLng = lng;
    double finalSpeed = 0.0;
    double uncertainty = acc;
    double confidence = 0.0;

    // Apply Kalman filter
    final kalmanOutput = _kalmanFilter.update(lat, lng, acc, currentTimestampSec);
    finalLat = kalmanOutput['latitude']!;
    finalLng = kalmanOutput['longitude']!;
    finalSpeed = kalmanOutput['speed']!;
    uncertainty = kalmanOutput['uncertainty']!;
    confidence = kalmanOutput['confidence']!;

    bool positionFiltered = false;
    final accelerationFilterOutput = _accelerationFilter.filter(
      // Rename the method call
      lat: finalLat,
      lng: finalLng,
      speed: finalSpeed,
      timestamp: currentTimestampSec,
    );

    finalLat = accelerationFilterOutput['latitude'];
    finalLng = accelerationFilterOutput['longitude'];
    finalSpeed = accelerationFilterOutput['speed'];
    positionFiltered = accelerationFilterOutput['filtered'];

    int dist = 0;
    if (!positionFiltered && !_lastPositionWasFiltered) {
      dist = geo.Geolocator.distanceBetween(_oldPos!.latitude, _oldPos!.longitude, finalLat, finalLng).round();
    } else if (_lastPositionWasFiltered && !positionFiltered) {
      LogHelper.staticLogWarn("[GEO] Transition from filtered to non-filtered position - not counting distance");
    }

    final inZone = await isLocationInZone(finalLat, finalLng);
    if (!positionFiltered && !_lastPositionWasFiltered) {
      _handleZoneLogic(inZone, dist);
    }

    bool hasInvalid = false;
    for (final v in [finalLat, finalLng, finalSpeed, uncertainty, confidence]) {
      if (v.isNaN || v.isInfinite) {
        hasInvalid = true;
        break;
      }
    }

    if (hasInvalid) {
      LogHelper.staticLogError("[GEO] Invalid (NaN/Inf) value in processed position. Using raw values.");
      return FilteredPosition(
        latitude: lat,
        longitude: lng,
        speed: 0,
        uncertainty: acc,
        confidence: 0.0, // Ensure a default confidence value is provided
        filtered: true,
        transitionState: false,
        distance: 0,
      );
    }

    bool transitionState = _lastPositionWasFiltered && !positionFiltered;

    return FilteredPosition(
      latitude: finalLat,
      longitude: finalLng,
      speed: finalSpeed,
      uncertainty: uncertainty,
      confidence: confidence,
      filtered: positionFiltered,
      transitionState: transitionState,
      distance: dist,
    );
  }

  void _handleZoneLogic(bool inZone, int dist) {
    if (inZone) {
      _outsideCounter = 0;
      _isCountingInZone = true;
      _distance += dist;
    } else {
      if (_outsideCounter <= config.outsideCounterMax) {
        _outsideCounter++;
        _distance += dist;
      } else {
        _isCountingInZone = false;
        // Do not accumulate duration or change timestamps, just set flag
      }
    }
  }

  void _saveOldPos(double lat, double lng, double acc, DateTime timestamp, {double speed = 0}) {
    _oldPos = geo.Position(
      latitude: lat,
      longitude: lng,
      accuracy: acc,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
      timestamp: timestamp,
      altitude: 0,
      heading: 0,
      speed: speed,
      speedAccuracy: 0,
    );
  }

  Future<void> _sendCurrentDistance() async {
    if (_isSending) return;
    _isSending = true;

    try {
      final response = await MeasureController.editMeters(_distance);
      if (response.error != null) {
        LogHelper.staticLogError("[API] Failed to send current distance: ${response.error}");
      } else {
        LogHelper.staticLogInfo("[API] Sent current distance: $_distance m");
      }
    } catch (e) {
      LogHelper.staticLogError("[API] Exception while sending distance: $e");
    } finally {
      _isSending = false;
    }
  }

  Future<void> _sendFinalDistance() async {
    LogHelper.staticLogInfo("[GEO] Sending final distance $_distance m...");

    try {
      final response = await MeasureController.editMeters(_distance);
      if (response.error != null) {
        LogHelper.staticLogError("[API] Failed to send final distance: ${response.error}");
      } else {
        LogHelper.staticLogInfo("[API] Sent final distance: $_distance m");
      }
    } catch (e) {
      LogHelper.staticLogError("[API] Exception sending final distance: $e");
    }
  }

  Future<void> _cleanupResources() async {
    _positionStreamStarted = false;

    try {
      await _positionStream?.cancel();
      _apiTimer?.cancel();
      _streamTimer?.cancel();
      if (!_streamController.isClosed) {
        await _streamController.close();
      }
      await bg.BackgroundLocation.stopLocationService();
    } catch (e) {
      LogHelper.staticLogError("[GEO] Error during cleanup: $e");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_positionStreamStarted) return;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (state == AppLifecycleState.paused) {
        _switchToBackgroundLocation();
      } else if (state == AppLifecycleState.resumed) {
        _switchToForegroundLocation();
      }
    }
  }

  Future<void> _switchToBackgroundLocation() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    LogHelper.staticLogInfo("[BG] Switching to background...");

    await _positionStream?.cancel();

    if (!await PermissionHelper.isProperLocationPermissionGranted()) {
      LogHelper.staticLogError("[BG] Permission lost!");
      _streamController.sink.add({"time": -1, "distance": -1});
      return;
    }

    _resetPosition = true;
    await bg.BackgroundLocation.startLocationService(distanceFilter: config.locationDistanceFilter.toDouble());
    bg.BackgroundLocation.getLocationUpdates(_handleBackgroundUpdate);
  }

  Future<void> _switchToForegroundLocation() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    LogHelper.staticLogInfo("[FG] Switching to foreground...");

    try {
      await bg.BackgroundLocation.stopLocationService();
    } catch (e) {
      LogHelper.staticLogError("[FG] Failed to stop background: $e");
    }

    _resetPosition = true;
    if (!await PermissionHelper.isProperLocationPermissionGranted()) {
      LogHelper.staticLogError("[FG] Permission lost!");
      _streamController.sink.add({"time": -1, "distance": -1});
      return;
    }

    _startPositionStream();
  }
}
