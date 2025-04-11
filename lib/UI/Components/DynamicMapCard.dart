import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;

import '../../Utils/config.dart';

class DynamicMapCard extends StatefulWidget {
  const DynamicMapCard({Key? key}) : super(key: key);

  @override
  State<DynamicMapCard> createState() => _DynamicMapCardState();
}

class _DynamicMapCardState extends State<DynamicMapCard> with AutomaticKeepAliveClientMixin {
  final MapController _mapController = MapController();
  bg.Location? _currentLocation;
  bool _isFetchingPosition = true;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _fetchPosition();

    // Always show map after 5 seconds even if no location
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_isMapReady) {
        setState(() {
          _isMapReady = true;
        });
      }
    });
  }

  Future<void> _fetchPosition() async {
    try {
      final state = await bg.BackgroundGeolocation.state;

      if (state.authorization != 0) {
        // Authorized → Fetch position
        final location = await bg.BackgroundGeolocation.getCurrentPosition(samples: 1);
        if (mounted) {
          setState(() {
            _currentLocation = location;
            _isFetchingPosition = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapBounds());
        }

        // Listen live updates
        bg.BackgroundGeolocation.onLocation((bg.Location location) {
          if (mounted) {
            setState(() {
              _currentLocation = location;
            });
          }
        });
      } else {
        // Not authorized → Only show map
        setState(() {
          _isFetchingPosition = false;
        });
      }
    } catch (e) {
      setState(() {
        _isFetchingPosition = false;
      });
    }
  }

  double _latRad(double lat) {
    final sinValue = sin(lat * pi / 180);
    return log((1 + sinValue) / (1 - sinValue)) / 2;
  }

  double _zoom(double mapPx, double worldPx, double fraction) {
    return log(mapPx / worldPx / fraction) / ln2;
  }

  void _fitMapBounds() {
    if (!_isMapReady) return;

    final double defaultLat = Config.LAT1;
    final double defaultLon = Config.LON1;
    double userLat = _currentLocation?.coords.latitude ?? defaultLat;
    double userLon = _currentLocation?.coords.longitude ?? defaultLon;

    List<LatLng> points = [
      LatLng(userLat, userLon),
      ...Config.ZONE_EVENT.map((p) => LatLng(p.latitude, p.longitude)),
    ];

    double minLat = points.map((p) => p.latitude).reduce(min);
    double maxLat = points.map((p) => p.latitude).reduce(max);
    double minLon = points.map((p) => p.longitude).reduce(min);
    double maxLon = points.map((p) => p.longitude).reduce(max);

    LatLng center = LatLng((minLat + maxLat) / 2, (minLon + maxLon) / 2);

    final Size mapSize = MediaQuery.of(context).size;
    double latFraction = (_latRad(maxLat) - _latRad(minLat)) / pi;
    double lonFraction = (maxLon - minLon) / 360;

    double latZoom = _zoom(mapSize.height, 256, latFraction);
    double lonZoom = _zoom(mapSize.width, 256, lonFraction);
    double zoom = min(latZoom, lonZoom);

    if (!zoom.isFinite) zoom = 8.0;
    if (zoom < 0.8) zoom = 0.8;
    zoom -= 0.2;
    if (zoom < 0.8) zoom = 0.8;

    _mapController.move(center, zoom);
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final mapHeight = MediaQuery.of(context).size.height * 0.5;

    final userMarker = _currentLocation != null
        ? Marker(
            point: LatLng(
              _currentLocation!.coords.latitude,
              _currentLocation!.coords.longitude,
            ),
            child: const Icon(
              Icons.my_location,
              color: Color(Config.COLOR_APP_BAR),
              size: 32,
            ),
          )
        : null;

    return AbsorbPointer(
      absorbing: true,
      child: Container(
        height: mapHeight,
        margin: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          color: Colors.white,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: _isFetchingPosition || !_isMapReady
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 10),
                      const Text(
                        "Chargement de la carte...",
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(Config.COLOR_APP_BAR),
                        ),
                      ),
                    ],
                  ),
                )
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(Config.LAT1, Config.LON1),
                    initialZoom: 0.8,
                    onMapReady: () {
                      if (mounted) {
                        setState(() {
                          _isMapReady = true;
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapBounds());
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: Config.ZONE_EVENT.map((p) => LatLng(p.latitude, p.longitude)).toList(),
                          color: Color(Config.COLOR_BUTTON).withOpacity(0.2),
                          borderColor: Color(Config.COLOR_BUTTON),
                          borderStrokeWidth: 3,
                        ),
                      ],
                    ),
                    if (userMarker != null)
                      MarkerLayer(
                        markers: [userMarker],
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
