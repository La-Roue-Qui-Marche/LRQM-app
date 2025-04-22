import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../Data/MeasureData.dart';
import '../../Utils/config.dart';

class RunPathMap extends StatefulWidget {
  const RunPathMap({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _RunPathMapState createState() => _RunPathMapState();
}

class _RunPathMapState extends State<RunPathMap> {
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

    // Add padding to the bounds (approximate method)
    final double latPadding = (maxLat - minLat) * 0.1;
    final double lngPadding = (maxLng - minLng) * 0.1;

    minLat -= latPadding;
    maxLat += latPadding;
    minLng -= lngPadding;
    maxLng += lngPadding;

    // Calculate center point
    final LatLng center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);

    // Calculate appropriate zoom level
    const pi = 3.14159265359;
    const ln2 = 0.6931471805599453;

    double _latRad(double lat) => log((1 + sin(lat * pi / 180)) / (1 - sin(lat * pi / 180))) / 2;

    double _zoom(double mapPx, double worldPx, double fraction) => log(mapPx / worldPx / fraction) / ln2;

    final Size mapSize = MediaQuery.of(context).size;

    double latZoom = _zoom(mapSize.height, 256, (_latRad(maxLat) - _latRad(minLat)) / pi);
    double lngZoom = _zoom(mapSize.width, 256, (maxLng - minLng) / 360);

    double zoom = min(latZoom, lngZoom);

    if (!zoom.isFinite || zoom < 2.0) zoom = 5.0;
    zoom -= 0.3; // Adjust to ensure everything is visible
    if (zoom < 2.0) zoom = 2.0;

    _mapController.move(center, zoom);
  }

  void _startPathAnimation() {
    _animationTimer?.cancel();
    _animatedPath = [];
    _currentIndex = 0;

    if (_fullPath.length < 2) return;

    _animationTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
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
