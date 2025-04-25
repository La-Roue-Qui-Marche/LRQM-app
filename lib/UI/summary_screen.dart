import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:transparent_image/transparent_image.dart';

import '../Utils/config.dart';
import '../Data/MeasureData.dart';
import 'Components/RunPathMap.dart';
import 'Components/top_app_bar.dart';
import 'working_screen.dart';

class SummaryScreen extends StatefulWidget {
  final int distanceAdded;
  final int timeAdded;
  final double percentageAdded;
  final int contributors;

  const SummaryScreen({
    super.key,
    required this.distanceAdded,
    required this.timeAdded,
    required this.percentageAdded,
    required this.contributors,
  });

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> with TickerProviderStateMixin {
  late final AnimationController _metersController;
  late final AnimationController _percentController;
  late final Animation<double> _metersAnimation;
  late final Animation<double> _percentAnimation;
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();

    _metersController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _percentController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _metersAnimation = Tween<double>(
      begin: 0,
      end: (widget.distanceAdded * widget.contributors).toDouble(),
    ).animate(CurvedAnimation(parent: _metersController, curve: Curves.easeOutCubic));

    _percentAnimation = Tween<double>(
      begin: 0,
      end: widget.percentageAdded,
    ).animate(CurvedAnimation(parent: _percentController, curve: Curves.easeOutCubic));

    _metersController.forward();
    _percentController.forward();

    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _confettiController.play();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/pictures/Cup-AI.png'), context);
  }

  @override
  void dispose() {
    _metersController.dispose();
    _percentController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _handleClose() async {
    await MeasureData.clearMeasurePoints();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WorkingScreen()),
        (_) => false,
      );
    }
  }

  String _formatTime(int seconds) {
    final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$secs";
  }

  @override
  Widget build(BuildContext context) {
    final double mapHeight = MediaQuery.of(context).size.height * 0.5;

    return Scaffold(
      backgroundColor: const Color(Config.backgroundColor),
      appBar: TopAppBar(
        title: "Résumé",
        showBackButton: false,
        showCloseButton: true,
        showInfoButton: false,
        showLogoutButton: false,
        onClose: _handleClose,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCelebrationCard(),
                      SizedBox(
                        height: mapHeight,
                        width: double.infinity,
                        child: const RunPathMap(),
                      ),
                      const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // Positioned confetti at the top of the screen
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 50),
              child: SizedBox(
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [Colors.blue, Colors.pink, Colors.orange, Colors.green, Colors.purple],
                  emissionFrequency: 0.05,
                  numberOfParticles: 20,
                  maxBlastForce: 20,
                  minBlastForce: 5,
                  gravity: 0.2,
                  particleDrag: 0.05,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCelebrationCard() {
    return Card(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      margin: const EdgeInsets.only(top: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      _confettiController.play();
                    },
                    child: FadeInImage(
                      placeholder: MemoryImage(kTransparentImage),
                      image: const AssetImage('assets/pictures/Cup-AI.png'),
                      width: 140,
                      height: 140,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bravo !',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Voici le résumé de ta contribution',
              style: TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            AnimatedBuilder(
              animation: Listenable.merge([_metersAnimation, _percentAnimation]),
              builder: (context, _) {
                return _buildContributionCard(
                  meters: _metersAnimation.value.round(),
                  percent: _percentAnimation.value,
                  distance: widget.distanceAdded,
                  contributors: widget.contributors,
                  time: widget.timeAdded,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionCard({
    required int meters,
    required double percent,
    required int distance,
    required int contributors,
    required int time,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$meters m',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(Config.accentColor).withOpacity(0.13),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '+${percent.toStringAsFixed(2)}%',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(Config.accentColor),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDetailItem('Distance', '$distance m'),
            _verticalDivider(),
            _buildDetailItem('Participants', '$contributors'),
            _verticalDivider(),
            _buildDetailItem('Temps', _formatTime(time)),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Colors.black54),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _verticalDivider() {
    return Container(
      width: 1,
      height: 28,
      color: Colors.grey.shade300,
    );
  }
}
