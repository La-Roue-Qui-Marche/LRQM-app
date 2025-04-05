import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../Utils/config.dart';

class MapCard extends StatefulWidget {
  const MapCard({Key? key}) : super(key: key);

  @override
  _MapCardState createState() => _MapCardState();
}

class _MapCardState extends State<MapCard> {
  final MapController _mapController = MapController();
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

  // Helper to convert latitude to radians used in zoom calculation.
  double _latRad(double lat) {
    final sinValue = sin(lat * pi / 180);
    return log((1 + sinValue) / (1 - sinValue)) / 2;
  }

  // Helper to calculate zoom from map pixel dimensions.
  double _zoom(double mapPx, double worldPx, double fraction) {
    return log(mapPx / worldPx / fraction) / ln2;
  }

  void _fitMapBounds() {
    // Use default coordinates from Config if user position is not available.
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

    // Combine the user’s position and the zone points.
    List<LatLng> points = [LatLng(userLat, userLon), ...Config.ZONE_EVENT.map((p) => LatLng(p.latitude, p.longitude))];

    double minLat = points.map((p) => p.latitude).reduce(min);
    double maxLat = points.map((p) => p.latitude).reduce(max);
    double minLon = points.map((p) => p.longitude).reduce(min);
    double maxLon = points.map((p) => p.longitude).reduce(max);

    // Calculate the center of these bounds.
    LatLng center = LatLng((minLat + maxLat) / 2, (minLon + maxLon) / 2);

    // Get the map widget size.
    final Size mapSize = MediaQuery.of(context).size;

    // Calculate fractions (for latitude and longitude) that the bounds occupy.
    double latFraction = (_latRad(maxLat) - _latRad(minLat)) / pi;
    double lonFraction = (maxLon - minLon) / 360;

    // Compute a zoom level for each and choose the smaller.
    double latZoom = _zoom(mapSize.height, 256, latFraction);
    double lonZoom = _zoom(mapSize.width, 256, lonFraction);
    double zoom = min(latZoom, lonZoom);

    // Fallback if the computed zoom is not finite.
    if (!zoom.isFinite) zoom = 8.0;

    // Move the map controller to the computed center and zoom.
    _mapController.move(center, zoom);
  }

  @override
  void initState() {
    super.initState();
    _fetchUserPosition().then((_) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapBounds());
    });
  }

  @override
  Widget build(BuildContext context) {
    // Default center for initial rendering.
    final double defaultLat = Config.LAT1;
    final double defaultLon = Config.LON1;
    double userLat = _currentPosition?.latitude ?? defaultLat;
    double userLon = _currentPosition?.longitude ?? defaultLon;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.0,
            spreadRadius: 5.0,
            offset: Offset(0, 5),
          ),
        ],
        color: Colors.white,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30.0),
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
                      color: Colors.blue.withOpacity(0.2),
                      borderColor: Colors.blue,
                      borderStrokeWidth: 3,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(userLat, userLon),
                      child: const Icon(
                        Icons.my_location,
                        color: Color(Config.COLOR_APP_BAR),
                        size: 48,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black, size: 32),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
