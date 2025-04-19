import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:background_location/background_location.dart' as bg;
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'package:lrqm/API/NewMeasureController.dart';
import 'package:lrqm/Utils/config.dart';
import 'package:lrqm/Utils/LogHelper.dart';
import '../Utils/Permission.dart';
import '../Data/EventData.dart';

/// Configuration parameters for geolocation tracking.
class GeolocationConfig {
  /// How often (and with what accuracy) the location should be updated.
  final Duration locationUpdateInterval;
  final int locationDistanceFilter;
  final geo.LocationAccuracy locationAccuracy;

  /// The interval used for API calls to send the distance diff.
  final Duration apiInterval;

  /// The maximum chunk of data to send in one API call.
  final int maxChunkSize;

  /// Filtering thresholds to help ignore spurious location updates.
  final double accuracyThreshold; // meters threshold
  final int distanceThreshold; // meters threshold
  final double speedThreshold; // m/s threshold

  /// Number of consecutive updates outside the zone before pausing counting.
  final int outsideCounterMax;

  /// Notification configuration for Android foreground service.
  final String notificationTitle;
  final String notificationText;
  final String notificationIconName;
  final String notificationIconType;

  GeolocationConfig({
    this.locationUpdateInterval = const Duration(seconds: 5),
    this.locationDistanceFilter = 5,
    this.locationAccuracy = geo.LocationAccuracy.bestForNavigation,
    this.apiInterval = const Duration(seconds: 10),
    this.maxChunkSize = 40,
    this.accuracyThreshold = 20, // meters
    this.distanceThreshold = 50, // meters
    this.speedThreshold = 10, // m/s
    this.outsideCounterMax = 10,
    this.notificationTitle = "La RQM Background Tracking",
    this.notificationText = "Tracking in progress...",
    this.notificationIconName = 'launcher_icon',
    this.notificationIconType = 'mipmap',
  });
}

class Geolocation with WidgetsBindingObserver {
  final GeolocationConfig config;

  Geolocation({required this.config}) {
    _settings = _getSettings();
    WidgetsBinding.instance.addObserver(this);
    _initZone(); // Called here, not in initState
  }

  Future<void> _initZone() async {
    _zonePoints = await EventData.getSiteCoordLatLngList();
  }

  late geo.LocationSettings _settings;
  geo.Position? _oldPos;
  StreamSubscription<geo.Position>? _positionStream;
  Timer? _apiTimer;
  Timer? _streamTimer; // Timer for periodic stream updates
  final StreamController<Map<String, int>> _streamController = StreamController<Map<String, int>>.broadcast();

  bool _positionStreamStarted = false;
  int _distance = 0;
  int _totalDistanceSent = 0;
  int _outsideCounter = 0;
  DateTime _startTime = DateTime.now();
  bool _resetPosition = false;
  bool _isSending = false;
  bool _isCountingInZone = true;

  List<mp.LatLng>? _zonePoints;

  Stream<Map<String, int>> get stream => _streamController.stream;

  Future<geo.Position?> get currentPosition async {
    if (!await PermissionHelper.requestLocationWhenInUsePermission()) {
      LogHelper.logError("[GEO] Location permission not granted. Cannot get current position.");
      return null;
    }
    try {
      return await geo.Geolocator.getCurrentPosition();
    } catch (e) {
      LogHelper.logError("[GEO] Failed to get current position: $e");
      return null;
    }
  }

  geo.LocationSettings _getSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return geo.AndroidSettings(
        accuracy: config.locationAccuracy,
        distanceFilter: config.locationDistanceFilter,
        intervalDuration: config.locationUpdateInterval,
        forceLocationManager: true,
        foregroundNotificationConfig: geo.ForegroundNotificationConfig(
          notificationText: config.notificationText,
          notificationTitle: config.notificationTitle,
          enableWakeLock: true,
          notificationIcon:
              geo.AndroidResource(name: config.notificationIconName, defType: config.notificationIconType),
        ),
      );
    } else {
      return geo.LocationSettings(
        accuracy: config.locationAccuracy,
        distanceFilter: config.locationDistanceFilter,
      );
    }
  }

  int get _elapsedTimeInSeconds => DateTime.now().difference(_startTime).inSeconds;

  Future<void> startListening() async {
    LogHelper.logInfo("[GEO] Starting geolocation...");
    if (_positionStreamStarted || !(await PermissionHelper.isLocationAlwaysGranted())) {
      LogHelper.logError("Permission not granted or already started.");
      _streamController.sink.add({"time": -1, "distance": -1});
      return;
    }

    _positionStreamStarted = true;
    _startTime = DateTime.now();
    _distance = 0;
    _outsideCounter = 0;
    _totalDistanceSent = 0;

    _oldPos = await geo.Geolocator.getCurrentPosition();
    _resetPosition = false;

    // Start listening to location updates.
    _startPositionStream();

    // Timer used for API calls to send the current total distance.
    _apiTimer = Timer.periodic(config.apiInterval, (_) {
      _sendCurrentDistance();
    });

    // Timer to periodically send stream updates.
    _streamTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_streamController.isClosed) {
        _streamController.sink.add({
          "time": _elapsedTimeInSeconds,
          "distance": _distance,
          "isCountingInZone": _isCountingInZone ? 1 : 0,
        });
      }
    });

    LogHelper.logInfo("[GEO] Geolocation started in foreground.");
  }

  void _startPositionStream() {
    _positionStream =
        geo.Geolocator.getPositionStream(locationSettings: _settings).listen(_handleForegroundUpdate, onError: (error) {
      LogHelper.logError("[GEO] Position stream error: $error");
    });
  }

  void _handleForegroundUpdate(geo.Position position) {
    LogHelper.logInfo("[GEO] Handling foreground update...");
    _processPositionUpdate(
      position.latitude,
      position.longitude,
      position.accuracy,
      position.timestamp ?? DateTime.now(),
    );
  }

  void _handleBackgroundUpdate(bg.Location location) {
    LogHelper.logInfo("[GEO] Handling background update...");
    _processPositionUpdate(
      location.latitude ?? 0,
      location.longitude ?? 0,
      location.accuracy ?? config.accuracyThreshold,
      DateTime.now(),
    );
  }

  void _processPositionUpdate(double lat, double lng, double acc, DateTime timestamp) async {
    LogHelper.logInfo("[GEO] Update: Lat=$lat, Lng=$lng, Acc=${acc.toStringAsFixed(1)}m");

    // On first update or when a reset is needed, record the new position and send an update.
    if (_resetPosition || _oldPos == null) {
      _saveOldPos(lat, lng, acc, timestamp);
      _resetPosition = false;
      if (!_streamController.isClosed) {
        _streamController.sink.add({
          "time": _elapsedTimeInSeconds,
          "distance": _distance,
          "isCountingInZone": _isCountingInZone ? 1 : 0,
        });
      }
      return;
    }

    final dist = geo.Geolocator.distanceBetween(
      _oldPos!.latitude,
      _oldPos!.longitude,
      lat,
      lng,
    ).round();

    final timeDiff = timestamp.difference(_oldPos!.timestamp ?? DateTime.now()).inSeconds;
    final speed = timeDiff > 0 ? dist / timeDiff : 0;

    // Filter out spurious updates.
    if (acc > config.accuracyThreshold || dist > config.distanceThreshold || speed > config.speedThreshold) {
      LogHelper.logWarn(
          "[GEO] Filtered point: dist=$dist m, speed=${speed.toStringAsFixed(2)} m/s, acc=${acc.toStringAsFixed(1)}");
      _saveOldPos(lat, lng, acc, timestamp);
      return;
    }

    final inZone = await isLocationInZone(lat, lng);
    if (inZone) {
      if (!_isCountingInZone) {
        LogHelper.logInfo("[ZONE] User re-entered zone, resuming counting. Resetting baseline.");
        _isCountingInZone = true;
      } else if (_outsideCounter > 0) {
        LogHelper.logInfo("[ZONE] Back in zone. Resetting outside counter.");
      }
      _outsideCounter = 0;
      _distance += dist;
    } else {
      _outsideCounter++;
      LogHelper.logWarn("[ZONE] Outside zone counter: $_outsideCounter");

      if (_outsideCounter <= config.outsideCounterMax) {
        _distance += dist;
      } else {
        if (_isCountingInZone) {
          LogHelper.logError("[ZONE] Outside too long, pausing counting!");
          _isCountingInZone = false;
        }
      }
    }

    _saveOldPos(lat, lng, acc, timestamp);
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
      final response = await NewMeasureController.editMeters(_distance);
      if (response.error != null) {
        LogHelper.logError("[API] Failed to send current distance: ${response.error}");
      } else {
        _totalDistanceSent = _distance;
        LogHelper.logInfo("[API] Sent current distance: $_distance m");
      }
    } catch (e) {
      LogHelper.logError("[API] Exception in sending current distance: $e");
    } finally {
      _isSending = false;
    }
  }

  Future<void> _sendFinalDistance() async {
    LogHelper.logInfo("[GEO] Sending final distance ($_distance m) before stopping...");
    try {
      final response = await NewMeasureController.editMeters(_distance);
      if (response.error != null) {
        LogHelper.logError("[API] Failed to send final distance: ${response.error}");
      } else {
        _totalDistanceSent = _distance;
        LogHelper.logInfo("[API] Sent final distance: $_distance m");
      }
    } catch (e) {
      LogHelper.logError("[API] Exception in sending final distance: $e");
    }
  }

  Future<void> stopListening() async {
    if (!_positionStreamStarted) return;
    LogHelper.logInfo("[GEO] Stopping geolocation...");

    try {
      await _positionStream?.cancel();
      _positionStream = null;

      _apiTimer?.cancel();

      _streamTimer?.cancel();

      await _sendFinalDistance();

      if (!_streamController.isClosed) {
        _streamController.close();
      }

      await bg.BackgroundLocation.stopLocationService();
      _positionStreamStarted = false;

      final result = await NewMeasureController.stopMeasure();
      if (result.value == true) {
        LogHelper.logInfo("[GEO] Measure stopped successfully.");
      } else {
        LogHelper.logError("[GEO] Failed to stop measure: ${result.error}");
      }
    } catch (e) {
      LogHelper.logError("[GEO] Exception during stopListening: $e");
    } finally {
      LogHelper.logInfo("[GEO] Geolocation stopped.");
    }
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
    return double.parse((minDistance / 1000).toStringAsFixed(1));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_positionStreamStarted) return;
    if (state == AppLifecycleState.paused) {
      _switchToBackgroundLocation();
    } else if (state == AppLifecycleState.resumed) {
      _switchToForegroundLocation();
    }
  }

  Future<void> _switchToBackgroundLocation() async {
    LogHelper.logInfo("[BG] Switching to background tracking...");
    await _positionStream?.cancel();
    if (!await PermissionHelper.isLocationAlwaysGranted()) {
      LogHelper.logError("[BG] Permission lost while switching to background!");
      _streamController.sink.add({"time": -1, "distance": -1});
      return;
    }

    _resetPosition = true;
    await bg.BackgroundLocation.startLocationService(
      distanceFilter: config.locationDistanceFilter.toDouble(),
    );
    bg.BackgroundLocation.getLocationUpdates(_handleBackgroundUpdate);
  }

  Future<void> _switchToForegroundLocation() async {
    LogHelper.logInfo("[FG] Switching to foreground tracking...");
    try {
      await bg.BackgroundLocation.stopLocationService();
    } catch (e) {
      LogHelper.logError("[FG] Failed to stop background service: $e");
    }

    _resetPosition = true;
    if (!await PermissionHelper.isLocationAlwaysGranted()) {
      LogHelper.logError("[FG] Permission lost while switching to foreground!");
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
