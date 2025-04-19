import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../Utils/config.dart';
import 'dart:ui';

class NavBar extends StatelessWidget {
  final int currentPage;
  final Function(int) onPageSelected;
  final bool isMeasureActive;
  final bool canStartNewSession;
  final VoidCallback onStartStopPressed;

  const NavBar({
    super.key,
    required this.currentPage,
    required this.onPageSelected,
    required this.isMeasureActive,
    required this.canStartNewSession,
    required this.onStartStopPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.only(top: 8, bottom: 12), // Only top and bottom padding
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0x11000000), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navBarButton(
            context,
            svgActive: 'assets/icons/user-fill.svg',
            svgInactive: 'assets/icons/user.svg',
            label: 'Personnel',
            selected: currentPage == 0,
            onTap: () => onPageSelected(0),
          ),
          _startStopButton(context),
          _navBarButton(
            context,
            svgActive: 'assets/icons/calendar-fill.svg',
            svgInactive: 'assets/icons/calendar.svg',
            label: 'Événement',
            selected: currentPage == 1,
            onTap: () => onPageSelected(1),
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
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Color(Config.COLOR_BUTTON).withOpacity(0) : Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              selected ? svgActive : svgInactive,
              color: selected ? Color(Config.COLOR_BUTTON) : Colors.black87,
              width: 28,
              height: 28,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: selected ? Color(Config.COLOR_BUTTON) : Colors.black54,
                fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _startStopButton(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: canStartNewSession ? onStartStopPressed : null,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: canStartNewSession
              ? LinearGradient(
                  colors: isMeasureActive
                      ? [Colors.redAccent, Colors.red]
                      : [Color(Config.COLOR_BUTTON), Color(Config.COLOR_BUTTON)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [Colors.grey.shade300, Colors.grey.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          boxShadow: [
            if (canStartNewSession)
              BoxShadow(
                color: (isMeasureActive ? Colors.red : Color(Config.COLOR_BUTTON)).withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.7),
            width: 2,
          ),
        ),
        child: Center(
          child: isMeasureActive
              ? Icon(Icons.stop_rounded, key: const ValueKey('stop'), color: Colors.white, size: 36)
              : SvgPicture.asset(
                  'assets/icons/dot-circle.svg',
                  key: const ValueKey('dot-circle'),
                  color: Colors.white,
                  width: 28,
                  height: 28,
                ),
        ),
      ),
    );
  }
}
