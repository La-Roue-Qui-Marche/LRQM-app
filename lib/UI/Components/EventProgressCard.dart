// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../Utils/config.dart';
import '../../Data/EventData.dart';
import '../../API/NewEventController.dart';

class EventProgressCard extends StatefulWidget {
  const EventProgressCard({
    super.key,
  });

  @override
  State<EventProgressCard> createState() => _EventProgressCardState();
}

class _EventProgressCardState extends State<EventProgressCard> {
  String? _objectif;
  String? _currentValue;
  double? _percentage;
  String? _remainingTime;
  String? _participants;
  Timer? _countdownTimer;
  Timer? _refreshTimer;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _eventId;

  @override
  void initState() {
    super.initState();
    // Load event dates and start timers
    _loadEventDates();
    _startTimers();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _loadEventDates() async {
    final startDate = await EventData.getStartDate();
    final endDate = await EventData.getEndDate();
    final eventId = await EventData.getEventId();

    if (mounted) {
      setState(() {
        _startDate = startDate != null ? DateTime.parse(startDate) : null;
        _endDate = endDate != null ? DateTime.parse(endDate) : null;
        _eventId = eventId?.toString(); // Convert int to String
      });

      // Start countdown once we have dates
      if (_startDate != null && _endDate != null) {
        _countdown();
      }

      // Refresh data immediately after loading dates
      _refreshEventValues();
    }
  }

  void _startTimers() {
    // Timer for countdown (every second)
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_startDate != null && _endDate != null) {
        _countdown();
      }
    });

    // Timer for API refresh (every 10 seconds)
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _refreshEventValues();
    });
  }

  void _countdown() {
    if (_startDate == null || _endDate == null) return;

    DateTime now = DateTime.now();
    Duration remaining = _endDate!.difference(now);

    // Calculate percentage of event completion
    Duration totalDuration = _endDate!.difference(_startDate!);
    Duration elapsed = now.difference(_startDate!);
    double newPercentage = elapsed.inSeconds / totalDuration.inSeconds * 100;

    if (remaining.isNegative) {
      // Event is over
      String newRemainingTime = "L'évènement est terminé !";
      if (_remainingTime != newRemainingTime) {
        if (mounted) {
          setState(() {
            _remainingTime = newRemainingTime;
            _percentage = 100.0;
          });
        }
      }
    } else if (now.isBefore(_startDate!)) {
      // Event hasn't started yet
      String newRemainingTime = "L'évènement n'a pas encore commencé !";
      if (_remainingTime != newRemainingTime) {
        if (mounted) {
          setState(() {
            _remainingTime = newRemainingTime;
            _percentage = 0.0;
          });
        }
      }
    } else {
      // Event is ongoing
      String newRemainingTime = _formatModernTime(remaining.inSeconds);
      if (_remainingTime != newRemainingTime ||
          (_percentage?.toStringAsFixed(1) ?? '') != newPercentage.toStringAsFixed(1)) {
        if (mounted) {
          setState(() {
            _remainingTime = newRemainingTime;
            _percentage = newPercentage;
          });
        }
      }
    }
  }

  void _refreshEventValues() async {
    if (_eventId == null) return;

    try {
      // Get the total distance
      final metersResult = await NewEventController.getTotalMeters(int.parse(_eventId!));
      if (!metersResult.hasError && mounted) {
        setState(() {
          _currentValue = '${_formatDistance(metersResult.value!)} m';
        });
      }

      // Get the number of participants
      final participantsResult = await NewEventController.getActiveUsers(int.parse(_eventId!));
      if (!participantsResult.hasError && mounted) {
        setState(() {
          _participants = '${participantsResult.value}';
        });
      }

      // Get meters goal
      final metersGoal = await EventData.getMetersGoal();
      if (metersGoal != null && mounted) {
        setState(() {
          _objectif = '${_formatDistance(metersGoal)} m';
        });
      }
    } catch (e) {
      log("Error refreshing event values: $e");
    }
  }

  String _formatDistance(int distance) {
    return distance.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}\'',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 0.0, right: 0.0, left: 0.0, top: 6.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(0.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Progression de l\'événement',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 16),

              // Objectif Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Objectif',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  _currentValue != null && _objectif != null && _objectif != '-1'
                      ? Row(
                          children: [
                            _styledValue(_currentValue!, color: const Color(Config.primaryColor)),
                            const Text(
                              ' / ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.normal,
                                color: Colors.black87,
                              ),
                            ),
                            _styledValue(_objectif!, color: Colors.black54),
                          ],
                        )
                      : _buildShimmer(width: 100),
                ],
              ),
              // Percentage below, aligned left, with less space
              if (_currentValue != null && _objectif != null && _objectif != '-1')
                Padding(
                  padding: const EdgeInsets.only(top: 2.0, bottom: 2.0), // reduced top padding
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${(_sanitizeValue(_currentValue!) / _sanitizeValue(_objectif!) * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              // Progress Bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16), // make progress bar edges rounder
                      child: LinearProgressIndicator(
                        value: _currentValue != null && _objectif != null && _objectif != '-1'
                            ? _sanitizeValue(_currentValue!) / _sanitizeValue(_objectif!)
                            : 0.0,
                        backgroundColor: Color(Config.backgroundColor),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(Config.primaryColor),
                        ),
                        minHeight: 12, // increased height
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Time and Participants (stacked vertically)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Countdown with new style
                  _countdownCard(
                    value: _formatRemainingTime(_remainingTime),
                    color: const Color(Config.primaryColor),
                  ),
                  const SizedBox(height: 16),
                  // Participants active: green dot + number + text on same line, no divider
                  if (_participants != null)
                    Row(
                      children: [
                        if (int.tryParse(_participants!) != null)
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: int.parse(_participants!) > 1
                                  ? Colors.green
                                  : int.parse(_participants!) == 0
                                      ? Colors.grey
                                      : Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          _participants!,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Expanded(
                          child: Text(
                            'participants ou groupe actifs sur le parcours',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  else
                    _buildShimmer(width: 120),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String? _formatRemainingTime(String? value) {
    if (value == null) return null;
    // If value contains letters (like "L'évènement est terminé"), return as is
    if (RegExp(r'[a-zA-Z]').hasMatch(value)) return value;
    // Try to parse as int (seconds)
    if (value.contains(':')) return value; // Already formatted
    final seconds = int.tryParse(value);
    if (seconds == null) return value;
    return _formatModernTime(seconds);
  }

  String _formatModernTime(int seconds) {
    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    // Format with days if more than 24 hours
    if (days > 0) {
      return "$days:${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
    } else {
      return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
    }
  }

  Widget _infoCard({
    required String label,
    String? value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty)
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          if (label.isNotEmpty) const SizedBox(height: 4),
          value != null
              ? RegExp(r'[a-zA-Z]').hasMatch(value)
                  ? _styledValue(value, color: color)
                  : label.isEmpty || label.toLowerCase().contains("temps")
                      ? Row(
                          children: styledCountdownTimer(value, color: color),
                        )
                      : _formatTimeWithLabels(value, color: color)
              : _buildShimmer(width: 60),
        ],
      ),
    );
  }

  Widget _formatTimeWithLabels(String value, {required Color color}) {
    // Format the value (usually for participants count)
    return _styledValue(value, color: color);
  }

  Widget _countdownCard({
    String? value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            "Temps restant",
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        value != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: styledCountdownTimer(value, color: color),
              )
            : _buildShimmer(width: 240),
      ],
    );
  }

  List<Widget> styledCountdownTimer(String timeStr, {required Color color}) {
    List<String> parts = timeStr.split(':');
    List<String> labels =
        parts.length == 4 ? ['jours', 'heures', 'minutes', 'secondes'] : ['heures', 'minutes', 'secondes'];

    // Pad to always have 4 columns for layout consistency
    if (parts.length == 3) {
      parts = ['0', ...parts];
      labels = ['jours', ...labels];
    }

    List<Widget> widgets = [];
    for (int i = 0; i < 4; i++) {
      widgets.add(
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  parts[i],
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      // Add ":" separator except after the last container
      if (i < 3) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Text(
              ":",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.grey[400],
              ),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  Widget _styledValue(String value, {required Color color}) {
    // If it's a time format, use the dedicated formatter

    // Extract value and unit if possible
    String mainValue = '';
    String unit = '';
    final match = RegExp(r"^([\d\s'.,]+)\s*([a-zA-Z]*)$").firstMatch(value);
    if (match != null) {
      mainValue = match.group(1)?.trim() ?? value;
      unit = match.group(2)?.trim() ?? '';
    } else {
      mainValue = value;
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          mainValue,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        if (unit.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 4.0, bottom: 2.0),
            child: Text(
              unit,
              style: TextStyle(
                fontSize: 14,
                color: color.withOpacity(0.85),
              ),
            ),
          ),
      ],
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
