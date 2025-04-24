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
  // Using ValueNotifier instead of regular state variables
  final ValueNotifier<String?> _objectifNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _currentValueNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<double?> _percentageNotifier = ValueNotifier<double?>(null);
  final ValueNotifier<String?> _remainingTimeNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _participantsNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _eventNameNotifier = ValueNotifier<String?>(null);
  final ValueNotifier<EventStatus> _eventStatusNotifier = ValueNotifier<EventStatus>(EventStatus.inProgress);
  final ValueNotifier<String?> _countdownLabelNotifier = ValueNotifier<String?>("Temps restant");
  final ValueNotifier<String?> _countdownValueNotifier = ValueNotifier<String?>(null);

  // Colors for different event statuses
  final Color _notStartedColor = Colors.green;
  final Color _inProgressColor = Colors.black87;
  final Color _overColor = Colors.red.shade700;

  Timer? _countdownTimer;
  Timer? _refreshTimer;
  String? _eventId;

  // Event status messages moved from EventData
  String getEventStatusMessage(EventStatus status) {
    switch (status) {
      case EventStatus.notStarted:
        return "L'évènement n'a pas encore commencé !";
      case EventStatus.inProgress:
        return "L'évènement est en cours";
      case EventStatus.over:
        return "L'évènement est terminé !";
    }
  }

  // New method to get colored event status text
  Widget getColoredEventStatusText(EventStatus status) {
    String message = getEventStatusMessage(status);
    Color textColor;

    switch (status) {
      case EventStatus.notStarted:
        textColor = _notStartedColor;
        break;
      case EventStatus.inProgress:
        textColor = _inProgressColor;
        break;
      case EventStatus.over:
        textColor = _overColor;
        break;
    }

    return Text(
      message,
      style: TextStyle(
        fontSize: 16,
        color: textColor,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Load initial data and start timers
    _loadEventData();
    _startTimers();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _refreshTimer?.cancel();
    // Dispose all ValueNotifiers
    _objectifNotifier.dispose();
    _currentValueNotifier.dispose();
    _percentageNotifier.dispose();
    _remainingTimeNotifier.dispose();
    _participantsNotifier.dispose();
    _eventNameNotifier.dispose();
    _eventStatusNotifier.dispose();
    _countdownLabelNotifier.dispose();
    _countdownValueNotifier.dispose();
    super.dispose();
  }

  void _loadEventData() async {
    final eventId = await EventData.getEventId();
    _eventId = eventId?.toString(); // Convert int to String

    // Load event name once
    final eventName = await EventData.getEventName();
    _eventNameNotifier.value = eventName;

    // Check initial event status and update UI
    await _updateEventStatus();

    // Refresh data immediately after loading event ID
    _refreshEventValues();
    _updateEventTimeDisplay();
  }

  Future<void> _updateEventStatus() async {
    // Get event status from centralized EventData class
    final status = await EventData.getEventStatus();
    _eventStatusNotifier.value = status;

    // Update countdown label based on status
    switch (status) {
      case EventStatus.notStarted:
        _countdownLabelNotifier.value = "L'évènement commence dans";
        break;
      case EventStatus.inProgress:
        _countdownLabelNotifier.value = "Temps restant";
        break;
      case EventStatus.over:
        _countdownLabelNotifier.value = "L'évènement est terminé";
        break;
    }
  }

  void _startTimers() {
    // Timer for countdown (every second)
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateEventTimeDisplay();
    });

    // Timer for API refresh (every 10 seconds)
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _refreshEventValues();
      _updateEventStatus();
    });
  }

  void _updateEventTimeDisplay() async {
    final eventStatus = _eventStatusNotifier.value;

    switch (eventStatus) {
      case EventStatus.notStarted:
        // For event not started, show countdown until start
        final timeUntilStart = await EventData.getFormattedTimeUntilStart();
        // Skip transitional text and directly show countdown
        if (!timeUntilStart.contains("L'évènement")) {
          _countdownValueNotifier.value = timeUntilStart;
        } else {
          // If we get a message instead of a countdown format, convert to countdown
          final secondsUntilStart = await EventData.getTimeUntilStartInSeconds();
          if (secondsUntilStart > 0) {
            _countdownValueNotifier.value = _formatTime(secondsUntilStart);
          } else {
            _countdownValueNotifier.value = "00:00:00";
          }
        }
        _percentageNotifier.value = 0.0;
        break;

      case EventStatus.inProgress:
        // For event in progress, show countdown until end
        final remainingSeconds = await EventData.getRemainingTimeInSeconds();
        if (remainingSeconds > 0) {
          _countdownValueNotifier.value = _formatTime(remainingSeconds);
        } else {
          _countdownValueNotifier.value = "00:00:00";
        }
        // Update percentage
        final percentage = await EventData.getEventCompletionPercentage();
        _percentageNotifier.value = percentage;
        break;

      case EventStatus.over:
        // For event over, show all zeros in countdown
        _countdownValueNotifier.value = "00:00:00";
        _percentageNotifier.value = 100.0;
        break;
    }
  }

  // Format time in seconds to DD:HH:MM:SS or HH:MM:SS
  String _formatTime(int seconds) {
    if (seconds <= 0) return "00:00:00";

    final days = seconds ~/ 86400;
    final hours = (seconds % 86400) ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;

    if (days > 0) {
      return "$days:${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
    } else {
      return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
    }
  }

  // Get color based on current event status
  Color _getStatusColor(EventStatus status) {
    switch (status) {
      case EventStatus.notStarted:
        return _notStartedColor;
      case EventStatus.inProgress:
        return _inProgressColor;
      case EventStatus.over:
        return _overColor;
    }
  }

  void _refreshEventValues() async {
    if (_eventId == null) return;

    try {
      // Get the total distance
      final metersResult = await NewEventController.getTotalMeters(int.parse(_eventId!));
      if (!metersResult.hasError) {
        _currentValueNotifier.value = '${_formatDistance(metersResult.value!)} m';
      }

      // Get the number of participants
      final participantsResult = await NewEventController.getActiveUsers(int.parse(_eventId!));
      if (!participantsResult.hasError) {
        _participantsNotifier.value = '${participantsResult.value}';
      }

      // Get meters goal
      final metersGoal = await EventData.getMetersGoal();
      if (metersGoal != null) {
        _objectifNotifier.value = '${_formatDistance(metersGoal)} m';
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

              // Event status with colored text

              // Event name using ValueListenableBuilder
              ValueListenableBuilder<String?>(
                valueListenable: _eventNameNotifier,
                builder: (context, eventName, _) {
                  return Text(
                    eventName ?? 'Nom de l\'événement',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  );
                },
              ),
              ValueListenableBuilder<EventStatus>(
                valueListenable: _eventStatusNotifier,
                builder: (context, status, _) {
                  return getColoredEventStatusText(status);
                },
              ),

              const SizedBox(height: 16),

              // Objectif Info using ValueListenableBuilder
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Objectif',
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                  ValueListenableBuilder<String?>(
                    valueListenable: _currentValueNotifier,
                    builder: (context, currentValue, _) {
                      return ValueListenableBuilder<String?>(
                        valueListenable: _objectifNotifier,
                        builder: (context, objectif, _) {
                          if (currentValue != null && objectif != null && objectif != '-1') {
                            return Row(
                              children: [
                                _styledValue(currentValue, color: const Color(Config.primaryColor)),
                                const Text(
                                  ' / ',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.black87,
                                  ),
                                ),
                                _styledValue(objectif, color: Colors.black54),
                              ],
                            );
                          } else {
                            return _buildShimmer(width: 100);
                          }
                        },
                      );
                    },
                  ),
                ],
              ),

              // Percentage using ValueListenableBuilder
              ValueListenableBuilder<String?>(
                valueListenable: _currentValueNotifier,
                builder: (context, currentValue, _) {
                  return ValueListenableBuilder<String?>(
                    valueListenable: _objectifNotifier,
                    builder: (context, objectif, _) {
                      if (currentValue != null && objectif != null && objectif != '-1') {
                        return Padding(
                          padding: const EdgeInsets.only(top: 2.0, bottom: 2.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${(_sanitizeValue(currentValue) / _sanitizeValue(objectif) * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  );
                },
              ),

              // Progress Bar
              ValueListenableBuilder<String?>(
                valueListenable: _currentValueNotifier,
                builder: (context, currentValue, _) {
                  return ValueListenableBuilder<String?>(
                    valueListenable: _objectifNotifier,
                    builder: (context, objectif, _) {
                      return Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: LinearProgressIndicator(
                                value: currentValue != null && objectif != null && objectif != '-1'
                                    ? _sanitizeValue(currentValue) / _sanitizeValue(objectif)
                                    : 0.0,
                                backgroundColor: Color(Config.backgroundColor),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(Config.primaryColor),
                                ),
                                minHeight: 12,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 16),

              // Time and Participants section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Countdown with dynamic label and value
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                        child: ValueListenableBuilder<String?>(
                          valueListenable: _countdownLabelNotifier,
                          builder: (context, label, _) {
                            return Text(
                              label ?? "Temps restant",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            );
                          },
                        ),
                      ),
                      ValueListenableBuilder<String?>(
                        valueListenable: _countdownValueNotifier,
                        builder: (context, countdownValue, _) {
                          return ValueListenableBuilder<EventStatus>(
                            valueListenable: _eventStatusNotifier,
                            builder: (context, status, _) {
                              // Get the appropriate color based on event status
                              final statusColor = _getStatusColor(status);

                              // For standard countdown format
                              if (countdownValue != null) {
                                return Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: _buildCountdownTimer(
                                    countdownValue,
                                    color: statusColor,
                                  ),
                                );
                              } else {
                                return _buildShimmer(width: 240);
                              }
                            },
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Participants active
                  ValueListenableBuilder<String?>(
                    valueListenable: _participantsNotifier,
                    builder: (context, participants, _) {
                      if (participants != null) {
                        return Row(
                          children: [
                            if (int.tryParse(participants) != null)
                              Container(
                                width: 10,
                                height: 10,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: int.parse(participants) > 1
                                      ? Colors.green
                                      : int.parse(participants) == 0
                                          ? Colors.grey
                                          : Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            Text(
                              participants,
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
                        );
                      } else {
                        return _buildShimmer(width: 120);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCountdownTimer(String timeStr, {required Color color}) {
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
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              // Add a subtle border with the status color
              border: Border.all(color: color.withOpacity(0.3), width: 1.5),
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
                    fontSize: 12,
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
