import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'dart:io' show Platform;

import 'Components/InfoCard.dart';
import 'Components/ActionButton.dart';
import 'Components/TextModal.dart';
import 'Components/DynamicMapCard.dart';
import 'Components/TopAppBar.dart';

import '../Utils/config.dart';
import 'LoadingScreen.dart';
import 'SetupTeamScreen.dart';
import 'WorkingScreen.dart';

import '../API/NewMeasureController.dart';
import '../Data/MeasureData.dart';
import '../Geolocalisation/Geolocation.dart'; // <--- Import your Geolocation class!

class SetupPosScreen extends StatefulWidget {
  const SetupPosScreen({super.key});

  @override
  _SetupPosScreenState createState() => _SetupPosScreenState();
}

class _SetupPosScreenState extends State<SetupPosScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionOnEnter();
  }

  Future<void> _requestPermissionOnEnter() async {
    try {
      await Geolocation.handlePermission();
    } catch (e) {
      log("Error requesting permission: $e");
    }
  }

  void _openInGoogleMaps() async {
    final Uri fallbackUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Config.LAT1},${Config.LON1}');
    try {
      if (!await launchUrl(fallbackUrl)) {
        throw 'Could not launch Maps';
      }
    } catch (e) {
      log("Error opening maps: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir Google Maps.')),
      );
    }
  }

  void _copyCoordinates() {
    Clipboard.setData(ClipboardData(text: '${Config.LAT1}, ${Config.LON1}'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coordonnées copiées.')),
    );
  }

  void _showMapModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext context) {
        return const SizedBox(
          height: 400,
          child: DynamicMapCard(),
        );
      },
    );
  }

  Future<void> _navigateToSetupTeamScreen() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final geolocation = Geolocation();

      // TODO Check permission first

      final insideZone = await geolocation.isInZone();

      if (!insideZone) {
        final distance = await geolocation.distanceToZone();
        showTextModal(
          context,
          "Hors de la zone",
          "Tu es hors de la zone de l'évènement.${distance > 0 ? "\n\nTu es à ${distance.toStringAsFixed(1)} km de la zone." : ""}",
          showConfirmButton: true,
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      bool canStartNewMeasure = true;

      if (await MeasureData.isMeasureOngoing()) {
        final stopResult = await NewMeasureController.stopMeasure();
        canStartNewMeasure = !stopResult.hasError;
        if (stopResult.hasError) {
          log("Failed to stop ongoing measure: ${stopResult.error}");
        }
      }

      if (canStartNewMeasure) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SetupTeamScreen()),
        );
      }
    } catch (e) {
      log("Unexpected error: $e");
      showTextModal(
        context,
        "Erreur",
        "Une erreur est survenue. Vérifie ta connexion ou réessaie.",
        showConfirmButton: true,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(Config.COLOR_BACKGROUND),
      appBar: _isLoading
          ? null
          : TopAppBar(
              title: "Position",
              showInfoButton: false,
              showBackButton: true,
              showLogoutButton: false,
            ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
              child: Column(
                children: [
                  Container(
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
                            child: const Image(
                              image: AssetImage('assets/pictures/DrawPosition-removebg.png'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        InfoCard(
                          title: "Préparez-vous",
                          data: "Rendez-vous au point de départ de l'évènement.",
                          actionItems: [
                            ActionItem(
                              icon: SvgPicture.asset(
                                'assets/icons/map.svg',
                                color: Colors.black87,
                                width: 28,
                                height: 28,
                              ),
                              label: 'Carte',
                              onPressed: () => _showMapModal(context),
                            ),
                            ActionItem(
                              icon: SvgPicture.asset(
                                'assets/icons/diamond-turn-right.svg',
                                color: Colors.black87,
                                width: 28,
                                height: 28,
                              ),
                              label: 'Maps',
                              onPressed: _openInGoogleMaps,
                            ),
                            ActionItem(
                              icon: SvgPicture.asset(
                                'assets/icons/copy.svg',
                                color: Colors.black87,
                                width: 28,
                                height: 28,
                              ),
                              label: 'Copier',
                              onPressed: _copyCoordinates,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      "Appuie sur 'Suivant' quand tu es sur le lieu de l'évènement.",
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
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
    );
  }
}
