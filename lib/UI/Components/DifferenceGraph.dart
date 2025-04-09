import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../Data/SessionDistanceData.dart';
import '../../Utils/config.dart';

class DifferenceGraph extends StatefulWidget {
  const DifferenceGraph({super.key});

  @override
  State<DifferenceGraph> createState() => DifferenceGraphState();
}

class DifferenceGraphState extends State<DifferenceGraph> {
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
    _refreshTimer?.cancel(); // Cancel any existing timer before starting a new one
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) async {
      final totalDistance = await SessionDistanceData.getTotalDistance() ?? 0;
      final diff = totalDistance - _lastTotalDistance;
      final diffmms = (diff / 10).toDouble();
      _lastTotalDistance = totalDistance;

      setState(() {
        if (_graphData.length >= 30) {
          _graphData.removeAt(0);
        }
        _graphData.add(FlSpot(_index.toDouble(), diffmms.toDouble()));
        _index++;
      });
    });
  }

  void stopAndClearGraph() {
    if (_refreshTimer != null) {
      _refreshTimer!.cancel();
      _refreshTimer = null; // Set to null after canceling
    }
    setState(() {
      _graphData.clear();
      _index = 0;
      _lastTotalDistance = 0;
    });
  }

  @override
  void dispose() {
    if (_refreshTimer != null) {
      _refreshTimer!.cancel();
      _refreshTimer = null; // Set to null after canceling
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _graphData.isEmpty
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Contribution moyenne",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 180,
                  child: LineChart(
                    LineChartData(
                      lineTouchData: LineTouchData(
                        enabled: true,
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: Colors.white,
                          tooltipRoundedRadius: 8,
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        verticalInterval: 5,
                        getDrawingVerticalLine: (value) => FlLine(
                          color: Colors.grey[300],
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: Colors.black12,
                          width: 1,
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _graphData,
                          isCurved: true,
                          gradient: LinearGradient(
                            colors: [
                              Color(Config.COLOR_APP_BAR),
                              Color(Config.COLOR_APP_BAR).withOpacity(0.4),
                            ],
                          ),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false), // Disable dots
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                      minX: _index > 30 ? (_index - 30).toDouble() : 0,
                      maxX: _index.toDouble(),
                      minY: 0,
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}
