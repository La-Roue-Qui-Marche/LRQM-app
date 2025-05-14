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
      color: Colors.transparent, // Remove amber debug color
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Background bar
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 24.0).copyWith(bottom: 6.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(
                  color: Color(Config.backgroundColor),
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0), // Push to the left
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _NavBarButton(
                        svgActive: 'assets/icons/user-fill.svg',
                        svgInactive: 'assets/icons/user.svg',
                        label: 'Personnel',
                        selected: currentPage == 0,
                        onTap: () => onPageSelected(0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 74), // Space for center button
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0), // Push to the right
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: _NavBarButton(
                        svgActive: 'assets/icons/calendar-fill.svg',
                        svgInactive: 'assets/icons/calendar.svg',
                        label: 'Événement',
                        selected: currentPage == 1,
                        onTap: () => onPageSelected(1),
                      ),
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
                      gradient: LinearGradient(
                        colors: canStartNewSession
                            ? (isMeasureActive
                                ? [Colors.redAccent, Colors.red]
                                : [const Color(Config.accentColor), const Color(Config.accentColor)])
                            : [Colors.grey.shade100, Colors.grey.shade200],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white,
                        width: 6,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(Config.backgroundColor),
                          offset: Offset(0, -1),
                        ),
                      ],
                    ),
                    child: Center(
                      child: canStartNewSession
                          ? (isMeasureActive
                              ? const Icon(Icons.stop_rounded, color: Colors.white, size: 38)
                              : _GlowingDot(color: Colors.white))
                          : _GlowingDot(color: Colors.grey.shade50),
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
}

class _NavBarButton extends StatelessWidget {
  final String svgActive;
  final String svgInactive;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavBarButton({
    required this.svgActive,
    required this.svgInactive,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 64, minHeight: 64),
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? const Color(Config.primaryColor) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowingDot extends StatefulWidget {
  final Color color;
  const _GlowingDot({required this.color});

  @override
  State<_GlowingDot> createState() => _GlowingDotState();
}

class _GlowingDotState extends State<_GlowingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double baseSize = 24;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final double waveSize = baseSize + (_animation.value * 24);
        final double waveOpacity = (1 - _animation.value) * 0.3;
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: waveSize,
              height: waveSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color.withOpacity(waveOpacity),
              ),
            ),
            Container(
              width: baseSize,
              height: baseSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
            ),
          ],
        );
      },
    );
  }
}
