import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../Utils/config.dart';

class NavBar extends StatelessWidget {
  final int currentPage;
  final Function(int) onPageSelected;
  final bool isMeasureActive;
  final VoidCallback onStartStopPressed;

  NavBar({
    super.key,
    required this.currentPage,
    required this.onPageSelected,
    required this.isMeasureActive,
    required this.onStartStopPressed,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 24.0, right: 12.0, left: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildNavBarButton(
            icon: null,
            svgAsset: currentPage == 0 ? 'assets/icons/user-fill.svg' : 'assets/icons/user.svg',
            isSelected: currentPage == 0,
            onTap: () => onPageSelected(0),
            width: screenWidth * 0.3,
            label: 'Perso',
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: _buildStartStopButton(),
          ),
          _buildNavBarButton(
            icon: null,
            svgAsset: currentPage == 1 ? 'assets/icons/calendar-fill.svg' : 'assets/icons/calendar.svg',
            isSelected: currentPage == 1,
            onTap: () => onPageSelected(1),
            width: screenWidth * 0.3,
            label: 'Événement',
          ),
        ],
      ),
    );
  }

  Widget _buildNavBarButton({
    required IconData? icon,
    required bool isSelected,
    required VoidCallback onTap,
    required double width,
    required String label,
    String? svgAsset,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 70,
        decoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (svgAsset != null)
              SvgPicture.asset(
                svgAsset,
                color: isSelected ? const Color(Config.COLOR_APP_BAR) : Colors.black54,
                width: 20.0,
                height: 20.0,
              )
            else if (icon != null)
              Icon(
                icon,
                color: isSelected ? const Color(Config.COLOR_APP_BAR) : Colors.black54,
                size: 24.0,
              ),
            const SizedBox(height: 4.0),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(Config.COLOR_APP_BAR) : Colors.black54,
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartStopButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isMeasureActive
            ? LinearGradient(
                colors: [
                  const Color(0xFF5A4C9C), // Lighter shade of COLOR_APP_BAR
                  const Color(Config.COLOR_APP_BAR), // Original COLOR_APP_BAR
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  const Color(0xFFFFA726), // Lighter shade of COLOR_BUTTON
                  const Color(Config.COLOR_BUTTON), // Original COLOR_BUTTON
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
      ),
      child: GestureDetector(
        onTapDown: (_) => _onButtonPress(),
        onTapUp: (_) => _onButtonRelease(),
        onTapCancel: _onButtonRelease,
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              padding: const EdgeInsets.all(16.0),
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
            ),
            onPressed: onStartStopPressed,
            child: isMeasureActive
                ? const Icon(
                    Icons.stop,
                    color: Colors.white,
                    size: 28.0,
                  )
                : SvgPicture.asset(
                    'assets/icons/flag.svg',
                    color: Colors.white,
                    width: 28.0,
                    height: 28.0,
                  ),
          ),
        ),
      ),
    );
  }

  bool _isPressed = false;

  void _onButtonPress() {
    _isPressed = true;
  }

  void _onButtonRelease() {
    _isPressed = false;
  }
}
