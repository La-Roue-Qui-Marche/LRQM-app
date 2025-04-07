import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';

import 'Components/InfoCard.dart';
import 'Components/TopAppBar.dart';
import 'Components/TitleCard.dart';
import 'Components/TextModal.dart';

import 'SetupPosScreen.dart';
import 'LoadingScreen.dart';
import 'SummaryScreen.dart';

import '../Utils/Result.dart';
import '../Utils/config.dart';
import '../Data/TimeData.dart';
import '../Geolocalisation/Geolocation.dart';

import '../API/NewEventController.dart';
import '../API/NewUserController.dart';
import '../API/NewMeasureController.dart';

import '../Data/EventData.dart';
import '../Data/UserData.dart';
import '../Data/MeasureData.dart';
import '../Data/ContributorsData.dart'; // Import ContributorsData
import 'Components/NavBar.dart';
import 'Components/DynamicMapCard.dart';
import 'Components/PersonalInfoCard.dart';
import 'Components/EventProgressCard.dart';
import 'Components/DonationCard.dart';

/// Class to display the working screen.
/// This screen displays the remaining time before the end of the event,
/// the total distance traveled by all participants,
/// the distance traveled by the current participant,
/// the dossard number and the name of the user.
class WorkingScreen extends StatefulWidget {
  const WorkingScreen({super.key});

  @override
  State<WorkingScreen> createState() => _WorkingScreenState();
}

/// State of the WorkingScreen class.
class _WorkingScreenState extends State<WorkingScreen> with SingleTickerProviderStateMixin {
  /// Timer to update the remaining time every second
  Timer? _timer;

  /// Start time of the event
  DateTime? start;

  /// End time of the event
  DateTime? end;

  /// Remaining time before the end of the event
  String _remainingTime = "";

  /// Total distance traveled by all participants
  int? _distanceTotale;

  /// Distance traveled by the current participant
  int? _distancePerso;

  /// Dossard number of the user
  String _dossard = "";

  /// Name of the user
  String _name = "";

  /// Number of participants
  int? _numberOfParticipants;

  /// Number of participants
  int? _contributors;

  int _currentPage = 0;
  final PageController _pageController = PageController();

  IconData _selectedIcon = Icons.face;

  final GlobalKey iconKey = GlobalKey();

  int? _sessionTimePerso;
  int? _totalTimePerso;

  final ScrollController _parentScrollController = ScrollController();

  bool _isMeasureActive = false;
  Geolocation _geolocation = Geolocation();
  int _distance = 0;

  /// Event meters goal
  int? _metersGoal;

  Timer? _eventRefreshTimer; // Timer for event refresh

  /// Function to show a snackbar with the message [value]
  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  /// Function to update the remaining time every second
  void countDown() {
    if (start == null || end == null) return;

    DateTime now = DateTime.now();
    Duration remaining = end!.difference(now);
    if (remaining.isNegative) {
      _timer?.cancel();
      if (mounted) {
        setState(() {
          _remainingTime = "L'évènement est terminé !";
        });
      }
      return;
    } else if (now.isBefore(start!)) {
      if (mounted) {
        setState(() {
          _remainingTime = "L'évènement n'a pas encore commencé !";
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _remainingTime =
            '${remaining.inHours.toString().padLeft(2, '0')}h ${(remaining.inMinutes % 60).toString().padLeft(2, '0')}m ${(remaining.inSeconds % 60).toString().padLeft(2, '0')}s';
      });
    }
  }

  /// Function to get the value from the API [fetchVal]
  /// and if it fails, get the value from the shared preferences [getVal]
  /// Returns the value
  /// If the value is not found, returns -1
  Future<int> _getValue(Future<Result<int>> Function() fetchVal, Future<int?> Function() getVal) {
    return fetchVal().then((value) {
      if (value.hasError) {
        throw Exception("Could not fetch value because : ${value.error}");
      } else {
        log("Value: ${value.value}");
        return value.value!;
      }
    }).onError((error, stackTrace) {
      log('Error here: $error');
      return getVal().then((value) {
        if (value == null) {
          log("No value");
          return -1;
        } else {
          return value;
        }
      });
    });
  }

  /// Function to calculate the percentage of remaining time
  double _calculateRemainingTimePercentage() {
    if (start == null || end == null) return 0.0;

    Duration totalDuration = end!.difference(start!);
    Duration elapsed = DateTime.now().difference(start!);
    return elapsed.inSeconds / totalDuration.inSeconds * 100;
  }

  /// Function to calculate the percentage of total distance
  double _calculateTotalDistancePercentage() {
    if (_metersGoal == null || _metersGoal == 0) return 0.0;
    return (_distanceTotale ?? 0) / _metersGoal! * 100;
  }

  /// Function to calculate the percentage of total distance based on event meters goal
  double _calculateRealProgress() {
    if (_metersGoal == null || _metersGoal == 0) return 0.0;
    return (_distanceTotale ?? 0) / _metersGoal! * 100;
  }

  String _formatDistance(int distance) {
    return distance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}\'');
  }

  @override
  void initState() {
    super.initState();

    // Retrieve the event start and end times
    EventData.getStartDate().then((startDate) {
      if (startDate != null && mounted) {
        setState(() {
          start = DateTime.parse(startDate);
        });
      }
    });

    EventData.getEndDate().then((endDate) {
      if (endDate != null && mounted) {
        setState(() {
          end = DateTime.parse(endDate);
        });
      }
    });

    // Retrieve the bib_id from UserData
    UserData.getBibId().then((bibId) {
      if (bibId != null && mounted) {
        setState(() {
          _dossard = bibId;
        });

        // Get the personal distance
        _getValue(() => NewUserController.getUserTotalMeters(int.parse(bibId)), () async => null).then((value) {
          if (mounted) {
            setState(() {
              _distancePerso = value;
            });
          }
        });

        // Get the total time
        _getValue(() => NewUserController.getUserTotalTime(int.parse(bibId)), () async => null).then((value) {
          if (mounted) {
            setState(() {
              _totalTimePerso = value;
            });
          }
        });

        // Get the name of the user
        UserData.getUsername().then((username) {
          if (username != null && mounted) {
            setState(() {
              _name = username;
            });
          } else {
            log("Failed to fetch username from UserData.");
          }
        });
      } else {
        log("Bib ID not found in UserData.");
      }
    });

    // Check if a measure is ongoing
    MeasureData.isMeasureOngoing().then((isOngoing) {
      if (isOngoing && mounted) {
        setState(() {
          _isMeasureActive = true;
        });
        _geolocation.stream.listen((event) {
          log("Stream event: $event");
          if (event["distance"] == -1) {
            log("Stream event: $event");
            _geolocation.stopListening();
            NewMeasureController.stopMeasure();
            if (mounted) {
              setState(() {
                _isMeasureActive = false;
              });
            }
          } else {
            if (mounted) {
              setState(() {
                _distance = event["distance"] ?? 0;
                _sessionTimePerso = event["time"];
              });
            }
          }
        });
        _geolocation.startListening();
      } else {
        // Get the total time spent on the track
        UserData.getBibId().then((bibId) {
          if (bibId != null) {
            NewUserController.getUserTotalTime(int.parse(bibId)).then((result) {
              if (!result.hasError && mounted) {
                setState(() {
                  _totalTimePerso = result.value;
                });
              }
            });
          }
        });
      }
    });

    // Check if the event has started or ended
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (start != null && end != null) {
        countDown();
      }
    });

    // Get the event ID
    EventData.getEventId().then((eventId) {
      if (eventId != null && mounted) {
        // Get the total distance
        _getValue(() => NewEventController.getTotalMeters(eventId), () async => null).then((value) {
          if (mounted) {
            setState(() {
              _distanceTotale = value;
            });
          }
        });

        // Get the number of participants
        NewEventController.getActiveUsers(eventId).then((result) {
          if (!result.hasError && mounted) {
            setState(() {
              _numberOfParticipants = result.value;
            });
          }
        });
      } else {
        log("Failed to fetch event ID from EventData.");
      }
    });

    // Retrieve the number of contributors
    ContributorsData.getContributors().then((contributors) {
      if (contributors != null && mounted) {
        setState(() {
          _contributors = contributors;
        });
      }
    });

    // Retrieve the event meters goal
    EventData.getMetersGoal().then((metersGoal) {
      if (metersGoal != null && mounted) {
        setState(() {
          _metersGoal = metersGoal;
        });
      }
    });

    // Timer to refresh "Informations sur l'évènement" values every second
    _startEventRefreshTimer();
  }

  void _startEventRefreshTimer() {
    _eventRefreshTimer?.cancel(); // Cancel any existing timer
    _eventRefreshTimer = Timer.periodic(const Duration(seconds: 5), (Timer t) {
      if (mounted) {
        _refreshEventValues(); // Always refresh values when on the screen
      }
    });
  }

  void _stopEventRefreshTimer() {
    _eventRefreshTimer?.cancel(); // Stop the timer
    _eventRefreshTimer = null;
  }

  @override
  void deactivate() {
    super.deactivate();
    _stopEventRefreshTimer(); // Stop refreshing when leaving the screen
  }

  @override
  void activate() {
    super.activate();
    _startEventRefreshTimer(); // Restart refreshing when returning to the screen
  }

  void _navigateToScreen(Widget screen) {
    _stopEventRefreshTimer(); // Stop the timer before navigating
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    ).then((_) {
      _startEventRefreshTimer(); // Restart the timer when returning
    });
  }

  @override
  void dispose() {
    log("Dispose");
    _timer?.cancel();
    _stopEventRefreshTimer(); // Ensure the event refresh timer is stopped
    _geolocation.stopListening(); // Stop geolocation stream
    super.dispose();
  }

  void _refreshEventValues() {
    // Get the event ID
    EventData.getEventId().then((eventId) {
      if (eventId != null) {
        // Get the total distance
        _getValue(() => NewEventController.getTotalMeters(eventId), () async => null).then((value) {
          if (mounted) {
            setState(() {
              _distanceTotale = value;
            });
          }
        });

        // Get the number of participants
        NewEventController.getActiveUsers(eventId).then((result) {
          if (!result.hasError && mounted) {
            setState(() {
              _numberOfParticipants = result.value;
            });
          }
        });
      } else {
        log("Failed to fetch event ID from EventData.");
      }
    });

    // Retrieve the number of contributors
    ContributorsData.getContributors().then((contributors) {
      if (contributors != null && mounted) {
        setState(() {
          _contributors = contributors;
        });
      }
    });

    // Retrieve the event meters goal
    EventData.getMetersGoal().then((metersGoal) {
      if (metersGoal != null && mounted) {
        setState(() {
          _metersGoal = metersGoal;
        });
      }
    });
  }

  /// Function to refresh all values
  void _refreshValues() {
    // Retrieve the bib_id from UserData
    UserData.getBibId().then((bibId) {
      if (bibId != null) {
        if (mounted) {
          setState(() {
            _dossard = bibId;
          });
        }

        // Get the personal distance
        _getValue(() => NewUserController.getUserTotalMeters(int.parse(bibId)), () async => null).then((value) {
          if (mounted) {
            setState(() {
              _distancePerso = value;
            });
          }
        });

        // Get the name of the user
        UserData.getUsername().then((username) {
          if (username != null && mounted) {
            setState(() {
              _name = username;
            });
          } else {
            log("Failed to fetch username from UserData.");
          }
        });
      } else {
        log("Bib ID not found in UserData.");
      }
    });

    // Get the event ID
    EventData.getEventId().then((eventId) {
      if (eventId != null) {
        // Get the total distance
        _getValue(() => NewEventController.getTotalMeters(eventId), () async => null).then((value) {
          if (mounted) {
            setState(() {
              _distanceTotale = value;
            });
          }
        });

        // Get the number of participants
        NewEventController.getActiveUsers(eventId).then((result) {
          if (!result.hasError && mounted) {
            setState(() {
              _numberOfParticipants = result.value;
            });
          }
        });
      } else {
        log("Failed to fetch event ID from EventData.");
      }
    });

    // Get the time spent on the track
    UserData.getBibId().then((bibId) {
      if (bibId != null) {
        NewUserController.getUserTotalTime(int.parse(bibId)).then((result) {
          if (!result.hasError && mounted) {
            setState(() {
              _totalTimePerso = result.value;
            });
          }
        });
      }
    });
  }

  void _confirmStopMeasure(BuildContext context) {
    showTextModal(
      context,
      'Confirmation',
      'Tu es sûr de vouloir arrêter la mesure en cours ?\n\n'
          'Cela mettra fin à l\'enregistrement de ta distance et de ton temps. '
          'Si tu veux continuer plus tard, tu devras redémarrer une nouvelle mesure.\n\n'
          'Prends une pause si nécessaire, mais n\'oublie pas de revenir pour continuer '
          'à contribuer à l\'événement !',
      showConfirmButton: true,
      onConfirm: () async {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const LoadingScreen(text: 'On se repose un peu...'),
          ),
        );
        try {
          _geolocation.stopListening();
          await NewMeasureController.stopMeasure();
        } catch (e) {
          log("Failed to stop measure: $e");
        }
        setState(() {
          _isMeasureActive = false;
        });
        _refreshValues();
        Navigator.of(context).pop(); // Close the loading screen

        // Calculate percentage of total event progress
        int totalDistanceAdded = _distance * (_contributors ?? 1);
        double eventPercentageAdded = (totalDistanceAdded / (_metersGoal ?? 1)) * 100;

        // Navigate to the SummaryScreen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SummaryScreen(
              distanceAdded: _distance,
              timeAdded: _sessionTimePerso ?? 0,
              percentageAdded: eventPercentageAdded,
              contributors: _contributors ?? 1, // Pass contributors count
            ),
          ),
        );
      },
      showDiscardButton: true,
      onDiscard: () {
        Navigator.of(context).pop(); // Close the modal and continue the session
      },
    );
  }

  void _animateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    int displayedTime = _isMeasureActive ? (_sessionTimePerso ?? 0) : (_totalTimePerso ?? 0);

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        log("Trying to pop");
      },
      child: Scaffold(
        backgroundColor: const Color(Config.COLOR_BACKGROUND), // Set background color
        appBar: TopAppBar(
          title: 'Informations',
          showInfoButton: true,
          isRecording: _isMeasureActive, // Pass recording status
        ),
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 95.0), // Reserve space for NavBar and START/STOP button
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Disable swipe gestures
                  children: [
                    // Page 1: Informations personnelles
                    SingleChildScrollView(
                      controller: _parentScrollController,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0.0), // Remove horizontal padding
                            child: PersonalInfoCard(
                              isSessionActive: _isMeasureActive,
                              logoPath: _isMeasureActive
                                  ? 'assets/pictures/LogoSimpleAnimated.gif'
                                  : 'assets/pictures/LogoSimple.png',
                              bibNumber: _dossard.isNotEmpty ? _dossard : '',
                              userName: _name.isNotEmpty ? _name : '',
                              contribution: _distancePerso != null || _isMeasureActive
                                  ? '${_formatDistance(_isMeasureActive ? _distance : (_distancePerso ?? 0))} m'
                                  : '',
                              totalTime: _totalTimePerso != null || _isMeasureActive
                                  ? '${(displayedTime ~/ 3600).toString().padLeft(2, '0')}h ${((displayedTime % 3600) ~/ 60).toString().padLeft(2, '0')}m ${(displayedTime % 60).toString().padLeft(2, '0')}s'
                                  : '',
                            ),
                          ),
                          const SizedBox(height: 6),
                          const DynamicMapCard(), // Add the DynamicMapCard widget here
                          if (!_isMeasureActive) // Show message only when no session is active
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: Center(
                                child: Text(
                                  'Appuie sur START pour démarrer une session',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16), // Add margin before the text
                          //const SizedBox(height: 120), // Add more margin at the bottom to allow more scrolling
                        ],
                      ),
                    ),
                    // Page 2: Informations sur l'évènement
                    SingleChildScrollView(
                      controller: _parentScrollController,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 0.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
                          children: <Widget>[
                            // Use the new component
                            Container(
                              child: EventProgressCard(
                                objectif: _metersGoal != null && _metersGoal != -1
                                    ? '${_formatDistance(_metersGoal!)} m'
                                    : null, // Pass null to trigger shimmer
                                currentValue: _distanceTotale != null
                                    ? '${_formatDistance(_distanceTotale!)} m'
                                    : null, // Pass null to trigger shimmer
                                percentage: start != null && end != null
                                    ? _calculateRemainingTimePercentage() // Calculate remaining time percentage
                                    : null, // Pass null to trigger shimmer
                                remainingTime: start != null && end != null
                                    ? _remainingTime
                                    : null, // Pass null to trigger shimmer
                                participants: _numberOfParticipants != null
                                    ? '${_numberOfParticipants!}' // Pass max participants
                                    : null, // Pass null to trigger shimmer
                              ),
                            ),

                            const SizedBox(height: 6),
                            const DonationCard(), // Add the DonationCard component
                            const SizedBox(height: 100), // Add more margin at the bottom to allow more scrolling
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0.0,
              left: 0.0,
              right: 0.0,
              child: NavBar(
                currentPage: _currentPage,
                onPageSelected: (int page) {
                  setState(() {
                    _currentPage = page;
                    _animateToPage(page);
                  });
                },
                isMeasureActive: _isMeasureActive, // Pass the active state
                onStartStopPressed: () {
                  if (_isMeasureActive) {
                    _confirmStopMeasure(context); // Stop the measure
                  } else {
                    _navigateToScreen(const SetupPosScreen()); // Start a new measure
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
