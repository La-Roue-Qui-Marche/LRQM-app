// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';

import 'Components/TopAppBar.dart';
import 'Components/TextModal.dart';

import 'SetupPosScreen.dart';
import 'LoadingScreen.dart';
import 'SummaryScreen.dart';

import '../Utils/Result.dart';
import '../Utils/config.dart';
import '../Geolocalisation/Geolocation.dart';

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
  // Only keep necessary variables
  DateTime? end;
  int? _distancePerso, _contributors, _sessionTimePerso, _totalTimePerso, _metersGoal;
  int _distance = 0;
  String _dossard = "", _name = "";
  int _currentPage = 0;
  bool _isEventOver = false, _isMeasureOngoing = false, _isCountingInZone = true;
  final ScrollController _parentScrollController = ScrollController();
  late GeolocationConfig _geoConfig;
  late Geolocation _geolocation;

  @override
  void initState() {
    super.initState();
    _geoConfig = GeolocationConfig(
      locationUpdateInterval: Config.locationUpdateInterval,
      locationDistanceFilter: Config.locationDistanceFilter,
      accuracyThreshold: Config.accuracyThreshold,
      distanceThreshold: Config.distanceThreshold,
      speedThreshold: Config.speedThreshold,
      apiInterval: Config.apiInterval,
      outsideCounterMax: Config.outsideCounterMax,
    );
    _geolocation = Geolocation(config: _geoConfig);
    _initializeData();
  }

  @override
  void dispose() {
    _geolocation.stopListening();
    super.dispose();
  }

  // --- Initialization ---
  void _initializeData() {
    // Check if event is over for the start/stop button state
    EventData.getEndDate().then((endDate) {
      if (endDate != null && mounted) {
        setState(() {
          end = DateTime.parse(endDate);
          // Check if event is over immediately
          if (DateTime.now().isAfter(end!)) {
            _isEventOver = true;
          }
        });
      }
    });

    // Retrieve user data (for personal info card)
    UserData.getBibId().then((bibId) {
      if (bibId != null && mounted) {
        setState(() {
          _dossard = bibId;
        });

        UserData.getUserId().then((userId) {
          if (userId != null && mounted) {
            // Get the personal distance
            _getValue(() => NewUserController.getUserTotalMeters(userId), () async => null).then((value) {
              if (mounted) {
                setState(() {
                  _distancePerso = value;
                });
              }
            });

            // Get the total time
            _getValue(() => NewUserController.getUserTotalTime(userId), () async => null).then((value) {
              if (mounted) {
                setState(() {
                  _totalTimePerso = value;
                });
              }
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

    // Check if a measure is ongoing and set up geolocation tracking if needed
    _updateMeasureStatus();
    MeasureData.isMeasureOngoing().then((isOngoing) {
      if (isOngoing && mounted) {
        _geolocation.stream.listen((event) {
          if (event["distance"] == -1) {
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
        // Get the total time spent on the track if no measure is ongoing
        UserData.getUserId().then((userId) {
          if (userId != null) {
            NewUserController.getUserTotalTime(userId).then((result) {
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

    // Retrieve the number of contributors (needed for summary screen)
    ContributorsData.getContributors().then((contributors) {
      if (contributors != null && mounted) {
        setState(() {
          _contributors = contributors;
        });
      }
    });

    // Retrieve meters goal (needed for summary screen)
    EventData.getMetersGoal().then((metersGoal) {
      if (metersGoal != null && mounted) {
        setState(() {
          _metersGoal = metersGoal;
        });
      }
    });
  }

  void _refreshValues() {
    // Only refresh user-specific values, event data now handled by EventProgressCard
    UserData.getBibId().then((bibId) {
      if (bibId != null) {
        if (mounted) {
          setState(() {
            _dossard = bibId;
          });
        }

        // Get the user id for meters
        UserData.getUserId().then((userId) {
          if (userId != null && mounted) {
            // Get the personal distance
            _getValue(() => NewUserController.getUserTotalMeters(userId), () async => null).then((value) {
              if (mounted) {
                setState(() {
                  _distancePerso = value;
                });
              }
            });

            // Get the total time
            NewUserController.getUserTotalTime(userId).then((result) {
              if (!result.hasError && mounted) {
                setState(() {
                  _totalTimePerso = result.value;
                });
              }
            });
          }
        });

        // Get the name of the user
        UserData.getUsername().then((username) {
          if (username != null && mounted) {
            setState(() {
              _name = username;
            });
          }
        });
      }
    });
  }

  // --- Navigation ---
  void _navigateToScreen(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
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
            geolocation: _isMeasureOngoing ? _geolocation : null,
          ),
        ),
        DynamicMapCard(geolocation: _geolocation),
        if (!_isMeasureOngoing)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12.0),
            child: Center(
              child: Text(
                'Appuie sur le bouton orange pour démarrer une mesure !',
                style: TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ),
          ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildEventInfoContent() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 0.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          EventProgressCard(),
          SupportCard(),
        ],
      ),
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
        backgroundColor: const Color(Config.backgroundColor),
        appBar: TopAppBar(
          title: 'Accueil',
          showInfoButton: true,
          showLogoutButton: true,
        ),
        body: Padding(
          padding: const EdgeInsets.only(bottom: 0.0),
          child: SingleChildScrollView(
            controller: _parentScrollController,
            child: IndexedStack(
              index: _currentPage,
              children: [
                _buildPersonalInfoContent(displayedTime),
                _buildEventInfoContent(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: NavBar(
          currentPage: _currentPage,
          onPageSelected: (int page) {
            setState(() {
              _currentPage = page;
            });
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
          await _geolocation.stopListening();
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
              contributors: _contributors ?? 1,
            ),
          ),
        );
      },
      showDiscardButton: true,
    );
  }
}
