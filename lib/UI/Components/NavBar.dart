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
                SizedBox(width: 88), // Space for center button, matches floating button size
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
            top: -12, // Adjusted for new button size to keep it centered
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: canStartNewSession ? onStartStopPressed : null,
                child: Container(
                  width: 78,
                  height: 78,
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
                    border: Border.all(
                      color: Colors.white,
                      width: 8,
                    ),
                  ),
                  child: Center(
                    child: isMeasureActive
                        ? Icon(Icons.stop_rounded, color: Colors.white, size: 34)
                        : SvgPicture.asset(
                            'assets/icons/dot-circle.svg',
                            color: Colors.white,
                            width: 34,
                            height: 34,
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
              color: selected ? Color(Config.COLOR_APP_BAR) : Colors.black87,
              width: 26,
              height: 26,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Color(Config.COLOR_APP_BAR) : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
