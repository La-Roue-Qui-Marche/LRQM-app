import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../../Utils/config.dart';

class ContributionGraph extends StatefulWidget {
  final Stream<Map<String, int>> geoStream; // Stream passed as a parameter

  const ContributionGraph({super.key, required this.geoStream});

  @override
  ContributionGraphState createState() => ContributionGraphState();
}

class ContributionGraphState extends State<ContributionGraph> {
  final List<FlSpot> _graphData = [];
  static const int maxGraphPoints = 150;
  static const int updateIntervalSeconds = 10; // Interval for calculating the diff
  int _lastDistance = 0; // Track the last distance value
  int _accumulatedDistance = 0; // Accumulate distance over the interval
  Timer? _updateTimer; // Timer to trigger updates every 10 seconds

  @override
  void initState() {
    super.initState();

    // Listen to the stream and accumulate distance
    widget.geoStream.listen((event) {
      final currentDistance = event["distance"] ?? 0;
      final diff = currentDistance - _lastDistance; // Calculate the difference
      _lastDistance = currentDistance; // Update the last distance
      _accumulatedDistance += diff; // Accumulate the difference
    });

    // Set up a timer to update the graph every 10 seconds
    _updateTimer = Timer.periodic(
      const Duration(seconds: updateIntervalSeconds),
      (_) {
        _addContributionValue(_accumulatedDistance.toDouble() / 10);
        _accumulatedDistance = 0; // Reset the accumulated distance
      },
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  void _addContributionValue(double contribution) {
    setState(() {
      if (_graphData.length >= maxGraphPoints) {
        _graphData.removeAt(0);
        // Shift all X values back to keep the graph clean
        for (int i = 0; i < _graphData.length; i++) {
          _graphData[i] = FlSpot(i.toDouble(), _graphData[i].y);
        }
      }
      _graphData.add(FlSpot(_graphData.length.toDouble(), contribution));
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hasEnoughData = _graphData.length > 6;

    double maxY = 3;
    if (hasEnoughData) {
      final maxDataValue = _graphData.map((e) => e.y).reduce((a, b) => a > b ? a : b);
      if (maxDataValue > 3) {
        maxY = maxDataValue + 1;
      }
    }

    List<FlSpot> visibleData = _getVisibleGraphData();

    return Padding(
      padding: const EdgeInsets.only(left: 0, top: 0, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Contribution moyenne",
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
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
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value % 1 != 0) return const Text('');
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.black38,
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
                    spots: hasEnoughData ? visibleData : _placeholderGraph(),
                    isCurved: true,
                    color: hasEnoughData ? Color(Config.COLOR_BUTTON).withOpacity(1) : Colors.black54.withOpacity(0.1),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: hasEnoughData,
                      color: hasEnoughData ? Color(Config.COLOR_BUTTON).withOpacity(0.15) : Colors.transparent,
                    ),
                  ),
                ],
                minX: 0,
                maxX: hasEnoughData ? (_graphData.length.toDouble()) : 10,
                minY: 0,
                maxY: maxY,
              ),
            ),
          ),
          SizedBox(height: hasEnoughData ? 6 : 12),
          if (!hasEnoughData)
            const Padding(
              padding: EdgeInsets.only(left: 8.0),
              child: Text(
                "Continue à d'avancer pour voir ta progression !",
                style: TextStyle(fontSize: 13, color: Colors.black45),
                textAlign: TextAlign.left,
              ),
            ),
        ],
      ),
    );
  }

  List<FlSpot> _getVisibleGraphData() {
    return _graphData;
  }

  List<FlSpot> _placeholderGraph() {
    return List.generate(
      10,
      (index) => FlSpot(
        index.toDouble(),
        (index % 3 == 0 ? 0.4 : 0.1) + (index % 2 == 0 ? 0.8 : 0.5),
      ),
    );
  }
}
