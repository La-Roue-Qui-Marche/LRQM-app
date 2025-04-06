import 'package:flutter/material.dart';
import '../../Utils/config.dart';

class NavBar extends StatelessWidget {
  final int currentPage;
  final Function(int) onPageSelected;
  final bool isMeasureActive; // Add a flag to indicate if a measure is active
  final VoidCallback onStartStopPressed; // Callback for the start/stop button

  const NavBar({
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
      color: Colors.white, // Background color for the NavBar
      padding: const EdgeInsets.only(bottom: 24.0, right: 12.0, left: 12.0), // Adjust padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center, // Align items vertically
        children: [
          _buildNavBarButton(
            icon: Icons.person,
            isSelected: currentPage == 0,
            onTap: () => onPageSelected(0),
            width: screenWidth * 0.3, // Adjust width for left section
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0), // Move the START/STOP button slightly down
            child: _buildStartStopButton(), // Add the circular start/stop button in the center
          ),
          _buildNavBarButton(
            icon: Icons.calendar_month,
            isSelected: currentPage == 1,
            onTap: () => onPageSelected(1),
            width: screenWidth * 0.3, // Adjust width for right section
          ),
        ],
      ),
    );
  }

  Widget _buildNavBarButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required double width,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 70, // Maintain consistent height to prevent movement
        decoration: BoxDecoration(
          color: Colors.transparent, // No background color
          border: Border(
            top: BorderSide(
              color: isSelected ? const Color(Config.COLOR_APP_BAR) : Colors.transparent, // Border color
              width: 4.0, // Reserve space for the border
            ),
          ),
        ),
        child: Center(
          child: Icon(
            icon,
            color: const Color(Config.COLOR_APP_BAR), // Icon color
            size: 26.0,
          ),
        ),
      ),
    );
  }

  Widget _buildStartStopButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(16.0),
        backgroundColor: isMeasureActive
            ? const Color(Config.COLOR_APP_BAR) // Active state color
            : const Color(Config.COLOR_BUTTON), // Inactive state color
      ),
      onPressed: onStartStopPressed,
      child: Icon(
        isMeasureActive ? Icons.stop : Icons.flag_outlined,
        color: Colors.white,
        size: 28.0,
      ),
    );
  }
}
