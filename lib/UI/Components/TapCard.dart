import 'package:flutter/material.dart';
import '../../Utils/config.dart';

class TapCard extends StatelessWidget {
  final Widget logo;
  final String text;
  final VoidCallback onTap;
  final bool isSelected; // Add isSelected property

  const TapCard({
    super.key,
    required this.logo,
    required this.text,
    required this.onTap,
    this.isSelected = false, // Default to falser
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isSelected ? Color(Config.COLOR_BUTTON) : Colors.white, // Change background color if selected
          borderRadius: BorderRadius.circular(4.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0), // Reduce vertical padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTheme(
                  data: IconThemeData(
                    size: 32,
                    color:
                        isSelected ? Colors.white : const Color(Config.COLOR_APP_BAR), // Change logo color if selected
                  ),
                  child: logo,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      color: isSelected ? Colors.white : Color(Config.COLOR_APP_BAR), // Change text color if selected
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
