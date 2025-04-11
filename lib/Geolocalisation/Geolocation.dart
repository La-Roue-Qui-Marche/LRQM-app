import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:background_location/background_location.dart' as bg;
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'package:lrqm/API/NewMeasureController.dart';
import 'package:lrqm/Data/SessionDistanceData.dart';
import 'package:lrqm/Data/TimeData.dart';
import 'package:lrqm/Utils/config.dart';
import 'package:lrqm/Utils/LogHelper.dart';
import '../Utils/Permission.dart';

class Geolocation with WidgetsBindingObserver {
  late geo.LocationSettings _settings;
  geo.Position? _oldPos;
  StreamSubscription<geo.Position>? _positionStream;
  Timer? _timeTimer;

  final StreamController<Map<String, int>> _streamController = StreamController<Map<String, int>>();
  bool _positionStreamStarted = false;
  bool _isInBackground = false;

  int _distance = 0;
  int _lastSentDistance = 0;
  int _totalDistanceSent = 0;
  int _outsideCounter = 0;
  DateTime _startTime = DateTime.now();

  Geolocation() {
    _settings = _getSettings();
    WidgetsBinding.instance.addObserver(this);
  }

  Stream<Map<String, int>> get stream => _streamController.stream;

  geo.LocationSettings _getSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return geo.AndroidSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: const geo.ForegroundNotificationConfig(
          notificationText: "Tracking in progress...",
          notificationTitle: "RQM Background Tracking",
          enableWakeLock: true,
          notificationIcon: geo.AndroidResource(name: 'launcher_icon', defType: 'mipmap'),
        ),
      );
    } else {
      return const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 5,
      );
    }
  }

  Future<void> startListening() async {
    log("[GEO] Starting geolocation...");
    if (_positionStreamStarted || !(await PermissionHelper.checkPermissionAlways())) {
      _streamController.sink.add({"time": -1, "distance": -1});
      return;
    }

    _positionStreamStarted = true;
    _startTime = DateTime.now();
    _distance = 0;
    _outsideCounter = 0;

    final resetSuccess = await SessionDistanceData.resetTotalDistance();
    LogHelper.logInfo(resetSuccess ? "[GEO] Total distance reset." : "[GEO] Failed to reset distance.");

    _lastSentDistance = await SessionDistanceData.getTotalDistance() ?? 0;
    _oldPos = await geo.Geolocator.getCurrentPosition();

    _timeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _streamController.sink.add({"time": _elapsedTimeInSeconds, "distance": _distance});
    });

    _positionStream = geo.Geolocator.getPositionStream(locationSettings: _settings).listen(_handleForegroundUpdate);

    LogHelper.logInfo("[GEO] Geolocation started in foreground.");
  }

  int get _elapsedTimeInSeconds => DateTime.now().difference(_startTime).inSeconds;

  void _handleForegroundUpdate(geo.Position position) {
    _processPositionUpdate(
        position.latitude, position.longitude, position.accuracy, position.timestamp ?? DateTime.now());
  }

  void _handleBackgroundUpdate(bg.Location location) {
    _processPositionUpdate(location.latitude ?? 0, location.longitude ?? 0, location.accuracy ?? 20, DateTime.now());
  }

  void _processPositionUpdate(double lat, double lng, double acc, DateTime timestamp) async {
    LogHelper.logInfo("[GEO] Update: Lat=$lat, Lng=$lng, Acc=${acc.toStringAsFixed(1)}m");

    if (_oldPos == null) {
      _saveOldPos(lat, lng, acc, timestamp);
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

    if (acc > 20 || dist > 50 || speed > 10) {
      LogHelper.logWarn(
          "[GEO] Filtered point: dist=$dist m, speed=${speed.toStringAsFixed(2)} m/s, acc=${acc.toStringAsFixed(1)}");
      _saveOldPos(lat, lng, acc, timestamp);
      return;
    }

    _saveOldPos(lat, lng, acc, timestamp);
    _distance += dist;

    if (!isLocationInZone(lat, lng)) {
      _outsideCounter++;
      LogHelper.logWarn("[ZONE] Outside zone. Counter: $_outsideCounter");
      if (_outsideCounter > 5) {
        LogHelper.logError("[ZONE] Outside too long, stopping tracking!");
        _streamController.sink.add({"time": _elapsedTimeInSeconds, "distance": -1});
        stopListening();
        return;
      }
    } else {
      _outsideCounter = 0;
      final diff = _distance - _lastSentDistance;
      if (diff > 0) await _sendDistanceToServer(diff);
    }

    if (!_streamController.isClosed) {
      _streamController.sink.add({"time": _elapsedTimeInSeconds, "distance": _distance});
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

  Future<void> _sendDistanceToServer(int diff) async {
    final response = await NewMeasureController.editMeters(diff);
    if (response.error != null) {
      LogHelper.logError("[API] Failed to send distance: ${response.error}");
      return;
    }

    _totalDistanceSent += diff;
    _lastSentDistance = _distance;

    await SessionDistanceData.saveTotalDistance(_lastSentDistance);
    await TimeData.saveSessionTime(_elapsedTimeInSeconds);

    if (_totalDistanceSent != _lastSentDistance) {
      LogHelper.logWarn("[API] Total sent vs saved mismatch.");
    }

    LogHelper.logInfo("[API] Sent $diff m. Total=${_totalDistanceSent}m");
  }

  void stopListening() async {
    if (!_positionStreamStarted) return;
    LogHelper.logInfo("[GEO] Stopping geolocation...");
    _positionStream?.cancel();
    _timeTimer?.cancel();
    _streamController.close();
    _positionStreamStarted = false;
    await bg.BackgroundLocation.stopLocationService();
    log("[GEO] Geolocation stopped.");
  }

  bool isLocationInZone(double lat, double lng) {
    final pos = mp.LatLng(lat, lng);
    return mp.PolygonUtil.containsLocation(pos, Config.ZONE_EVENT, false);
  }

  Future<bool> isInZone() async {
    final pos = await geo.Geolocator.getCurrentPosition();
    return isLocationInZone(pos.latitude, pos.longitude);
  }

  Future<double> distanceToZone() async {
    final pos = await geo.Geolocator.getCurrentPosition();
    if (isLocationInZone(pos.latitude, pos.longitude)) return -1;

    final currentPoint = mp.LatLng(pos.latitude, pos.longitude);
    double minDistance = double.infinity;

    for (int i = 0; i < Config.ZONE_EVENT.length; i++) {
      final p1 = Config.ZONE_EVENT[i];
      final p2 = Config.ZONE_EVENT[(i + 1) % Config.ZONE_EVENT.length];
      final dist = mp.PolygonUtil.distanceToLine(currentPoint, p1, p2).toDouble();
      if (dist < minDistance) minDistance = dist;
    }

    return double.parse((minDistance / 1000).toStringAsFixed(1)); // in km
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_positionStreamStarted) return;

    if (state == AppLifecycleState.paused) {
      _isInBackground = true;
      _switchToBackgroundLocation();
    } else if (state == AppLifecycleState.resumed) {
      _isInBackground = false;
      _switchToForegroundLocation();
    }
  }

  Future<void> _switchToBackgroundLocation() async {
    LogHelper.logInfo("[BG] Switching to background tracking...");
    await _positionStream?.cancel();
    await bg.BackgroundLocation.startLocationService(distanceFilter: 5);
    bg.BackgroundLocation.getLocationUpdates(_handleBackgroundUpdate);
  }

  Future<void> _switchToForegroundLocation() async {
    LogHelper.logInfo("[FG] Switching to foreground tracking...");
    await bg.BackgroundLocation.stopLocationService();
    _positionStream = geo.Geolocator.getPositionStream(locationSettings: _settings).listen(_handleForegroundUpdate);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    stopListening();
  }
}
