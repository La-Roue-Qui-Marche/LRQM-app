// ignore_for_file: use_build_context_synchronously, prefer_const_constructors, prefer_const_literals_to_create_immutables, sized_box_for_whitespace

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:lrqm/utils/config.dart';
import 'package:lrqm/geo/geolocation.dart';
import 'package:lrqm/data/event_data.dart';

class CardDynamicMap extends StatefulWidget {
  final GeolocationController geolocation;
  final bool followUser;
  final bool fullScreen; // New parameter for full screen mode

  const CardDynamicMap({
    super.key,
    required this.geolocation,
    this.followUser = false,
    this.fullScreen = false, // Default to false for backward compatibility
  });

  @override
  // ignore: library_private_types_in_public_api
  _CardDynamicMapState createState() => _CardDynamicMapState();
}

class _CardDynamicMapState extends State<CardDynamicMap> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  final MapController _mapController = MapController();
  LatLng? _currentLatLng;
  bool _isFetchingPosition = true;
  bool _isMapReady = false;
  Timer? _positionTimer;
  bool _showLegend = false;
  bool _followUserMode = false;
  bool _initialFitDone = false;
  bool _enableZoomAnimation = true;

  List<LatLng> _zonePoints = [];
  LatLng? _meetingPoint;
  _MapBaseType _mapBaseType = _MapBaseType.voyager;

  AnimationController? _moveAnimController;

  @override
  void initState() {
    super.initState();
    _followUserMode = widget.followUser;
    _initZone();
    _initMeetingPoint();
    _initLocation();
  }

  @override
  void didUpdateWidget(covariant CardDynamicMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.followUser != oldWidget.followUser) {
      setState(() {
        _followUserMode = widget.followUser;
        if (_followUserMode) {
          _centerOnUser();
        } else {
          _fitMapBounds();
        }
      });
    }
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
    const double followZoomLevel = 17.5;
    try {
      // Offset the user marker 100px below the center of the map
      final offsetLatLng = _latLngFromOffset(_currentLatLng!, Offset(0, 50), followZoomLevel);
      _animatedMove(offsetLatLng, followZoomLevel);
    } catch (_) {}
  }

  /// Converts a pixel offset (from center) to a LatLng at the given zoom.
  LatLng _latLngFromOffset(LatLng center, Offset offset, double zoom) {
    // Get the map size in pixels at the current zoom
    final mapSize = 256 * pow(2, zoom);
    // Convert LatLng to world coordinates
    double x = (center.longitude + 180.0) / 360.0 * mapSize;
    double sinLat = sin(center.latitude * pi / 180.0);
    double y = (0.5 - log((1 + sinLat) / (1 - sinLat)) / (4 * pi)) * mapSize;

    // Apply pixel offset (y is inverted in screen coordinates)
    x += offset.dx;
    y += offset.dy;

    // Convert back to LatLng
    double lon = x / mapSize * 360.0 - 180.0;
    double n = pi - 2.0 * pi * y / mapSize;
    double lat = 180.0 / pi * atan(0.5 * (exp(n) - exp(-n)));
    return LatLng(lat, lon);
  }

  void _fitMapBounds() {
    if (!_isMapReady || !mounted) return;

    final double defaultLat = _meetingPoint?.latitude ?? Config.defaultLat1;
    final double defaultLon = _meetingPoint?.longitude ?? Config.defaultLon1;
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
    zoom -= 0.4; // Adjust zoom to fit the map better
    if (zoom < 2.0) zoom = 2.0;

    _animatedMove(center, zoom);
  }

  void _animatedMove(LatLng dest, double zoom) {
    if (!_enableZoomAnimation) {
      _mapController.move(dest, zoom);
      return;
    }
    final from = _mapController.camera.center;
    final fromZoom = _mapController.camera.zoom;
    _moveAnimController?.dispose();
    _moveAnimController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    final animation = CurvedAnimation(parent: _moveAnimController!, curve: Curves.easeOut);

    final latTween = Tween<double>(begin: from.latitude, end: dest.latitude);
    final lngTween = Tween<double>(begin: from.longitude, end: dest.longitude);
    final zoomTween = Tween<double>(begin: fromZoom, end: zoom);

    animation.addListener(() {
      final lat = latTween.evaluate(animation);
      final lng = lngTween.evaluate(animation);
      final z = zoomTween.evaluate(animation);
      _mapController.move(LatLng(lat, lng), z);
    });

    _moveAnimController!.forward();
  }

  double _latRad(double lat) => log((1 + sin(lat * pi / 180)) / (1 - sin(lat * pi / 180))) / 2;
  double _zoom(double mapPx, double worldPx, double fraction) => log(mapPx / worldPx / fraction) / ln2;

  @override
  void dispose() {
    _positionTimer?.cancel();
    _moveAnimController?.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // Prevent all text in this widget from being resizable by the OS
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Builder(
        builder: (context) {
          final defaultLat = _meetingPoint?.latitude ?? Config.defaultLat1;
          final defaultLon = _meetingPoint?.longitude ?? Config.defaultLon1;
          final userLat = _currentLatLng?.latitude ?? defaultLat;
          final userLon = _currentLatLng?.longitude ?? defaultLon;

          final styles = _mapBaseType == _MapBaseType.voyager ? _MapStyles.voyager : _MapStyles.satellite;

          String urlTemplate;
          List<String> subdomains;
          IconData icon;
          String tooltip;

          switch (_mapBaseType) {
            case _MapBaseType.voyager:
              urlTemplate = "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png";
              subdomains = ['a', 'b', 'c', 'd'];
              icon = Icons.map;
              tooltip = "Vue satellite";
              break;
            case _MapBaseType.satellite:
              urlTemplate =
                  "https://wmts10.geo.admin.ch/1.0.0/ch.swisstopo.swissimage/default/current/3857/{z}/{x}/{y}.jpeg";
              subdomains = [];
              icon = Icons.satellite_alt;
              tooltip = "Vue Swisstopo";
              break;
          }

          return Column(
            children: [
              if (_isFetchingPosition)
                Expanded(
                  child: Container(
                    color: Colors.white,
                    width: double.infinity,
                    child: Center(
                      child: Image.asset(
                        'assets/pictures/LogoSimpleAnimated.gif',
                        width: 32.0,
                      ),
                    ),
                  ),
                )
              else if (widget.fullScreen)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final mediaQuery = MediaQuery.of(context);
                    const double topBarHeight = 50.0;
                    const double navBarHeight = 80.0;
                    const double personalInfoCollapsedHeight = 190.0;
                    final double availableHeight = mediaQuery.size.height -
                        mediaQuery.padding.top -
                        mediaQuery.padding.bottom -
                        topBarHeight -
                        navBarHeight -
                        personalInfoCollapsedHeight;

                    return Container(
                      height: availableHeight > 0 ? availableHeight : 0,
                      width: double.infinity,
                      child: _buildMapStack(
                        userLat,
                        userLon,
                        urlTemplate,
                        subdomains,
                        icon,
                        tooltip,
                        styles,
                      ),
                    );
                  },
                )
              else
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: _buildMapStack(userLat, userLon, urlTemplate, subdomains, icon, tooltip, styles),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMapStack(
    double userLat,
    double userLon,
    String urlTemplate,
    List<String> subdomains,
    IconData icon,
    String tooltip,
    _MapStyleParams styles,
  ) {
    return Stack(
      children: [
        FlutterMap(
          key: const ValueKey("main-map"),
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(userLat, userLon),
            initialZoom: 6.0,
            // Block map rotation by removing InteractiveFlag.rotate
            interactionOptions: InteractionOptions(
              flags: _followUserMode ? (InteractiveFlag.none) : (InteractiveFlag.all & ~InteractiveFlag.rotate),
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
                  color: styles.polygonFillColor.withOpacity(styles.polygonFillOpacity),
                  borderColor: styles.polygonBorderColor.withOpacity(1),
                  borderStrokeWidth: 1,
                  strokeJoin: StrokeJoin.round,
                  pattern: StrokePattern.dashed(segments: [5, 5]),
                  strokeCap: StrokeCap.round,
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
                    child: Icon(Icons.location_pin, size: 34, color: styles.meetingPointColor),
                  ),
                if (_currentLatLng != null)
                  Marker(
                    point: _currentLatLng!,
                    width: 40,
                    height: 40,
                    child: PulsingLocationMarker(color: styles.userColor),
                  ),
              ],
            ),
          ],
        ),

        // --- North indicator floating top left ---
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.black54,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Button stack (info, map type, and tracing all top right)
        Positioned(
          top: 12,
          right: 12,
          child: Column(
            children: [
              _modernMapButton(
                icon: Icons.question_mark,
                onTap: () {
                  setState(() {
                    _showLegend = !_showLegend;
                  });
                },
              ),
              const SizedBox(height: 14),
              _modernMapButton(
                icon: icon,
                onTap: () {
                  setState(() {
                    _mapBaseType =
                        _mapBaseType == _MapBaseType.satellite ? _MapBaseType.voyager : _MapBaseType.satellite;
                  });
                },
                tooltip: tooltip,
              ),
              const SizedBox(height: 14),
              _modernMapButton(
                icon: Icons.navigation,
                iconColor: _followUserMode ? styles.userColor : Colors.black87,
                onTap: () {
                  setState(() {
                    _followUserMode = !_followUserMode;
                    if (_followUserMode) {
                      _centerOnUser();
                    } else {
                      _fitMapBounds();
                    }
                  });
                },
              ),
            ],
          ),
        ),

        // Fixed position legend popup (centered horizontally, top overlay)
        if (_showLegend)
          Positioned(
            top: 14,
            left: 120,
            right: 14,
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
                          color: styles.polygonFillColor.withOpacity(styles.polygonFillOpacity),
                          border: Border.all(color: styles.polygonBorderColor, width: 1),
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
                      Icon(Icons.location_pin, color: styles.meetingPointColor, size: 24),
                      const SizedBox(width: 10),
                      const Text("Point de rassemblement", style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: styles.userColor,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 2,
                                    spreadRadius: 0.5,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text("Votre position", style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.navigation, color: styles.userColor, size: 22),
                      const SizedBox(width: 10),
                      const Text("Suivi/centrage", style: TextStyle(fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

        // --- Map credits centered top ---
        if (!_showLegend)
          Positioned(
            top: 10,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  _mapBaseType == _MapBaseType.satellite ? "© Swisstopo" : "© OpenStreetMap x © CARTO",
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black38,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // --- Modern flat round map button ---
  Widget _modernMapButton({
    required IconData icon,
    VoidCallback? onTap,
    String? tooltip,
    Color iconColor = Colors.black87,
  }) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        borderRadius: BorderRadius.circular(40),
        onTap: onTap,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(1),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.grey.withOpacity(0.18),
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.all(0),
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: iconColor,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class PulsingLocationMarker extends StatefulWidget {
  final Color color;

  const PulsingLocationMarker({
    Key? key,
    required this.color,
  }) : super(key: key);

  @override
  State<PulsingLocationMarker> createState() => _PulsingLocationMarkerState();
}

class _PulsingLocationMarkerState extends State<PulsingLocationMarker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulsing circle
          AnimatedBuilder(
            animation: _animation,
            builder: (_, __) {
              return Container(
                width: 48 * _animation.value,
                height: 48 * _animation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.color.withOpacity(0.3 * (1 - _animation.value)),
                ),
              );
            },
          ),
          // Inner circle with border
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _MapBaseType { satellite, voyager }

class _MapStyles {
  static const double zoneFillOpacity = 0.05;

  static const voyager = _MapStyleParams(
    userColor: Color(Config.primaryColor),
    meetingPointColor: Colors.redAccent,
    polygonFillOpacity: zoneFillOpacity,
    polygonBorderColor: Color(Config.primaryColor),
    polygonFillColor: Color(Config.primaryColor),
  );

  static final satellite = _MapStyleParams(
    userColor: Colors.pinkAccent,
    meetingPointColor: Colors.tealAccent,
    polygonFillOpacity: zoneFillOpacity,
    polygonBorderColor: Colors.white,
    polygonFillColor: Colors.white,
  );
}

class _MapStyleParams {
  final Color userColor;
  final Color meetingPointColor;
  final double polygonFillOpacity;
  final Color polygonBorderColor;
  final Color polygonFillColor;

  const _MapStyleParams({
    required this.userColor,
    required this.meetingPointColor,
    required this.polygonFillOpacity,
    required this.polygonBorderColor,
    required this.polygonFillColor,
  });
}
