import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:lrqm/data/measure_data.dart';
import 'package:lrqm/utils/config.dart';

class CardPathMap extends StatefulWidget {
  const CardPathMap({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CardPathMapState createState() => _CardPathMapState();
}

class _CardPathMapState extends State<CardPathMap> {
  final MapController _mapController = MapController();
  List<LatLng> _fullPath = [];
  List<LatLng> _animatedPath = [];
  bool _isLoading = true;
  bool _isError = false;
  bool _isMapReady = false;
  Timer? _animationTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _isError = false;
      });

      final measurePoints = await MeasureData.getMeasurePoints();
      _fullPath = measurePoints.map((p) => LatLng(p['lat'] as double, p['lng'] as double)).toList();

      setState(() {
        _isLoading = false;
        _animatedPath = [];
      });

      if (_fullPath.isNotEmpty && _isMapReady) {
        _fitMapToPath();
        _startPathAnimation();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isError = true;
      });
    }
  }

  void _fitMapToPath() {
    if (!_isMapReady || !mounted) return;

    if (_fullPath.length < 2) {
      if (_fullPath.isNotEmpty) {
        _mapController.move(_fullPath.first, 16.0);
      }
      return;
    }

    // Calculate bounds
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLng = double.infinity;
    double maxLng = -double.infinity;

    for (final point in _fullPath) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    // Add smaller padding (in degrees, approx 0.001 ~ 100m)
    const double padding = 0.0012; // reduced padding for closer fit
    minLat -= padding;
    maxLat += padding;
    minLng -= padding;
    maxLng += padding;

    // Center
    final LatLng center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);

    // Calculate zoom to fit bounds
    double latToY(double lat) => log(tan((lat * pi / 180) / 2 + pi / 4));
    double worldMapWidth = MediaQuery.of(context).size.width;
    double worldMapHeight = MediaQuery.of(context).size.height * 0.6;

    double latFraction = (latToY(maxLat) - latToY(minLat)) / pi;
    double lngDiff = maxLng - minLng;
    double lngFraction = ((lngDiff < 0 ? lngDiff + 360 : lngDiff) / 360);

    double latZoom = _zoom(worldMapHeight, 256, latFraction);
    double lngZoom = _zoom(worldMapWidth, 256, lngFraction);

    double zoom = min(latZoom, lngZoom);
    zoom = zoom.clamp(13.0, 18.0); // allow closer zoom (min 13 instead of 10)

    _mapController.move(center, zoom);
  }

  double _zoom(double mapPx, double worldPx, double fraction) {
    const ln2 = 0.6931471805599453;
    return log(mapPx / worldPx / fraction) / ln2;
  }

  void _startPathAnimation() {
    _animationTimer?.cancel();
    _animatedPath = [];
    _currentIndex = 0;

    if (_fullPath.length < 2) return;

    // Calculate interval based on fixed 10 second total duration
    // with a minimum interval of 100ms between points
    final int totalPoints = _fullPath.length;
    int intervalMs = (10000 / totalPoints).round(); // 10 seconds = 10000 ms
    intervalMs = intervalMs.clamp(10, 200);

    _animationTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      if (_currentIndex >= _fullPath.length) {
        timer.cancel();
        return;
      }

      setState(() {
        _animatedPath.add(_fullPath[_currentIndex]);
        _currentIndex++;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text(
              'Impossible de charger le parcours',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    if (_fullPath.isEmpty) {
      return const Center(
        child: Text(
          'Aucun point de mesure disponible',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(0),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _fullPath.isNotEmpty ? _fullPath.first : const LatLng(0, 0),
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                onMapReady: () {
                  _isMapReady = true;
                  if (_fullPath.isNotEmpty) {
                    Future.delayed(const Duration(milliseconds: 200), () {
                      if (mounted) {
                        _fitMapToPath();
                        _startPathAnimation();
                      }
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  retinaMode: RetinaMode.isHighDensity(context),
                ),
                if (_animatedPath.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: _animatedPath,
                        color: const Color(Config.accentColor),
                        strokeWidth: 5,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _fullPath.first,
                      width: 40,
                      height: 40,
                      child: const Icon(Icons.location_on, color: Color(Config.primaryColor), size: 40),
                    ),
                    if (_animatedPath.length == _fullPath.length)
                      Marker(
                        point: _fullPath.last,
                        width: 40,
                        height: 40,
                        child: const Icon(Icons.flag, color: Colors.redAccent, size: 36),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        // BETA badge at top left
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'BETA',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontSize: 13,
              ),
            ),
          ),
        ),
        // Copyright at bottom right
        Positioned(
          bottom: 8,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(0),
            ),
            child: const Text(
              '© OpenStreetMap × © CARTO',
              style: TextStyle(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: "replay",
                mini: true,
                backgroundColor: Colors.white,
                onPressed: _startPathAnimation,
                tooltip: 'Rejouer le tracé',
                child: const Icon(Icons.replay, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
