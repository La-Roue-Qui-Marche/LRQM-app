import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'package:lrqm/API/NewMeasureController.dart';
import 'package:lrqm/Data/SessionDistanceData.dart';
import 'package:lrqm/Data/TimeData.dart';
import 'package:lrqm/Utils/config.dart';
import 'package:lrqm/Utils/LogHelper.dart';

class Geolocation {
  late StreamSubscription<geo.Position> _positionStream;
  late geo.LocationSettings _settings;
  geo.Position? _oldPos;
  int _distance = 0;
  int _lastSentDistance = 0;
  int _mesureToWait = 3;
  int _outsideCounter = 0;
  DateTime _startTime = DateTime.now();
  bool _positionStreamStarted = false;
  int _totalDistanceSent = 0; // Track the total distance sent to the server

  final StreamController<Map<String, int>> _streamController = StreamController<Map<String, int>>();
  Timer? _timeTimer;

  Geolocation() {
    _settings = _getSettings();
  }

  Stream<Map<String, int>> get stream => _streamController.stream;

  // Permissions
  static Future<bool> handlePermission() async {
    final geo.GeolocatorPlatform geoPlatform = geo.GeolocatorPlatform.instance;

    if (!await geoPlatform.isLocationServiceEnabled()) {
      LogHelper.writeLog("Location services are disabled.");
      return false;
    }

    geo.LocationPermission permission = await geoPlatform.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await geoPlatform.requestPermission();
      if (permission == geo.LocationPermission.denied) return false;
    }

    if (permission == geo.LocationPermission.deniedForever) {
      LogHelper.writeLog("Location permissions are permanently denied.");
      return false;
    }

    return true;
  }

  // Platform-specific settings
  geo.LocationSettings _getSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return geo.AndroidSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 5,
        intervalDuration: const Duration(seconds: 5),
        foregroundNotificationConfig: const geo.ForegroundNotificationConfig(
          notificationText: "Pas de panique, c'est la RQM qui vous suit!",
          notificationTitle: "Running in Background",
          enableWakeLock: true,
          notificationIcon: geo.AndroidResource(name: 'launcher_icon', defType: 'mipmap'),
        ),
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS) {
      return geo.AppleSettings(
        accuracy: geo.LocationAccuracy.high,
        activityType: geo.ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    } else {
      return const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 5,
      );
    }
  }

  // Start geolocation tracking
  Future<void> startListening() async {
    log("Attempting to start position stream...");
    LogHelper.logInfo("Starting geolocation tracking...");

    // Reset the total distance to 0 at the start of a measure
    final resetSuccess = await SessionDistanceData.resetTotalDistance();
    if (resetSuccess) {
      LogHelper.logInfo("Successfully reset total distance to 0.");
    } else {
      LogHelper.logWarn("Failed to reset total distance to 0.");
    }

    if (_positionStreamStarted || !(await handlePermission())) {
      _streamController.sink.add({"time": -1, "distance": -1});
      return;
    }

    _positionStreamStarted = true;
    _startTime = DateTime.now();
    _distance = 0;
    _outsideCounter = 0;

    _lastSentDistance = await SessionDistanceData.getTotalDistance() ?? 0;

    _timeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final seconds = DateTime.now().difference(_startTime).inSeconds;
      _streamController.sink.add({"time": seconds, "distance": _distance});
    });

    _oldPos = await geo.Geolocator.getCurrentPosition();

    _positionStream = geo.Geolocator.getPositionStream(locationSettings: _settings).listen(_handlePositionUpdate);
  }

  void _handlePositionUpdate(geo.Position position) async {
    LogHelper.logInfo(
        "Position updated: Lat=${position.latitude}, Lng=${position.longitude}, Acc=${position.accuracy}");

    if (!_positionStreamStarted) {
      LogHelper.logWarn("Position update received but no session is active. Ignoring update.");
      return;
    }

    if (_mesureToWait > 0) {
      _oldPos = position;
      _mesureToWait--;
      return;
    }

    if (_oldPos == null) {
      _oldPos = position;
      return;
    }

    final dist = geo.Geolocator.distanceBetween(
      _oldPos!.latitude,
      _oldPos!.longitude,
      position.latitude,
      position.longitude,
    ).round();

    final timeDiffSec = position.timestamp?.difference(_oldPos!.timestamp ?? DateTime.now()).inSeconds ?? 1;
    final speed = timeDiffSec > 0 ? dist / timeDiffSec : 0;

    // Filter: ignore noisy data
    if (position.accuracy > 20 || dist > 50 || speed > 10) {
      LogHelper.logWarn("Filtered GPS point: $dist m @ ${speed.toStringAsFixed(2)} m/s, acc=${position.accuracy}");
      _oldPos = position; // Save the old position even if the point is filtered
      return;
    }

    _oldPos = position;
    _distance += dist;

    if (!isLocationInZone(position)) {
      _outsideCounter++;
      LogHelper.logWarn("User outside zone. Outside counter: $_outsideCounter");
      if (_outsideCounter > 5) {
        LogHelper.logError("User outside too long, stopping...");
        if (!_streamController.isClosed) {
          _streamController.sink.add({"time": DateTime.now().difference(_startTime).inSeconds, "distance": -1});
        }
        stopListening();
        return;
      }
    } else {
      _outsideCounter = 0;
      final diff = _distance - _lastSentDistance;
      if (diff > 0) {
        await _sendDistanceToServer(diff, position);
      }
    }

    if (!_streamController.isClosed) {
      _streamController.sink.add({"time": DateTime.now().difference(_startTime).inSeconds, "distance": _distance});
    }
  }

  Future<void> _sendDistanceToServer(int diff, geo.Position position) async {
    final response = await NewMeasureController.editMeters(diff);
    if (response.error != null) {
      LogHelper.logError("Error sending to server: ${response.error}");
      return;
    }

    _totalDistanceSent += diff; // Update the total distance sent
    _lastSentDistance = _distance;
    await SessionDistanceData.saveTotalDistance(_lastSentDistance);
    await TimeData.saveSessionTime(DateTime.now().difference(_startTime).inSeconds);

    // Compare total distance sent to the saved distance
    if (_totalDistanceSent != _lastSentDistance) {
      LogHelper.logWarn(
          "Discrepancy detected: Total distance sent ($_totalDistanceSent m) does not match saved distance ($_lastSentDistance m).");
    }

    LogHelper.logInfo(
        "Distance sent: $diff m — Total sent: $_totalDistanceSent m — Total saved: $_lastSentDistance m ");
  }

  void stopListening() {
    if (_positionStreamStarted) {
      LogHelper.logInfo("Stopping geolocation tracking...");
      _positionStream.cancel();
      _timeTimer?.cancel();
      _streamController.close();
      _positionStreamStarted = false;
      log("Position stream stopped.");
    }
  }

  bool isLocationInZone(geo.Position point) {
    final pos = mp.LatLng(point.latitude, point.longitude);
    return mp.PolygonUtil.containsLocation(pos, Config.ZONE_EVENT, false);
  }

  Future<bool> isInZone() async {
    final pos = await geo.Geolocator.getCurrentPosition();
    return isLocationInZone(pos);
  }

  Future<double> distanceToZone() async {
    final pos = await geo.Geolocator.getCurrentPosition();
    if (isLocationInZone(pos)) return -1;

    final currentPoint = mp.LatLng(pos.latitude, pos.longitude);
    double minDistance = double.infinity;

    for (int i = 0; i < Config.ZONE_EVENT.length; i++) {
      final p1 = Config.ZONE_EVENT[i];
      final p2 = Config.ZONE_EVENT[(i + 1) % Config.ZONE_EVENT.length];
      final dist = mp.PolygonUtil.distanceToLine(currentPoint, p1, p2).toDouble();
      if (dist < minDistance) minDistance = dist;
    }

    return double.parse((minDistance / 1000).toStringAsFixed(1));
  }
}
