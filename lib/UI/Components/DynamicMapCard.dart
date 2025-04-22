// ignore_for_file: use_build_context_synchronously

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

class _DynamicMapCardState extends State<DynamicMapCard> with AutomaticKeepAliveClientMixin {
  final MapController _mapController = MapController();
  LatLng? _currentLatLng;
  bool _isFetchingPosition = true;
  bool _isMapReady = false;
  Timer? _positionTimer;
  bool _showLegend = false;
  bool _followUserMode = false;
  bool _initialFitDone = false;

  List<LatLng> _zonePoints = [];
  LatLng? _meetingPoint;
  _MapBaseType _mapBaseType = _MapBaseType.voyager;

  @override
  void initState() {
    super.initState();
    _initZone();
    _initMeetingPoint();
    _initLocation();
  }

  Future<void> _initZone() async {
    final zone = await EventData.getSiteCoordLatLngList();
    setState(() {
      _zonePoints = zone?.map((p) => LatLng(p.latitude, p.longitude)).toList() ?? [];
    });
  }

  Future<void> _initMeetingPoint() async {
    final points = await EventData.getMeetingPointLatLngList();
    setState(() {
      _meetingPoint = (points != null && points.isNotEmpty) ? LatLng(points[0].latitude, points[0].longitude) : null;
    });
  }

  Future<void> _initLocation() async {
    _fetchUserPosition();
    _positionTimer = Timer.periodic(const Duration(seconds: 1), (_) => _fetchUserPosition());
  }

  Future<void> _fetchUserPosition() async {
    final pos = await widget.geolocation.currentPosition;
    if (!mounted) return;

    setState(() {
      if (pos != null && pos.latitude.isFinite && pos.longitude.isFinite) {
        _currentLatLng = LatLng(pos.latitude, pos.longitude);

        if (_followUserMode) {
          _centerOnUser();
        }
      }

      _isFetchingPosition = false;
    });
  }

  void _centerOnUser() {
    if (_currentLatLng == null || !_isMapReady) return;
    const double followZoomLevel = 17.0;
    try {
      _mapController.move(_currentLatLng!, followZoomLevel);
    } catch (_) {}
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

    double latZoom = _zoom(mapSize.height, 256, (_latRad(maxLat) - _latRad(minLat)) / pi);
    double lonZoom = _zoom(mapSize.width, 256, (maxLon - minLon) / 360);
    double zoom = min(latZoom, lonZoom);

    if (!zoom.isFinite || zoom < 2.0) zoom = 5.0;
    zoom -= 0.3;
    if (zoom < 2.0) zoom = 2.0;

    _mapController.move(center, zoom);
  }

  double _latRad(double lat) => log((1 + sin(lat * pi / 180)) / (1 - sin(lat * pi / 180))) / 2;
  double _zoom(double mapPx, double worldPx, double fraction) => log(mapPx / worldPx / fraction) / ln2;

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
    final defaultLat = _meetingPoint?.latitude ?? Config.DEFAULT_LAT1;
    final defaultLon = _meetingPoint?.longitude ?? Config.DEFAULT_LON1;
    final userLat = _currentLatLng?.latitude ?? defaultLat;
    final userLon = _currentLatLng?.longitude ?? defaultLon;

    String urlTemplate;
    List<String> subdomains;
    IconData icon;
    String tooltip;
    Color polygonColor;
    Color polygonBorderColor;
    Color userColor;
    Color meetingPointColor;

    switch (_mapBaseType) {
      case _MapBaseType.voyager:
        urlTemplate = "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png";
        subdomains = ['a', 'b', 'c', 'd'];
        icon = Icons.satellite_alt;
        tooltip = "Vue satellite";
        polygonColor = _MapStyles.zoneFillColor.withOpacity(_MapStyles.zoneFillOpacity);
        polygonBorderColor = _MapStyles.zoneBorderColor;
        userColor = Color(Config.COLOR_APP_BAR);
        meetingPointColor = Colors.redAccent;
        break;
      case _MapBaseType.satellite:
        urlTemplate = "https://wmts10.geo.admin.ch/1.0.0/ch.swisstopo.swissimage/default/current/3857/{z}/{x}/{y}.jpeg";
        subdomains = [];
        icon = Icons.terrain;
        tooltip = "Vue Swisstopo";
        polygonColor = Colors.grey.shade400.withOpacity(0.25);
        polygonBorderColor = Colors.grey.shade400;
        userColor = Colors.pinkAccent;
        meetingPointColor = Colors.tealAccent;
        break;
    }

    return Column(
      children: [
        if (_isFetchingPosition)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Chargement de la carte..."),
          )
        else
          Stack(
            children: [
              AbsorbPointer(
                absorbing: true,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: FlutterMap(
                    key: const ValueKey("main-map"),
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(userLat, userLon),
                      initialZoom: 5.0,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.none,
                      ),
                      onMapReady: () {
                        _isMapReady = true;
                        if (!_followUserMode && !_initialFitDone) {
                          Future.delayed(const Duration(milliseconds: 200), () {
                            if (mounted) {
                              _fitMapBounds();
                              _initialFitDone = true;
                            }
                          });
                        }
                      },
                    ),
                    children: [
                      TileLayer(
                        key: ValueKey("tiles-${_mapBaseType.toString()}"),
                        urlTemplate: urlTemplate,
                        subdomains: subdomains,
                        retinaMode: urlTemplate.contains('{r}') ? RetinaMode.isHighDensity(context) : false,
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
                          if (_meetingPoint != null)
                            Marker(
                              point: _meetingPoint!,
                              width: 34,
                              height: 34,
                              child: Icon(Icons.location_pin, size: 34, color: meetingPointColor),
                            ),
                          if (_currentLatLng != null)
                            Marker(
                              point: _currentLatLng!,
                              width: 36,
                              height: 36,
                              child: Icon(Icons.my_location, size: 36, color: userColor),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // --- North indicator floating top left ---
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(_MapStyles.legendBgOpacity),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.navigation, color: Colors.redAccent, size: 18),
                        Text(
                          "N",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Button stack (top right)
              Positioned(
                top: 20,
                right: 20,
                child: Column(
                  children: [
                    FloatingActionButton(
                      heroTag: "legend",
                      mini: true,
                      backgroundColor: Colors.white.withOpacity(_MapStyles.legendBgOpacity),
                      onPressed: () {
                        setState(() {
                          _showLegend = !_showLegend;
                        });
                      },
                      child: const Icon(Icons.info_outline, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton(
                      heroTag: "map-type",
                      mini: true,
                      backgroundColor: Colors.white.withOpacity(_MapStyles.legendBgOpacity),
                      onPressed: () {
                        setState(() {
                          _mapBaseType =
                              _mapBaseType == _MapBaseType.satellite ? _MapBaseType.voyager : _MapBaseType.satellite;
                        });
                      },
                      child: Icon(icon, color: Colors.black87),
                      tooltip: tooltip,
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton(
                      heroTag: "follow-user",
                      mini: true,
                      backgroundColor: Colors.white.withOpacity(_MapStyles.legendBgOpacity),
                      onPressed: () {
                        setState(() {
                          _followUserMode = !_followUserMode;
                          if (_followUserMode) {
                            _centerOnUser();
                          } else {
                            _fitMapBounds();
                          }
                        });
                      },
                      child: Icon(
                        _followUserMode ? Icons.gps_fixed : Icons.gps_not_fixed,
                        color: _followUserMode ? userColor : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              // Fixed position legend popup (centered horizontally, top overlay)
              if (_showLegend)
                Positioned(
                  top: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.only(top: 6, left: 16, right: 16, bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(1),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Légende", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () => setState(() => _showLegend = false),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                color: polygonColor,
                                border: Border.all(color: polygonBorderColor, width: 2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text("Zone de l'événement", style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.location_pin, color: meetingPointColor, size: 24),
                            const SizedBox(width: 10),
                            const Text("Point de rassemblement", style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.my_location, color: userColor, size: 24),
                            const SizedBox(width: 10),
                            const Text("Votre position", style: TextStyle(fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              // --- Map credits bottom right ---
              Positioned(
                bottom: 10,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(0),
                  ),
                  child: Text(
                    _mapBaseType == _MapBaseType.satellite ? "© Swisstopo" : "© OpenStreetMap x © CARTO",
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

enum _MapBaseType { satellite, voyager }

class _MapStyles {
  static const Color zoneBorderColor = Color(Config.COLOR_APP_BAR);
  static const Color zoneFillColor = Color(Config.COLOR_APP_BAR);
  static const double zoneFillOpacity = 0.1;
  static const double legendBgOpacity = 0.95;
  static const double userIconSize = 36;
  static const double rassemblementIconSize = 34;
}
