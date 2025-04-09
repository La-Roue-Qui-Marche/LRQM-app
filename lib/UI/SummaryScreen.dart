import 'package:flutter/material.dart';
import '../Utils/config.dart';
import 'WorkingScreen.dart';
import 'Components/ActionButton.dart';

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
    _mainController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..forward();
    _itemControllers = List.generate(5, (index) {
      return AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    });
    _startItemAnimations();
  }

  void _startItemAnimations() async {
    for (var controller in _itemControllers) {
      await Future.delayed(const Duration(milliseconds: 300));
      controller.forward();
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String _formatTime(int seconds) {
    return "${(seconds ~/ 3600).toString().padLeft(2, '0')}h "
        "${(seconds % 3600 ~/ 60).toString().padLeft(2, '0')}m "
        "${(seconds % 60).toString().padLeft(2, '0')}s";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(Config.COLOR_BACKGROUND),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 48.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: FadeTransition(
                    opacity: _mainController,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.emoji_events, color: Color(Config.COLOR_APP_BAR), size: 48),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Bravo !',
                          style: TextStyle(fontSize: 22),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Voici le résumé de ta contribution',
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildSummaryCard(),
                const SizedBox(height: 120),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
              child: ActionButton(
                icon: Icons.check,
                text: 'OK',
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const WorkingScreen()),
                  (route) => false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          _animatedItem(0, Icons.directions_walk, "Distance parcourue", widget.distanceAdded, isMeter: true),
          const Divider(height: 32),
          _animatedItem(1, Icons.group, "Participants", widget.contributors),
          const Divider(height: 32),
          _animatedItem(2, Icons.timer, "Temps total", widget.timeAdded, isTime: true),
          const Divider(height: 32),
          _animatedItem(3, Icons.add_chart, "Distance totale", widget.distanceAdded * widget.contributors,
              isMeter: true),
          const Divider(height: 32),
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
                Text(title, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(height: 4),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, animationValue, child) {
                    return Text(
                      _formatAnimatedValue(value, animationValue,
                          isTime: isTime, isPercentage: isPercentage, isMeter: isMeter),
                      style: const TextStyle(fontSize: 18, color: Colors.black87),
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
