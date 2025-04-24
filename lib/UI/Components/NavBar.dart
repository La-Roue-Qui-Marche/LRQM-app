// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../Utils/config.dart';

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
    return Container(
      color: Colors.amber.withOpacity(0.2), // For debugging: visualize the area
      child: Stack(
        clipBehavior: Clip.none, // allows the button to overflow
        alignment: Alignment.bottomCenter,
        children: [
          // Background bar
          Container(
            height: 80, // Slightly increased for better vertical balance
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0.0)
                .copyWith(bottom: 6.0), // Increased bottom padding
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // Even horizontal spacing
              crossAxisAlignment: CrossAxisAlignment.center, // Vertically center items
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
                const SizedBox(width: 88), // Space for center button, matches floating button size
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
            top: -10, // Adjusted for new button size to keep it centered
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
                    ),
                    child: Center(
                      child: canStartNewSession
                          ? (isMeasureActive
                              ? const Icon(Icons.stop_rounded, color: Colors.white, size: 38)
                              : const Icon(Icons.radio_button_on, color: Color.fromARGB(255, 53, 52, 52), size: 38))
                          : Icon(Icons.radio_button_on, color: Colors.grey.shade50, size: 38),
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
}
