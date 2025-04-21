import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:background_location/background_location.dart' as bg;
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'package:lrqm/API/NewMeasureController.dart';
import 'package:lrqm/Utils/LogHelper.dart';
import '../Utils/Permission.dart';
import '../Data/EventData.dart';
import '../Data/MeasureData.dart';

class GeolocationConfig {
  final Duration locationUpdateInterval;
  final int locationDistanceFilter;
  final geo.LocationAccuracy locationAccuracy;
  final Duration apiInterval;
  final int maxChunkSize;
  final double accuracyThreshold;
  final int distanceThreshold;
  final double speedThreshold;
  final int outsideCounterMax;
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
    this.accuracyThreshold = 20,
    this.distanceThreshold = 50,
    this.speedThreshold = 10,
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
    _initZone();
  }

  late geo.LocationSettings _settings;
  geo.Position? _oldPos;
  StreamSubscription<geo.Position>? _positionStream;
  Timer? _apiTimer;
  Timer? _streamTimer;
  Timer? _silenceCheckTimer;

  final Stopwatch _gpsSilenceStopwatch = Stopwatch();
  final StreamController<Map<String, int>> _streamController = StreamController<Map<String, int>>.broadcast();

  bool _positionStreamStarted = false;
  int _distance = 0;
  int _outsideCounter = 0;
  DateTime _startTime = DateTime.now();
  bool _resetPosition = false;
  bool _isSending = false;
  bool _isCountingInZone = true;

  List<mp.LatLng>? _zonePoints;

  Stream<Map<String, int>> get stream => _streamController.stream;

  Future<void> _initZone() async {
    _zonePoints = await EventData.getSiteCoordLatLngList();
  }

  Future<geo.Position?> get currentPosition async {
    if (!await PermissionHelper.requestLocationWhenInUsePermission()) {
      LogHelper.logError("[GEO] Location permission not granted.");
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

  int get _elapsedTimeInSeconds => DateTime.now().difference(_startTime).inSeconds;

  Future<void> startListening() async {
    LogHelper.logInfo("[GEO] Starting geolocation...");

    if (_positionStreamStarted || !(await PermissionHelper.isLocationAlwaysGranted())) {
      LogHelper.logError("Permission not granted or already started.");
      _streamController.sink.add({"time": -1, "distance": -1});
      return;
    }

    await MeasureData.clearMeasureData();

    _positionStreamStarted = true;
    _startTime = DateTime.now();
    _distance = 0;
    _outsideCounter = 0;

    _oldPos = await geo.Geolocator.getCurrentPosition();
    _resetPosition = false;

    _gpsSilenceStopwatch.reset();
    _gpsSilenceStopwatch.start();

    _startPositionStream();

    _apiTimer = Timer.periodic(config.apiInterval, (_) {
      _sendCurrentDistance();
    });

    _streamTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_streamController.isClosed) {
        _streamController.sink.add({
          "time": _elapsedTimeInSeconds,
          "distance": _distance,
          "isCountingInZone": _isCountingInZone ? 1 : 0,
        });
      }
    });

    _silenceCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_gpsSilenceStopwatch.elapsed.inSeconds >= 10) {
        LogHelper.logInfo("[GEO] No GPS update in 10s , recording stationary point...");
        _recordStationaryPoint();
        _gpsSilenceStopwatch.reset();
        _gpsSilenceStopwatch.start();
      }
    });

    LogHelper.logInfo("[GEO] Geolocation started.");
  }

  void _startPositionStream() {
    _positionStream =
        geo.Geolocator.getPositionStream(locationSettings: _settings).listen(_handleForegroundUpdate, onError: (error) {
      LogHelper.logError("[GEO] Position stream error: $error");
    });
  }

  void _handleForegroundUpdate(geo.Position position) {
    _gpsSilenceStopwatch.reset();
    _gpsSilenceStopwatch.start();

    _processPositionUpdate(
      position.latitude,
      position.longitude,
      position.accuracy,
      position.timestamp ?? DateTime.now(),
    );
  }

  void _handleBackgroundUpdate(bg.Location location) {
    _gpsSilenceStopwatch.reset();
    _gpsSilenceStopwatch.start();

    _processPositionUpdate(
      location.latitude ?? 0,
      location.longitude ?? 0,
      location.accuracy ?? config.accuracyThreshold,
      DateTime.now(),
    );
  }

  Future<void> _recordStationaryPoint() async {
    if (_oldPos != null) {
      await MeasureData.addMeasurePoint(
        distance: _distance.toDouble(),
        speed: 0.0,
        acc: _oldPos!.accuracy,
        timestamp: DateTime.now(),
        lat: _oldPos!.latitude,
        lng: _oldPos!.longitude,
        duration: _elapsedTimeInSeconds, // Add duration
      );
      LogHelper.logInfo("[GEO] Recorded stationary point at ${_oldPos!.latitude}, ${_oldPos!.longitude}");
    } else {
      LogHelper.logError("[GEO] Cannot record stationary point: no previous position available");
    }
  }

  void _processPositionUpdate(double lat, double lng, double acc, DateTime timestamp) async {
    if (_resetPosition || _oldPos == null) {
      LogHelper.logInfo("[GEO] First update or reset position. Acc=${acc.toStringAsFixed(1)}m");
      _saveOldPos(lat, lng, acc, timestamp);
      _resetPosition = false;
      _streamController.sink.add({
        "time": _elapsedTimeInSeconds,
        "distance": _distance,
        "isCountingInZone": _isCountingInZone ? 1 : 0,
      });
      return;
    }

    final dist = geo.Geolocator.distanceBetween(_oldPos!.latitude, _oldPos!.longitude, lat, lng).round();
    final timeDiff = timestamp.difference(_oldPos!.timestamp ?? DateTime.now()).inSeconds;
    final speed = timeDiff > 0 ? dist / timeDiff : 0;

    if (acc > config.accuracyThreshold || dist > config.distanceThreshold || speed > config.speedThreshold) {
      LogHelper.logWarn("[GEO] Filtered point. acc=$acc, dist=$dist, speed=$speed");
      _saveOldPos(lat, lng, acc, timestamp);
      return;
    }

    final inZone = await isLocationInZone(lat, lng);
    if (inZone) {
      if (!_isCountingInZone) LogHelper.logInfo("[ZONE] Re-entered zone.");
      _outsideCounter = 0;
      _isCountingInZone = true;
      _distance += dist;
    } else {
      _outsideCounter++;
      if (_outsideCounter > config.outsideCounterMax) {
        if (_isCountingInZone) LogHelper.logError("[ZONE] Outside too long, pausing count.");
        _isCountingInZone = false;
        _saveOldPos(lat, lng, acc, timestamp);
        return;
      } else {
        _distance += dist;
      }
    }

    await MeasureData.addMeasurePoint(
      distance: _distance.toDouble(),
      speed: speed.toDouble(),
      acc: acc.toDouble(),
      timestamp: timestamp,
      lat: lat,
      lng: lng,
      duration: _elapsedTimeInSeconds, // Add duration
    );

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
        LogHelper.logInfo("[API] Sent current distance: $_distance m");
      }
    } catch (e) {
      LogHelper.logError("[API] Exception while sending distance: $e");
    } finally {
      _isSending = false;
    }
  }

  Future<void> _sendFinalDistance() async {
    LogHelper.logInfo("[GEO] Sending final distance $_distance m...");
    try {
      final response = await NewMeasureController.editMeters(_distance);
      if (response.error != null) {
        LogHelper.logError("[API] Failed to send final distance: ${response.error}");
      } else {
        LogHelper.logInfo("[API] Sent final distance: $_distance m");
      }
    } catch (e) {
      LogHelper.logError("[API] Exception sending final distance: $e");
    }
  }

  Future<void> stopListening() async {
    if (!_positionStreamStarted) return;
    LogHelper.logInfo("[GEO] Stopping geolocation...");

    _positionStreamStarted = false;

    try {
      await _positionStream?.cancel();
      _apiTimer?.cancel();
      _streamTimer?.cancel();
      _silenceCheckTimer?.cancel();
      _gpsSilenceStopwatch.stop();

      await _sendFinalDistance();

      if (!_streamController.isClosed) {
        _streamController.close();
      }

      await bg.BackgroundLocation.stopLocationService();

      final result = await NewMeasureController.stopMeasure();
      if (result.value == true) {
        await MeasureData.clearMeasureData();
        LogHelper.logInfo("[GEO] Measure stopped successfully.");
      } else {
        LogHelper.logError("[GEO] Failed to stop measure: ${result.error}");
      }
    } catch (e) {
      LogHelper.logError("[GEO] Error during stop: $e");
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
    LogHelper.logInfo("[BG] Switching to background...");
    await _positionStream?.cancel();

    if (!await PermissionHelper.isLocationAlwaysGranted()) {
      LogHelper.logError("[BG] Permission lost!");
      _streamController.sink.add({"time": -1, "distance": -1});
      return;
    }

    _resetPosition = true;
    await bg.BackgroundLocation.startLocationService(distanceFilter: config.locationDistanceFilter.toDouble());
    bg.BackgroundLocation.getLocationUpdates(_handleBackgroundUpdate);
  }

  Future<void> _switchToForegroundLocation() async {
    LogHelper.logInfo("[FG] Switching to foreground...");
    try {
      await bg.BackgroundLocation.stopLocationService();
    } catch (e) {
      LogHelper.logError("[FG] Failed to stop background: $e");
    }

    _resetPosition = true;
    if (!await PermissionHelper.isLocationAlwaysGranted()) {
      LogHelper.logError("[FG] Permission lost!");
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
