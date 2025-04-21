import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../Utils/config.dart';
import '../../Data/MeasureData.dart';

class ContributionGraph extends StatefulWidget {
  const ContributionGraph({super.key});

  @override
  ContributionGraphState createState() => ContributionGraphState();
}

class ContributionGraphState extends State<ContributionGraph> {
  final List<FlSpot> _graphData = [];
  static const int maxGraphPoints = 150;
  static const int updateIntervalSeconds = 1;
  static const int minGraphPoints = 5;
  Timer? _updateTimer;
  bool _showGraph = false;

  @override
  void initState() {
    super.initState();
    _loadMeasurePoints();
    _updateTimer = Timer.periodic(
      const Duration(seconds: updateIntervalSeconds),
      (_) => _loadMeasurePoints(),
    );
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showGraph = true;
        });
      }
    });
  }

  Future<void> _loadMeasurePoints() async {
    final points = await MeasureData.getMeasurePoints();
    if (points.isEmpty) return;
    List<FlSpot> spots = [];
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      double y = (p['speed'] as num?)?.toDouble() ?? 0;

      // Parse timestamp from ISO 8601 string to DateTime and convert to milliseconds
      double x;
      if (p['timestamp'] is String) {
        try {
          DateTime dateTime = DateTime.parse(p['timestamp'] as String);
          x = dateTime.millisecondsSinceEpoch.toDouble();
        } catch (_) {
          x = DateTime.now().millisecondsSinceEpoch.toDouble();
        }
      } else {
        x = DateTime.now().millisecondsSinceEpoch.toDouble();
      }

      spots.add(FlSpot(x, y));
    }
    // Keep only the last maxGraphPoints
    if (spots.length > maxGraphPoints) {
      spots = spots.sublist(spots.length - maxGraphPoints);
    }

    // Sort by timestamp (x value)
    spots.sort((a, b) => a.x.compareTo(b.x));

    setState(() {
      _graphData
        ..clear()
        ..addAll(spots);
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _addContributionValue(double contribution) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toDouble();

    setState(() {
      if (_graphData.length >= maxGraphPoints) {
        _graphData.removeAt(0);
      }
      _graphData.add(FlSpot(timestamp, contribution));

      // Keep the list sorted by timestamp
      _graphData.sort((a, b) => a.x.compareTo(b.x));
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasEnoughData = _graphData.length >= minGraphPoints; // Use const for threshold

    double maxY = 3;
    if (hasEnoughData) {
      final maxDataValue = _graphData.map((e) => e.y).reduce((a, b) => a > b ? a : b);
      if (maxDataValue > 3) {
        maxY = maxDataValue + 1;
      }
    }

    List<FlSpot> visibleData = _getVisibleGraphData();

    // Set min and max X based on actual timestamps in the data
    double minX =
        hasEnoughData && _graphData.isNotEmpty ? _graphData.first.x : DateTime.now().millisecondsSinceEpoch.toDouble();
    double maxX;
    if (hasEnoughData && _graphData.isNotEmpty) {
      final range = _graphData.last.x - _graphData.first.x;
      final margin = range > 0 ? range * 0.10 : 10000; // fallback to 10s if all timestamps are equal
      maxX = _graphData.last.x + margin;
    } else {
      maxX = minX + 10000; // Default range of 10 seconds if no data
    }

    return Padding(
      padding: const EdgeInsets.only(left: 0, top: 0, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Contribution moyenne",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedOpacity(
                  opacity: _showGraph ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(enabled: false),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 1,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: Colors.grey.withOpacity(0.1),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 12,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              if (value % 1 != 0) return const Text('');
                              return Text(
                                value.toInt().toString(),
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: hasEnoughData ? visibleData : [],
                          isCurved: true,
                          preventCurveOverShooting: true,
                          preventCurveOvershootingThreshold: 0.0,
                          color: hasEnoughData
                              ? Color(Config.COLOR_BUTTON).withOpacity(1)
                              : Colors.black54.withOpacity(0.1),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: hasEnoughData,
                            color: hasEnoughData
                                ? Color(Config.COLOR_BUTTON).withOpacity(0.15)
                                : Colors.black54.withOpacity(0.1),
                          ),
                        ),
                      ],
                      minX: minX,
                      maxX: maxX,
                      minY: 0,
                      maxY: maxY,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!hasEnoughData)
            const Padding(
              padding: EdgeInsets.only(top: 12.0),
              child: Text(
                "Continue d'avancer pour voir ta progression !",
                style: TextStyle(fontSize: 13, color: Colors.black45),
                textAlign: TextAlign.left,
              ),
            ),
          SizedBox(height: hasEnoughData ? 6 : 0),
        ],
      ),
    );
  }

  List<FlSpot> _getVisibleGraphData() {
    return _graphData;
  }
}
