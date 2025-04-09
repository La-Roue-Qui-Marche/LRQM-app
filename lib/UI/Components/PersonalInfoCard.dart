import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../Utils/config.dart';
import 'DifferenceGraph.dart';

class PersonalInfoCard extends StatefulWidget {
  final bool isSessionActive;
  final String logoPath;
  final String bibNumber;
  final String userName;
  final String contribution;
  final String totalTime;

  const PersonalInfoCard({
    super.key,
    required this.isSessionActive,
    required this.logoPath,
    required this.bibNumber,
    required this.userName,
    required this.contribution,
    required this.totalTime,
  });

  @override
  State<PersonalInfoCard> createState() => _PersonalInfoCardState();
}

class _PersonalInfoCardState extends State<PersonalInfoCard> with SingleTickerProviderStateMixin {
  final GlobalKey<DifferenceGraphState> _differenceGraphKey = GlobalKey<DifferenceGraphState>();

  late int _currentContribution;
  late int _previousContribution;
  final List<Widget> _particles = [];

  @override
  void initState() {
    super.initState();
    _currentContribution = _parseDistance(widget.contribution);
    _previousContribution = _currentContribution;
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
        _previousContribution = _currentContribution;
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
    return Stack(
      children: [
        _buildCard(),
        ..._particles,
      ],
    );
  }

  Widget _buildCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ta contribution à l\'événement',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 20),
          _buildHeader(),
          const SizedBox(height: 24),
          _buildInfoCards(),
          const SizedBox(height: 16),
          _buildFunMessage(),
          const SizedBox(height: 8),
          if (widget.isSessionActive) const DifferenceGraph(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            shape: BoxShape.circle,
          ),
          child: Image.asset(
            widget.logoPath,
            width: 32,
            height: 32,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('№ de dossard: ${widget.bibNumber}', style: const TextStyle(fontSize: 16, color: Colors.black87)),
              const SizedBox(height: 4),
              widget.userName.isNotEmpty
                  ? Text(widget.userName, style: const TextStyle(fontSize: 16, color: Colors.black54))
                  : _buildShimmer(width: 100),
            ],
          ),
        ),
        _statusBadge(),
      ],
    );
  }

  Widget _buildInfoCards() {
    return Row(
      children: [
        _infoCard(
          label: 'Contribution',
          value: "${_formatDistance(_currentContribution)} m",
          color: const Color(Config.COLOR_APP_BAR),
        ),
        const SizedBox(width: 12),
        _infoCard(
          label: 'Temps total',
          value: widget.totalTime.isNotEmpty ? widget.totalTime : null,
          color: const Color(Config.COLOR_BUTTON),
        ),
      ],
    );
  }

  Widget _buildFunMessage() {
    if (widget.contribution.isNotEmpty) {
      return Text(
        _getDistanceMessage(_currentContribution),
        style: const TextStyle(fontSize: 14, color: Colors.black87),
      );
    }
    return _buildShimmer(width: double.infinity, height: 16);
  }

  Widget _infoCard({required String label, String? value, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 14, color: Colors.black54)),
            const SizedBox(height: 4),
            value != null
                ? Text(
                    value,
                    style: const TextStyle(fontSize: 18, color: Color(Config.COLOR_APP_BAR)),
                  )
                : _buildShimmer(width: 60),
          ],
        ),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: widget.isSessionActive ? Colors.green.shade400 : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: widget.isSessionActive ? Colors.white : Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            widget.isSessionActive ? 'Actif' : 'En pause',
            style: TextStyle(fontSize: 12, color: widget.isSessionActive ? Colors.white : Colors.grey.shade600),
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
          top: 200 - widget.offsetY * _controller.value,
          left: MediaQuery.of(context).size.width / 3.5 + widget.offsetX * _controller.value,
          child: Opacity(
            opacity: 1 - _controller.value,
            child: Text(
              widget.label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.green,
              ),
            ),
          ),
        );
      },
    );
  }
}
