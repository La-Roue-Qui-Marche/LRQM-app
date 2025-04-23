import 'package:flutter/material.dart';
import '../Utils/config.dart';
import 'WorkingScreen.dart';
import 'Components/RunPathMap.dart';
import '../Data/MeasureData.dart';
import 'Components/TopAppBar.dart';

class SummaryScreen extends StatefulWidget {
  final int distanceAdded;
  final int timeAdded;
  final double percentageAdded;
  final int contributors;

  const SummaryScreen({
    Key? key,
    required this.distanceAdded,
    required this.timeAdded,
    required this.percentageAdded,
    required this.contributors,
  }) : super(key: key);

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> with TickerProviderStateMixin {
  late final AnimationController _metersController;
  late final AnimationController _percentController;
  late final Animation<double> _metersAnimation;
  late final Animation<double> _percentAnimation;

  @override
  void initState() {
    super.initState();
    _metersController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _percentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
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
  }

  @override
  void dispose() {
    _metersController.dispose();
    _percentController.dispose();
    super.dispose();
  }

  Future<void> _handleClose() async {
    await MeasureData.clearMeasurePoints();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WorkingScreen()),
      (_) => false,
    );
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
      body: Container(
        color: const Color(Config.backgroundColor),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        color: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(height: 16),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Image.asset(
                                    'assets/pictures/Cup-AI.png',
                                    width: 140,
                                    height: 140,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
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
                                  return _contributionCard(
                                    meters: _metersAnimation.value.round(),
                                    percent: _percentAnimation.value,
                                    distance: widget.distanceAdded,
                                    contributors: widget.contributors,
                                    time: widget.timeAdded,
                                  );
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _contributionCard({
    required int meters,
    required double percent,
    required int distance,
    required int contributors,
    required int time,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
              _contributionDetail('Distance', '$distance m'),
              Container(width: 1, height: 28, color: Colors.grey.shade300),
              _contributionDetail('Participants', '$contributors'),
              Container(width: 1, height: 28, color: Colors.grey.shade300),
              _contributionDetail('Temps', _formatTime(time)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _contributionDetail(String label, String value) {
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
}
