import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// Remove Geolocator import
// import 'package:geolocator/geolocator.dart';

import '../../Utils/config.dart';
import '../../Utils/Permission.dart';
import '../../Geolocalisation/Geolocation.dart';
import '../../Data/EventData.dart';

class DynamicMapCard extends StatefulWidget {
  // Remove title parameter
  final Geolocation geolocation;

  const DynamicMapCard({Key? key, required this.geolocation}) : super(key: key);

  @override
  _DynamicMapCardState createState() => _DynamicMapCardState();
}

// --- Global style definitions for icons and colors ---
class _MapStyles {
  static const Color zoneBorderColor = Color(Config.COLOR_APP_BAR);
  static const Color zoneFillColor = Color(Config.COLOR_APP_BAR); // Used with opacity
  static const Color legendBgColor = Colors.white;
  static const double zoneFillOpacity = 0.1;
  static const double legendBgOpacity = 0.95;

  static const double userIconSize = 28;
  static const double rassemblementIconSize = 28;
  static const double legendUserIconSize = 22;
  static const double legendRassemblementIconSize = 20;

  static Icon userPositionIcon({double? size}) => Icon(
        Icons.my_location,
        color: zoneBorderColor,
        size: size ?? userIconSize,
      );

  static Icon rassemblementIcon({double? size}) => Icon(
        Icons.location_pin,
        color: zoneBorderColor,
        size: size ?? rassemblementIconSize,
      );

  static BoxDecoration zoneLegendDecoration = BoxDecoration(
    color: zoneBorderColor.withOpacity(zoneFillOpacity),
    border: Border.all(
      color: zoneBorderColor,
      width: 2,
    ),
    borderRadius: BorderRadius.circular(4),
  );
}
// --- End global style definitions ---

class _DynamicMapCardState extends State<DynamicMapCard> with AutomaticKeepAliveClientMixin {
  final MapController _mapController = MapController();
  // Remove Position? _currentPosition;
  LatLng? _currentLatLng;
  bool _isFetchingPosition = true;
  bool _isMapReady = false;
  // Remove StreamSubscription<Position>? _positionSubscription;
  Timer? _positionTimer;
  bool _showLegend = false;
  bool _mapInteractive = false; // Add: controls map interactivity
  List<LatLng> _zonePoints = [];
  LatLng? _meetingPoint;

  bool isValidCoordinate(double? value) {
    return value != null && value.isFinite;
  }

  @override
  void initState() {
    super.initState();
    _initZone();
    _initMeetingPoint();
    _initLocation();
  }

  Future<void> _initZone() async {
    final zone = await EventData.getSiteCoordLatLngList();
    if (zone != null) {
      setState(() {
        _zonePoints = zone.map((p) => LatLng(p.latitude, p.longitude)).toList();
      });
    } else {
      // fallback to config if needed
      setState(() {
        _zonePoints = Config.ZONE_EVENT.map((p) => LatLng(p.latitude, p.longitude)).toList();
      });
    }
  }

  Future<void> _initMeetingPoint() async {
    final points = await EventData.getMeetingPointLatLngList();
    if (points != null && points.isNotEmpty) {
      setState(() {
        _meetingPoint = LatLng(points[0].latitude, points[0].longitude);
      });
    } else {
      setState(() {
        _meetingPoint = null;
      });
    }
  }

  Future<void> _initLocation() async {
    // No permission or Geolocator logic here, just poll from Geolocation
    _fetchUserPosition();
    _positionTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchUserPosition());

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && !_isMapReady) {
        setState(() {
          _isMapReady = true;
        });
      }
    });
  }

  Future<void> _fetchUserPosition() async {
    final pos = await widget.geolocation.currentPosition;
    // Debug print for current user position
    // ignore: avoid_print
    print('[DynamicMapCard] Current user position: $pos');
    if (mounted) {
      setState(() {
        if (pos != null && isValidCoordinate(pos.latitude) && isValidCoordinate(pos.longitude)) {
          _currentLatLng = LatLng(pos.latitude, pos.longitude);
        } else {
          _currentLatLng = null;
        }
        _isFetchingPosition = false;
        // Only fit bounds if map is locked (not interactive)
        if (_isMapReady && !_mapInteractive) _fitMapBounds();
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
    double userLat = _currentLatLng?.latitude ?? defaultLat;
    double userLon = _currentLatLng?.longitude ?? defaultLon;

    List<LatLng> points = [LatLng(userLat, userLon), ..._zonePoints];

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
    zoom -= 0.3;
    if (zoom < 0.8) zoom = 0.8;

    _mapController.move(center, zoom);
  }

  Widget _userPositionMarker() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: _MapStyles.userPositionIcon(),
    );
  }

  Widget _gatheringPointMarker() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: _MapStyles.rassemblementIcon(),
    );
  }

  void _toggleLegend() {
    setState(() {
      _showLegend = !_showLegend;
    });
  }

  Widget _buildFloatingLegend() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _showLegend
          ? Container(
              key: const ValueKey('legend'),
              padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
              decoration: BoxDecoration(
                color: _MapStyles.legendBgColor.withOpacity(_MapStyles.legendBgOpacity),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "Légende",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          splashRadius: 18,
                          onPressed: _toggleLegend,
                          tooltip: "Fermer",
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: _MapStyles.zoneLegendDecoration,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Zone de l'événement",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _MapStyles.rassemblementIcon(size: _MapStyles.legendRassemblementIconSize),
                        const SizedBox(width: 10),
                        const Text(
                          "Point de rassemblement",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _MapStyles.userPositionIcon(size: _MapStyles.legendUserIconSize),
                        const SizedBox(width: 10),
                        const Text(
                          "Votre position",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final double defaultLat = Config.LAT1;
    final double defaultLon = Config.LON1;
    double userLat = _currentLatLng?.latitude ?? defaultLat;
    double userLon = _currentLatLng?.longitude ?? defaultLon;

    final mapHeight = 400.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hardcode the title here
        Padding(
          padding: const EdgeInsets.only(right: 16.0, left: 16.0, bottom: 8.0, top: 16.0),
          child: Text(
            'Ta position en temps réel',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        Stack(
          children: [
            AbsorbPointer(
              absorbing: !_mapInteractive, // Change: allow interaction if _mapInteractive
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
                      ? Container(
                          height: mapHeight,
                          width: double.infinity,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: Image.asset(
                                  'assets/pictures/LogoSimpleAnimated.gif',
                                  fit: BoxFit.contain,
                                ),
                              ),
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
                            initialCenter: LatLng(userLat, userLon),
                            initialZoom: 0.8,
                            onMapReady: () {
                              setState(() {
                                _isMapReady = true;
                              });
                              WidgetsBinding.instance.addPostFrameCallback((_) => _fitMapBounds());
                            },
                            interactionOptions: _mapInteractive
                                ? const InteractionOptions(flags: InteractiveFlag.all)
                                : const InteractionOptions(flags: InteractiveFlag.none),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                              subdomains: const ['a', 'b', 'c'],
                            ),
                            PolygonLayer(
                              polygons: [
                                Polygon(
                                  points: _zonePoints,
                                  color: _MapStyles.zoneFillColor.withOpacity(_MapStyles.zoneFillOpacity),
                                  borderColor: _MapStyles.zoneBorderColor,
                                  borderStrokeWidth: 2,
                                ),
                              ],
                            ),
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: LatLng(userLat, userLon),
                                  width: _MapStyles.userIconSize,
                                  height: _MapStyles.userIconSize,
                                  child: _userPositionMarker(),
                                ),
                                if (_meetingPoint != null)
                                  Marker(
                                    point: _meetingPoint!,
                                    width: _MapStyles.rassemblementIconSize,
                                    height: _MapStyles.rassemblementIconSize,
                                    child: _gatheringPointMarker(),
                                  ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
            ),
            // Only show floating buttons if map is ready and not fetching position
            if (!_isFetchingPosition && _isMapReady)
              Positioned(
                top: 20,
                right: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _showLegend
                          ? _buildFloatingLegend()
                          : Material(
                              color: Colors.white.withOpacity(_MapStyles.legendBgOpacity),
                              shape: const CircleBorder(),
                              elevation: 2,
                              child: IconButton(
                                icon: const Icon(Icons.info_outline, color: Colors.black87),
                                tooltip: "Légende de la carte",
                                onPressed: _toggleLegend,
                              ),
                            ),
                    ),
                    const SizedBox(height: 14),
                    // Remove fullscreen button, add map interaction toggle button
                    Material(
                      color: Colors.white.withOpacity(_MapStyles.legendBgOpacity),
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: IconButton(
                        icon: Icon(
                          _mapInteractive ? Icons.lock_open : Icons.lock,
                          color: Colors.black87,
                        ),
                        tooltip:
                            _mapInteractive ? "Désactiver le contrôle de la carte" : "Activer le contrôle de la carte",
                        onPressed: () {
                          setState(() {
                            _mapInteractive = !_mapInteractive;
                            // If just locked, recenter the map and reset rotation to north
                            if (!_mapInteractive) {
                              _fitMapBounds();
                              _mapController.rotate(0); // Reset map direction to north
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}
