import 'package:flutter/material.dart';
import '../Utils/config.dart';
import 'WorkingScreen.dart';
import 'Components/ActionButton.dart';
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
  _SummaryScreenState createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> with TickerProviderStateMixin {
  late final AnimationController _mainController;
  late final List<AnimationController> _itemControllers;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..forward();
    _itemControllers =
        List.generate(5, (index) => AnimationController(vsync: this, duration: const Duration(milliseconds: 600)));
    _animateItems();
  }

  Future<void> _animateItems() async {
    for (final controller in _itemControllers) {
      await Future.delayed(const Duration(milliseconds: 200));
      controller.forward();
    }
  }

  Future<void> _handleBack() async {
    await MeasureData.clearMeasurePoints();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WorkingScreen()),
      (_) => false,
    );
  }

  @override
  void dispose() {
    _mainController.dispose();
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatTime(int seconds) {
    return "${(seconds ~/ 3600).toString().padLeft(2, '0')}h ${((seconds % 3600) ~/ 60).toString().padLeft(2, '0')}m ${((seconds % 60)).toString().padLeft(2, '0')}s";
  }

  @override
  Widget build(BuildContext context) {
    final double mapHeight = MediaQuery.of(context).size.height * 0.32;

    return Scaffold(
      backgroundColor: const Color(Config.backgroundColor),
      appBar: TopAppBar(
        title: "Résumé",
        showBackButton: true,
        showInfoButton: false,
        showLogoutButton: false,
        onBack: () async {
          await _handleBack();
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),
                  // Centered Cup image in white circle
                  Center(
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                          'assets/pictures/Cup-AI.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Centered "Bravo !" text
                  const Center(
                    child: Text(
                      'Bravo !',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Centered subtitle
                  const Center(
                    child: Text(
                      'Voici le résumé de ta contribution',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Contribution card with details inside
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: _contributionCard(
                      meters: widget.distanceAdded * widget.contributors,
                      percent: widget.percentageAdded,
                      distance: widget.distanceAdded,
                      contributors: widget.contributors,
                      time: widget.timeAdded,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Map at the bottom
                  SizedBox(
                    height: mapHeight,
                    width: double.infinity,
                    child: const RunPathMap(),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
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
    return FadeTransition(
      opacity: _itemControllers[3],
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 0),
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(0),
          border: Border.all(color: const Color(Config.primaryColor).withOpacity(0.10), width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main contribution row
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(Config.accentColor).withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.stars,
                    color: Color(Config.accentColor),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedBuilder(
                        animation: _itemControllers[0],
                        builder: (context, child) => Opacity(
                          opacity: _itemControllers[0].value,
                          child: child,
                        ),
                        child: const Text(
                          "Contribution",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Color(Config.primaryColor),
                            letterSpacing: 0.1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 900),
                        builder: (context, animationValue, child) {
                          final int animatedMeters = (meters * animationValue).toInt();
                          final double animatedPercent = percent * animationValue;
                          return Row(
                            children: [
                              AnimatedOpacity(
                                opacity: animationValue,
                                duration: const Duration(milliseconds: 400),
                                child: Text(
                                  '$animatedMeters m',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(Config.primaryColor),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              AnimatedOpacity(
                                opacity: animationValue,
                                duration: const Duration(milliseconds: 400),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(Config.accentColor).withOpacity(0.13),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '+${animatedPercent.toStringAsFixed(2)}%',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(Config.accentColor),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // Details section
            Row(
              children: [
                Icon(Icons.route, color: const Color(Config.primaryColor).withOpacity(0.85), size: 20),
                const SizedBox(width: 10),
                AnimatedBuilder(
                  animation: _itemControllers[1],
                  builder: (context, child) => Opacity(
                    opacity: _itemControllers[1].value,
                    child: child,
                  ),
                  child: Text(
                    'Distance parcourue : ',
                    style: const TextStyle(fontSize: 15, color: Color(Config.primaryColor)),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 700),
                  builder: (context, animationValue, child) {
                    return AnimatedOpacity(
                      opacity: animationValue,
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        '${(distance * animationValue).toInt()} m',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(Config.primaryColor),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Icon(Icons.group, color: const Color(Config.primaryColor).withOpacity(0.85), size: 20),
                const SizedBox(width: 10),
                AnimatedBuilder(
                  animation: _itemControllers[2],
                  builder: (context, child) => Opacity(
                    opacity: _itemControllers[2].value,
                    child: child,
                  ),
                  child: Text(
                    'Participants : ',
                    style: const TextStyle(fontSize: 15, color: Color(Config.primaryColor)),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 700),
                  builder: (context, animationValue, child) {
                    return AnimatedOpacity(
                      opacity: animationValue,
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        '${(contributors * animationValue).toInt()}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(Config.primaryColor),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                Icon(Icons.timer, color: const Color(Config.primaryColor).withOpacity(0.85), size: 20),
                const SizedBox(width: 10),
                AnimatedBuilder(
                  animation: _itemControllers[4],
                  builder: (context, child) => Opacity(
                    opacity: _itemControllers[4].value,
                    child: child,
                  ),
                  child: Text(
                    'Temps total : ',
                    style: const TextStyle(fontSize: 15, color: Color(Config.primaryColor)),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 700),
                  builder: (context, animationValue, child) {
                    return AnimatedOpacity(
                      opacity: animationValue,
                      duration: const Duration(milliseconds: 400),
                      child: Text(
                        _formatTime((time * animationValue).toInt()),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(Config.primaryColor),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatAnimatedValue(dynamic target, double progress,
      {bool isTime = false, bool isPercentage = false, bool isMeter = false}) {
    if (isTime && target is int) {
      return _formatTime((target * progress).toInt());
    } else if (isPercentage && target is double) {
      return '+${(target * progress).toStringAsFixed(2)}%';
    } else if (target is int) {
      return '${(target * progress).toInt()}${isMeter ? ' m' : ''}';
    } else {
      return target.toString();
    }
  }
}
