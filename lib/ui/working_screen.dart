// ignore_for_file: prefer_const_constructors, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';

import 'package:lrqm/utils/config.dart';
import 'package:lrqm/geo/geolocation.dart';
import 'package:lrqm/data/event_data.dart';
import 'package:lrqm/data/measure_data.dart';
import 'package:lrqm/data/contributors_data.dart';
import 'package:lrqm/data/utils_data.dart';
import 'package:lrqm/ui/components/app_top_bar.dart';
import 'package:lrqm/ui/components/modal_bottom_text.dart';
import 'package:lrqm/ui/components/app_nav_bar.dart';
import 'package:lrqm/ui/components/card_dynamic_map.dart';
import 'package:lrqm/ui/components/card_progress_event.dart';
import 'package:lrqm/ui/components/card_support_event.dart';
import 'package:lrqm/ui/components/app_toast.dart';
import 'package:lrqm/ui/components/card_personal_info.dart';
import 'package:lrqm/ui/setup_pos_screen.dart';
import 'package:lrqm/ui/loading_screen.dart';
import 'package:lrqm/ui/summary_screen.dart';
import 'package:lrqm/ui/login_screen.dart';
import 'package:lrqm/ui/info_screen.dart';

class WorkingScreen extends StatefulWidget {
  const WorkingScreen({super.key});
  @override
  State<WorkingScreen> createState() => _WorkingScreenState();
}

class _WorkingScreenState extends State<WorkingScreen> with SingleTickerProviderStateMixin {
  final _scrollController = ScrollController();

  EventStatus _eventStatus = EventStatus.notStarted;
  bool _isMeasureOngoing = false;
  bool _isLoading = true;
  bool _isForceLoading = false;
  int _currentPage = 0;
  bool _showMainCards = true;
  Timer? _eventCheckTimer;

  late GeolocationController _geolocation;

  @override
  void initState() {
    super.initState();
    _initializeGeolocation();
    _initializeMeasureStatus();
    _initializeEventStatus();
    _startEventStatusTimer();
  }

  @override
  void dispose() {
    _eventCheckTimer?.cancel();
    _geolocation.stopListening();
    super.dispose();
  }

  Future<void> _initializeMeasureStatus() async {
    _isMeasureOngoing = await MeasureData.isMeasureOngoing();
    if (_isMeasureOngoing) {
      _geolocation.startListening();
    }
  }

  void _initializeGeolocation() {
    _geolocation = GeolocationController(
      config: GeolocationConfig(
        locationDistanceFilter: Config.locationDistanceFilter,
        apiInterval: Config.apiInterval,
        outsideCounterMax: Config.outsideCounterMax,
      ),
    );
  }

  Future<void> _initializeEventStatus() async {
    _eventStatus = await EventData.getEventStatus();
    if (_eventStatus == EventStatus.notStarted) {
      AppToast.showInfo("L'événement n'a pas encore commencé.");
    } else if (_eventStatus == EventStatus.over) {
      AppToast.showInfo("L'événement est terminé.");
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _startEventStatusTimer() {
    _eventCheckTimer = Timer.periodic(Duration(seconds: 1), (_) async {
      await _checkEventStatus();
      await _checkMeasureStatus();
    });
  }

  Future<void> _checkEventStatus() async {
    final currentStatus = await EventData.getEventStatus();
    if (currentStatus == _eventStatus) return;

    if (currentStatus == EventStatus.over && _isMeasureOngoing) {
      AppToast.showInfo("L'événement est terminé. Arrêt de la session en cours.");
      await _forceStopAndShowSummary();
    }

    if (currentStatus == EventStatus.inProgress && _eventStatus == EventStatus.notStarted) {
      AppToast.showInfo("L'événement a commencé! \n Tu peux maintenant enregistrer ta distance.");
    }

    setState(() {
      _eventStatus = currentStatus; // Refresh the event status
    });
  }

  Future<void> _checkMeasureStatus() async {
    if (!_geolocation.isCountingInZone && _isMeasureOngoing) {
      AppToast.showError("Tu es hors de la zone autorisée. Arrêt de la session en cours.");
      await _forceStopAndShowSummary();
    }
  }

  Future<void> _forceStopAndShowSummary() async {
    _eventCheckTimer?.cancel();

    setState(() => _isForceLoading = true);

    int distance = 0, duration = 0;
    bool stopSuccess = false;

    while (!stopSuccess) {
      try {
        distance = _geolocation.currentDistance;
        duration = _geolocation.elapsedTimeInSeconds;
        stopSuccess = await _geolocation.stopListening();
      } catch (e) {
        AppToast.showError("Erreur lors de l'arrêt de la mesure : $e, ");
      }

      if (!stopSuccess) {
        if (mounted) {
          AppToast.showError("Impossible d'arrêter la mesure, on réessaie...");
          await Future.delayed(const Duration(seconds: 10));
        }
      }
    }

    AppToast.showSuccess("Mesure arrêtée et enregistrée !");

    final contributors = await ContributorsData.getContributors() ?? 1;
    final goal = await EventData.getMetersGoal() ?? 1;
    final contribution = (distance * contributors / goal) * 100;

    if (!mounted) return;

    setState(() => _isForceLoading = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SummaryScreen(
          distanceAdded: distance,
          timeAdded: duration,
          percentageAdded: contribution,
          contributors: contributors,
        ),
      ),
    );
  }

  void _onStartStopPressed(bool isOngoing) {
    if (isOngoing) {
      _confirmStopMeasure();
    } else {
      _navigateToSetupScreen();
    }
  }

  void _navigateToSetupScreen() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => SetupPosScreen(geolocation: _geolocation)));
  }

  void _confirmStopMeasure() {
    showModalBottomText(
      context,
      'Confirmation',
      'Arrêter la mesure en cours ?\n\nCela mettra fin à l\'enregistrement de ta distance et de ton temps.',
      showConfirmButton: true,
      onConfirm: _forceStopAndShowSummary,
      showDiscardButton: true,
    );
  }

  void _handleInfoButton() => Navigator.push(context, MaterialPageRoute(builder: (_) => const InfoScreen()));

  void _handleLogoutButton() async {
    showModalBottomText(
      context,
      'Confirmation',
      'Es-tu sûr de vouloir te déconnecter ?\n\nCela supprimera toutes les données locales et arrêtera toute mesure en cours.',
      showConfirmButton: true,
      onConfirm: () async {
        setState(() => _showMainCards = false);
        await Future.delayed(const Duration(milliseconds: 100));

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const LoadingScreen(text: "Déconnexion..."),
            fullscreenDialog: true,
          ),
        );

        await Future.delayed(const Duration(seconds: 2));
        if (await MeasureData.isMeasureOngoing()) {
          await _geolocation.forceStopListening();
        }

        final cleared = await UtilsData.deleteAllData();
        if (cleared && mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const Login()),
            (route) => false,
          );
        } else if (mounted) {
          Navigator.pop(context);
          AppToast.showError("Échec de la suppression des données utilisateur");
        }
      },
      showDiscardButton: true,
    );
  }

  Widget _buildMainContent() {
    return IndexedStack(
      index: _currentPage,
      children: [
        if (_showMainCards) _buildHomePage() else const SizedBox.shrink(),
        if (_showMainCards) _buildEventPage() else const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildHomePage() {
    return Stack(
      children: [
        // Full screen map that fills the entire space
        Positioned.fill(
          child: CardDynamicMap(
            geolocation: _geolocation,
            followUser: _isMeasureOngoing,
          ),
        ),

        // PersonalInfoCard as a draggable bottom sheet
        CardPersonalInfo(
          key: const ValueKey('personalInfoCard'),
          isSessionActive: _isMeasureOngoing,
          geolocation: _geolocation,
        ),
      ],
    );
  }

  Widget _buildEventPage() {
    return SingleChildScrollView(
      key: PageStorageKey('scrollPage1'),
      controller: _scrollController,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CardProgressEvent(key: ValueKey('eventProgressCard')),
          CardSupportEvent(),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return AppNavBar(
      currentPage: _currentPage,
      onPageSelected: (int page) => setState(() => _currentPage = page),
      isMeasureActive: _isMeasureOngoing,
      canStartNewSession: _eventStatus == EventStatus.inProgress,
      onStartStopPressed: () => _onStartStopPressed(_isMeasureOngoing),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _isForceLoading) {
      return LoadingScreen(
          timeout: _isForceLoading ? null : const Duration(seconds: 10),
          onTimeout: () {
            setState(() => _isLoading = false);
            AppToast.showError("Chargement trop long. Veuillez réessayer.");
          },
          timeoutMessage: "Chargement trop long. Veuillez réessayer.");
    }

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
      child: PopScope(
        canPop: false,
        onPopInvoked: (_) async {},
        child: Scaffold(
          backgroundColor: Color(Config.backgroundColor),
          appBar: AppTopBar(
            title: 'Accueil',
            showInfoButton: true,
            showLogoutButton: true,
            geolocation: _geolocation,
            onInfo: _handleInfoButton,
            onLogout: _handleLogoutButton,
          ),
          body: _buildMainContent(),
          bottomNavigationBar: _buildBottomNavigation(),
        ),
      ),
    );
  }
}
