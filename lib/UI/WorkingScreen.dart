import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'dart:async';

import 'Components/TopAppBar.dart';
import 'Components/TextModal.dart';

import 'SetupPosScreen.dart';
import 'LoadingScreen.dart';
import 'SummaryScreen.dart';

import '../Utils/Result.dart';
import '../Utils/config.dart';
import '../Geolocalisation/Geolocation.dart';

import '../API/NewEventController.dart';
import '../API/NewUserController.dart';

import '../Data/EventData.dart';
import '../Data/UserData.dart';
import '../Data/MeasureData.dart';
import '../Data/ContributorsData.dart';

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

class _WorkingScreenState extends State<WorkingScreen> with SingleTickerProviderStateMixin {
  // --- State variables ---
  Timer? _timer;
  Timer? _eventRefreshTimer;
  DateTime? start, end;
  String _remainingTime = "";
  int? _distanceTotale,
      _distancePerso,
      _numberOfParticipants,
      _contributors,
      _sessionTimePerso,
      _totalTimePerso,
      _metersGoal;
  int _distance = 0;
  String _dossard = "", _name = "";
  int _currentPage = 0;
  bool _isEventOver = false, _isMeasureOngoing = false, _isCountingInZone = true;
  final GlobalKey iconKey = GlobalKey();
  final ScrollController _parentScrollController = ScrollController();
  late PageController _pageController; // Add PageController
  late GeolocationConfig _geoConfig;
  late Geolocation _geolocation;

  // --- Lifecycle ---
  @override
  void initState() {
    _pageController = PageController(initialPage: _currentPage); // Initialize first!
    super.initState();
    _geoConfig = GeolocationConfig(
      locationUpdateInterval: Config.LOCATION_UPDATE_INTERVAL,
      locationDistanceFilter: Config.LOCATION_DISTANCE_FILTER,
      maxChunkSize: Config.MAX_CHUNK_SIZE,
      accuracyThreshold: Config.ACCURACY_THRESHOLD,
      distanceThreshold: Config.DISTANCE_THRESHOLD,
      speedThreshold: Config.SPEED_THRESHOLD,
      apiInterval: Config.API_INTERVAL,
      outsideCounterMax: Config.OUTSIDE_COUNTER_MAX,
    );
    _geolocation = Geolocation(config: _geoConfig);
    _initializeData();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => countDown());
    _startEventRefreshTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopEventRefreshTimer();
    _geolocation.stopListening();
    _pageController.dispose(); // Dispose PageController
    super.dispose();
  }

  @override
  void deactivate() {
    super.deactivate();
    _stopEventRefreshTimer();
  }

  @override
  void activate() {
    super.activate();
    _startEventRefreshTimer();
  }

  // --- Initialization ---
  void _initializeData() {
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
          } else {
            if (mounted) {
              setState(() {
                _distance = event["distance"] ?? 0;
                _sessionTimePerso = event["time"];
                _isCountingInZone = (event["isCountingInZone"] ?? 1) == 1;
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
  }

  // --- Timer and Refresh ---
  void _startEventRefreshTimer() {
    _eventRefreshTimer?.cancel();
    _eventRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) => _refreshEventValues());
  }

  void _stopEventRefreshTimer() {
    _eventRefreshTimer?.cancel();
    _eventRefreshTimer = null;
  }

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
        } catch (e) {
          log("Failed to stop measure: $e");
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
        _remainingTime = _formatModernTime(remaining.inSeconds);
      });
    }
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

  // --- Navigation ---
  void _navigateToScreen(Widget screen) {
    _stopEventRefreshTimer();
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen)).then((_) => _startEventRefreshTimer());
  }

  void _startSetupPosScreen() => _navigateToScreen(SetupPosScreen(geolocation: _geolocation));

  // --- UI Helper Methods ---
  Widget _buildPersonalInfoContent(int displayedTime) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0),
          child: PersonalInfoCard(
            isSessionActive: _isMeasureOngoing,
            isCountingInZone: _isCountingInZone,
            logoPath: _isMeasureOngoing ? 'assets/pictures/LogoSimpleAnimated.gif' : 'assets/pictures/LogoSimple.png',
            bibNumber: _dossard.isNotEmpty ? _dossard : '',
            userName: _name.isNotEmpty ? _name : '',
            contribution: _distancePerso != null || _isMeasureOngoing
                ? '${_formatDistance(_isMeasureOngoing ? _distance : (_distancePerso ?? 0))} m'
                : '',
            totalTime: _totalTimePerso != null || _isMeasureOngoing ? _formatModernTime(displayedTime) : '',
            geoStream: _geolocation.stream,
          ),
        ),
        DynamicMapCard(geolocation: _geolocation),
        if (!_isMeasureOngoing)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Center(
              child: Text(
                'Appuie sur le bouton orange pour démarrer une mesure !',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          ),
        const SizedBox(height: 160),
      ],
    );
  }

  Widget _buildEventInfoContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          EventProgressCard(
            objectif: _metersGoal != null && _metersGoal != -1 ? '${_formatDistance(_metersGoal!)} m' : null,
            currentValue: _distanceTotale != null ? '${_formatDistance(_distanceTotale!)} m' : null,
            percentage: start != null && end != null ? _calculateRemainingTimePercentage() : null,
            remainingTime: start != null && end != null ? _remainingTime : null,
            participants: _numberOfParticipants != null ? '${_numberOfParticipants!}' : null,
          ),
          const SupportCard(),
          const SizedBox(height: 160),
        ],
      ),
    );
  }

  void _animateToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.ease,
    );
  }

  // --- Main Build ---
  @override
  Widget build(BuildContext context) {
    int displayedTime = _isMeasureOngoing ? (_sessionTimePerso ?? 0) : (_totalTimePerso ?? 0);

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {},
      child: Scaffold(
        backgroundColor: const Color(Config.COLOR_BACKGROUND),
        appBar: TopAppBar(
          title: 'Accueil',
          showInfoButton: true,
          showLogoutButton: true,
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 0.0),
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe gestures
                children: [
                  // Page 1: Informations personnelles
                  SingleChildScrollView(
                    controller: _parentScrollController,
                    child: _buildPersonalInfoContent(displayedTime),
                  ),
                  // Page 2: Informations sur l'évènement
                  SingleChildScrollView(
                    controller: _parentScrollController,
                    child: _buildEventInfoContent(),
                  ),
                ],
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
                  });
                  _animateToPage(page);
                },
                isMeasureActive: _isMeasureOngoing,
                canStartNewSession: !_isEventOver,
                onStartStopPressed: () {
                  if (_isMeasureOngoing) {
                    _confirmStopMeasure(context);
                  } else {
                    _startSetupPosScreen();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Utility methods ---
  Future<void> _updateMeasureStatus() async {
    final isOngoing = await MeasureData.isMeasureOngoing();
    if (mounted) {
      setState(() {
        _isMeasureOngoing = isOngoing;
      });
    }
  }

  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  void _showEventCompletionModal() {
    showTextModal(
      context,
      'L\'Évènement est Terminé !',
      "Merci d'avoir participé à cet évènement !\n\n"
          "N'hésite pas à prendre une capture d'écran de ton résultat.",
      showConfirmButton: true,
    );
  }

  Future<int> _getValue(Future<Result<int>> Function() fetchVal, Future<int?> Function() getVal) {
    return fetchVal().then((value) {
      if (value.hasError) {
        throw Exception("Could not fetch value because : ${value.error}");
      } else {
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

  double _calculateRemainingTimePercentage() {
    if (start == null || end == null) return 0.0;

    Duration totalDuration = end!.difference(start!);
    Duration elapsed = DateTime.now().difference(start!);
    return elapsed.inSeconds / totalDuration.inSeconds * 100;
  }

  String _formatDistance(int distance) {
    return distance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}\'');
  }

  String _formatModernTime(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  void _confirmStopMeasure(BuildContext context) {
    showTextModal(
      context,
      'Confirmation',
      'Arrêter la mesure en cours ?\n\n'
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
          await _geolocation.stopListening(); // Ensure stopListening is awaited
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
}
