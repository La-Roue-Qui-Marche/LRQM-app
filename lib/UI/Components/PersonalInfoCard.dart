import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../Utils/config.dart';
import 'ContributionGraph.dart';

class PersonalInfoCard extends StatefulWidget {
  final bool isSessionActive;
  final bool isCountingInZone;
  final String logoPath;
  final String bibNumber;
  final String userName;
  final String contribution;
  final String totalTime;
  final Stream<Map<String, int>> geoStream;

  const PersonalInfoCard({
    super.key,
    required this.isSessionActive,
    required this.isCountingInZone,
    required this.logoPath,
    required this.bibNumber,
    required this.userName,
    required this.contribution,
    required this.totalTime,
    required this.geoStream,
  });

  @override
  State<PersonalInfoCard> createState() => _PersonalInfoCardState();
}

class _PersonalInfoCardState extends State<PersonalInfoCard> with SingleTickerProviderStateMixin {
  late int _currentContribution;
  final List<Widget> _particles = [];

  @override
  void initState() {
    super.initState();
    _currentContribution = _parseDistance(widget.contribution);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PersonalInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkForContributionIncrease();
  }

  void _checkForContributionIncrease() {
    final newContribution = _parseDistance(widget.contribution);

    if (newContribution > _currentContribution) {
      final int diff = newContribution - _currentContribution;
      _spawnParticle("+$diff m");

      setState(() {
        _currentContribution = newContribution;
      });
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0, left: 12.0, bottom: 8.0, top: 16.0),
          child: Row(
            children: [
              Text(
                'Ta contribution à l\'événement',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        Stack(
          children: [
            _buildCard(),
            ..._particles,
          ],
        ),
      ],
    );
  }

  Widget _buildCard() {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 0.0, right: 12.0, left: 12.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 8),
              Divider(color: Color(Config.COLOR_BACKGROUND), thickness: 1),
              const SizedBox(height: 8),
              _buildInfoCards(),
              const SizedBox(height: 16),
              _buildFunMessage(),
              const SizedBox(height: 8),
              if (widget.isSessionActive) Divider(color: Color(Config.COLOR_BACKGROUND), thickness: 1),
              if (widget.isSessionActive) const SizedBox(height: 8),
              if (widget.isSessionActive) ContributionGraph(geoStream: widget.geoStream),
            ],
          ),
        ),
        Positioned(
          top: 16,
          right: 28,
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
                      Text(
                        '№ de dossard: ',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                      Text(
                        widget.bibNumber,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        child: Image.asset(
                          widget.logoPath,
                          width: 22,
                          height: 22,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (widget.userName.isNotEmpty)
                        Text(
                          widget.userName,
                          style: const TextStyle(fontSize: 18, color: Colors.black87),
                        ),
                    ],
                  ),
                  if (widget.userName.isEmpty) _buildShimmer(width: 100),
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
          child: _infoCard(
            label: 'Distance',
            value: widget.contribution.isNotEmpty
                ? "${_formatDistance(_currentContribution)} m"
                : null, // Pass null to trigger shimmer
            color: const Color(Config.COLOR_APP_BAR),
          ),
        ),
        Expanded(
          child: _infoCard(
            label: 'Temps total',
            value: widget.totalTime.isNotEmpty ? widget.totalTime : null,
            color: const Color(Config.COLOR_APP_BAR),
          ),
        ),
      ],
    );
  }

  Widget _buildFunMessage() {
    if (widget.contribution.isNotEmpty) {
      return Text(
        _getDistanceMessage(_currentContribution),
        style: const TextStyle(fontSize: 16, color: Colors.black87),
      );
    }
    return _buildShimmer(width: double.infinity, height: 16);
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Color(Config.COLOR_BACKGROUND),
        borderRadius: BorderRadius.circular(16),
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
      badgeColor = Color(Config.COLOR_BACKGROUND);
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
    return distance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\\d))'), (m) => "${m[1]}'");
  }

  int _parseDistance(String input) {
    return int.tryParse(input.replaceAll("'", "").replaceAll(" m", "")) ?? 0;
  }

  String _getDistanceMessage(int distance) {
    if (distance <= 100) {
      return "C'est ${(distance / 0.2).toStringAsFixed(0)} saucisse aux choux mis bout à bout. Quel papet!";
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
          top: 150 - widget.offsetY * _controller.value,
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
