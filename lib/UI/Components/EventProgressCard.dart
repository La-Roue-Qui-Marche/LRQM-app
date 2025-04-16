import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../Utils/config.dart';
import '../../Data/EventData.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0, left: 12.0, bottom: 6.0, top: 12.0),
          child: Text(
            'Progression de l\'événement',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(bottom: 12.0, right: 12.0, left: 12.0),
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
              FutureBuilder<String?>(
                future: EventData.getEventName(),
                builder: (context, snapshot) {
                  final eventName = snapshot.data ?? 'Nom de l\'événement';
                  return Text(
                    eventName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Objectif Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Objectif',
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  currentValue != null && objectif != null && objectif != '-1'
                      ? Row(
                          children: [
                            Text(
                              currentValue!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(Config.COLOR_APP_BAR),
                              ),
                            ),
                            const Text(
                              ' / ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.normal,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              objectif!,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.normal,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        )
                      : _buildShimmer(width: 100),
                ],
              ),

              // Progress Bar
              Row(
                children: [
                  if (currentValue != null && objectif != null && objectif != '-1')
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: Text(
                        '${(_sanitizeValue(currentValue!) / _sanitizeValue(objectif!) * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: currentValue != null && objectif != null && objectif != '-1'
                            ? _sanitizeValue(currentValue!) / _sanitizeValue(objectif!)
                            : 0.0,
                        backgroundColor: Color(Config.COLOR_BACKGROUND),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(Config.COLOR_APP_BAR),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Time + Participants (stacked vertically)
              Column(
                children: [
                  _infoCard(
                    label: 'Temps restant',
                    value: remainingTime,
                    percentage: percentage,
                    color: const Color(Config.COLOR_APP_BAR),
                    showProgress: true,
                  ),
                  Divider(
                    color: Color(Config.COLOR_BACKGROUND),
                    thickness: 1,
                  ),
                  _infoCard(
                    label: 'Participants ou groupes sur le parcours',
                    value: participants,
                    percentage: null,
                    color: const Color(Config.COLOR_BUTTON),
                    showProgress: false,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoCard({
    required String label,
    String? value,
    double? percentage,
    required Color color,
    required bool showProgress,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
      child: Row(
        children: [
          if (showProgress)
            SizedBox(
              width: 50,
              height: 50,
              child: Stack(
                alignment: Alignment.bottomLeft,
                children: [
                  CircularProgressIndicator(
                    value: (percentage ?? 0) / 100,
                    strokeWidth: 6,
                    backgroundColor: Color(Config.COLOR_BACKGROUND),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ],
              ),
            )
          else
            const SizedBox(width: 0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                value != null
                    ? Text(
                        value,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(Config.COLOR_APP_BAR),
                        ),
                      )
                    : _buildShimmer(width: 60),
              ],
            ),
          ),
        ],
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
