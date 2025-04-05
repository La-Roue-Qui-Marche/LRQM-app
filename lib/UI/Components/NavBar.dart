import 'package:flutter/material.dart';
import '../../Utils/config.dart';

class NavBar extends StatelessWidget {
  final int currentPage;
  final Function(int) onPageSelected;

  const NavBar({
    super.key,
    required this.currentPage,
    required this.onPageSelected,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0), // Add 10 padding on left and right
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space buttons evenly
        children: [
          _buildNavBarButton(
            icon: Icons.person,
            isSelected: currentPage == 0,
            onTap: () => onPageSelected(0),
            width: currentPage == 0 ? screenWidth * 0.50 : screenWidth * 0.50,
          ),
          _buildNavBarButton(
            icon: Icons.calendar_month,
            isSelected: currentPage == 1,
            onTap: () => onPageSelected(1),
            width: currentPage == 1 ? screenWidth * 0.50 : screenWidth * 0.50,
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: width, // Dynamically set width based on selection
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.transparent, // Ensure no background color is applied
            border: isSelected
                ? const Border(
                    top: BorderSide(color: Color(Config.COLOR_APP_BAR), width: 4.0), // Set top border to 4px
                  )
                : null, // Add top border only when selected
            borderRadius: BorderRadius.circular(0.0), // Add rounded corners
          ),
          child: Center(
            child: Icon(
              icon,
              color: isSelected
                  ? const Color(Config.COLOR_APP_BAR)
                  : const Color(Config.COLOR_APP_BAR), // Keep icon color consistent
              size: isSelected ? 20.0 : 20.0, // Increase icon size when selected
            ),
          ),
        ),
      ),
    );
  }
}
