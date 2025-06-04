import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:lrqm/utils/config.dart';
import 'package:lrqm/geo/geolocation.dart';

class ContributionGraph extends StatefulWidget {
  final GeolocationController? geolocation;

  const ContributionGraph({
    super.key,
    this.geolocation,
  });

  @override
  ContributionGraphState createState() => ContributionGraphState();
}

class ContributionGraphState extends State<ContributionGraph> {
  final List<FlSpot> _graphData = [];
  static const int maxGraphPoints = 150;
  static const int minGraphPoints = 5;
  static const int plotIntervalSeconds = 10;

  Timer? _plotTimer;
  bool _showGraph = false;
  StreamSubscription? _geoSubscription;
  int _dataIndex = 0;

  // Variables for tracking distance and time for better speed calculation
  int _lastDistance = 0;
  int _previousDistance = 0;
  int _lastPlotTime = 0;

  @override
  void initState() {
    super.initState();
    _setupGeolocationListener();
    _setupPlotTimer();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showGraph = true;
        });
      }
    });
  }

  void _setupGeolocationListener() {
    if (widget.geolocation != null) {
      _geoSubscription = widget.geolocation!.stream.listen((event) {
        if (event.containsKey('distance')) {
          _lastDistance = event['distance'] ?? 0;
        }
        // No need to track time from the stream
      });
    }
  }

  void _setupPlotTimer() {
    _plotTimer = Timer.periodic(const Duration(seconds: plotIntervalSeconds), (_) {
      _plotDistanceBasedSpeed();
    });
  }

  void _plotDistanceBasedSpeed() {
    if (widget.geolocation == null) return;

    // Get current time
    final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    // Calculate time delta since last plot - should be approximately plotIntervalSeconds
    final timeDelta = _lastPlotTime > 0 ? currentTime - _lastPlotTime : plotIntervalSeconds;

    // Calculate distance change
    final distanceDelta = _lastDistance - _previousDistance;

    // Only calculate if we have valid data
    if (distanceDelta >= 0 && timeDelta > 0) {
      // Calculate speed in m/s
      final calculatedSpeed = (distanceDelta / timeDelta) * 3.6; // Convert m/s to km/h

      debugPrint("Calculated speed: $calculatedSpeed km/h");

      // Plot the calculated speed
      _addContributionValue(calculatedSpeed);
    }

    // Update values for next calculation
    _previousDistance = _lastDistance;
    _lastPlotTime = currentTime;
  }

  @override
  void didUpdateWidget(ContributionGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.geolocation != widget.geolocation) {
      _geoSubscription?.cancel();
      _setupGeolocationListener();
    }
  }

  @override
  void dispose() {
    _plotTimer?.cancel();
    _geoSubscription?.cancel();
    super.dispose();
  }

  void _addContributionValue(double contribution) {
    setState(() {
      _dataIndex++;

      if (_graphData.length >= maxGraphPoints) {
        _graphData.removeAt(0);
      }
      _graphData.add(FlSpot(_dataIndex.toDouble(), contribution));
    });
  }

  // Add this method to calculate the interval for Y-axis
  double _calculateYAxisInterval() {
    if (_graphData.length < minGraphPoints) return 1.0;

    double maxY = _graphData.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    maxY = maxY > 3 ? maxY + 1 : 3;

    // Calculate interval to ensure no more than 5 values on Y-axis
    return (maxY / 4).ceil().toDouble();
  }

  @override
  Widget build(BuildContext context) {
    // Prevent all text in this widget from being resizable by the OS
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Padding(
        padding: const EdgeInsets.only(left: 0, top: 0, bottom: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Contribution moyenne (km/h)",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 130,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedOpacity(
                    opacity: _showGraph ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: LineChart(
                      LineChartData(
                        lineTouchData: const LineTouchData(enabled: false),
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
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 12,
                              interval: _calculateYAxisInterval(),
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
                            spots: _graphData.length >= minGraphPoints
                                ? _graphData
                                : List.generate(10, (index) {
                                    return FlSpot(index.toDouble(), 1.0 + (index % 3) * 0.5);
                                  }),
                            isCurved: true,
                            preventCurveOverShooting: true,
                            preventCurveOvershootingThreshold: 0.0,
                            color: _graphData.length >= minGraphPoints
                                ? const Color(Config.accentColor).withOpacity(1)
                                : Colors.black26.withOpacity(0.2),
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: _graphData.length >= minGraphPoints
                                  ? const Color(Config.accentColor).withOpacity(0.15)
                                  : Colors.black26.withOpacity(0.05),
                            ),
                          ),
                        ],
                        minX: _graphData.length >= minGraphPoints && _graphData.isNotEmpty ? _graphData.first.x : 0,
                        maxX: _graphData.length >= minGraphPoints && _graphData.isNotEmpty ? _graphData.last.x + 1 : 10,
                        minY: 0,
                        maxY: _graphData.length >= minGraphPoints
                            ? (_graphData.map((e) => e.y).reduce((a, b) => a > b ? a : b) > 3
                                ? _graphData.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 1
                                : 3)
                            : 3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_graphData.length < minGraphPoints)
              const Padding(
                padding: EdgeInsets.only(top: 6.0),
                child: Text(
                  "Continue d'avancer pour voir ta progression !",
                  style: TextStyle(fontSize: 13, color: Colors.black45),
                  textAlign: TextAlign.left,
                ),
              ),
            SizedBox(height: _graphData.length >= minGraphPoints ? 6 : 0),
          ],
        ),
      ),
    );
  }
}
