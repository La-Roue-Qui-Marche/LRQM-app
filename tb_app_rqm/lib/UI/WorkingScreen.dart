import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import '../API/NewEventController.dart'; // Replace DistanceController with NewEventController
import '../API/NewUserController.dart'; // Replace user-related calls with NewUserController
import '../Data/DossardData.dart'; // Import DossardData
import 'Components/ProgressCard.dart';
import 'Components/InfoCard.dart';
import 'Components/Dialog.dart';
import 'Components/ActionButton.dart';
import 'Components/TopAppBar.dart';
import 'SetupPosScreen.dart'; // Add this import
import '../Data/Session.dart';
import '../Utils/Result.dart';
import '../Utils/config.dart';
import '../Data/TimeData.dart';
import '../Geolocalisation/Geolocation.dart';
import 'Components/DiscardButton.dart';
import 'Components/InfoDialog.dart'; // Add this import
import 'LoadingScreen.dart'; // Add this import
import 'Components/TitleCard.dart';

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
  DateTime start = DateTime.parse(Config.START_TIME);

  /// End time of the event
  DateTime end = DateTime.parse(Config.END_TIME);

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

  int _currentPage = 0;
  final PageController _pageController = PageController();

  IconData _selectedIcon = Icons.face;

  final GlobalKey iconKey = GlobalKey();

  int? _sessionTimePerso;
  int? _totalTimePerso;

  final ScrollController _parentScrollController = ScrollController();

  bool _isSessionActive = false;
  Geolocation _geolocation = Geolocation();
  int _distance = 0;

  void _showIconMenu(BuildContext context) {
    final List<IconData> icons = [
      Icons.face,
      Icons.face_2,
      Icons.face_3,
      Icons.face_4,
      Icons.face_5,
      Icons.face_6,
    ];

    final List<Widget> iconWidgets = icons.map((icon) {
      return Icon(icon, size: 40, color: const Color(Config.COLOR_APP_BAR));
    }).toList();

    CustomDialog.showCustomDialog(
      context,
      'Choisis ton avatar !',
      iconWidgets,
      (selectedItem) {
        setState(() {
          _selectedIcon = (selectedItem as Icon).icon!;
        });
      },
    );
  }

  /// Function to show a snackbar with the message [value]
  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  /// Function to update the remaining time every second
  void countDown() {
    DateTime now = DateTime.now();
    Duration remaining = end.difference(now);
    if (remaining.isNegative) {
      _timer?.cancel();
      setState(() {
        _remainingTime = "L'évènement est terminé !";
      });
      return;
    } else if (now.isBefore(start)) {
      setState(() {
        _remainingTime = "L'évènement n'a pas encore commencé !";
      });
      return;
    }

    setState(() {
      _remainingTime =
          '${remaining.inHours.toString().padLeft(2, '0')}h ${(remaining.inMinutes % 60).toString().padLeft(2, '0')}m ${(remaining.inSeconds % 60).toString().padLeft(2, '0')}s';
    });
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
    Duration totalDuration = end.difference(start);
    Duration elapsed = DateTime.now().difference(start);
    return elapsed.inSeconds / totalDuration.inSeconds * 100;
  }

  /// Function to calculate the percentage of total distance
  double _calculateTotalDistancePercentage() {
    return (_distanceTotale ?? 0) / Config.TARGET_DISTANCE * 100;
  }

  String _formatDistance(int distance) {
    return distance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}\'');
  }

  String _getDistanceMessage(int distance) {
    if (distance <= 100) {
      return "C'est ${(distance / 0.2).toStringAsFixed(0)} saucisse aux choux mis bout à bout. Quel papet! Continue comme ça";
    } else if (distance <= 4000) {
      return "C'est ${(distance / 400).toStringAsFixed(1)} tour(s) de la piste de la pontaise. Trop fort!";
    } else if (distance <= 38400) {
      return "C'est ${(distance / 12800).toStringAsFixed(1)} fois la distance Bottens-Lausanne. Tu es un champion, n'oublie pas de boire!";
    } else {
      return "C'est ${(distance / 42195).toStringAsFixed(1)} marathon. Tu as une forme et une détermination fantastique. Pense à reprendre des forces";
    }
  }

  @override
  void initState() {
    super.initState();

    // Retrieve the dossard number
    DossardData.getDossard().then((dossardNumber) {
      if (dossardNumber != null) {
        setState(() {
          _dossard = dossardNumber.toString();
        });

        // Get the personal distance
        _getValue(() => NewUserController.getUserTotalMeters(dossardNumber), () async => null).then((value) => setState(() {
              _distancePerso = value;
            }));

        // Get the name of the user
        NewUserController.getUser(dossardNumber).then((result) {
          if (result.value != null) {
            setState(() {
              _name = result.value!['username'] ?? "Unknown";
            });
          } else {
            log("Failed to fetch username: ${result.error}");
          }
        });
      } else {
        log("Dossard number not found");
      }
    });

    // Check if a session is ongoing
    Session.isStarted().then((isOngoing) {
      if (isOngoing) {
        setState(() {
          _isSessionActive = true;
        });
        _geolocation.stream.listen((event) {
          log("Stream event: $event");
          if (event["distance"] == -1) {
            log("Stream event: $event");
            _geolocation.stopListening();
            Session.stopSession();
            setState(() {
              _isSessionActive = false;
            });
          } else {
            setState(() {
              _distance = event["distance"] ?? 0;
              _sessionTimePerso = event["time"];
            });
          }
        });
        _geolocation.startListening();
      } else {
        // TODO REPLACE WITH TOTAL TIME FROM API
        // Get the total time spent on the track
        TimeData.getSessionTime().then((value) => setState(() {
              _totalTimePerso = value;
            }));
      }
    });

    // Check if the event has started or ended
    if (DateTime(2023, 1, 1).isAfter(end) || DateTime(2023, 1, 1).isBefore(start)) { // Replace DateTime.now() with a fixed date
      _remainingTime = "L'évènement ${DateTime(2023, 1, 1).isAfter(end) ? "est terminé" : "n'a pas encore commencé"} !";
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) => countDown());
    }

    // Get the total distance
    _getValue(() => NewEventController.getTotalMeters(1), () async => null).then((value) => setState(() {
          _distanceTotale = value;
        }));

    // Get the number of participants
    NewEventController.getActiveUsers(1).then((result) {
      if (!result.hasError) {
        setState(() {
          _numberOfParticipants = result.value;
        });
      }
    });
  }

  @override
  void dispose() {
    log("Dispose");
    _timer?.cancel();
    _geolocation.stopListening();
    super.dispose();
  }

  /// Function to refresh all values
  void _refreshValues() {
    // Retrieve the dossard number
    DossardData.getDossard().then((dossardNumber) {
      if (dossardNumber != null) {
        setState(() {
          _dossard = dossardNumber.toString();
        });

        // Get the personal distance
        _getValue(() => NewUserController.getUserTotalMeters(dossardNumber), () async => null).then((value) => setState(() {
              _distancePerso = value;
            }));

        // Get the name of the user
        NewUserController.getUser(dossardNumber).then((result) {
          if (result.value != null) {
            setState(() {
              _name = result.value!['username'] ?? "Unknown";
            });
          } else {
            log("Failed to fetch username: ${result.error}");
          }
        });
      } else {
        log("Dossard number not found");
      }
    });

    // Get the total distance
    _getValue(() => NewEventController.getTotalMeters(1), () async => null).then((value) => setState(() {
          _distanceTotale = value;
        }));

    // Get the number of participants
    NewEventController.getActiveUsers(1).then((result) {
      if (!result.hasError) {
        setState(() {
          _numberOfParticipants = result.value;
        });
      }
    });

    // Get the time spent on the track
    TimeData.getSessionTime().then((value) => setState(() {
          _totalTimePerso = value;
        }));
  }

  void _confirmStopSession(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return InfoDialog(
          title: 'Confirmation',
          content: 'Arrêter la session en cours ?',
          onYes: () async {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const LoadingScreen(text: 'On se repose un peu...'),
              ),
            );
            try {
              await Session.stopSession();
            } catch (e) {
              await Session.forceStopSession();
            }
            setState(() {
              _isSessionActive = false;
            });
            _refreshValues(); // Refresh values after stopping the session
            Navigator.of(context).pop(); // Close the loading screen
            Navigator.of(context).pop(); // Close the confirmation dialog
          },
          onNo: () {
            Navigator.of(context).pop();
          },
          logo: const Icon(Icons.warning_outlined, color: Color(Config.COLOR_APP_BAR)), // Add optional logo
        );
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
    int displayedTime = _isSessionActive ? (_sessionTimePerso ?? 0) : (_totalTimePerso ?? 0);

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        log("Trying to pop");
      },
      child: Scaffold(
        backgroundColor: const Color(Config.COLOR_BACKGROUND),
        appBar: const TopAppBar(
          title: 'Informations',
          showInfoButton: true,
        ),
        body: Stack(
          children: [
            GestureDetector(
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity! < 0) {
                  // Swiped left
                  setState(() {
                    _currentPage = (_currentPage + 1) % 2;
                    _animateToPage(_currentPage);
                  });
                } else if (details.primaryVelocity! > 0) {
                  // Swiped right
                  setState(() {
                    _currentPage = (_currentPage - 1 + 2) % 2;
                    _animateToPage(_currentPage);
                  });
                }
              },
              child: PageView(
                controller: _pageController,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  SingleChildScrollView(
                    // Make the full page scrollable
                    controller: _parentScrollController,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
                        children: <Widget>[
                          const SizedBox(height: 24), // Add margin at the top
                          const TitleCard(
                            icon: Icons.person,
                            title: 'Informations ',
                            subtitle: 'personnelles',
                          ),
                          const SizedBox(height: 24), // Add margin before the first card
                          InfoCard(
                            logo: GestureDetector(
                              onTap: () => _showIconMenu(context),
                              child: Icon(_selectedIcon),
                            ),
                            title: '№ de dossard: $_dossard',
                            data: _name,
                          ),
                          const SizedBox(height: 12),
                          InfoCard(
                            logo: Image.asset(
                              _isSessionActive
                                  ? 'assets/pictures/LogoSimpleAnimated.gif'
                                  : 'assets/pictures/LogoSimple.png',
                              width: _isSessionActive ? 40 : 32, // Adjust the width as needed
                              height: _isSessionActive ? 40 : 32, // Adjust the height as needed
                            ),
                            title: 'Distance parcourue pour l\'évènement',
                            data: '${_formatDistance(_isSessionActive ? _distance : (_distancePerso ?? 0))} mètres',
                            additionalDetails:
                                _getDistanceMessage(_isSessionActive ? _distance : (_distancePerso ?? 0)),
                          ),
                          const SizedBox(height: 12),
                          InfoCard(
                            logo: const Icon(Icons.timer_outlined),
                            title: 'Temps total passé sur le parcours',
                            data:
                                '${(displayedTime ~/ 3600).toString().padLeft(2, '0')}h ${((displayedTime % 3600) ~/ 60).toString().padLeft(2, '0')}m ${(displayedTime % 60).toString().padLeft(2, '0')}s',
                          ),
                          const SizedBox(height: 12),
                          if (_isSessionActive)
                            InfoCard(
                              logo: const Icon(Icons.groups_2),
                              title: 'L\'équipe',
                              data: '${_numberOfParticipants ?? 0}',
                            )
                          else
                            const SizedBox(height: 12),
                          if (!_isSessionActive)
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10.0),
                              child: Text(
                                'Appuie sur START pour démarrer une session',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(Config.COLOR_APP_BAR),
                                ),
                              ),
                            ),
                          const SizedBox(height: 16), // Add margin before the text
                          const SizedBox(height: 100), // Add more margin at the bottom to allow more scrolling
                        ],
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    // Make the full page scrollable
                    controller: _parentScrollController,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
                        children: <Widget>[
                          const SizedBox(height: 24), // Add margin at the top
                          const TitleCard(
                            icon: Icons.calendar_month,
                            title: 'Informations sur',
                            subtitle: 'l\'évènement',
                          ),
                          const SizedBox(height: 24),
                          ProgressCard(
                            title: 'Temps restant',
                            value: _remainingTime,
                            percentage: _calculateRemainingTimePercentage(),
                            logo: const Icon(Icons.timer_outlined),
                          ),
                          const SizedBox(height: 12),
                          ProgressCard(
                            title: 'Distance totale parcourue',
                            value: '${_formatDistance(_distanceTotale ?? 0)} m',
                            percentage: _calculateTotalDistancePercentage(),
                            logo: Image.asset(
                              'assets/pictures/LogoSimple.png',
                              width: 32, // Adjust the width as needed
                              height: 32, // Adjust the height as needed
                            ),
                          ),
                          const SizedBox(height: 12),
                          InfoCard(
                            logo: const Icon(Icons.groups_2),
                            title: 'Participants ou groupe actuellement sur le parcours',
                            data: '${_numberOfParticipants ?? 0}',
                          ),
                          const SizedBox(height: 100), // Add more margin at the bottom to allow more scrolling
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter, // Fix the "START/STOP" button at the bottom
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (int i = 0; i < 2; i++)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4.0),
                          width: 8.0, // Width for oval shape
                          height: 8.0, // Height for oval shape
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4.0), // Border radius for oval shape
                            color: _currentPage == i
                                ? const Color(Config.COLOR_APP_BAR)
                                : const Color(Config.COLOR_APP_BAR).withOpacity(0.1),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0)
                        .copyWith(bottom: 20.0), // Add padding
                    child: _isSessionActive
                        ? DiscardButton(
                            icon: Icons.stop, // Pass the icon parameter
                            text: 'STOP',
                            onPressed: () {
                              _confirmStopSession(context);
                            },
                          )
                        : ActionButton(
                            icon: Icons.flag_outlined,
                            text: 'START',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SetupPosScreen()),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
