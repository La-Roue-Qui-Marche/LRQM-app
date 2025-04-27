import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import '../API/NewMeasureController.dart';
import '../Utils/LogHelper.dart';
import '../Utils/Permission.dart';
import '../Data/EventData.dart';
import '../Data/MeasureData.dart';

class GeolocationConfig {
  final int locationDistanceFilter;
  final geo.LocationAccuracy locationAccuracy;
  final Duration apiInterval;
  final double accuracyThreshold;
  final int distanceThreshold;
  final double speedThreshold;
  final int outsideCounterMax;
  final String notificationTitle;
  final String notificationText;

  GeolocationConfig({
    this.locationDistanceFilter = 5,
    this.locationAccuracy = geo.LocationAccuracy.bestForNavigation,
    this.apiInterval = const Duration(seconds: 10),
    this.accuracyThreshold = 20,
    this.distanceThreshold = 50,
    this.speedThreshold = 10,
    this.outsideCounterMax = 10,
    this.notificationTitle = "La RQM Background Tracking",
    this.notificationText = "Tracking in progress...",
  });
}

class Geolocation with WidgetsBindingObserver {
  final GeolocationConfig config;
  Geolocation({required this.config}) {
    _settings = _getSettings();
    WidgetsBinding.instance.addObserver(this);
    _initZone();
  }

  Map<String, int>? lastEvent;
  late geo.LocationSettings _settings;
  geo.Position? _oldPos;
  StreamSubscription<geo.Position>? _positionStream;
  Timer? _apiTimer;
  Timer? _streamTimer;
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
  int get currentDistance => _distance;
  int get elapsedTimeInSeconds => DateTime.now().difference(_startTime).inSeconds;

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
    return geo.LocationSettings(
      accuracy: config.locationAccuracy,
      distanceFilter: config.locationDistanceFilter,
    );
  }

  Future<void> startListening() async {
    LogHelper.logInfo("[GEO] Starting geolocation...");

    await MeasureData.clearMeasurePoints();

    if (_positionStreamStarted || !(await PermissionHelper.isLocationAlwaysGranted())) {
      LogHelper.logError("Permission not granted or already started.");
      _streamController.sink.add({"time": -1, "distance": -1});
      return;
    }

    _positionStreamStarted = true;
    _startTime = DateTime.now();
    _distance = 0;
    _outsideCounter = 0;
    _resetPosition = false;

    lastEvent = {
      "time": 0,
      "distance": 0,
      "isCountingInZone": 1,
      "speed": 0,
    };

    _oldPos = await geo.Geolocator.getCurrentPosition();

    _startPositionStream();

    _apiTimer = Timer.periodic(config.apiInterval, (_) => _sendCurrentDistance());
    _streamTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_streamController.isClosed) {
        _streamController.sink.add({
          "time": elapsedTimeInSeconds,
          "distance": _distance,
          "isCountingInZone": _isCountingInZone ? 1 : 0,
          "speed": 0,
        });
      }
    });

    LogHelper.logInfo("[GEO] Geolocation started.");
  }

  void _startPositionStream() {
    _positionStream = geo.Geolocator.getPositionStream(locationSettings: _settings).listen(
      _handlePositionUpdate,
      onError: (error) => LogHelper.logError("[GEO] Position stream error: $error"),
    );
  }

  void _handlePositionUpdate(geo.Position position) {
    _processPositionUpdate(
      position.latitude,
      position.longitude,
      position.accuracy,
      position.timestamp,
    );
  }

  void _processPositionUpdate(double lat, double lng, double acc, DateTime timestamp) async {
    if (_resetPosition || _oldPos == null) {
      LogHelper.logInfo("[GEO] First update or reset position.");
      _saveOldPos(lat, lng, acc, timestamp);
      _resetPosition = false;
      _streamController.sink.add({
        "time": elapsedTimeInSeconds,
        "distance": _distance,
        "isCountingInZone": _isCountingInZone ? 1 : 0,
        "speed": 0,
      });
      return;
    }

    final dist = geo.Geolocator.distanceBetween(_oldPos!.latitude, _oldPos!.longitude, lat, lng).round();
    final timeDiff = timestamp.difference(_oldPos!.timestamp).inSeconds;
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
      duration: elapsedTimeInSeconds,
    );

    lastEvent = {
      "time": elapsedTimeInSeconds,
      "distance": _distance,
      "isCountingInZone": _isCountingInZone ? 1 : 0,
      "speed": speed.toInt(),
    };

    if (!_streamController.isClosed) {
      _streamController.sink.add(lastEvent!);
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
        LogHelper.logInfo("[API] Sent current distance: $_distance m");
      }
    } catch (e) {
      LogHelper.logError("[API] Exception while sending distance: $e");
    } finally {
      _isSending = false;
    }
  }

  Future<bool> stopListening() async {
    if (!_positionStreamStarted) return false;
    LogHelper.logInfo("[GEO] Stopping geolocation...");

    try {
      await _sendCurrentDistance();
      final result = await NewMeasureController.stopMeasure();
      if (result.value != true) {
        LogHelper.logError("[GEO] Failed to stop measure: ${result.error}");
        return false;
      }
    } catch (e) {
      LogHelper.logError("[GEO] Error during stop measure: $e");
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
      return true;
    } catch (e) {
      LogHelper.logError("[GEO] Error during cleanup: $e");
      return false;
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

  void cleanup() {
    WidgetsBinding.instance.removeObserver(this);
    stopListening();
  }
}
