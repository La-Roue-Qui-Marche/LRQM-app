// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:lrqm/utils/config.dart';
import 'package:lrqm/geo/geolocation.dart';
import 'package:lrqm/data/user_data.dart';
import 'package:lrqm/api/user_controller.dart';
import 'package:lrqm/ui/Components/contribution_graph.dart';

class CardPersonalInfo extends StatefulWidget {
  final bool isSessionActive;
  final GeolocationController? geolocation;

  const CardPersonalInfo({
    super.key,
    required this.isSessionActive,
    this.geolocation,
  });

  @override
  State<CardPersonalInfo> createState() => _CardPersonalInfoState();
}

class _CardPersonalInfoState extends State<CardPersonalInfo> with SingleTickerProviderStateMixin {
  // Replace state variables with ValueNotifiers
  final ValueNotifier<int> _currentContributionNotifier = ValueNotifier<int>(0);

  // User data as ValueNotifiers
  final ValueNotifier<String> _bibNumberNotifier = ValueNotifier<String>("");
  final ValueNotifier<String> _userNameNotifier = ValueNotifier<String>("");
  final ValueNotifier<int> _totalDistanceNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _totalTimeNotifier = ValueNotifier<int>(0);

  // Session data as ValueNotifiers
  final ValueNotifier<int> _sessionDistanceNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _sessionTimeNotifier = ValueNotifier<int>(0);

  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(true);

  // Internal state for zone as ValueNotifiers
  final ValueNotifier<bool> _isCountingInZoneNotifier = ValueNotifier<bool>(true);

  // Sheet expansion controller
  final ValueNotifier<bool> _isExpandedNotifier = ValueNotifier<bool>(false);
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Track whether animation has completed for content display
  final ValueNotifier<bool> _showExpandedContentNotifier = ValueNotifier<bool>(false);

  // For drag gestures
  double _dragStartY = 0;
  double _dragDistance = 0;
  final double _dragThreshold = 50; // Distance needed to consider it a valid drag

  StreamSubscription? _geoSubscription;
  StreamSubscription? _zoneSubscription;

  @override
  void initState() {
    super.initState();
    _currentContributionNotifier.value = 0;
    _loadUserData();
    _setupGeolocationListener();
    _listenCountingInZone();

    // Initialize animation controller for expanding/collapsing with shorter duration for iOS-like snappiness
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200), // Shorter duration for snappier feel
    );

    // Use easeInOutBack for iOS-like rebound effect with overshoot
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
      reverseCurve: Curves.easeInBack,
    );

    // Add animation status listener to control content visibility
    _animationController.addStatusListener(_animationStatusListener);
  }

  @override
  void dispose() {
    _animationController.removeStatusListener(_animationStatusListener);
    _geoSubscription?.cancel();
    _zoneSubscription?.cancel();
    // Dispose all ValueNotifiers
    _currentContributionNotifier.dispose();
    _bibNumberNotifier.dispose();
    _userNameNotifier.dispose();
    _totalDistanceNotifier.dispose();
    _totalTimeNotifier.dispose();
    _sessionDistanceNotifier.dispose();
    _sessionTimeNotifier.dispose();
    _isLoadingNotifier.dispose();
    _isCountingInZoneNotifier.dispose();
    _isExpandedNotifier.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    _isLoadingNotifier.value = true;

    try {
      // Get bib ID
      final bibId = await UserData.getBibId();
      if (bibId != null) {
        _bibNumberNotifier.value = bibId;
      }

      // Get username
      final username = await UserData.getUsername();
      if (username != null) {
        _userNameNotifier.value = username;
      }

      // Get user ID for distance and time
      final userId = await UserData.getUserId();
      if (userId != null) {
        // Get total distance
        final distanceResult = await UserController.getUserTotalMeters(userId);
        if (!distanceResult.hasError) {
          final totalDistance = distanceResult.value ?? 0;
          _totalDistanceNotifier.value = totalDistance;
          // Set current contribution to total distance initially
          _currentContributionNotifier.value = totalDistance;
        }

        // Get total time
        final timeResult = await UserController.getUserTotalTime(userId);
        if (!timeResult.hasError) {
          _totalTimeNotifier.value = timeResult.value ?? 0;
        }
      }
    } catch (e) {
      developer.log("Error loading user data: $e");
    } finally {
      _isLoadingNotifier.value = false;
    }
  }

  void _listenCountingInZone() {
    if (widget.geolocation != null) {
      _zoneSubscription = widget.geolocation!.stream.listen((event) {
        final inZone = (event["isCountingInZone"] as num?)?.toInt() == 1;
        if (_isCountingInZoneNotifier.value != inZone) {
          _isCountingInZoneNotifier.value = inZone;
        }
      });
    }
  }

  void _setupGeolocationListener() {
    _geoSubscription?.cancel();

    if (widget.geolocation != null) {
      _geoSubscription = widget.geolocation!.stream.listen((event) {
        final int newDistance = (event["distance"] as num?)?.toInt() ?? 0;
        final int newTime = (event["time"] as num?)?.toInt() ?? 0;

        _sessionDistanceNotifier.value = newDistance;
        _sessionTimeNotifier.value = newTime;
        _currentContributionNotifier.value = newDistance;
      });
    }
  }

  @override
  void didUpdateWidget(covariant CardPersonalInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.geolocation != widget.geolocation) {
      _geoSubscription?.cancel();
      _zoneSubscription?.cancel();
      _setupGeolocationListener();
      _listenCountingInZone();
    }
  }

  void _toggleExpanded() {
    final newValue = !_isExpandedNotifier.value;
    _isExpandedNotifier.value = newValue;

    if (newValue) {
      _animationController.forward();
      // Content will be shown when animation completes via listener
    } else {
      // Hide content immediately when starting to collapse
      _showExpandedContentNotifier.value = false;
      _animationController.reverse();
    }
  }

  void _animationStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // Animation completed (fully expanded) - show content
      _showExpandedContentNotifier.value = true;
    } else if (status == AnimationStatus.reverse || status == AnimationStatus.dismissed) {
      // Starting to collapse or fully collapsed - hide content
      _showExpandedContentNotifier.value = false;
    }
  }

  // Handle drag gestures to expand/collapse
  void _onDragStart(DragStartDetails details) {
    _dragStartY = details.globalPosition.dy;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _dragDistance = _dragStartY - details.globalPosition.dy;
  }

  void _onDragEnd(DragEndDetails details) {
    if (_dragDistance.abs() > _dragThreshold) {
      if (_dragDistance > 0) {
        // Dragged upward - expand
        if (!_isExpandedNotifier.value) {
          _toggleExpanded();
        }
      } else {
        // Dragged downward - collapse
        if (_isExpandedNotifier.value) {
          _toggleExpanded();
        }
      }
    }
    // Reset values
    _dragStartY = 0;
    _dragDistance = 0;
  }

  @override
  Widget build(BuildContext context) {
    // Always use the bottom sheet implementation
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final collapsedHeight = 120.0;
        final expandedHeight = widget.isSessionActive ? 380.0 : 300.0;
        final height = collapsedHeight + (_animation.value * (expandedHeight - collapsedHeight));

        return Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: height,
            width: double.infinity,
            // Wrap the bottom sheet in a Stack to allow fixed positioning inside it
            child: Stack(
              children: [
                _buildDraggableBottomSheet(),
                Positioned(
                  top: 16,
                  right: 12,
                  child: _statusBadge(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDraggableBottomSheet() {
    return GestureDetector(
      onVerticalDragStart: _onDragStart,
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Drag handle with reduced padding
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            // Add title with reduced top padding
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 0, bottom: 0), // Reduced top padding from 4 to 0
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: ValueListenableBuilder<String>(
                        valueListenable: _userNameNotifier,
                        builder: (context, userName, _) {
                          return ValueListenableBuilder<String>(
                            valueListenable: _bibNumberNotifier,
                            builder: (context, bibNumber, _) {
                              return Text(
                                "${userName.isNotEmpty ? userName : ""} ${bibNumber.isNotEmpty ? '• N°$bibNumber' : ""}",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Scrollable content area
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Info cards with distance at the top - no padding
                    Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                      child: _buildInfoCards(),
                    ),
                    // Always build additional content, it will be hidden when collapsed
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _buildFunMessage(),
                          ),
                        ),
                        if (widget.isSessionActive)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                            child: ContributionGraph(geolocation: widget.geolocation),
                          ),
                        // Add message and animated arrow if session is not active
                        if (!widget.isSessionActive)
                          Padding(
                            padding: const EdgeInsets.only(top: 24, bottom: 16),
                            child: Column(
                              children: [
                                Text(
                                  "Appuie sur le bouton orange pour démarrer une session",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color(Config.accentColor),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                _AnimatedDownArrow(),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCards() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Distance info (50%)
        Expanded(
          flex: 1,
          child: ValueListenableBuilder<bool>(
            valueListenable: _isLoadingNotifier,
            builder: (context, isLoading, _) {
              return ValueListenableBuilder<int>(
                valueListenable: widget.isSessionActive ? _sessionDistanceNotifier : _totalDistanceNotifier,
                builder: (context, displayedDistance, _) {
                  return _infoCard(
                    label: 'Distance',
                    value: isLoading ? null : "${_formatDistance(displayedDistance)} m",
                    color: const Color(Config.primaryColor),
                    fontSize: 22,
                  );
                },
              );
            },
          ),
        ),
        // Vertical divider
        Container(
          height: 60,
          child: VerticalDivider(
            color: Color(Config.backgroundColor),
            width: 2,
            thickness: 1,
          ),
        ),
        // Time info (50%)
        Expanded(
          flex: 1,
          child: ValueListenableBuilder<bool>(
            valueListenable: _isLoadingNotifier,
            builder: (context, isLoading, _) {
              return ValueListenableBuilder<int>(
                valueListenable: widget.isSessionActive ? _sessionTimeNotifier : _totalTimeNotifier,
                builder: (context, displayedTime, _) {
                  return _infoCard(
                    label: 'Durée',
                    value: isLoading ? null : _formatModernTime(displayedTime),
                    color: const Color(Config.primaryColor),
                    fontSize: 22,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  // Remove fullWidth, add fontSize param
  Widget _infoCard({required String label, String? value, required Color color, double fontSize = 20}) {
    String mainValue = '';
    String unit = '';
    if (value != null && value.isNotEmpty) {
      final match = RegExp(r"^([\d\s'.,]+)\s*([a-zA-Z]*)$").firstMatch(value);
      if (match != null) {
        mainValue = match.group(1)?.trim() ?? value;
        unit = match.group(2)?.trim() ?? '';
      } else {
        mainValue = value;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row without icon
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),

          const SizedBox(height: 0),

          // Value display
          value != null && value.isNotEmpty
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      mainValue,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w600,
                        color: color,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (unit.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0, bottom: 2.0),
                        child: Text(
                          unit,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: color.withOpacity(0.8),
                          ),
                        ),
                      ),
                  ],
                )
              : Align(
                  alignment: Alignment.centerLeft,
                  child: _buildShimmer(width: 80, height: 26),
                ),
        ],
      ),
    );
  }

  Widget _buildShimmer({double width = 80, double height = 18}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _statusBadge() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isCountingInZoneNotifier,
      builder: (context, isCountingInZone, _) {
        String statusText;
        Color badgeColor;
        Color textColor = Colors.white;

        if (!widget.isSessionActive) {
          statusText = 'En pause';
          badgeColor = const Color(Config.backgroundColor);
          textColor = Colors.black87;
        } else if (!isCountingInZone) {
          statusText = 'Hors Zone';
          badgeColor = Colors.red.shade400;
        } else {
          statusText = 'Actif';
          badgeColor = Colors.green.shade400;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.circle,
                size: 10,
                color: !widget.isSessionActive ? Colors.black87 : Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                statusText,
                style: TextStyle(fontSize: 14, color: textColor),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFunMessage() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isLoadingNotifier,
      builder: (context, isLoading, _) {
        if (isLoading) {
          return _buildShimmer(width: double.infinity, height: 16);
        }
        return ValueListenableBuilder<int>(
          valueListenable: widget.isSessionActive ? _sessionDistanceNotifier : _totalDistanceNotifier,
          builder: (context, displayedDistance, _) {
            return Text(
              _getDistanceMessage(displayedDistance),
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            );
          },
        );
      },
    );
  }

  String _formatDistance(int distance) {
    if (distance <= 0) return "0";
    return distance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => "${m[1]}'");
  }

  String _formatModernTime(int seconds) {
    if (seconds < 0) seconds = 0;
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  String _getDistanceMessage(int distance) {
    if (distance == 0) {
      return "Vas-y, je suis prêt ! Commence à avancer pour faire progresser les mètres!";
    } else if (distance <= 100) {
      return "C'est ${(distance / 0.2).toStringAsFixed(0)} saucisses aux choux mis bout à bout. Quel papet!";
    } else if (distance <= 4000) {
      return "C'est ${(distance / 400).toStringAsFixed(1)} tour(s) de la piste de la Pontaise. Trop fort!";
    } else if (distance <= 38400) {
      return "C'est ${(distance / 12800).toStringAsFixed(1)} fois la distance Bottens-Lausanne. Tu es un champion!";
    } else {
      return "C'est ${(distance / 42195).toStringAsFixed(1)} marathon. Forme et détermination au top!";
    }
  }
}

// --- Animated down arrow widget ---
class _AnimatedDownArrow extends StatefulWidget {
  @override
  State<_AnimatedDownArrow> createState() => _AnimatedDownArrowState();
}

class _AnimatedDownArrowState extends State<_AnimatedDownArrow> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _animation.value),
        child: child,
      ),
      child: Icon(
        Icons.keyboard_double_arrow_down_rounded,
        size: 36,
        color: Color(Config.accentColor),
      ),
    );
  }
}
