import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../Utils/config.dart';

class NavBar extends StatelessWidget {
  final int currentPage;
  final Function(int) onPageSelected;
  final bool isMeasureActive;
  final bool canStartNewSession; // New parameter to control start button state
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
    return Container(
      // Removed SafeArea
      padding: const EdgeInsets.only(top: 16, bottom: 24, left: 12, right: 12), // Adjusted top padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
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
          _startStopButton(context),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 12.0),
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
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            selected ? svgActive : svgInactive,
            color: selected ? Theme.of(context).primaryColor : Colors.black54,
            width: 28,
            height: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: selected ? Theme.of(context).primaryColor : Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _startStopButton(BuildContext context) {
    return GestureDetector(
      onTap: canStartNewSession ? onStartStopPressed : null, // Disable tap if not allowed
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: canStartNewSession
              ? LinearGradient(
                  colors: isMeasureActive ? [Colors.redAccent, Colors.red] : [Colors.orangeAccent, Colors.deepOrange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : LinearGradient(
                  colors: [Colors.grey, Colors.grey.shade400], // Greyed out when disabled
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          boxShadow: canStartNewSession
              ? [
                  BoxShadow(
                    color: (isMeasureActive ? Colors.red : Colors.deepOrange).withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isMeasureActive
                ? const Icon(Icons.stop, key: ValueKey('stop'), color: Colors.white, size: 30)
                : SvgPicture.asset(
                    'assets/icons/flag.svg',
                    key: const ValueKey('flag'),
                    color: Colors.white,
                    width: 30,
                    height: 30,
                  ),
          ),
        ),
      ),
    );
  }
}
