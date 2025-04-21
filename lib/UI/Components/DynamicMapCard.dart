import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../Utils/config.dart';
import '../../Geolocalisation/Geolocation.dart';
import '../../Data/EventData.dart';

class DynamicMapCard extends StatefulWidget {
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

  static const double userIconSize = 36; // Increased from 28
  static const double rassemblementIconSize = 34; // Increased from 28
  static const double legendUserIconSize = 26; // Increased from 22
  static const double legendRassemblementIconSize = 24; // Increased from 20
}
// --- End global style definitions ---

// Update: enum for map type (remove standard)
enum _MapBaseType { satellite, voyager }

class _DynamicMapCardState extends State<DynamicMapCard> with AutomaticKeepAliveClientMixin {
  final MapController _mapController = MapController();
  LatLng? _currentLatLng;
  bool _isFetchingPosition = true;
  bool _isMapReady = false;
  Timer? _positionTimer;
  bool _showLegend = false;
  bool _followUserMode = false; // Tracks if camera should follow user
  List<LatLng> _zonePoints = [];
  LatLng? _meetingPoint;

  // Default to voyager
  _MapBaseType _mapBaseType = _MapBaseType.voyager;

  // Helper for marker color based on map type
  Color get _userMarkerColor {
    if (_mapBaseType == _MapBaseType.satellite) {
      // Bright blue for user (stands out on green/brown satellite)
      return Colors.pink; // Material grey 800
    }
    return _MapStyles.zoneBorderColor;
  }

  Color get _gatheringMarkerColor {
    if (_mapBaseType == _MapBaseType.satellite) {
      // Bright orange for meeting point (contrasts with blue and green)
      return Colors.black;
    }
    return Color(Config.COLOR_BUTTON);
  }

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
      setState(() {
        _zonePoints = [];
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
    _fetchUserPosition();
    _positionTimer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchUserPosition());

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && !_isMapReady) {
        setState(() {
          _isMapReady = true;
        });
      }
    });
  }

  // New method to center map on user with close zoom
  void _centerOnUser() {
    if (_currentLatLng == null || !_isMapReady) return;

    // Use a closer zoom level when following the user
    const double followZoomLevel = 17.0;

    try {
      _mapController.move(_currentLatLng!, followZoomLevel);
    } catch (e) {
      // Ignore if controller is not ready
    }
  }

  Future<void> _fetchUserPosition() async {
    final pos = await widget.geolocation.currentPosition;
    print('[DynamicMapCard] Current user position: $pos');
    if (mounted) {
      setState(() {
        if (pos != null && isValidCoordinate(pos.latitude) && isValidCoordinate(pos.longitude)) {
          _currentLatLng = LatLng(pos.latitude, pos.longitude);

          // If in follow mode, update camera position
          if (_followUserMode && _currentLatLng != null) {
            _centerOnUser();
          }
        } else {
          _currentLatLng = null;
        }
        _isFetchingPosition = false;
        if (_isMapReady && !_followUserMode) _fitMapBounds();
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
    if (!_isMapReady || !mounted) return;

    final double defaultLat = _meetingPoint?.latitude ?? Config.DEFAULT_LAT1;
    final double defaultLon = _meetingPoint?.longitude ?? Config.DEFAULT_LON1;
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

    // Schedule move after frame to ensure controller is attached
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _mapController.move(center, zoom);
      } catch (e) {
        // Ignore if controller is not ready
      }
    });
  }

  Widget _userPositionMarker() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Icon(
        Icons.my_location,
        color: _userMarkerColor,
        size: _MapStyles.userIconSize,
      ),
    );
  }

  Widget _gatheringPointMarker() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Icon(
        Icons.location_pin,
        color: _gatheringMarkerColor,
        size: _MapStyles.rassemblementIconSize,
      ),
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
                          decoration: BoxDecoration(
                            color: _mapBaseType == _MapBaseType.satellite
                                ? Colors.grey.shade400.withOpacity(0.25)
                                : _MapStyles.zoneBorderColor.withOpacity(_MapStyles.zoneFillOpacity),
                            border: Border.all(
                              color: _mapBaseType == _MapBaseType.satellite
                                  ? Colors.grey.shade400
                                  : _MapStyles.zoneBorderColor,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
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
                        Icon(
                          Icons.location_pin,
                          color: _gatheringMarkerColor,
                          size: _MapStyles.legendRassemblementIconSize,
                        ),
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
                        Icon(
                          Icons.my_location,
                          color: _userMarkerColor,
                          size: _MapStyles.legendUserIconSize,
                        ),
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

    final double defaultLat = _meetingPoint?.latitude ?? Config.DEFAULT_LAT1;
    final double defaultLon = _meetingPoint?.longitude ?? Config.DEFAULT_LON1;
    double userLat = _currentLatLng?.latitude ?? defaultLat;
    double userLon = _currentLatLng?.longitude ?? defaultLon;

    final mapHeight = MediaQuery.of(context).size.height * 0.6;

    // Map tile selection logic (voyager and satellite)
    String urlTemplate;
    List<String> subdomains;
    String tooltip;
    IconData icon;
    // Polygon color logic
    Color polygonColor;
    Color polygonBorderColor;
    switch (_mapBaseType) {
      case _MapBaseType.voyager:
        // Use CartoDB Voyager for a modern, light, and clean look
        urlTemplate = "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png";
        subdomains = ['a', 'b', 'c', 'd'];
        tooltip = "Vue satellite";
        icon = Icons.satellite_alt;
        polygonColor = _MapStyles.zoneFillColor.withOpacity(_MapStyles.zoneFillOpacity);
        polygonBorderColor = _MapStyles.zoneBorderColor;
        break;
      case _MapBaseType.satellite:
      default:
        urlTemplate = "https://wmts10.geo.admin.ch/1.0.0/ch.swisstopo.swissimage/default/current/3857/{z}/{x}/{y}.jpeg";
        subdomains = [];
        tooltip = "Vue Swisstopo";
        icon = Icons.terrain;
        polygonColor = Colors.grey.shade400.withOpacity(0.25);
        polygonBorderColor = Colors.grey.shade400;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0, left: 16.0, bottom: 8.0, top: 16.0),
        ),
        Stack(
          children: [
            AbsorbPointer(
              absorbing: false,
              child: Container(
                height: mapHeight,
                margin: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(0.0),
                  color: Colors.white,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(0.0),
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
                            interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: urlTemplate,
                              subdomains: subdomains,
                              retinaMode: urlTemplate.contains('{r}') ? RetinaMode.isHighDensity(context) : false,
                              // attributionBuilder removed for flutter_map 7.x
                            ),
                            PolygonLayer(
                              polygons: [
                                Polygon(
                                  points: _zonePoints,
                                  color: polygonColor,
                                  borderColor: polygonBorderColor,
                                  borderStrokeWidth: 2,
                                ),
                              ],
                            ),
                            MarkerLayer(
                              markers: [
                                // Place meeting point first so it appears below user position
                                if (_meetingPoint != null)
                                  Marker(
                                    point: _meetingPoint!,
                                    width: _MapStyles.rassemblementIconSize,
                                    height: _MapStyles.rassemblementIconSize,
                                    child: _gatheringPointMarker(),
                                  ),
                                // User position marker appears last (on top)
                                if (_currentLatLng != null)
                                  Marker(
                                    point: _currentLatLng!,
                                    width: _MapStyles.userIconSize,
                                    height: _MapStyles.userIconSize,
                                    child: _userPositionMarker(),
                                  ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
            ),
            // Attribution overlay for map provider
            if ((!_isFetchingPosition && _isMapReady) &&
                (_mapBaseType == _MapBaseType.satellite || _mapBaseType == _MapBaseType.voyager))
              Positioned(
                bottom: 18,
                right: 24,
                child: Container(
                  color: Colors.white.withOpacity(0.7),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    _mapBaseType == _MapBaseType.voyager ? "© OpenStreetMap contributors © CARTO" : "© swisstopo",
                    style: const TextStyle(fontSize: 10, color: Colors.black87),
                  ),
                ),
              ),
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
                    // Map type toggle button
                    Material(
                      color: Colors.white.withOpacity(_MapStyles.legendBgOpacity),
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: IconButton(
                        icon: Icon(icon, color: Colors.black87),
                        tooltip: tooltip,
                        onPressed: () {
                          setState(() {
                            _mapBaseType =
                                _mapBaseType == _MapBaseType.satellite ? _MapBaseType.voyager : _MapBaseType.satellite;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Follow user toggle button
                    Material(
                      color: Colors.white.withOpacity(_MapStyles.legendBgOpacity),
                      shape: const CircleBorder(),
                      elevation: 2,
                      child: IconButton(
                        icon: Icon(
                          _followUserMode ? Icons.gps_fixed : Icons.gps_not_fixed,
                          color: _followUserMode ? Color(Config.COLOR_BUTTON) : Colors.black87,
                        ),
                        tooltip: _followUserMode ? "Arrêter de suivre ma position" : "Suivre ma position",
                        onPressed: () {
                          setState(() {
                            _followUserMode = !_followUserMode;

                            if (_followUserMode) {
                              // When enabling follow mode, center on user immediately
                              _centerOnUser();
                            } else {
                              // When disabling, return to fitting map bounds
                              _fitMapBounds();
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
