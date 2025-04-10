import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:async';

import 'Components/TopAppBar.dart';
import 'Components/TextModal.dart';

import 'SetupPosScreen.dart';
import 'LoadingScreen.dart';
import 'SummaryScreen.dart';
import 'LoginScreen.dart';

import '../Utils/Result.dart';
import '../Utils/config.dart';
import '../Geolocalisation/Geolocation.dart';

import '../API/NewEventController.dart';
import '../API/NewUserController.dart';
import '../API/NewMeasureController.dart';

import '../Data/EventData.dart';
import '../Data/UserData.dart';
import '../Data/MeasureData.dart';
import '../Data/ContributorsData.dart';
import '../Data/DataUtils.dart';

import 'Components/NavBar.dart';
import 'Components/DynamicMapCard.dart';
import 'Components/PersonalInfoCard.dart';
import 'Components/EventProgressCard.dart';
import 'Components/SupportCard.dart';

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

  final GlobalKey iconKey = GlobalKey();

  int? _sessionTimePerso;
  int? _totalTimePerso;

  final ScrollController _parentScrollController = ScrollController();

  Geolocation _geolocation = Geolocation();
  int _distance = 0;

  /// Event meters goal
  int? _metersGoal;

  Timer? _eventRefreshTimer; // Timer for event refresh

  bool _isEventOver = false; // Flag to track if the event is over

  /// Add a state variable to track if a measure is ongoing
  bool _isMeasureOngoing = false;

  /// Function to check if a measure is ongoing and update the state
  Future<void> _updateMeasureStatus() async {
    final isOngoing = await MeasureData.isMeasureOngoing();
    if (mounted) {
      setState(() {
        _isMeasureOngoing = isOngoing;
      });
    }
  }

  /// Function to show a snackbar with the message [value]
  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  /// Function to display the event completion modal
  void _showEventCompletionModal() {
    showTextModal(
      context,
      'L\'Évènement est Terminé !',
      "Merci d'avoir participé à cet évènement !\n\n"
          "N'hésite pas à prendre une capture d'écran de ton résultat.",
      showConfirmButton: true,
    );
  }

  /// Function to update the remaining time every second
  void countDown() async {
    if (start == null || end == null) return;

    DateTime now = DateTime.now();
    Duration remaining = end!.difference(now);
    if (remaining.isNegative) {
      _timer?.cancel();

      // Stop the measure directly
      if (await MeasureData.isMeasureOngoing()) {
        try {
          _geolocation.stopListening();
          await NewMeasureController.stopMeasure();
        } catch (e) {
          log("Failed to stop measure: $e");
        }
      }

      if (await MeasureData.isMeasureOngoing()) {
        String? measureId = await MeasureData.getMeasureId();
        final stopResult = await NewMeasureController.stopMeasure();
        if (stopResult.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Échec de l'arrêt de la mesure (ID: $measureId): ${stopResult.error}")),
          );
          return;
        }
      }

      if (mounted) {
        setState(() {
          _isEventOver = true; // Set the event over flag
          _remainingTime = "L'évènement est terminé !";
        });
        _showEventCompletionModal(); // Show modal for event completion
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
    _updateMeasureStatus();

    // Start listening to geolocation if a measure is ongoing
    MeasureData.isMeasureOngoing().then((isOngoing) {
      if (isOngoing && mounted) {
        _geolocation.stream.listen((event) {
          log("Stream event: $event");
          if (event["distance"] == -1) {
            log("Stream event: $event");
            _geolocation.stopListening();
            NewMeasureController.stopMeasure();
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
    int displayedTime = _isMeasureOngoing ? (_sessionTimePerso ?? 0) : (_totalTimePerso ?? 0);

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        log("Trying to pop");
      },
      child: Scaffold(
        backgroundColor: const Color(Config.COLOR_BACKGROUND), // Set background color
        appBar: TopAppBar(
          title: 'Accueil',
          showInfoButton: true, // Ensure the info button is enabled
          showLogoutButton: true,
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
                              isSessionActive: _isMeasureOngoing,
                              logoPath: _isMeasureOngoing
                                  ? 'assets/pictures/LogoSimpleAnimated.gif'
                                  : 'assets/pictures/LogoSimple.png',
                              bibNumber: _dossard.isNotEmpty ? _dossard : '',
                              userName: _name.isNotEmpty ? _name : '',
                              contribution: _distancePerso != null || _isMeasureOngoing
                                  ? '${_formatDistance(_isMeasureOngoing ? _distance : (_distancePerso ?? 0))} m'
                                  : '',
                              totalTime: _totalTimePerso != null || _isMeasureOngoing
                                  ? '${(displayedTime ~/ 3600).toString().padLeft(2, '0')}h ${((displayedTime % 3600) ~/ 60).toString().padLeft(2, '0')}m ${(displayedTime % 60).toString().padLeft(2, '0')}s'
                                  : '',
                            ),
                          ),
                          const DynamicMapCard(), // Add the DynamicMapCard widget here
                          if (!_isMeasureOngoing) // Show message only when no session is active
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                              child: Center(
                                child: Text(
                                  'Appuie sur le drapeau pour démarrer une session',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 32), // Add margin before the text
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

                            const SizedBox(height: 0),
                            const SupportCard(), // Add the DonationCard component
                            const SizedBox(height: 120), // Add more margin at the bottom to allow more scrolling
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
                isMeasureActive: _isMeasureOngoing, // Pass the active state
                canStartNewSession: !_isEventOver, // Disable start button if event is over
                onStartStopPressed: () {
                  if (_isMeasureOngoing) {
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
