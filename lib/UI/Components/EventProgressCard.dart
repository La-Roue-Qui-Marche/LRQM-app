import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../Utils/config.dart';

class EventProgressCard extends StatelessWidget {
  final String? objectif;
  final String? currentValue;
  final double? percentage;
  final String? remainingTime;
  final String? participants;

  const EventProgressCard({
    super.key,
    this.objectif,
    this.currentValue,
    this.percentage,
    this.remainingTime,
    this.participants,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0.0),
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progression de l\'événement',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(Config.COLOR_APP_BAR),
            ),
          ),
          const SizedBox(height: 12),

          /// First Row: Objectif and Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Objectif',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
              currentValue != null && objectif != null && objectif != '-1'
                  ? Text(
                      '$currentValue / $objectif',
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
                        height: 20,
                        width: 100,
                        color: Colors.grey[300],
                      ),
                    ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (currentValue != null && objectif != null && objectif != '-1')
                Padding(
                  padding: const EdgeInsets.only(right: 14.0),
                  child: Text(
                    '${(_sanitizeValue(currentValue!) / _sanitizeValue(objectif!) * 100).toStringAsFixed(1)}%', // Calculate progress percentage
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(0),
                  child: LinearProgressIndicator(
                    value: currentValue != null && objectif != null && objectif != '-1'
                        ? _sanitizeValue(currentValue!) / _sanitizeValue(objectif!)
                        : 0.0, // Calculate progress value
                    backgroundColor: const Color(Config.COLOR_BACKGROUND).withOpacity(1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(Config.COLOR_APP_BAR),
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          /// Second Row: Remaining Time and Participants
          Row(
            children: [
              /// Remaining Time (60% width)
              Expanded(
                flex: 3, // 60% of the width
                child: Container(
                  padding: const EdgeInsets.all(12), // Added padding
                  decoration: BoxDecoration(
                    color: const Color(Config.COLOR_BACKGROUND).withOpacity(0.5), // Added background color
                    borderRadius: BorderRadius.circular(4), // Rounded corners
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: percentage != null ? percentage! / 100 : 0.0, // Use percentage for progress
                              backgroundColor: Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(Config.COLOR_APP_BAR),
                              ),
                            ),
                            Text(
                              '${percentage != null ? percentage!.toStringAsFixed(0) : 0}%', // Display percentage inside the circle
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Temps restant',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 6),
                            remainingTime != null
                                ? Text(
                                    remainingTime!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  )
                                : Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(
                                      height: 20,
                                      width: 80,
                                      color: Colors.grey[300],
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6), // Adjusted spacing between rows
          Row(
            children: [
              Expanded(
                flex: 2, // 40% of the width
                child: Container(
                  padding: const EdgeInsets.all(12), // Added padding
                  decoration: BoxDecoration(
                    color: const Color(Config.COLOR_BACKGROUND).withOpacity(0.5), // Added background color
                    borderRadius: BorderRadius.circular(4), // Rounded corners
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: participants != null
                                  ? (int.tryParse(participants!) ?? 0) / Config.NUMBER_MAX_PARTICIPANTS
                                  : 0.0, // Calculate progress based on max participants
                              backgroundColor: Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(Config.COLOR_BUTTON),
                              ),
                            ),
                            Text(
                              '${participants != null ? ((int.tryParse(participants!) ?? 0) / Config.NUMBER_MAX_PARTICIPANTS * 100).toStringAsFixed(0) : 0}%', // Display percentage
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Participants sur le parcours',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 6),
                            participants != null
                                ? Text(
                                    participants!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  )
                                : Shimmer.fromColors(
                                    baseColor: Colors.grey[300]!,
                                    highlightColor: Colors.grey[100]!,
                                    child: Container(
                                      height: 20,
                                      width: 80,
                                      color: Colors.grey[300],
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _sanitizeValue(String value) {
    // Remove non-numeric characters and parse to double
    return double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
  }
}
