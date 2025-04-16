import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import '../../Utils/config.dart';
import '../../Utils/Permission.dart';

class DynamicMapCard extends StatefulWidget {
  final String? title; // Made title optional (nullable)

  const DynamicMapCard({Key? key, this.title}) : super(key: key);

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
  Position? _currentPosition;
  bool _isFetchingPosition = true;
  bool _isMapReady = false;
  StreamSubscription<Position>? _positionSubscription;
  bool _showLegend = false;

  bool isValidCoordinate(double? value) {
    return value != null && value.isFinite;
  }

  Future<void> _initLocation() async {
    bool permissionGranted = await PermissionHelper.requestLocationPermission();
    if (permissionGranted) {
      await _fetchUserPosition();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen((position) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _isFetchingPosition = false;
            _fitMapBounds();
          });
        }
      });
    } else {
      setState(() {
        _isFetchingPosition = false;
      });
    }

    Future.delayed(const Duration(seconds: 6), () {
      if (mounted && !_isMapReady) {
        setState(() {
          _isMapReady = true;
        });
      }
    });
  }

  Future<void> _fetchUserPosition() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _isFetchingPosition = false;
      });
    } catch (e) {
      debugPrint("Error fetching user position: $e");
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

  void _showFullScreenMap(BuildContext context) {
    // Get current center and zoom from the main map controller
    final center = _mapController.camera.center;
    final zoom = _mapController.camera.zoom;

    // Save the actual user position for the marker
    final double defaultLat = Config.LAT1;
    final double defaultLon = Config.LON1;
    double userLat = _currentPosition?.latitude ?? defaultLat;
    double userLon = _currentPosition?.longitude ?? defaultLon;

    showDialog(
      context: context,
      builder: (context) {
        final MapController fullScreenController = MapController();
        return Dialog(
          insetPadding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                color: Colors.black,
                child: FlutterMap(
                  mapController: fullScreenController,
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: zoom,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all,
                    ),
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
                        Marker(
                          point: Config.RASSEMBLEMENT_POINT_FLUTTER,
                          width: _MapStyles.rassemblementIconSize,
                          height: _MapStyles.rassemblementIconSize,
                          child: _gatheringPointMarker(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 32,
                right: 32,
                child: Material(
                  color: Colors.white.withOpacity(_MapStyles.legendBgOpacity),
                  shape: const CircleBorder(),
                  elevation: 2,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.black87),
                    tooltip: "Fermer la carte",
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final double defaultLat = Config.LAT1;
    final double defaultLon = Config.LON1;
    double userLat = _currentPosition?.latitude ?? defaultLat;
    double userLon = _currentPosition?.longitude ?? defaultLon;

    final mapHeight = 400.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title != null)
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 12.0, bottom: 6.0, top: 6.0),
            child: Text(
              widget.title!,
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
              absorbing: true,
              child: Container(
                height: mapHeight,
                margin: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 12.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
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
                                Marker(
                                  point: Config.RASSEMBLEMENT_POINT_FLUTTER,
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
                    Material(
                      color: Colors.white.withOpacity(_MapStyles.legendBgOpacity),
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: IconButton(
                        icon: const Icon(Icons.fullscreen, color: Colors.black87),
                        tooltip: "Afficher la carte en plein écran",
                        onPressed: () => _showFullScreenMap(context),
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
