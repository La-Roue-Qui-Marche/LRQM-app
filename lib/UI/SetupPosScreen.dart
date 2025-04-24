// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io' show Platform;
import 'package:transparent_image/transparent_image.dart';

import '../Utils/Permission.dart';
import 'Components/InfoCard.dart';
import 'Components/ActionButton.dart';
import 'Components/TextModal.dart';
import 'Components/DynamicMapCard.dart';
import 'Components/TopAppBar.dart';
import '../Utils/config.dart';
import 'LoadingScreen.dart';
import 'SetupTeamScreen.dart';
import '../Geolocalisation/Geolocation.dart';
import '../API/NewMeasureController.dart';
import '../Data/MeasureData.dart';
import '../Data/EventData.dart';

class SetupPosScreen extends StatefulWidget {
  final Geolocation geolocation;

  const SetupPosScreen({super.key, required this.geolocation});

  @override
  // ignore: library_private_types_in_public_api
  _SetupPosScreenState createState() => _SetupPosScreenState();
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
    // Pre-cache image here, context is available
    precacheImage(const AssetImage('assets/pictures/DrawPos-AI.png'), context);
  }

  Future<void> _checkPermissions() async {
    bool hasPermission = await PermissionHelper.isLocationAlwaysGranted();
    if (!hasPermission) {
      _showLocationPermissionModal();
    }
  }

  void _showLocationPermissionModal() {
    showTextModal(
      context,
      "Position en arrière-plan",
      "Peux-tu sélectionner 'TOUJOURS AUTORISER' afin que nous puissions calculer ta distance parcourue, même si ton téléphone est inactif, dans ta poche par exemple ?",
      showConfirmButton: true,
      onConfirm: () async {
        await PermissionHelper.requestLocationAlwaysPermission();
      },
    );
  }

  Future<void> _loadMeetingPoint() async {
    final points = await EventData.getMeetingPointLatLngList();
    if (points != null && points.isNotEmpty) {
      setState(() {
        _meetingLat = points[0].latitude;
        _meetingLon = points[0].longitude;
      });
    } else {
      // no fallback
      setState(() {
        _meetingLat = null;
        _meetingLon = null;
      });
    }
  }

  void _navigateToSetupTeamScreen() async {
    setState(() => _isLoading = true);

    try {
      bool hasPermission = await PermissionHelper.isLocationAlwaysGranted();
      if (!hasPermission) {
        showTextModal(
          context,
          "Position en arrière-plan",
          "Peux-tu sélectionner 'TOUJOURS AUTORISER' afin que nous puissions calculer votre distance parcourue, même si votre téléphone est inactif, dans votre poche par exemple ?",
          showConfirmButton: true,
          onConfirm: () async {
            await PermissionHelper.openLocationSettings();
          },
        );
        setState(() => _isLoading = false);
        return;
      }

      bool canStartNewMeasure = true;
      if (await MeasureData.isMeasureOngoing()) {
        final stopResult = await NewMeasureController.stopMeasure();
        canStartNewMeasure = !stopResult.hasError;
        if (stopResult.hasError) {
          showInSnackBar("Erreur pour arrêter la mesure: ${stopResult.error}");
        }
      }

      if (await widget.geolocation.isInZone()) {
        if (canStartNewMeasure) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupTeamScreen()));
        }
      } else {
        final distance = await widget.geolocation.distanceToZone();
        showTextModal(
          context,
          "Hors zone",
          "Tu es à ${distance.toStringAsFixed(1)} km de la zone de l'évènement.",
          showConfirmButton: true,
        );
      }
    } catch (e) {
      showTextModal(
        context,
        "Erreur",
        "Une erreur est survenue. Vérifie les paramètres et réessaie.",
        showConfirmButton: true,
      );
    }

    setState(() => _isLoading = false);
  }

  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(Config.backgroundColor),
      appBar: _isLoading
          ? null
          : const TopAppBar(
              title: "Position",
              showInfoButton: false,
              showBackButton: true,
              showLogoutButton: false,
            ),
      body: Padding(
        padding: const EdgeInsets.only(top: 0.0),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 6.0, bottom: 12.0),
                child: Column(
                  children: [
                    _buildInfoCard(context),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        "Appuie sur 'Suivant' quand tu es sur le lieu de l'évènement.",
                        textAlign: TextAlign.left,
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 48.0),
                child: ActionButton(
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

  Widget _buildInfoCard(BuildContext context) {
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
              width: MediaQuery.of(context).size.width * 0.4,
              child: Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: FadeInImage(
                  placeholder: MemoryImage(kTransparentImage),
                  image: const AssetImage('assets/pictures/DrawPos-AI.png'),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          InfoCard(
            title: "Prépares-toi !",
            data: "Rends-toi au point de départ de l'évènement.",
            actionItems: [
              ActionItem(
                icon: SvgPicture.asset('assets/icons/map.svg', color: Colors.black87, width: 28, height: 28),
                label: 'Carte',
                onPressed: () => _showMapModal(context),
              ),
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

  void _openInGoogleMaps() async {
    if (_meetingLat == null || _meetingLon == null) {
      showInSnackBar("Impossible d'ouvrir l'application de navigation.");
      return;
    }
    double lat = _meetingLat!;
    double lon = _meetingLon!;

    Uri? uri;
    if (Platform.isIOS) {
      // Use maps:// protocol to directly open the native Apple Maps app
      uri = Uri.parse('maps://?ll=$lat,$lon&q=Point+de+départ');
    } else if (Platform.isAndroid) {
      // Android geo URI
      uri = Uri.parse('geo:$lat,$lon?q=$lat,$lon');
    } else {
      // Fallback to Google Maps web
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lon');
    }

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        showInSnackBar("Impossible d'ouvrir l'application de navigation.");
      }
    } catch (e) {
      showInSnackBar("Impossible d'ouvrir l'application de navigation: ${e.toString()}");
    }
  }

  void _copyCoordinates() {
    if (_meetingLat == null || _meetingLon == null) {
      showInSnackBar("Impossible de copier les coordonnées.");
      return;
    }
    double lat = _meetingLat!;
    double lon = _meetingLon!;
    Clipboard.setData(ClipboardData(text: '$lat,$lon'));
    showInSnackBar('Coordonnées copiées.');
  }

  void _showMapModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (_) {
        final double modalHeight = MediaQuery.of(context).size.height * 0.50;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
          child: SizedBox(
            height: modalHeight,
            width: double.infinity,
            child: Stack(
              children: [
                // Map fills the modal (no Column/Expanded)
                Positioned.fill(
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: SizedBox(
                      height: modalHeight,
                      width: double.infinity,
                      child: DynamicMapCard(geolocation: widget.geolocation),
                    ),
                  ),
                ),
                // Floating close button
              ],
            ),
          ),
        );
      },
    );
  }
}
