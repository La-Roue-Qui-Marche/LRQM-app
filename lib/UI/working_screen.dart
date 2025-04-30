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

  final _eventStatusNotifier = ValueNotifier<EventStatus>(EventStatus.inProgress);
  final _isMeasureOngoingNotifier = ValueNotifier<bool>(false);
  final _isCountingInZoneNotifier = ValueNotifier<bool>(true);

  int _currentPage = 0;
  bool _shouldShowEventModal = false;
  bool _showMainCards = true;
  Timer? _eventCheckTimer;
  bool _isDisposed = false;

  late GeolocationController _geolocation;

  @override
  void initState() {
    super.initState();
    _initializeGeolocation();
    _initializeState();
    _startEventStatusTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shouldShowEventModal) {
      _shouldShowEventModal = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showEventCompletionModal();
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _eventCheckTimer?.cancel();
    _geolocation.stopListening();
    _eventStatusNotifier.dispose();
    _isMeasureOngoingNotifier.dispose();
    _isCountingInZoneNotifier.dispose();
    super.dispose();
  }

  void _initializeGeolocation() {
    _geolocation = GeolocationController(
      config: GeolocationConfig(
        locationDistanceFilter: Config.locationDistanceFilter,
        accuracyThreshold: Config.accuracyThreshold,
        distanceThreshold: Config.distanceThreshold,
        speedThreshold: Config.speedThreshold,
        apiInterval: Config.apiInterval,
        outsideCounterMax: Config.outsideCounterMax,
      ),
    );
  }

  void _initializeState() {
    _checkEventStatus();
    _syncMeasureStatus();
  }

  void _startEventStatusTimer() {
    _eventCheckTimer = Timer.periodic(Duration(seconds: 1), (_) {
      if (!_isDisposed) _checkEventStatus();
    });
  }

  Future<void> _checkEventStatus() async {
    if (_isDisposed) return;
    final currentStatus = await EventData.getEventStatus();
    final previousStatus = _eventStatusNotifier.value;
    if (currentStatus == previousStatus) return;

    _eventStatusNotifier.value = currentStatus;

    if (previousStatus == EventStatus.notStarted && currentStatus == EventStatus.inProgress) {
      _showEventStartedModal();
    }
    if (currentStatus == EventStatus.over && _isMeasureOngoingNotifier.value) {
      _shouldShowEventModal = true;
      await _forceStopAndShowSummary();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (currentStatus == EventStatus.notStarted && previousStatus != EventStatus.notStarted) {
        _showEventNotStartedModal();
      } else if (currentStatus == EventStatus.over && previousStatus != EventStatus.over) {
        _showEventCompletionModal();
      }
    });
  }

  Future<void> _syncMeasureStatus() async {
    final ongoing = await MeasureData.isMeasureOngoing();
    _isMeasureOngoingNotifier.value = ongoing;
    if (ongoing) _geolocation.startListening();
  }

  Future<void> _forceStopAndShowSummary() async {
    Navigator.push(context, MaterialPageRoute(builder: (_) => LoadingScreen(text: 'On se repose un peu...')));
    int distance = 0, duration = 0;
    bool stopSuccess = false;
    try {
      distance = _geolocation.currentDistance;
      duration = _geolocation.elapsedTimeInSeconds;
      stopSuccess = await _geolocation.stopListening();
    } catch (e) {
      AppToast.showError("Erreur lors de l'arrêt de la mesure : $e");
    }

    if (!stopSuccess) {
      if (mounted) {
        AppToast.showError("Impossible d'arrêter la mesure, veuillez réessayer.");
        Navigator.pop(context);
      }
      return;
    } else {
      AppToast.showSuccess("Mesure arrêtée et enregistrée !");
    }

    final contributors = await ContributorsData.getContributors() ?? 1;
    final goal = await EventData.getMetersGoal() ?? 1;
    final contribution = (distance * contributors / goal) * 100;

    if (!mounted) return;
    Navigator.pop(context);
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

  void _onStartStopPressed(EventStatus status, bool isOngoing) {
    if (isOngoing) {
      _confirmStopMeasure();
    } else if (status == EventStatus.notStarted) {
      _showEventNotStartedModal();
    } else if (status == EventStatus.over) {
      _showEventCompletionModal();
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
        _isDisposed = true; // Prevent further timer/event checks
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
          await _geolocation.stopListening();
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
        ValueListenableBuilder(
          valueListenable: _isMeasureOngoingNotifier,
          builder: (_, isOngoing, __) => Positioned.fill(
            child: CardDynamicMap(
              geolocation: _geolocation,
              followUser: isOngoing,
              fullScreen: true,
            ),
          ),
        ),

        // PersonalInfoCard as a draggable bottom sheet
        ValueListenableBuilder(
          valueListenable: _isMeasureOngoingNotifier,
          builder: (_, isOngoing, __) => CardPersonalInfo(
            key: const ValueKey('personalInfoCard'),
            isSessionActive: isOngoing,
            geolocation: _geolocation,
            isFloating: true,
          ),
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
    return ValueListenableBuilder<EventStatus>(
      valueListenable: _eventStatusNotifier,
      builder: (_, status, __) => ValueListenableBuilder<bool>(
        valueListenable: _isMeasureOngoingNotifier,
        builder: (_, isOngoing, __) => AppNavBar(
          currentPage: _currentPage,
          onPageSelected: (int page) => setState(() => _currentPage = page),
          isMeasureActive: isOngoing,
          canStartNewSession: status == EventStatus.inProgress,
          onStartStopPressed: () => _onStartStopPressed(status, isOngoing),
        ),
      ),
    );
  }

  void _showEventCompletionModal() => showModalBottomText(context, 'L\'Évènement est Terminé !',
      "Merci pour ta participation !\n N'hésites pas à prendre une capture d'écran de ta contribution",
      showConfirmButton: true);
  void _showEventNotStartedModal() => showModalBottomText(
      context, 'L\'Évènement n\'a pas Commencé', "Tu pourras démarrer une mesure dès le début de l'évènement.",
      showConfirmButton: true);
  void _showEventStartedModal() => showModalBottomText(context, 'L\'Évènement a Commencé !',
      "Tu peux maintenant démarrer une session pour enregistrer ta contribution à l'évènement.",
      showConfirmButton: true);

  @override
  Widget build(BuildContext context) {
    return PopScope(
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
    );
  }
}
