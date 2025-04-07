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
      margin: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progression de l\'événement',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(Config.COLOR_APP_BAR),
            ),
          ),
          const SizedBox(height: 20),

          // Objectif Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Objectif',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
              currentValue != null && objectif != null && objectif != '-1'
                  ? Text(
                      '$currentValue / $objectif',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(Config.COLOR_APP_BAR),
                      ),
                    )
                  : _buildShimmer(width: 100),
            ],
          ),
          const SizedBox(height: 10),

          // Progress Bar
          Row(
            children: [
              if (currentValue != null && objectif != null && objectif != '-1')
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Text(
                    '${(_sanitizeValue(currentValue!) / _sanitizeValue(objectif!) * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: currentValue != null && objectif != null && objectif != '-1'
                        ? _sanitizeValue(currentValue!) / _sanitizeValue(objectif!)
                        : 0.0,
                    backgroundColor: const Color(Config.COLOR_BACKGROUND).withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(Config.COLOR_APP_BAR),
                    ),
                    minHeight: 8,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Time + Participants
          Row(
            children: [
              _infoCard(
                label: 'Temps restant',
                value: remainingTime,
                percentage: percentage,
                color: const Color(Config.COLOR_APP_BAR),
                flex: 3,
                showProgress: true,
              ),
              const SizedBox(width: 12),
              _infoCard(
                label: 'Participants',
                value: participants,
                percentage: null,
                color: const Color(Config.COLOR_BUTTON),
                flex: 2,
                showProgress: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoCard({
    required String label,
    String? value,
    double? percentage,
    required Color color,
    required int flex,
    required bool showProgress,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (showProgress)
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: (percentage ?? 0) / 100,
                      strokeWidth: 4,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(width: 0), // spacing placeholder
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  value != null
                      ? Text(
                          value,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        )
                      : _buildShimmer(width: 60),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer({double width = 80}) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 18,
        width: width,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  double _sanitizeValue(String value) {
    return double.tryParse(value.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
  }
}
