import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lrqm/geo/kalman_simple.dart';

class KalmanPlaybackScreen extends StatefulWidget {
  const KalmanPlaybackScreen({super.key});

  @override
  State<KalmanPlaybackScreen> createState() => _KalmanPlaybackScreenState();
}

class _KalmanPlaybackScreenState extends State<KalmanPlaybackScreen> {
  SimpleLocationKalmanFilter2D filter = SimpleLocationKalmanFilter2D();
  final MapController _mapController = MapController();

  List<LatLng> rawPoints = [];
  List<LatLng> filteredPoints = [];

  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _loadCsvAndApplyFilter();
  }

  Future<void> _loadCsvAndApplyFilter() async {
    // Reset state for replay
    filter = SimpleLocationKalmanFilter2D();
    rawPoints = [];
    filteredPoints = [];
    setState(() {}); // Clear map immediately

    final csvString = await rootBundle.loadString('assets/sims/kalman_input_simulation.csv');
    final lines = const LineSplitter().convert(csvString);
    for (int i = 1; i < lines.length; i++) {
      final parts = lines[i].split(',');
      if (parts.length < 4) continue;

      final lat = double.tryParse(parts[0]);
      final lng = double.tryParse(parts[1]);
      final acc = double.tryParse(parts[2]);
      final ts = double.tryParse(parts[3]);

      if (lat == null || lng == null || acc == null || ts == null) continue;

      final raw = LatLng(lat, lng);
      rawPoints.add(raw);

      final result = filter.update(lat, lng, acc, ts);
      final fLat = result['latitude'];
      final fLng = result['longitude'];
      if (fLat != null && fLng != null) {
        filteredPoints.add(LatLng(fLat, fLng));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalman Playback'),
        actions: [
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
              if (rawPoints.isNotEmpty)
                PolylineLayer(polylines: [
                  Polyline(points: rawPoints, strokeWidth: 2, color: Colors.red),
                  Polyline(points: filteredPoints, strokeWidth: 2, color: Colors.green),
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
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("📏 Distance brute : ${filter.getTotalRawDistance().toStringAsFixed(1)} m"),
                    Text("🧠 Distance filtrée : ${filter.getTotalFilteredDistance().toStringAsFixed(1)} m"),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
