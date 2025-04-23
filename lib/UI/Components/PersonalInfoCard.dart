import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../Utils/config.dart';
import '../../Geolocalisation/Geolocation.dart';
import '../../Data/UserData.dart';
import '../../Data/MeasureData.dart';
import '../../API/NewUserController.dart';
import '../../Utils/Result.dart';
import 'ContributionGraph.dart';

class PersonalInfoCard extends StatefulWidget {
  final bool isSessionActive;
  final bool isCountingInZone;
  final Geolocation? geolocation;

  const PersonalInfoCard({
    super.key,
    required this.isSessionActive,
    required this.isCountingInZone,
    this.geolocation,
  });

  @override
  State<PersonalInfoCard> createState() => _PersonalInfoCardState();
}

class _PersonalInfoCardState extends State<PersonalInfoCard> with SingleTickerProviderStateMixin {
  // State variables
  late int _currentContribution;
  final List<Widget> _particles = [];

  // User data
  String _bibNumber = "";
  String _userName = "";
  int _totalDistance = 0;
  int _totalTime = 0;

  // Session data
  int _sessionDistance = 0;
  int _sessionTime = 0;

  bool _isLoading = true;
  StreamSubscription? _geoSubscription;

  @override
  void initState() {
    super.initState();
    _currentContribution = 0;
    _loadUserData();
    _setupGeolocationListener();
  }

  @override
  void dispose() {
    _geoSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get bib ID
      final bibId = await UserData.getBibId();
      if (bibId != null && mounted) {
        setState(() {
          _bibNumber = bibId;
        });
      }

      // Get username
      final username = await UserData.getUsername();
      if (username != null && mounted) {
        setState(() {
          _userName = username;
        });
      }

      // Get user ID for distance and time
      final userId = await UserData.getUserId();
      if (userId != null && mounted) {
        // Get total distance
        final distanceResult = await NewUserController.getUserTotalMeters(userId);
        if (!distanceResult.hasError && mounted) {
          setState(() {
            _totalDistance = distanceResult.value ?? 0;
            // Set current contribution to total distance initially
            // If session is active, it will be updated by the geolocation stream
            _currentContribution = _totalDistance;
          });
        }

        // Get total time
        final timeResult = await NewUserController.getUserTotalTime(userId);
        if (!timeResult.hasError && mounted) {
          setState(() {
            _totalTime = timeResult.value ?? 0;
          });
        }
      }

      // For active sessions, initial values come from geolocation stream
      // Don't need to fetch them here since they will be updated by the listener
    } catch (e) {
      developer.log("Error loading user data: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _setupGeolocationListener() {
    // Cancel any existing subscription first
    _geoSubscription?.cancel();

    if (widget.geolocation != null && widget.isSessionActive) {
      _geoSubscription = widget.geolocation!.stream.listen((event) {
        if (mounted) {
          // Add null checks for the distance and time
          final int newDistance = (event["distance"] as num?)?.toInt() ?? 0;
          final int newTime = (event["time"] as num?)?.toInt() ?? 0;

          setState(() {
            _sessionDistance = newDistance;
            _sessionTime = newTime;

            // Check for distance increase
            if (_sessionDistance > _currentContribution) {
              final int diff = _sessionDistance - _currentContribution;
              _spawnParticle("+$diff m");
              _currentContribution = _sessionDistance;
            }
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant PersonalInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If session status changed
    if (oldWidget.isSessionActive != widget.isSessionActive) {
      _loadUserData();

      // Update geolocation listener
      _geoSubscription?.cancel();
      _setupGeolocationListener();
    }
  }

  void _spawnParticle(String label) {
    final random = Random();
    final dx = random.nextDouble() * 60 - 30;
    final dy = random.nextDouble() * -60 - 30;

    final particle = _AnimatedParticle(
      offsetX: dx,
      offsetY: dy,
      label: label,
    );

    setState(() {
      _particles.add(particle);
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _particles.remove(particle);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Use current session values when session is active, otherwise use totals
    // Add null safety
    final int displayedDistance = widget.isSessionActive ? _sessionDistance : _totalDistance;
    final int displayedTime = widget.isSessionActive ? _sessionTime : _totalTime;

    return Stack(
      children: [
        _buildCard(displayedDistance, displayedTime),
        ..._particles,
      ],
    );
  }

  Widget _buildCard(int displayedDistance, int displayedTime) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 1.0, right: 0.0, left: 0.0, top: 6.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(0.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ta contribution à l\'événement',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildHeader(),
              const SizedBox(height: 12),
              _buildInfoCards(displayedDistance, displayedTime),
              const SizedBox(height: 16),
              _buildFunMessage(displayedDistance),
              if (widget.isSessionActive) const SizedBox(height: 8),
              if (widget.isSessionActive) const Divider(color: Color(Config.backgroundColor), thickness: 1),
              if (widget.isSessionActive) const SizedBox(height: 8),
              if (widget.isSessionActive) ContributionGraph(geolocation: widget.geolocation),
            ],
          ),
        ),
        Positioned(
          top: 72,
          right: 16,
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      _isLoading || _bibNumber.isEmpty
                          ? _buildShimmer(width: 40)
                          : Text(
                              _bibNumber,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                            ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (_isLoading)
                        _buildShimmer(width: 100)
                      else if (_userName.isNotEmpty)
                        Text(
                          _userName,
                          style: const TextStyle(fontSize: 18, color: Colors.black87),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCards(int displayedDistance, int displayedTime) {
    return Row(
      children: [
        Expanded(
          child: _infoCard(
            label: 'Distance',
            value: _isLoading ? null : "${_formatDistance(displayedDistance)} m",
            color: const Color(Config.primaryColor),
          ),
        ),
        const SizedBox(width: 16), // 16px horizontal space between the cards
        Expanded(
          child: _infoCard(
            label: 'Temps total',
            value: _isLoading ? null : _formatModernTime(displayedTime),
            color: const Color(Config.primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildFunMessage(int displayedDistance) {
    if (_isLoading) {
      return _buildShimmer(width: double.infinity, height: 16);
    }
    return Text(
      _getDistanceMessage(displayedDistance),
      style: const TextStyle(fontSize: 16, color: Colors.black87),
    );
  }

  Widget _infoCard({required String label, String? value, required Color color}) {
    // Extract value and unit if possible
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
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 4),
          value != null && value.isNotEmpty
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      mainValue,
                      style: TextStyle(
                        fontSize: 20,
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
    String statusText;
    Color badgeColor;
    Color textColor = Colors.white;

    if (!widget.isSessionActive) {
      statusText = 'En pause';
      badgeColor = const Color(Config.backgroundColor);
      textColor = Colors.black87;
    } else if (!widget.isCountingInZone) {
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
            color: !widget.isSessionActive ? Colors.black87 : Colors.white, // Change to black if "En pause"
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(fontSize: 14, color: textColor),
          ),
        ],
      ),
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

class _AnimatedParticle extends StatefulWidget {
  final double offsetX;
  final double offsetY;
  final String label;

  const _AnimatedParticle({required this.offsetX, required this.offsetY, required this.label});

  @override
  State<_AnimatedParticle> createState() => _AnimatedParticleState();
}

class _AnimatedParticleState extends State<_AnimatedParticle> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        return Positioned(
          top: 200 - widget.offsetY * _controller.value,
          left: MediaQuery.of(context).size.width / 3.5 + widget.offsetX * _controller.value,
          child: Opacity(
            opacity: 1 - _controller.value,
            child: Text(
              widget.label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.greenAccent,
              ),
            ),
          ),
        );
      },
    );
  }
}
