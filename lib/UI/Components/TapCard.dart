import 'package:flutter/material.dart';
import '../../Utils/config.dart';

class TapCard extends StatelessWidget {
  final Widget logo;
  final String text;
  final VoidCallback onTap;
  final bool isSelected;

  const TapCard({
    super.key,
    required this.logo,
    required this.text,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isSelected ? Color(Config.COLOR_BUTTON) : Colors.white,
          borderRadius: BorderRadius.circular(4.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTheme(
                  data: IconThemeData(
                    size: 32,
                    color: isSelected ? Colors.white : Color(Config.COLOR_APP_BAR),
                  ),
                  child: logo,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      color: isSelected ? Colors.white : Colors.black87,
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
