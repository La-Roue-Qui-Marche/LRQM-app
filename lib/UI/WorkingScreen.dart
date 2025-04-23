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
  int _currentPage = 0;
  bool _isEventOver = false, _isMeasureOngoing = false, _isCountingInZone = true;
  final ScrollController _parentScrollController = ScrollController();
  late GeolocationConfig _geoConfig;
  late Geolocation _geolocation;
  Timer? _eventCheckTimer;

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

    // Set up timer to check if event is over every second
    _eventCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) => _checkIfEventIsOver());
  }

  @override
  void dispose() {
    _eventCheckTimer?.cancel();
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
          _checkIfEventIsOver();
        });
      }
    });

    // Just check if a measure is ongoing to update UI state
    _updateMeasureStatus();
  }

  // Check if the event is over based on the current time
  void _checkIfEventIsOver() {
    if (end != null && mounted) {
      final isOver = DateTime.now().isAfter(end!);
      if (isOver != _isEventOver) {
        setState(() {
          _isEventOver = isOver;
        });

        // If the event just ended and a measure is ongoing, show the event completion modal
        if (isOver) {
          _showEventCompletionModal();
        }
      }
    }
  }

  // --- Navigation ---
  void _navigateToScreen(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  void _startSetupPosScreen() => _navigateToScreen(SetupPosScreen(geolocation: _geolocation));

  // --- UI Helper Methods ---
  Widget _buildPersonalInfoContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0.0),
          child: PersonalInfoCard(
            isSessionActive: _isMeasureOngoing,
            isCountingInZone: _isCountingInZone,
            geolocation: _geolocation,
          ),
        ),
        DynamicMapCard(
          geolocation: _geolocation,
          followUser: _isMeasureOngoing,
        ),
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
                _buildPersonalInfoContent(),
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

        int currentDistance = 0;
        int currentTime = 0;

        try {
          // Get current distance and time directly from geolocation getters
          currentDistance = _geolocation.currentDistance;
          currentTime = _geolocation.elapsedTimeInSeconds;
          log("Retrieved from geolocation: distance=$currentDistance, time=$currentTime");

          // Stop the geolocation
          await _geolocation.stopListening();
        } catch (e) {
          log("Failed to get measure data: $e");
        }

        // Fetch necessary data for summary screen
        final contributors = await ContributorsData.getContributors() ?? 1;
        final metersGoal = await EventData.getMetersGoal() ?? 1;

        // Pop loading screen
        Navigator.of(context).pop();

        // Navigate to the SummaryScreen
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => SummaryScreen(
                distanceAdded: currentDistance,
                timeAdded: currentTime,
                percentageAdded: (currentDistance * contributors / metersGoal) * 100,
                contributors: contributors,
              ),
            ),
          );
        }
      },
      showDiscardButton: true,
    );
  }
}
