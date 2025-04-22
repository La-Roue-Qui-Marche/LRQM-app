import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../Data/MeasureData.dart';
import '../../Utils/config.dart';

class RunPathMap extends StatefulWidget {
  const RunPathMap({Key? key}) : super(key: key);

  @override
  _RunPathMapState createState() => _RunPathMapState();
}

class _RunPathMapState extends State<RunPathMap> {
  final MapController _mapController = MapController();
  List<LatLng> _fullPath = [];
  List<LatLng> _animatedPath = [];
  bool _isLoading = true;
  bool _isError = false;
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

      if (_fullPath.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 300), () {
          _startPathAnimation();
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isError = true;
      });
    }
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
            height: 400,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _fullPath.first,
                initialZoom: 15.0,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
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
                        color: Color(Config.COLOR_BUTTON),
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
                      child: Icon(Icons.location_on, color: Color(Config.COLOR_APP_BAR), size: 40),
                    ),
                    if (_animatedPath.length == _fullPath.length)
                      Marker(
                        point: _fullPath.last,
                        width: 40,
                        height: 40,
                        child: Icon(Icons.flag, color: Colors.redAccent, size: 36),
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
