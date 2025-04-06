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
        color: Color(Config.COLOR_APP_BAR).withOpacity(1),
        borderRadius: BorderRadius.circular(0.0),
        boxShadow: [
          BoxShadow(
            color: Color(Config.COLOR_APP_BAR).withOpacity(0.1),
            blurRadius: 4.0,
            offset: Offset(0, 2),
          ),
          BoxShadow(
            color: Color(Config.COLOR_APP_BAR).withOpacity(0.05),
            blurRadius: 2.0,
            offset: Offset(-1, 0),
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
