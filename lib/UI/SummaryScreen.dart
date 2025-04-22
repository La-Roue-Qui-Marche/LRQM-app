import 'package:flutter/material.dart';
import '../Utils/config.dart';
import 'WorkingScreen.dart';
import 'Components/ActionButton.dart';
import 'Components/RunPathMap.dart';
import '../Data/MeasureData.dart';

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
      backgroundColor: const Color(Config.COLOR_BACKGROUND),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Bravo !',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            textAlign: TextAlign.left,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Voici le résumé de ta contribution',
                            style: TextStyle(fontSize: 16, color: Colors.black54),
                            textAlign: TextAlign.left,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Summary card first
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildSummaryCard(),
                    ),
                    const SizedBox(height: 20),
                    // Map at the bottom
                    // Remove horizontal padding and border radius for full width
                    SizedBox(
                      height: mapHeight,
                      width: double.infinity,
                      child: const RunPathMap(),
                    ),
                    // Add extra bottom padding for scroll
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
            // Add bottom bar for OK button
            Container(
              height: 80,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0x11000000), width: 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: ActionButton(
                icon: Icons.check,
                text: 'OK',
                onPressed: () async {
                  await MeasureData.clearMeasurePoints();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const WorkingScreen()),
                    (_) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
        ],
      ),
      // Reduced padding for more space
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          _animatedItem(0, Icons.route, "Distance parcourue", widget.distanceAdded, isMeter: true),
          const Divider(height: 22),
          _animatedItem(1, Icons.group, "Participants", widget.contributors),
          const Divider(height: 22),
          _animatedItem(2, Icons.timer, "Temps total", widget.timeAdded, isTime: true),
          const Divider(height: 22),
          _animatedItem(3, Icons.add_chart, "Distance totale", widget.distanceAdded * widget.contributors,
              isMeter: true),
          const Divider(height: 22),
          _animatedItem(4, Icons.pie_chart, "% Evènement", widget.percentageAdded, isPercentage: true),
        ],
      ),
    );
  }

  Widget _animatedItem(int index, IconData icon, String title, dynamic value,
      {bool isTime = false, bool isPercentage = false, bool isMeter = false}) {
    return FadeTransition(
      opacity: _itemControllers[index],
      child: Row(
        children: [
          Icon(icon, color: const Color(Config.COLOR_APP_BAR), size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 4),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, animationValue, child) {
                    return Text(
                      _formatAnimatedValue(value, animationValue,
                          isTime: isTime, isPercentage: isPercentage, isMeter: isMeter),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
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
