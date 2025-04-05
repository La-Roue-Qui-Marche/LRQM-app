import 'dart:async';
import 'dart:developer';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:maps_toolkit/maps_toolkit.dart' as mp;
import 'package:lrqm/API/NewMeasureController.dart'; // Replace MeasureController with NewMeasureController
import 'package:lrqm/Data/DistToSendData.dart'; // Correct package name
import 'package:lrqm/Data/TimeData.dart'; // Correct package name
import 'package:lrqm/Utils/config.dart'; // Correct package name
import 'package:lrqm/Utils/LogHelper.dart';
import 'package:flutter/foundation.dart'; // Add this import

class Geolocation {
  late StreamSubscription<geo.Position> _positionStream;
  late geo.LocationSettings _settings;
  late geo.Position _oldPos;
  int _distance = 0;
  int _mesureToWait = 0;
  DateTime _startTime = DateTime.now();
  int _outsideCounter = 0;
  final StreamController<Map<String, int>> _streamController = StreamController<Map<String, int>>();
  bool _positionStreamStarted = false;
  Timer? _timeTimer;

  // Add a new variable to track the last sent distance to prevent duplicates
  int _lastSentDistance = 0;

  Geolocation() {
    _settings = _getSettings();
  }

  Stream<Map<String, int>> get stream => _streamController.stream;

  static Future<bool> handlePermission() async {
    final geo.GeolocatorPlatform _geolocatorPlatform = geo.GeolocatorPlatform.instance;
    bool serviceEnabled;
    geo.LocationPermission permission;

    serviceEnabled = await _geolocatorPlatform.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await _geolocatorPlatform.checkPermission();
    if (permission == geo.LocationPermission.denied) {
      permission = await _geolocatorPlatform.requestPermission();
      if (permission == geo.LocationPermission.denied) {
        return false;
      }
    }

    if (permission == geo.LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  geo.LocationSettings _getSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return geo.AndroidSettings(
          accuracy: geo.LocationAccuracy.high,
          intervalDuration: const Duration(seconds: 5),
          foregroundNotificationConfig: const geo.ForegroundNotificationConfig(
            notificationText: "Pas de panique, c'est la RQM qui vous suit!",
            notificationTitle: "Running in Background",
            enableWakeLock: true,
            notificationIcon: geo.AndroidResource(name: 'launcher_icon', defType: 'mipmap'),
          ));
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

  Future<geo.Position> determinePosition() async {
    return await geo.Geolocator.getCurrentPosition();
  }

  Future<void> startListening() async {
    log("Checking if position stream can start...");
    if (!_positionStreamStarted && await handlePermission()) {
      log("Starting position stream.");

      _positionStreamStarted = true;
      _mesureToWait = 3;
      _startTime = DateTime.now();

      _timeTimer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
        Duration diff = DateTime.now().difference(_startTime);
        _streamController.sink.add({"time": diff.inSeconds, "distance": _distance});
      });

      _oldPos = await geo.Geolocator.getCurrentPosition();

      _positionStream =
          geo.Geolocator.getPositionStream(locationSettings: _settings).listen((geo.Position position) async {
        if (_mesureToWait > 0) {
          log("Initializing position stream. Waiting for stable readings...");
          _oldPos = position;
          _distance = 0;
          _mesureToWait--;
        } else {
          var distSinceLast =
              geo.Geolocator.distanceBetween(_oldPos.latitude, _oldPos.longitude, position.latitude, position.longitude)
                  .round();

          LogHelper.writeLog("Position: $position, Distance: $distSinceLast");

          _oldPos = position;
          _distance += distSinceLast;

          if (distSinceLast > 0) {
            int diff = _distance - _lastSentDistance; // Calculate the difference
            log("Distance difference to send: $diff meters");

            if (!isLocationInZone(position)) {
              log("User is outside the zone.");
              if (_outsideCounter < 5) {
                _outsideCounter++;
              } else {
                log("User has been outside the zone for too long. Stopping measurement.");
                _distance = -1;
                _streamController.sink
                    .add({"time": DateTime.now().difference(_startTime).inSeconds, "distance": _distance});
              }
            } else {
              log("User is inside the zone.");
              await TimeData.saveSessionTime(DateTime.now().difference(_startTime).inSeconds); // Save as int

              // Attempt to send the difference to the server
              NewMeasureController.editMeters(diff).then((value) async {
                if (value.error != null) {
                  log("Error updating distance on server: ${value.error}");
                  // Accumulate the difference if sending fails
                  _lastSentDistance += diff;
                } else {
                  log("Distance updated on server successfully.");
                  // Save the new total distance only after successful sending
                  _lastSentDistance = _distance;
                  await DistToSendData.saveDistToSend(_lastSentDistance);
                }
                _streamController.sink
                    .add({"time": DateTime.now().difference(_startTime).inSeconds, "distance": _distance});
              });
            }
          }
        }
      });
    } else {
      log("Position stream already started or location permissions not granted.");
      _streamController.sink.add({"time": -1, "distance": -1});
    }
  }

  void stopListening() {
    if (_positionStreamStarted) {
      _positionStream.cancel().then((value) {
        _streamController.close();
        _timeTimer?.cancel();
        _positionStreamStarted = false;
      });
    }
  }

  bool isLocationInZone(geo.Position point) {
    var tmp = mp.LatLng(point.latitude, point.longitude);
    var test = mp.PolygonUtil.containsLocation(tmp, Config.ZONE_EVENT, false);
    return test;
  }

  Future<bool> isInZone() async {
    final tmp = await determinePosition();
    var test = isLocationInZone(tmp);
    return test;
  }

  Future<double> distanceToZone() async {
    final currentPosition = await determinePosition();
    if (isLocationInZone(currentPosition)) {
      return -1; // User is inside the zone
    }

    final currentPoint = mp.LatLng(currentPosition.latitude, currentPosition.longitude);
    double minDistance = double.infinity;

    for (int i = 0; i < Config.ZONE_EVENT.length; i++) {
      final point1 = Config.ZONE_EVENT[i];
      final point2 = Config.ZONE_EVENT[(i + 1) % Config.ZONE_EVENT.length];
      final distance = mp.PolygonUtil.distanceToLine(currentPoint, point1, point2).toDouble();
      if (distance < minDistance) {
        minDistance = distance;
      }
    }

    return double.parse((minDistance / 1000).toStringAsFixed(1));
  }
}
