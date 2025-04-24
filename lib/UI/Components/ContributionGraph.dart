import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../../Utils/config.dart';
import '../../Geolocalisation/Geolocation.dart';

class ContributionGraph extends StatefulWidget {
  final Geolocation? geolocation;

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
      final calculatedSpeed = distanceDelta / timeDelta;

      debugPrint("Distance delta: $distanceDelta m in $timeDelta seconds");
      debugPrint("Calculated speed: $calculatedSpeed m/s");

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

  @override
  Widget build(BuildContext context) {
    // If no geolocation is provided, show a message instead of an empty graph
    if (widget.geolocation == null) {
      return const Padding(
        padding: EdgeInsets.only(top: 0, bottom: 16),
        child: Text(
          "La mesure n'est pas active. Démarrez une mesure pour voir votre progression.",
          style: TextStyle(fontSize: 13, color: Colors.black45),
          textAlign: TextAlign.left,
        ),
      );
    }

    final bool hasEnoughData = _graphData.length >= minGraphPoints;

    // Generate placeholder data if we don't have enough real data
    List<FlSpot> displayData;
    if (hasEnoughData) {
      displayData = _graphData;
    } else {
      // Create placeholder wave-like data
      displayData = List.generate(10, (index) {
        return FlSpot(index.toDouble(), 1.0 + (index % 3) * 0.5 // Creates a gentle wave pattern between 1.0 and 2.0
            );
      });
    }

    double maxY = 3;
    if (hasEnoughData) {
      final maxDataValue = _graphData.map((e) => e.y).reduce((a, b) => a > b ? a : b);
      if (maxDataValue > 3) {
        maxY = maxDataValue + 1;
      }
    }

    // Set min and max X based on the data indices
    double minX = hasEnoughData && _graphData.isNotEmpty ? _graphData.first.x : 0;
    double maxX = hasEnoughData && _graphData.isNotEmpty ? _graphData.last.x + 1 : 10;

    return Padding(
      padding: const EdgeInsets.only(left: 0, top: 0, bottom: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Contribution moyenne (m/s)",
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
                          spots: displayData,
                          isCurved: true,
                          preventCurveOverShooting: true,
                          preventCurveOvershootingThreshold: 0.0,
                          color: hasEnoughData
                              ? const Color(Config.accentColor).withOpacity(1)
                              : Colors.black26.withOpacity(0.2),
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: hasEnoughData
                                ? const Color(Config.accentColor).withOpacity(0.15)
                                : Colors.black26.withOpacity(0.05),
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
}
