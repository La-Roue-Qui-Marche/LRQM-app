// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'dart:io' show Platform;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:lrqm/data/event_data.dart';
import 'package:lrqm/utils/permission_helper.dart';
import 'package:lrqm/utils/config.dart';
import 'package:lrqm/geo/geolocation.dart';
import 'package:lrqm/ui/components/button_action.dart';
import 'package:lrqm/ui/components/card_info.dart';
import 'package:lrqm/ui/components/modal_bottom_text.dart';
import 'package:lrqm/ui/components/app_top_bar.dart';
import 'package:lrqm/ui/loading_screen.dart';
import 'package:lrqm/ui/setup_team_screen.dart';
import 'package:lrqm/ui/components/app_toast.dart';

class SetupPosScreen extends StatefulWidget {
  final GeolocationController geolocation;

  const SetupPosScreen({super.key, required this.geolocation});

  @override
  State<SetupPosScreen> createState() => _SetupPosScreenState();
}

class _SetupPosScreenState extends State<SetupPosScreen> {
  bool _isLoading = false;
  double? _meetingLat;
  double? _meetingLon;

  @override
  void initState() {
    super.initState();
    _loadMeetingPoint();
    _checkPermissions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/pictures/DrawPos-AI.png'), context);
  }

  Future<void> _checkPermissions() async {
    final granted = await PermissionHelper.isProperLocationPermissionGranted();
    if (!granted) _showLocationPermissionModal();
  }

  void _showLocationPermissionModal() {
    String title = Platform.isIOS ? "Position en arrière-plan" : "Autorisation de position";
    String message = Platform.isIOS
        ? "Peux-tu sélectionner 'TOUJOURS AUTORISER' afin que nous puissions calculer ta distance parcourue, même si ton téléphone est inactif, dans ta poche par exemple ?"
        : "Peux-tu autoriser l'accès à ta position afin que nous puissions calculer ta distance parcourue ?";

    showModalBottomText(
      context,
      title,
      message,
      showConfirmButton: true,
      onConfirm: () => PermissionHelper.requestProperLocationPermission(),
    );
  }

  Future<void> _loadMeetingPoint() async {
    final points = await EventData.getMeetingPointLatLngList();
    setState(() {
      if (points != null && points.isNotEmpty) {
        _meetingLat = points[0].latitude;
        _meetingLon = points[0].longitude;
      } else {
        _meetingLat = null;
        _meetingLon = null;
      }
    });
  }

  Future<void> _navigateToSetupTeamScreen() async {
    setState(() => _isLoading = true);

    // Use a Timer to allow cancellation
    bool timedOut = false;
    Timer? timeoutTimer;
    timeoutTimer = Timer(const Duration(seconds: 10), () {
      if (_isLoading) {
        setState(() => _isLoading = false);
        timedOut = true;
        AppToast.showError("Temps de chargement dépassé. Veuillez réessayer.");
      }
    });

    try {
      final granted = await PermissionHelper.isProperLocationPermissionGranted();
      if (!granted) {
        String title = Platform.isIOS ? "Position en arrière-plan" : "Autorisation de position";
        String message = Platform.isIOS
            ? "Peux-tu sélectionner 'TOUJOURS AUTORISER' afin que nous puissions calculer ta distance parcourue, même si ton téléphone est inactif, dans ta poche par exemple ?"
            : "Peux-tu autoriser l'accès à ta position afin que nous puissions calculer ta distance parcourue ?";

        showModalBottomText(
          context,
          title,
          message,
          showConfirmButton: true,
          onConfirm: () => PermissionHelper.openLocationSettings(),
        );
        setState(() => _isLoading = false);
        timeoutTimer.cancel();
        return;
      }

      timeoutTimer.cancel();
      if (await widget.geolocation.isInZone()) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupTeamScreen()));
      } else {
        final distance = await widget.geolocation.distanceToZone();
        showModalBottomText(
          context,
          "Position incorrecte",
          "Tu es à ${distance.toStringAsFixed(1)} km de la zone de l'événement. Consulte la carte pour te rendre au point de départ.",
          showConfirmButton: true,
        );
      }
    } catch (e) {
      if (!timedOut) {
        AppToast.showError("Une erreur est survenue. Vérifie les paramètres et réessaie.");
      }
    }

    if (!timedOut) setState(() => _isLoading = false);
    timeoutTimer.cancel();
  }

  void _copyCoordinates() {
    if (_meetingLat == null || _meetingLon == null) {
      AppToast.showError("Une erreur est survenue. Impossible de copier les coordonnées.");
      return;
    }
    Clipboard.setData(ClipboardData(text: '$_meetingLat,$_meetingLon'));
    AppToast.showSuccess("Coordonnées copiées dans le presse-papier !");
  }

  Future<void> _openInGoogleMaps() async {
    if (_meetingLat == null || _meetingLon == null) {
      AppToast.showError("Impossible d'ouvrir l'application de navigation.");
      return;
    }

    final lat = _meetingLat!;
    final lon = _meetingLon!;
    Uri uri;

    if (Platform.isIOS) {
      uri = Uri.parse('maps://?ll=$lat,$lon&q=Point+de+depart');
    } else if (Platform.isAndroid) {
      uri = Uri.parse('geo:$lat,$lon?q=$lat,$lon');
    } else {
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    }

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        AppToast.showError("Impossible d'ouvrir l'application de navigation.");
      }
    } catch (e) {
      AppToast.showError("Erreur de lancement de l'application de navigation: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
      child: Scaffold(
        backgroundColor: const Color(Config.backgroundColor),
        appBar: _isLoading
            ? null
            : const AppTopBar(
                title: "Position",
                showInfoButton: false,
                showBackButton: true,
                showLogoutButton: false,
              ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(top: 0.0, bottom: 12.0),
              child: Column(
                children: [
                  _buildInfoCard(),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 48.0),
                child: ButtonAction(
                  icon: Icons.arrow_forward,
                  text: 'Suivant',
                  onPressed: _navigateToSetupTeamScreen,
                ),
              ),
            ),
            if (_isLoading) const LoadingScreen(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(0.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.55,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: FadeInImage(
                  placeholder: MemoryImage(kTransparentImage),
                  image: const AssetImage('assets/pictures/DrawPos-AI.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          CardInfo(
            title: "Prépares-toi !",
            data: "Rends-toi au point de départ de l'évènement. Appuie sur suivant quand tu es prêt.",
            actionItems: [
              ActionItem(
                icon: SvgPicture.asset('assets/icons/diamond-turn-right.svg',
                    color: Colors.black87, width: 28, height: 28),
                label: 'Maps',
                onPressed: _openInGoogleMaps,
              ),
              ActionItem(
                icon: SvgPicture.asset('assets/icons/copy.svg', color: Colors.black87, width: 28, height: 28),
                label: 'Copier',
                onPressed: _copyCoordinates,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
