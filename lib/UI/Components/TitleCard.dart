import 'package:flutter/material.dart';
import '../../Utils/config.dart';

class TitleCard extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String subtitle;

  const TitleCard({
    Key? key,
    this.icon,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0.0),
        boxShadow: [
          BoxShadow(
            color: Color(Config.COLOR_APP_BAR).withOpacity(0.1), // Subtle shadow color
            blurRadius: 4.0, // Reduced blur radius for subtle shadow
            offset: Offset(0, 2), // Vertical shadow offset
          ),
          BoxShadow(
            color: Color(Config.COLOR_APP_BAR).withOpacity(0.05), // Even lighter shadow color
            blurRadius: 2.0, // Smaller blur radius
            offset: Offset(-1, 0), // Horizontal shadow offset
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.normal,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            if (icon != null)
              Container(
                width: 55,
                height: 55,
                decoration: BoxDecoration(
                  color: Color(Config.COLOR_BACKGROUND).withOpacity(1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: Color(Config.COLOR_APP_BAR),
                    size: 30,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
