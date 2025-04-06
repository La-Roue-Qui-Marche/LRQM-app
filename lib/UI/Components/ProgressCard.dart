import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart'; // Add this import for shimmer effect
import '../../Utils/config.dart';

class ProgressCard extends StatelessWidget {
  final String title;
  final String? value; // Make value nullable to handle loading state
  final double? percentage; // Make percentage nullable to handle loading state
  final Widget logo;

  const ProgressCard({
    super.key,
    required this.title,
    this.value, // Allow null for loading state
    this.percentage, // Allow null for loading state
    required this.logo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(2.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
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
                      value != null
                          ? Text(
                              value!,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(Config.COLOR_APP_BAR),
                              ),
                            )
                          : Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                height: 16,
                                width: 100,
                                color: Colors.grey,
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
                  flex: 2, // 33% of the row
                  child: percentage != null
                      ? Text(
                          '${percentage!.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(Config.COLOR_APP_BAR),
                          ),
                        )
                      : Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 20,
                            width: 40,
                            color: Colors.grey,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 10, // 66% of the row
                  child: percentage != null
                      ? LinearProgressIndicator(
                          value: percentage! / 100,
                          backgroundColor: const Color(Config.COLOR_BACKGROUND).withOpacity(1),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(Config.COLOR_APP_BAR)),
                          minHeight: 6,
                        )
                      : Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 6,
                            color: Colors.grey,
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
