// Full regenerated PersonalInfoCard with _StaticCard
import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../Utils/config.dart';
import '../../Geolocalisation/Geolocation.dart';
import '../../Data/UserData.dart';
import '../../API/NewUserController.dart';
import 'ContributionGraph.dart';

class PersonalInfoCard extends StatefulWidget {
  final bool isSessionActive;
  final Geolocation? geolocation;

  const PersonalInfoCard({super.key, required this.isSessionActive, this.geolocation});

  @override
  State<PersonalInfoCard> createState() => _PersonalInfoCardState();
}

class _PersonalInfoCardState extends State<PersonalInfoCard> with SingleTickerProviderStateMixin {
  final ValueNotifier<int> _currentContributionNotifier = ValueNotifier<int>(0);
  final ValueNotifier<String> _bibNumberNotifier = ValueNotifier<String>("");
  final ValueNotifier<String> _userNameNotifier = ValueNotifier<String>("");
  final ValueNotifier<int> _totalDistanceNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _totalTimeNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _sessionDistanceNotifier = ValueNotifier<int>(0);
  final ValueNotifier<int> _sessionTimeNotifier = ValueNotifier<int>(0);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier<bool>(true);
  final ValueNotifier<bool> _isCountingInZoneNotifier = ValueNotifier<bool>(true);

  StreamSubscription? _geoSubscription;
  StreamSubscription? _zoneSubscription;

  int _lastSessionDistance = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setupGeolocationListener();
    _listenCountingInZone();
  }

  @override
  void dispose() {
    _geoSubscription?.cancel();
    _zoneSubscription?.cancel();
    _currentContributionNotifier.dispose();
    _bibNumberNotifier.dispose();
    _userNameNotifier.dispose();
    _totalDistanceNotifier.dispose();
    _totalTimeNotifier.dispose();
    _sessionDistanceNotifier.dispose();
    _sessionTimeNotifier.dispose();
    _isLoadingNotifier.dispose();
    _isCountingInZoneNotifier.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    _isLoadingNotifier.value = true;
    try {
      final bibId = await UserData.getBibId();
      if (bibId != null) _bibNumberNotifier.value = bibId;

      final username = await UserData.getUsername();
      if (username != null) _userNameNotifier.value = username;

      final userId = await UserData.getUserId();
      if (userId != null) {
        final distanceResult = await NewUserController.getUserTotalMeters(userId);
        if (!distanceResult.hasError) _totalDistanceNotifier.value = distanceResult.value ?? 0;

        final timeResult = await NewUserController.getUserTotalTime(userId);
        if (!timeResult.hasError) _totalTimeNotifier.value = timeResult.value ?? 0;
      }
    } catch (e) {
      developer.log("Error loading user data: $e");
    } finally {
      _isLoadingNotifier.value = false;
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
        _lastSessionDistance = newDistance;
        _currentContributionNotifier.value = newDistance;
      });
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _StaticCard(
          isSessionActive: widget.isSessionActive,
          bibNumberNotifier: _bibNumberNotifier,
          userNameNotifier: _userNameNotifier,
          totalDistanceNotifier: _totalDistanceNotifier,
          totalTimeNotifier: _totalTimeNotifier,
          sessionDistanceNotifier: _sessionDistanceNotifier,
          sessionTimeNotifier: _sessionTimeNotifier,
          isLoadingNotifier: _isLoadingNotifier,
          isCountingInZoneNotifier: _isCountingInZoneNotifier,
          geolocation: widget.geolocation,
        ),
      ],
    );
  }
}

class _StaticCard extends StatelessWidget {
  final bool isSessionActive;
  final Geolocation? geolocation;
  final ValueNotifier<String> bibNumberNotifier;
  final ValueNotifier<String> userNameNotifier;
  final ValueNotifier<int> totalDistanceNotifier;
  final ValueNotifier<int> totalTimeNotifier;
  final ValueNotifier<int> sessionDistanceNotifier;
  final ValueNotifier<int> sessionTimeNotifier;
  final ValueNotifier<bool> isLoadingNotifier;
  final ValueNotifier<bool> isCountingInZoneNotifier;

  const _StaticCard({
    required this.isSessionActive,
    required this.geolocation,
    required this.bibNumberNotifier,
    required this.userNameNotifier,
    required this.totalDistanceNotifier,
    required this.totalTimeNotifier,
    required this.sessionDistanceNotifier,
    required this.sessionTimeNotifier,
    required this.isLoadingNotifier,
    required this.isCountingInZoneNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6.0),
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
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          _buildHeader(),
          const SizedBox(height: 12),
          _buildInfoCards(),
          const SizedBox(height: 16),
          _buildFunMessage(),
          if (isSessionActive) ...[
            const SizedBox(height: 8),
            const Divider(color: Color(Config.backgroundColor), thickness: 1),
            const SizedBox(height: 8),
            ContributionGraph(geolocation: geolocation),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
                    valueListenable: isLoadingNotifier,
                    builder: (_, isLoading, __) {
                      return ValueListenableBuilder<String>(
                        valueListenable: bibNumberNotifier,
                        builder: (_, bibNumber, __) {
                          if (isLoading || bibNumber.isEmpty) {
                            return _buildShimmer(width: 40);
                          }
                          return Text(
                            bibNumber,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 2),
              ValueListenableBuilder<bool>(
                valueListenable: isLoadingNotifier,
                builder: (_, isLoading, __) {
                  return ValueListenableBuilder<String>(
                    valueListenable: userNameNotifier,
                    builder: (_, username, __) {
                      if (isLoading || username.isEmpty) {
                        return _buildShimmer(width: 100);
                      }
                      return Text(username, style: const TextStyle(fontSize: 18, color: Colors.black87));
                    },
                  );
                },
              ),
            ],
          ),
        ),
        _buildStatusBadge(),
      ],
    );
  }

  Widget _buildInfoCards() {
    return Row(
      children: [
        Expanded(child: _buildDistanceCard()),
        const SizedBox(width: 16),
        Expanded(child: _buildTimeCard()),
      ],
    );
  }

  Widget _buildDistanceCard() {
    return ValueListenableBuilder<bool>(
      valueListenable: isLoadingNotifier,
      builder: (_, isLoading, __) {
        return ValueListenableBuilder<int>(
          valueListenable: isSessionActive ? sessionDistanceNotifier : totalDistanceNotifier,
          builder: (_, value, __) {
            return _infoCard(
              label: 'Distance',
              value: isLoading ? null : "${_formatDistance(value)} m",
              color: const Color(Config.primaryColor),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeCard() {
    return ValueListenableBuilder<bool>(
      valueListenable: isLoadingNotifier,
      builder: (_, isLoading, __) {
        return ValueListenableBuilder<int>(
          valueListenable: isSessionActive ? sessionTimeNotifier : totalTimeNotifier,
          builder: (_, value, __) {
            return _infoCard(
              label: 'Temps total',
              value: isLoading ? null : _formatTime(value),
              color: const Color(Config.primaryColor),
            );
          },
        );
      },
    );
  }

  Widget _buildFunMessage() {
    return ValueListenableBuilder<bool>(
      valueListenable: isLoadingNotifier,
      builder: (_, isLoading, __) {
        if (isLoading) {
          return _buildShimmer(width: double.infinity, height: 16);
        }
        return ValueListenableBuilder<int>(
          valueListenable: isSessionActive ? sessionDistanceNotifier : totalDistanceNotifier,
          builder: (_, distance, __) {
            return Text(
              _getDistanceMessage(distance),
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            );
          },
        );
      },
    );
  }

  Widget _infoCard({required String label, String? value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black87.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 4),
          value != null
              ? Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                )
              : _buildShimmer(width: 60, height: 26),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return ValueListenableBuilder<bool>(
      valueListenable: isCountingInZoneNotifier,
      builder: (_, isCounting, __) {
        String text;
        Color badgeColor;
        Color textColor = Colors.white;

        if (!isSessionActive) {
          text = 'En pause';
          badgeColor = const Color(Config.backgroundColor);
          textColor = Colors.black87;
        } else if (!isCounting) {
          text = 'Hors Zone';
          badgeColor = Colors.red.shade400;
        } else {
          text = 'Actif';
          badgeColor = Colors.green.shade400;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 10, color: textColor),
              const SizedBox(width: 6),
              Text(text, style: TextStyle(fontSize: 14, color: textColor)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShimmer({double width = 80, double height = 18}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  String _formatDistance(int distance) {
    if (distance <= 0) return "0";
    return distance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => "${m[1]}'");
  }

  String _formatTime(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  String _getDistanceMessage(int distance) {
    if (distance == 0) {
      return "Vas-y, je suis prêt ! Commence à avancer !";
    } else if (distance <= 100) {
      return "C'est ${(distance / 0.2).toStringAsFixed(0)} saucisses aux choux alignées !";
    } else if (distance <= 4000) {
      return "C'est ${(distance / 400).toStringAsFixed(1)} tour(s) de piste. Bravo !";
    } else if (distance <= 38400) {
      return "C'est ${(distance / 12800).toStringAsFixed(1)} fois Bottens-Lausanne. Force !";
    } else {
      return "C'est ${(distance / 42195).toStringAsFixed(1)} marathon(s). Héroïque !";
    }
  }
}
