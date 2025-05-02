import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:lrqm/utils/config.dart';

class AppNavBar extends StatelessWidget {
  final int currentPage;
  final Function(int) onPageSelected;
  final bool isMeasureActive;
  final bool canStartNewSession;
  final VoidCallback onStartStopPressed;

  const AppNavBar({
    super.key,
    required this.currentPage,
    required this.onPageSelected,
    required this.isMeasureActive,
    required this.canStartNewSession,
    required this.onStartStopPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.amber.withOpacity(0.2),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Background bar
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0.0)
                .copyWith(bottom: 6.0), // Increased bottom padding
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: const Color(Config.backgroundColor),
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _navBarButton(
                      context,
                      svgActive: 'assets/icons/user-fill.svg',
                      svgInactive: 'assets/icons/user.svg',
                      label: 'Personnel',
                      selected: currentPage == 0,
                      onTap: () => onPageSelected(0),
                    ),
                  ),
                ),
                const SizedBox(width: 100),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _navBarButton(
                      context,
                      svgActive: 'assets/icons/calendar-fill.svg',
                      svgInactive: 'assets/icons/calendar.svg',
                      label: 'Événement',
                      selected: currentPage == 1,
                      onTap: () => onPageSelected(1),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Floating button
          Positioned(
            top: -10,
            left: 0,
            right: 0,
            child: Center(
              child: IgnorePointer(
                ignoring: !canStartNewSession,
                child: GestureDetector(
                  onTap: canStartNewSession ? onStartStopPressed : null,
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: canStartNewSession
                          ? LinearGradient(
                              colors: isMeasureActive
                                  ? [Colors.redAccent, Colors.red]
                                  : [const Color(Config.accentColor), const Color(Config.accentColor)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : LinearGradient(
                              colors: [Colors.grey.shade100, Colors.grey.shade200],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                      border: Border.all(
                        color: Colors.white,
                        width: 6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(Config.backgroundColor),
                          offset: const Offset(0, -1),
                          spreadRadius: 0,
                          blurRadius: 0,
                        ),
                      ],
                    ),
                    child: Center(
                      child: canStartNewSession
                          ? (isMeasureActive
                              ? const Icon(Icons.stop_rounded, color: Colors.white, size: 38)
                              : _buildAnimatedGlowingDot(Colors.white))
                          : _buildAnimatedGlowingDot(Colors.grey.shade50),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navBarButton(
    BuildContext context, {
    required String svgActive,
    required String svgInactive,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 64,
          minHeight: 64,
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
        alignment: Alignment.center,
        color: Colors.transparent, // Remove debug color
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              selected ? svgActive : svgInactive,
              color: selected ? const Color(Config.primaryColor) : Colors.black87,
              width: 26,
              height: 26,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? const Color(Config.primaryColor) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedGlowingDot(Color color) {
    return RepaintBoundary(
      child: PulsingDot(color: color),
    );
  }
}

class PulsingDot extends StatefulWidget {
  final Color color;

  const PulsingDot({super.key, required this.color});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Simple repeating pulse animation
    _animation = Tween<double>(begin: 0.5, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Simple pulsing circle
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              width: 24 + (_animation.value * 8),
              height: 24 + (_animation.value * 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(0.2 + (_animation.value * 0.2)),
              ),
            );
          },
        ),

        // Center dot
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
          ),
        ),
      ],
    );
  }
}
