import 'dart:async';
import 'dart:developer';
import 'package:background_location/background_location.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'package:lrqm/API/NewMeasureController.dart';
import 'package:lrqm/Data/SessionDistanceData.dart';
import 'package:lrqm/Data/TimeData.dart';
import 'package:lrqm/Utils/config.dart';
import 'package:lrqm/Utils/LogHelper.dart';
import 'package:permission_handler/permission_handler.dart';

class Geolocation {
  int _distance = 0;
  int _lastSentDistance = 0;
  int _outsideCounter = 0;
  DateTime _startTime = DateTime.now();
  bool _positionStreamStarted = false;
  int _totalDistanceSent = 0;
  double? _lastLat;
  double? _lastLng;
  DateTime? _lastTimestamp;

  final StreamController<Map<String, int>> _streamController = StreamController<Map<String, int>>();
  Timer? _timeTimer;

  Geolocation();

  Stream<Map<String, int>> get stream => _streamController.stream;

  static Future<bool> handlePermission() async {
    try {
      await BackgroundLocation.setAndroidNotification(
        title: 'Location Tracking',
        message: 'Tracking your location in background',
        icon: '@mipmap/ic_launcher',
      );
      await BackgroundLocation.setAndroidConfiguration(1000);
      return true;
    } catch (e) {
      LogHelper.logError("Permission error: $e");
      return false;
    }
  }

  static Future<bool> checkPermission() async {
    final status = await Permission.locationAlways.status;

    if (status.isGranted) {
      return true;
    }

    final requestStatus = await Permission.locationAlways.request();

    if (requestStatus.isGranted) {
      LogHelper.logInfo("Location permission granted.");
      return true;
    } else {
      LogHelper.logError("Location permission denied.");
      return false;
    }
  }

  Future<void> startListening() async {
    log("Attempting to start BackgroundLocation...");
    LogHelper.logInfo("Starting BackgroundLocation...");

    if (!await checkPermission()) {
      LogHelper.logError("Permission denied, cannot start tracking.");
      _streamController.sink.add({"time": -1, "distance": -1});
      return;
    }

    final resetSuccess = await SessionDistanceData.resetTotalDistance();
    if (resetSuccess) {
      LogHelper.logInfo("Successfully reset total distance to 0.");
    } else {
      LogHelper.logWarn("Failed to reset total distance to 0.");
    }

    if (_positionStreamStarted) {
      _streamController.sink.add({"time": -1, "distance": -1});
      return;
    }

    _positionStreamStarted = true;
    _startTime = DateTime.now();
    _distance = 0;
    _outsideCounter = 0;
    _totalDistanceSent = 0;
    _lastSentDistance = await SessionDistanceData.getTotalDistance() ?? 0;

    _timeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final seconds = DateTime.now().difference(_startTime).inSeconds;
      if (!_streamController.isClosed) {
        _streamController.sink.add({"time": seconds, "distance": _distance});
      }
    });

    await BackgroundLocation.setAndroidNotification(
      title: 'Location Tracking',
      message: 'Tracking your location in background',
      icon: '@mipmap/ic_launcher',
    );
    await BackgroundLocation.setAndroidConfiguration(1000);

    BackgroundLocation.startLocationService(distanceFilter: 5);
    BackgroundLocation.getLocationUpdates(_onLocation);
  }

  void _onLocation(Location location) async {
    if (!_positionStreamStarted) {
      LogHelper.logWarn("Location received but tracking not active. Ignoring.");
      return;
    }

    LogHelper.logInfo("Location update: ${location.latitude}, ${location.longitude}, acc: ${location.accuracy}");

    if (location.accuracy != null && location.accuracy! > 20) {
      LogHelper.logWarn("Bad GPS point (accuracy=${location.accuracy}m), ignoring.");
      _updateLastLocation(location);
      return;
    }

    if (_lastLat == null || _lastLng == null) {
      _updateLastLocation(location);
      return;
    }

    final dist = _calculateDistance(
      _lastLat!,
      _lastLng!,
      location.latitude!,
      location.longitude!,
    ).round();

    final timeDiffSec = _lastTimestamp == null ? 0 : DateTime.now().difference(_lastTimestamp!).inSeconds;

    final speed = timeDiffSec > 0 ? dist / timeDiffSec : 0;

    if (dist > 200 || speed > 30) {
      LogHelper.logWarn("GPS jump detected ($dist m, $speed m/s), ignoring.");
      _updateLastLocation(location);
      return;
    }

    _updateLastLocation(location);
    _distance += dist;

    if (!await _isLocationInZone(location.latitude!, location.longitude!)) {
      _outsideCounter++;
      LogHelper.logWarn("Outside zone detected ($_outsideCounter)");
      if (_outsideCounter > 5) {
        LogHelper.logError("Outside zone for too long, stopping...");
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
        await _sendDistanceToServer(diff);
      }
    }

    if (!_streamController.isClosed) {
      _streamController.sink.add({"time": DateTime.now().difference(_startTime).inSeconds, "distance": _distance});
    }
  }

  void _updateLastLocation(Location location) {
    _lastLat = location.latitude;
    _lastLng = location.longitude;
    _lastTimestamp = DateTime.now();
  }

  Future<void> _sendDistanceToServer(int diff) async {
    final response = await NewMeasureController.editMeters(diff);
    if (response.error != null) {
      LogHelper.logError("Error sending to server: ${response.error}");
      return;
    }

    _totalDistanceSent += diff;
    _lastSentDistance = _distance;
    await SessionDistanceData.saveTotalDistance(_lastSentDistance);
    await TimeData.saveSessionTime(DateTime.now().difference(_startTime).inSeconds);

    if (_totalDistanceSent != _lastSentDistance) {
      LogHelper.logWarn("Discrepancy: total sent $_totalDistanceSent != saved $_lastSentDistance");
    }

    LogHelper.logInfo("Sent $diff m, total $_totalDistanceSent m, saved $_lastSentDistance m");
  }

  void stopListening() {
    if (_positionStreamStarted) {
      LogHelper.logInfo("Stopping BackgroundLocation...");
      BackgroundLocation.stopLocationService();
      _timeTimer?.cancel();
      _streamController.close();
      _positionStreamStarted = false;
      log("Tracking stopped.");
    }
  }

  Future<bool> _isLocationInZone(double lat, double lng) async {
    final pos = mp.LatLng(lat, lng);
    return mp.PolygonUtil.containsLocation(pos, Config.ZONE_EVENT, false);
  }

  Future<bool> isInZone() async {
    final location = BackgroundLocation();
    final loc = await location.getCurrentLocation();
    return _isLocationInZone(loc.latitude!, loc.longitude!);
  }

  Future<double> distanceToZone() async {
    final location = BackgroundLocation();
    final loc = await location.getCurrentLocation();
    final pos = mp.LatLng(loc.latitude!, loc.longitude!);

    if (await _isLocationInZone(loc.latitude!, loc.longitude!)) return -1;

    double minDistance = double.infinity;
    for (int i = 0; i < Config.ZONE_EVENT.length; i++) {
      final p1 = Config.ZONE_EVENT[i];
      final p2 = Config.ZONE_EVENT[(i + 1) % Config.ZONE_EVENT.length];
      final dist = mp.PolygonUtil.distanceToLine(pos, p1, p2).toDouble();
      if (dist < minDistance) minDistance = dist;
    }
    return double.parse((minDistance / 1000).toStringAsFixed(1));
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return mp.SphericalUtil.computeDistanceBetween(
      mp.LatLng(lat1, lon1),
      mp.LatLng(lat2, lon2),
    ).toDouble();
  }
}
