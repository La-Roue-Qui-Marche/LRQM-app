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
  final bool isFloating;

  const CardPersonalInfo({
    super.key,
    required this.isSessionActive,
    this.geolocation,
    this.isFloating = false,
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

    // Initialize animation controller for expanding/collapsing
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
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
    } else {
      _animationController.reverse();
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
    if (!widget.isFloating) {
      // Original implementation for non-floating mode
      return Container(
        color: const Color(Config.backgroundColor),
        child: _buildCard(widget.isSessionActive),
      );
    }

    // New implementation with fixed heights instead of proportional sizing
    return Container(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          // Use fixed heights instead of height factors
          final collapsedHeight = 210.0; // Height when collapsed
          final expandedHeight = 520.0; // Height when expanded

          // Interpolate between the two heights based on animation value
          final height = collapsedHeight + (_animation.value * (expandedHeight - collapsedHeight));

          return Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: height,
              width: double.infinity,
              child: _buildDraggableBottomSheet(),
            ),
          );
        },
      ),
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ValueListenableBuilder<bool>(
          valueListenable: _isExpandedNotifier,
          builder: (context, isExpanded, _) {
            return Column(
              children: [
                // Drag handle
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
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

                // Scrollable content area
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header with basic info (always visible)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        '№ de dossard: ',
                                        style:
                                            TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                                      ),
                                      ValueListenableBuilder<bool>(
                                        valueListenable: _isLoadingNotifier,
                                        builder: (context, isLoading, _) {
                                          return ValueListenableBuilder<String>(
                                            valueListenable: _bibNumberNotifier,
                                            builder: (context, bibNumber, _) {
                                              return isLoading || bibNumber.isEmpty
                                                  ? _buildShimmer(width: 40)
                                                  : Text(
                                                      bibNumber,
                                                      style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.w600,
                                                          color: Colors.black87),
                                                    );
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  ValueListenableBuilder<bool>(
                                    valueListenable: _isLoadingNotifier,
                                    builder: (context, isLoading, _) {
                                      return ValueListenableBuilder<String>(
                                        valueListenable: _userNameNotifier,
                                        builder: (context, userName, _) {
                                          if (isLoading) {
                                            return _buildShimmer(width: 100);
                                          } else if (userName.isNotEmpty) {
                                            return Text(
                                              userName,
                                              style: const TextStyle(fontSize: 18, color: Colors.black87),
                                            );
                                          } else {
                                            return const SizedBox.shrink();
                                          }
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                              // Status badge
                              _statusBadge(),
                            ],
                          ),
                        ),

                        // Info cards (always visible)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                          child: _buildInfoCards(),
                        ),

                        // Only show if expanded
                        AnimatedCrossFade(
                          firstChild: const SizedBox(height: 1), // Small placeholder when collapsed
                          secondChild: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                                child: _buildFunMessage(),
                              ),
                              if (widget.isSessionActive)
                                const Divider(color: Color(Config.backgroundColor), thickness: 1),
                              if (widget.isSessionActive)
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                                  child: ContributionGraph(geolocation: widget.geolocation),
                                ),
                            ],
                          ),
                          crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 200),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard(bool isSessionActive) {
    return Stack(
      children: [
        Container(
          margin: widget.isFloating
              ? EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0)
              : EdgeInsets.only(bottom: 0.0, right: 0.0, left: 0.0, top: 8.0),
          padding: EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(widget.isFloating ? 20.0 : 0.0),
            boxShadow: widget.isFloating
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              SizedBox(height: 12),
              _buildInfoCards(),
              SizedBox(height: 16),
              _buildFunMessage(),
              if (isSessionActive) SizedBox(height: 8),
              if (isSessionActive) Divider(color: Color(Config.backgroundColor), thickness: 1),
              if (isSessionActive) SizedBox(height: 8),
              if (isSessionActive) ContributionGraph(geolocation: widget.geolocation),
            ],
          ),
        ),
        Positioned(
          top: 32.0,
          right: 32.0,
          child: _statusBadge(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        '№ de dossard: ',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: _isLoadingNotifier,
                        builder: (context, isLoading, _) {
                          return ValueListenableBuilder<String>(
                            valueListenable: _bibNumberNotifier,
                            builder: (context, bibNumber, _) {
                              return isLoading || bibNumber.isEmpty
                                  ? _buildShimmer(width: 40)
                                  : Text(
                                      bibNumber,
                                      style: const TextStyle(
                                          fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                                    );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  ValueListenableBuilder<bool>(
                    valueListenable: _isLoadingNotifier,
                    builder: (context, isLoading, _) {
                      return ValueListenableBuilder<String>(
                        valueListenable: _userNameNotifier,
                        builder: (context, userName, _) {
                          if (isLoading) {
                            return _buildShimmer(width: 100);
                          } else if (userName.isNotEmpty) {
                            return Text(
                              userName,
                              style: const TextStyle(fontSize: 18, color: Colors.black87),
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCards() {
    return Row(
      children: [
        Expanded(
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
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ValueListenableBuilder<bool>(
            valueListenable: _isLoadingNotifier,
            builder: (context, isLoading, _) {
              return ValueListenableBuilder<int>(
                valueListenable: widget.isSessionActive ? _sessionTimeNotifier : _totalTimeNotifier,
                builder: (context, displayedTime, _) {
                  return _infoCard(
                    label: 'Temps total',
                    value: isLoading ? null : _formatModernTime(displayedTime),
                    color: const Color(Config.primaryColor),
                  );
                },
              );
            },
          ),
        ),
      ],
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

  Widget _infoCard({required String label, String? value, required Color color}) {
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
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Color(Config.backgroundColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 2),
          value != null && value.isNotEmpty
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      mainValue,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
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
                            color: color.withOpacity(0.85),
                          ),
                        ),
                      ),
                  ],
                )
              : _buildShimmer(width: 60, height: 26),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(12),
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
