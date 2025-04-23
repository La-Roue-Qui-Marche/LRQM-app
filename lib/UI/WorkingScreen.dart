// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';

import 'Components/TopAppBar.dart';
import 'Components/TextModal.dart';
import 'SetupPosScreen.dart';
import 'LoadingScreen.dart';
import 'SummaryScreen.dart';
import '../Utils/config.dart';
import '../Geolocalisation/Geolocation.dart';
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
  DateTime? _eventEnd;
  int _currentPage = 0;
  bool _isEventOver = false;
  bool _isMeasureOngoing = false;
  bool _isCountingInZone = true;
  bool _shouldShowEventModal = false;
  final ScrollController _scrollController = ScrollController();
  late Geolocation _geolocation;
  Timer? _eventCheckTimer;

  @override
  void initState() {
    super.initState();
    _initGeolocation();
    _initializeData();
    _eventCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) => _checkIfEventIsOver());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Show the event modal if needed after returning from summary
    if (_shouldShowEventModal) {
      _shouldShowEventModal = false;
      // Use a post-frame callback to avoid build context issues
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showEventCompletionModal();
      });
    }
  }

  @override
  void dispose() {
    _eventCheckTimer?.cancel();
    _geolocation.stopListening();
    super.dispose();
  }

  void _initGeolocation() {
    final geoConfig = GeolocationConfig(
      locationUpdateInterval: Config.locationUpdateInterval,
      locationDistanceFilter: Config.locationDistanceFilter,
      accuracyThreshold: Config.accuracyThreshold,
      distanceThreshold: Config.distanceThreshold,
      speedThreshold: Config.speedThreshold,
      apiInterval: Config.apiInterval,
      outsideCounterMax: Config.outsideCounterMax,
    );
    _geolocation = Geolocation(config: geoConfig);
  }

  void _initializeData() {
    _updateMeasureStatus();
    EventData.getEndDate().then((endDate) {
      if (endDate != null && mounted) {
        setState(() {
          _eventEnd = DateTime.parse(endDate);
        });
        _checkIfEventIsOver();
      }
    });
  }

  void _checkIfEventIsOver() async {
    if (_eventEnd == null || !mounted) return;
    final isOver = _isEventCurrentlyOver();
    if (isOver != _isEventOver) {
      setState(() => _isEventOver = isOver);
      if (isOver) {
        if (_isMeasureOngoing) {
          // Show summary, then set flag to show modal after returning
          _shouldShowEventModal = true;
          await _forceStopAndShowSummary();
        } else {
          // No summary, show modal directly
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

  // --- UI Builders ---
  Widget _buildPersonalInfoContent() => Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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

  Widget _buildEventInfoContent() => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 0.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EventProgressCard(),
            SupportCard(),
          ],
        ),
      );

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
        body: IndexedStack(
          index: _currentPage,
          children: [
            SingleChildScrollView(
              key: const PageStorageKey('scrollPage0'),
              controller: _scrollController,
              child: _buildPersonalInfoContent(),
            ),
            SingleChildScrollView(
              key: const PageStorageKey('scrollPage1'),
              controller: _scrollController,
              child: _buildEventInfoContent(),
            ),
          ],
        ),
        bottomNavigationBar: NavBar(
          currentPage: _currentPage,
          onPageSelected: (int page) => setState(() => _currentPage = page),
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
  bool _isEventCurrentlyOver() {
    return _eventEnd != null && DateTime.now().isAfter(_eventEnd!);
  }

  Future<void> _updateMeasureStatus() async {
    final isOngoing = await MeasureData.isMeasureOngoing();
    if (!mounted) return;
    setState(() => _isMeasureOngoing = isOngoing);
    if (isOngoing) _geolocation.startListening();
  }

  Future<void> _forceStopAndShowSummary() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LoadingScreen(text: 'On se repose un peu...'),
      ),
    );
    int currentDistance = 0;
    int currentTime = 0;
    try {
      currentDistance = _geolocation.currentDistance;
      currentTime = _geolocation.elapsedTimeInSeconds;
      log("Retrieved from geolocation: distance=$currentDistance, time=$currentTime");
      await _geolocation.stopListening();
    } catch (e) {
      log("Failed to get measure data: $e");
    }
    final contributors = await ContributorsData.getContributors() ?? 1;
    final metersGoal = await EventData.getMetersGoal() ?? 1;
    Navigator.of(context).pop();
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
        await _forceStopAndShowSummary();
      },
      showDiscardButton: true,
    );
  }
}
