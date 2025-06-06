import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lrqm/geo/kalman_simple.dart';
import 'package:lrqm/geo/low_pass_location_filter.dart';

enum DisplayMode { rawOnly, kalmanOnly, kalmanAndLowPass }

class KalmanPlaybackScreen extends StatefulWidget {
  const KalmanPlaybackScreen({super.key});

  @override
  State<KalmanPlaybackScreen> createState() => _KalmanPlaybackScreenState();
}

class _KalmanPlaybackScreenState extends State<KalmanPlaybackScreen> {
  SimpleLocationKalmanFilter2D filter = SimpleLocationKalmanFilter2D();
  LowPassLocationFilter _lowPassFilter = LowPassLocationFilter();

  final MapController _mapController = MapController();

  List<LatLng> rawPoints = [];
  List<LatLng> filteredPoints = [];
  List<LatLng> lowPassPoints = [];

  bool _isMapReady = false;
  double totalRawDistance = 0.0; // Define totalRawDistance at the class level
  double totalFilteredDistance = 0.0; // Define totalFilteredDistance at the class level
  double _totalLowPassDistance = 0.0;

  DisplayMode _displayMode = DisplayMode.rawOnly;

  @override
  void initState() {
    super.initState();
    _loadCsvAndApplyFilter();
  }

  Future<void> _loadCsvAndApplyFilter() async {
    filter = SimpleLocationKalmanFilter2D();
    _lowPassFilter = LowPassLocationFilter();
    rawPoints = [];
    filteredPoints = [];
    lowPassPoints = [];
    totalRawDistance = 0.0; // Reset totalRawDistance
    totalFilteredDistance = 0.0; // Reset totalFilteredDistance
    _totalLowPassDistance = 0.0;
    setState(() {});

    final csvString = await rootBundle.loadString('assets/sims/kalman_input_simulation.csv');
    final lines = const LineSplitter().convert(csvString);
    LatLng? previousRawPoint;
    LatLng? previousFilteredPoint;
    LatLng? previousLowPassPoint;

    for (int i = 1; i < lines.length; i++) {
      final parts = lines[i].split(',');
      if (parts.length < 4) continue;

      final lat = double.tryParse(parts[0]);
      final lng = double.tryParse(parts[1]);
      final acc = double.tryParse(parts[2]);
      final ts = double.tryParse(parts[3]);

      if (lat == null || lng == null || acc == null || ts == null) continue;

      final rawPoint = LatLng(lat, lng);
      rawPoints.add(rawPoint);

      if (previousRawPoint != null) {
        totalRawDistance += _haversineDistance(
          previousRawPoint.latitude,
          previousRawPoint.longitude,
          rawPoint.latitude,
          rawPoint.longitude,
        );
      }
      previousRawPoint = rawPoint;

      final result = filter.update(lat, lng, acc, ts);
      final fLat = result['latitude'];
      final fLng = result['longitude'];
      if (fLat != null && fLng != null) {
        final filteredPoint = LatLng(fLat, fLng);
        filteredPoints.add(filteredPoint);

        if (previousFilteredPoint != null) {
          totalFilteredDistance += _haversineDistance(
            previousFilteredPoint.latitude,
            previousFilteredPoint.longitude,
            filteredPoint.latitude,
            filteredPoint.longitude,
          );
        }
        previousFilteredPoint = filteredPoint;

        final smoothed = _lowPassFilter.filter(
          latitude: fLat,
          longitude: fLng,
          timestamp: ts,
        );
        final finalLat = smoothed['latitude']!;
        final finalLng = smoothed['longitude']!;
        final lowPassPoint = LatLng(finalLat, finalLng);
        lowPassPoints.add(lowPassPoint);

        if (previousLowPassPoint != null) {
          _totalLowPassDistance += _haversineDistance(
            previousLowPassPoint.latitude,
            previousLowPassPoint.longitude,
            lowPassPoint.latitude,
            lowPassPoint.longitude,
          );
        }
        previousLowPassPoint = lowPassPoint;
      }
    }

    if (_isMapReady && filteredPoints.isNotEmpty) {
      _fitMapToPath(filteredPoints);
    }

    setState(() {});
  }

  void _fitMapToPath(List<LatLng> path) {
    if (path.length < 2 || !mounted) {
      if (path.isNotEmpty) {
        _mapController.move(path.first, 16.0);
      }
      return;
    }

    double minLat = double.infinity, maxLat = -double.infinity;
    double minLng = double.infinity, maxLng = -double.infinity;

    for (final point in path) {
      minLat = min(minLat, point.latitude);
      maxLat = max(maxLat, point.latitude);
      minLng = min(minLng, point.longitude);
      maxLng = max(maxLng, point.longitude);
    }

    const padding = 0.0012;
    minLat -= padding;
    maxLat += padding;
    minLng -= padding;
    maxLng += padding;

    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);

    double latZoom = _zoom(MediaQuery.of(context).size.height * 0.6, 256,
        (log(tan((maxLat * pi / 180) / 2 + pi / 4)) - log(tan((minLat * pi / 180) / 2 + pi / 4))) / pi);
    double lngZoom = _zoom(MediaQuery.of(context).size.width, 256, (maxLng - minLng).abs() / 360);

    double zoom = min(latZoom, lngZoom).clamp(13.0, 18.0);

    _mapController.move(center, zoom);
  }

  double _zoom(double mapPx, double worldPx, double fraction) {
    return log(mapPx / worldPx / fraction) / ln2;
  }

  double _haversineDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000;
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);
    final a =
        (sin(dLat / 2) * sin(dLat / 2)) + cos(_degToRad(lat1)) * cos(_degToRad(lat2)) * (sin(dLng / 2) * sin(dLng / 2));
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _degToRad(double deg) => deg * (pi / 180);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalman Playback'),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers),
            tooltip: "Switch display mode",
            onPressed: () {
              setState(() {
                _displayMode = DisplayMode.values[(_displayMode.index + 1) % DisplayMode.values.length];
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.replay),
            tooltip: "Replay",
            onPressed: () {
              _loadCsvAndApplyFilter();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(0, 0),
              initialZoom: 15,
              onMapReady: () {
                _isMapReady = true;
                if (filteredPoints.isNotEmpty) {
                  _fitMapToPath(filteredPoints);
                }
              },
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              PolylineLayer(polylines: [
                Polyline(points: rawPoints, strokeWidth: 2, color: Colors.red),
                Polyline(points: filteredPoints, strokeWidth: 2, color: Colors.green),
                Polyline(points: lowPassPoints, strokeWidth: 2, color: Colors.blue),
              ]),
            ],
          ),
          if (rawPoints.isNotEmpty && filteredPoints.isNotEmpty)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Distance brute: ${totalRawDistance.toStringAsFixed(1)} m",
                        style: TextStyle(color: Colors.red)),
                    Text("Distance Kalman: ${totalFilteredDistance.toStringAsFixed(1)} m",
                        style: TextStyle(color: Colors.green)),
                    Text("Distance LP : ${_totalLowPassDistance.toStringAsFixed(1)} m",
                        style: TextStyle(color: Colors.blue)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
