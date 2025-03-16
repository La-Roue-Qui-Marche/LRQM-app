import 'package:flutter/material.dart';
import '../../Utils/config.dart';

class ProgressCard extends StatelessWidget {
  final String title;
  final String value;
  final double percentage;
  final Widget logo;

  const ProgressCard(
      {super.key,
      required this.title,
      required this.value,
      required this.percentage,
      required this.logo});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2.0),
        border: Border(
          left: BorderSide(
            color: Color(Config.COLOR_BUTTON), // Add right border
            width: 2.0, // Set the width of the right border
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Subtle shadow color
            blurRadius: 4.0, // Reduced blur radius for subtle shadow
            offset: Offset(0, 2), // Vertical shadow offset
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // Even lighter shadow color
            blurRadius: 2.0, // Smaller blur radius
            offset: Offset(2, 0), // Horizontal shadow offset
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(Config.COLOR_BACKGROUND).withOpacity(1),
                  ),
                  child: Center(
                    child: IconTheme(
                      data: const IconThemeData(
                        size: 28,
                        color: Color(Config.COLOR_APP_BAR),
                      ),
                      child: logo,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Color(Config.COLOR_APP_BAR),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        value,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(Config.COLOR_APP_BAR),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 1, // 33% of the row
                  child: Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(Config.COLOR_APP_BAR),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 5, // 66% of the row
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor:
                        const Color(Config.COLOR_BACKGROUND).withOpacity(1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(Config.COLOR_APP_BAR)),
                    minHeight: 4,
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
