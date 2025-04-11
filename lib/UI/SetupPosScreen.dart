import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io' show Platform;

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

class SetupPosScreen extends StatefulWidget {
  const SetupPosScreen({super.key});

  @override
  _SetupPosScreenState createState() => _SetupPosScreenState();
}

class _SetupPosScreenState extends State<SetupPosScreen> {
  bool _isLoading = false;
  bool _isMapLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  Future<void> _checkAndRequestPermissions() async {
    setState(() => _isLoading = true);

    bool granted = await PermissionHelper.handlePermission();

    if (!granted) {
      showTextModal(
        context,
        "Autorisation requise",
        "Pour utiliser cette fonctionnalité, l'accès à la localisation est nécessaire.\n\nVeux-tu ouvrir les paramètres de l'application ?",
        showConfirmButton: true,
        onConfirm: () async {
          await PermissionHelper.openLocationSettings();
        },
      );
    }

    setState(() => _isLoading = false);
  }

  void _navigateToSetupTeamScreen() async {
    setState(() => _isLoading = true);

    try {
      bool hasPermission = await PermissionHelper.checkPermissionAlways();

      if (!hasPermission) {
        showTextModal(
          context,
          "Positon en arrière-plan",
          "Pour cet évènement, l'application nécessite l'autorisation 'Toujours' pour suivre votre position en arrière-plan.\n\n"
              "Cela garantit que vous resterez toujours connecté à la zone de l'évènement, même si l'application est minimisée ou fermée.\n\n"
              "Clique sur OK pour être redirigé vers les paramètres.",
          showConfirmButton: true,
          onConfirm: () async => await PermissionHelper.openLocationSettings(),
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

      if (await Geolocation().isInZone()) {
        if (canStartNewMeasure) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupTeamScreen()));
        }
      } else {
        final distance = await Geolocation().distanceToZone();
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
      backgroundColor: Color(Config.COLOR_BACKGROUND),
      appBar: _isLoading
          ? null
          : TopAppBar(
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
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    _buildInfoCard(context),
                    const SizedBox(height: 12),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        "Appuie sur 'Suivant' quand tu es sur le lieu de l'évènement.",
                        textAlign: TextAlign.left,
                        style: TextStyle(fontSize: 14, color: Colors.black54),
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
        borderRadius: BorderRadius.circular(16.0),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.45,
              child: const Padding(
                padding: EdgeInsets.only(top: 16.0),
                child: Image(image: AssetImage('assets/pictures/DrawPosition-removebg.png')),
              ),
            ),
          ),
          const SizedBox(height: 32),
          InfoCard(
            title: "Préparez-vous",
            data: "Rendez-vous au point de départ de l'évènement.",
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
    final Uri fallbackUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Config.LAT1},${Config.LON1}');
    final Uri geoUrl = Uri.parse('geo:0,0?q=${Config.LAT1},${Config.LON1}');
    final Uri iosUrl = Uri.parse('maps:${Config.LAT1},${Config.LON1}');

    try {
      if (Platform.isAndroid && await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl);
      } else if (Platform.isIOS && await canLaunchUrl(iosUrl)) {
        await launchUrl(iosUrl);
      } else {
        await launchUrl(fallbackUrl);
      }
    } catch (e) {
      showInSnackBar("Impossible d'ouvrir Maps.");
    }
  }

  void _copyCoordinates() {
    Clipboard.setData(ClipboardData(text: '${Config.LAT1},${Config.LON1}'));
    showInSnackBar('Coordonnées copiées.');
  }

  void _showMapModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (_) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Stack(
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 32.0),
                child: DynamicMapCard(),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
