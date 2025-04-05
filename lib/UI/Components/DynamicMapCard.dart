import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../Utils/config.dart';
import '../../Geolocalisation/Geolocation.dart';

class DynamicMapCard extends StatefulWidget {
  const DynamicMapCard({Key? key}) : super(key: key);

  @override
  _DynamicMapCardState createState() => _DynamicMapCardState();
}

class _DynamicMapCardState extends State<DynamicMapCard> {
  final MapController _mapController = MapController();
  final Geolocation _geolocation = Geolocation();
  Position? _currentPosition;

  bool isValidCoordinate(double? value) {
    return value != null && value.isFinite;
  }

  Future<void> _fetchUserPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      debugPrint("Error fetching user position: $e");
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
    final double defaultLat = Config.LAT1;
    final double defaultLon = Config.LON1;
    double userLat = defaultLat;
    double userLon = defaultLon;

    if (_currentPosition != null &&
        isValidCoordinate(_currentPosition!.latitude) &&
        isValidCoordinate(_currentPosition!.longitude)) {
      userLat = _currentPosition!.latitude;
      userLon = _currentPosition!.longitude;
    }

    List<LatLng> points = [LatLng(userLat, userLon), ...Config.ZONE_EVENT.map((p) => LatLng(p.latitude, p.longitude))];

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

    _mapController.move(center, zoom);
  }

  @override
  void initState() {
    super.initState();
    _fetchUserPosition().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapBounds());
    });
    _geolocation.startListening();
    _geolocation.stream.listen((data) {
      _geolocation.determinePosition().then((position) {
        setState(() {
          _currentPosition = position;
          _fitMapBounds();
        });
      });
    });
  }

  @override
  void dispose() {
    _geolocation.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double defaultLat = Config.LAT1;
    final double defaultLon = Config.LON1;
    double userLat = _currentPosition?.latitude ?? defaultLat;
    double userLon = _currentPosition?.longitude ?? defaultLon;

    return AbsorbPointer(
      // Disable touch events
      absorbing: true,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5,
        margin: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 6.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0),
          color: Colors.white,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16.0),
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(userLat, userLon),
                  initialZoom: 8.0,
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
                        color: Color(Config.COLOR_APP_BAR).withOpacity(0.1), // Fill with opacity 0.1
                        borderColor: Color(Config.COLOR_APP_BAR),
                        borderStrokeWidth: 3,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: LatLng(userLat, userLon),
                        child: Icon(
                          Icons.my_location,
                          color: Color(Config.COLOR_BUTTON),
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
