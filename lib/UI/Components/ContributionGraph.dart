import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../Data/SessionDistanceData.dart';
import '../../Utils/config.dart';

class ContributionGraph extends StatefulWidget {
  const ContributionGraph({super.key});

  @override
  ContributionGraphState createState() => ContributionGraphState();
}

class ContributionGraphState extends State<ContributionGraph> {
  final List<FlSpot> _graphData = [];
  int _index = 0;
  int _lastTotalDistance = 0;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _startRefreshingGraph();
  }

  void _startRefreshingGraph() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final totalDistance = await SessionDistanceData.getTotalDistance() ?? 0;
      final diff = totalDistance - _lastTotalDistance;
      final diffmms = (diff / 10).toDouble();
      _lastTotalDistance = totalDistance;

      setState(() {
        if (_graphData.length >= 30) {
          _graphData.removeAt(0);
        }
        _graphData.add(FlSpot(_index.toDouble(), diffmms));
        _index++;
      });
    });
  }

  void stopAndClearGraph() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    setState(() {
      _graphData.clear();
      _index = 0;
      _lastTotalDistance = 0;
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool hasEnoughData = _graphData.length > 6;

    // Default maxY is 5, but only resize if data exceeds 5
    double maxY = 5;
    if (hasEnoughData) {
      // Find the maximum value in the graph data and increase maxY accordingly
      final maxDataValue = _graphData.map((e) => e.y).reduce((a, b) => a > b ? a : b);
      if (maxDataValue > 5) {
        maxY = maxDataValue + 1; // Allow scaling beyond 5 if needed
      }
    }

    return Padding(
      padding: const EdgeInsets.only(left: 0, top: 0, bottom: 0), // Removed right padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Contribution moyenne", // subtle title
            style: TextStyle(
              fontSize: 14, // smaller, more subtle
              fontWeight: FontWeight.w500,
              color: Colors.black54, // lighter color
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
                        if (value % 1 != 0) return const Text(''); // Only show integers
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
                    spots: hasEnoughData ? _graphData : _placeholderGraph(),
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
                maxX: hasEnoughData ? _index.toDouble() : 10,
                minY: 0,
                maxY: maxY, // Dynamic Y scaling based on data
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (!hasEnoughData)
            const Center(
              child: Text(
                "Ta contribution moyenne sera affichée ici.",
                style: TextStyle(fontSize: 13, color: Colors.black45),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  List<FlSpot> _placeholderGraph() {
    return List.generate(
      10,
      (index) => FlSpot(index.toDouble(), (index % 3 == 0 ? 1.5 : 1.0) + (index % 2 == 0 ? 2 : 0.5)),
    );
  }
}
