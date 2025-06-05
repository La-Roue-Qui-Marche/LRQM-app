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
import 'package:lrqm/geo/geolocation_log.dart';

class GeolocationConfig {
  final int locationDistanceFilter;
  final geo.LocationAccuracy locationAccuracy;
  final Duration apiInterval;
  final int outsideCounterMax;
  final String notificationTitle;
  final String notificationText;
  final String notificationIconName;
  final String notificationIconType;

  GeolocationConfig({
    this.locationDistanceFilter = 5,
    this.locationAccuracy = geo.LocationAccuracy.bestForNavigation,
    this.apiInterval = const Duration(seconds: 10),
    this.outsideCounterMax = 5,
    this.notificationTitle = "La RQM Background Tracking",
    this.notificationText = "Tracking in progress...",
    this.notificationIconName = 'launcher_icon',
    this.notificationIconType = 'mipmap',
  });
}

class GeolocationController with WidgetsBindingObserver {
  final GeolocationConfig config;
  static GeolocationController? _instance;

  // Static method to reset the singleton instance
  static void resetInstance() {
    if (_instance != null) {
      LogHelper.staticLogInfo("[GEO] Resetting GeolocationController instance");
      _instance!.cleanup();
      _instance = null;
    }
  }

  // Factory constructor for singleton pattern
  factory GeolocationController({required GeolocationConfig config}) {
    _instance ??= GeolocationController._internal(config);
    return _instance!;
  }

  // Private constructor
  GeolocationController._internal(this.config) {
    _settings = _getSettings();
    WidgetsBinding.instance.addObserver(this);
    _initZone();
    LogHelper.staticLogInfo("[GEO] GeolocationController initialized");
  }

  late geo.LocationSettings _settings;
  late SimpleLocationKalmanFilter2D _kalmanFilter;
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

  Duration _accumulatedActiveDuration = Duration.zero;
  DateTime? _lastActiveTimestamp;

  List<mp.LatLng>? _zonePoints;

  Stream<Map<String, int>> get stream => _streamController.stream;

  int get currentDistance => _distance;

  int get elapsedTimeInSeconds {
    if (_isCountingInZone && _lastActiveTimestamp != null) {
      return (_accumulatedActiveDuration + DateTime.now().difference(_lastActiveTimestamp!)).inSeconds;
    }
    return _accumulatedActiveDuration.inSeconds;
  }

  bool get isCountingInZone => _isCountingInZone;

  Future<void> _initZone() async {
    _zonePoints = await EventData.getSiteCoordLatLngList();
  }

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

  Future<void> startListening() async {
    LogHelper.staticLogInfo("[GEO] Starting geolocation...");

    await MeasureData.clearMeasurePoints();
    if (_positionStreamStarted || !(await PermissionHelper.isProperLocationPermissionGranted())) {
      LogHelper.staticLogError("Permission not granted or already started.");
      _streamController.sink.add({"time": -1, "distance": -1});
      return;
    }
    _positionStreamStarted = true;
    _distance = 0;
    _outsideCounter = 0;
    _accumulatedActiveDuration = Duration.zero;
    _lastActiveTimestamp = DateTime.now();
    final initialPos = await geo.Geolocator.getCurrentPosition();
    _kalmanFilter = SimpleLocationKalmanFilter2D(initialLat: initialPos.latitude, initialLng: initialPos.longitude);
    _oldPos = initialPos;
    _resetPosition = false;
    _startPositionStream();
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
    LogHelper.staticLogInfo("[GEO] Geolocation started.");
  }

  void _startPositionStream() {
    _positionStream =
        geo.Geolocator.getPositionStream(locationSettings: _settings).listen(_handleForegroundUpdate, onError: (error) {
      LogHelper.staticLogError("[GEO] Position stream error: $error");
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
    if (_resetPosition || _oldPos == null) {
      LogHelper.staticLogInfo("[GEO] First update or reset position. Acc=${acc.toStringAsFixed(1)}m");
      _saveOldPos(lat, lng, acc, timestamp);
      _resetPosition = false;
      return;
    }

    // Update Kalman filter with the new measurement
    final filteredPosition = _kalmanFilter.update(lat, lng, acc, timestamp.millisecondsSinceEpoch / 1000.0);

    // Calculate distance using filtered position
    final dist = geo.Geolocator.distanceBetween(
            _oldPos!.latitude, _oldPos!.longitude, filteredPosition['latitude']!, filteredPosition['longitude']!)
        .round();

    final inZone = await isLocationInZone(filteredPosition['latitude']!, filteredPosition['longitude']!);
    _handleZoneLogic(inZone, dist); // Calculate raw distance and speed from unfiltered positions
    final rawDist = geo.Geolocator.distanceBetween(_oldPos!.latitude, _oldPos!.longitude, lat, lng).round();
    final timeDiffSec = timestamp.difference(_oldPos!.timestamp).inMilliseconds / 1000;
    double rawSpeed = 0.0;
    if (timeDiffSec > 0.5) {
      rawSpeed = geo.Geolocator.distanceBetween(_oldPos!.latitude, _oldPos!.longitude, lat, lng) / timeDiffSec;
    }

    // Log position comparison with accuracy using the imported method
    LogHelper.staticLogInfo(formatPositionComparison(
      elapsedTime: elapsedTimeInSeconds,
      filteredPosition: {
        // Changed from smoothedPosition
        'latitude': filteredPosition['latitude']!,
        'longitude': filteredPosition['longitude']!,
        'speed': filteredPosition['speed']!,
      },
      lat: lat,
      lng: lng,
      rawSpeed: rawSpeed,
      rawAccuracy: acc,
      dist: dist,
      rawDist: rawDist,
      timestamp: timestamp,
      uncertainty: filteredPosition['uncertainty']!,
      confidence: filteredPosition['confidence']!,
    ));

    // Save measurement data
    await MeasureData.addMeasurePoint(
      distance: _distance.toDouble(),
      speed: filteredPosition['speed']!,
      acc: filteredPosition['uncertainty']!,
      timestamp: timestamp,
      lat: filteredPosition['latitude']!,
      lng: filteredPosition['longitude']!,
      duration: elapsedTimeInSeconds,
    );

    // Update last known position
    _saveOldPos(
        filteredPosition['latitude']!, filteredPosition['longitude']!, filteredPosition['uncertainty']!, timestamp);
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

  void _saveOldPos(double lat, double lng, double acc, DateTime timestamp) {
    _oldPos = geo.Position(
      latitude: lat,
      longitude: lng,
      accuracy: acc,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
      timestamp: timestamp,
      altitude: 0,
      heading: 0,
      speed: 0,
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

    _positionStreamStarted = false;
    try {
      await _positionStream?.cancel();
      _apiTimer?.cancel();
      _streamTimer?.cancel();

      if (!_streamController.isClosed) {
        await _streamController.close();
      }

      await bg.BackgroundLocation.stopLocationService();
      return true;
    } catch (e) {
      LogHelper.staticLogError("[GEO] Error during cleanup: $e");
      return false;
    }
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
    LogHelper.staticLogInfo("[GEO] Force stop completed.");
  }

  Future<bool> isLocationInZone(double lat, double lng) async {
    final pos = mp.LatLng(lat, lng);
    final zone = _zonePoints;
    if (zone == null) return false;
    return mp.PolygonUtil.containsLocation(pos, zone, false);
  }

  Future<bool> isInZone() async {
    if (!await PermissionHelper.isProperLocationPermissionGranted()) {
      LogHelper.staticLogError("[GEO] Location permission not granted.");
      return false;
    }
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
    return double.parse((minDistance / 1000).toStringAsFixed(1));
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

  void cleanup() {
    WidgetsBinding.instance.removeObserver(this);
    stopListening();
  }
}
