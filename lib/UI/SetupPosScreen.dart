import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'Components/InfoCard.dart';
import 'Components/ActionButton.dart';
import 'Components/TextModal.dart';
import 'Components/MapCard.dart';

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
  Position? _currentPosition;
  bool _isLoading = false; // Loading state
  bool _isMapLoading = false; // Map loading state

  @override
  void initState() {
    super.initState();
    _requestPermissionAndFetchPosition();
  }

  // Request permission and update current position immediately.
  Future<void> _requestPermissionAndFetchPosition() async {
    var status = await Permission.location.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      await Permission.location.request();
    }
    _updateUserPosition();
  }

  Future<void> _updateUserPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = pos;
      });
      log("User position updated: ${pos.latitude}, ${pos.longitude}");
    } catch (e) {
      log("Error getting current position: $e");
    }
  }

  void _openInGoogleMaps() async {
    // Using the event location as an example here (Config.LAT1, Config.LON1).
    final url = 'geo:${Config.LAT1},${Config.LON1}?q=${Config.LAT1},${Config.LON1}';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  void _copyCoordinates() {
    final coordinates = '${Config.LAT1}, ${Config.LON1}';
    Clipboard.setData(ClipboardData(text: coordinates));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Les coordonnées ont été copiées dans le presse-papiers.')),
    );
  }

  void _showMapModal(BuildContext context) {
    setState(() {
      _isMapLoading = true;
    });

    // Refresh the position before showing the map modal with a 7-second timeout.
    _updateUserPosition().timeout(const Duration(seconds: 7)).then((_) {
      setState(() {
        _isMapLoading = false;
      });
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return const MapCard();
        },
      );
    }).catchError((error) {
      setState(() {
        _isMapLoading = false;
      });
      log("Error or timeout updating position for map modal: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load map. Please try again.')),
      );
    });
  }

  void _navigateToSetupTeamScreen() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var status = await Permission.location.status;
      if (status.isDenied || status.isPermanentlyDenied) {
        showTextModal(
          context,
          "Accès à la localisation refusé",
          "On dirait que l'accès à la localisation est bloqué. Va dans les paramètres de ton téléphone et active la localisation. Appuie sur OK pour être redirigé.",
          showConfirmButton: true,
          onConfirm: () async {
            await Geolocator.openLocationSettings();
          },
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Fetch latest user position before navigation.
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      bool canStartNewMeasure = true;
      if (await MeasureData.isMeasureOngoing()) {
        String? measureId = await MeasureData.getMeasureId();
        log("Ongoing measure ID: $measureId");
        final stopResult = await NewMeasureController.stopMeasure();
        canStartNewMeasure = !stopResult.hasError;
        if (stopResult.hasError) {
          showInSnackBar("Failed to stop ongoing measure: ${stopResult.error}");
          log("Failed to stop measure: ${stopResult.error}");
        }
      }

      log("Can start new measure: $canStartNewMeasure");

      if (await Geolocation.handlePermission()) {
        if (await Geolocation().isInZone()) {
          if (canStartNewMeasure) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SetupTeamScreen()),
            );
          }
        } else {
          final distance = await Geolocation().distanceToZone();
          final distanceText = distance > 0 ? "Tu es actuellement à ${distance.toStringAsFixed(1)} km de la zone." : "";
          showTextModal(
            context,
            "Attention",
            "Tu es hors de la zone de l'évènement. Déplace-toi dans la zone pour continuer.\n\n$distanceText",
            showConfirmButton: true,
          );
          log("User is not in the zone");
        }
      } else {
        showTextModal(
          context,
          "Autorisation requise",
          "La localisation est désactivée. Active-la dans tes paramètres pour continuer.",
          showConfirmButton: true,
        );
        log("Location permission not granted");
      }
    } catch (e) {
      showTextModal(
        context,
        "Erreur d'accès à la localisation",
        "Une erreur inattendue s'est produite. Vérifie les paramètres de ton téléphone pour autoriser l'application à utiliser la localisation. Appuie sur OK pour réessayer.",
        showConfirmButton: true,
        onConfirm: _navigateToSetupTeamScreen,
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  void showInSnackBar(String value) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(Config.COLOR_BACKGROUND),
      body: Padding(
        padding: const EdgeInsets.only(top: 12.0),
        child: Stack(
          children: [
            SvgPicture.asset(
              'assets/pictures/background.svg',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 40.0, left: 8.0, right: 8.0),
                child: Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back, color: Color(Config.COLOR_APP_BAR), size: 32),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        ),
                        Center(
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.35,
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
                              icon: const Icon(Icons.map, color: Color(Config.COLOR_APP_BAR), size: 32),
                              label: 'Carte',
                              onPressed: () => _showMapModal(context),
                            ),
                            ActionItem(
                              icon: const Icon(Icons.directions, color: Color(Config.COLOR_APP_BAR), size: 32),
                              label: 'Maps',
                              onPressed: _openInGoogleMaps,
                            ),
                            ActionItem(
                              icon: const Icon(Icons.copy_rounded, color: Color(Config.COLOR_APP_BAR), size: 32),
                              label: 'Copier',
                              onPressed: _copyCoordinates,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Appuie sur 'Suivant' quand tu es sur le lieu de l'évènement.",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(Config.COLOR_APP_BAR),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
                child: ActionButton(
                  icon: Icons.arrow_forward,
                  text: 'Suivant',
                  onPressed: _navigateToSetupTeamScreen,
                ),
              ),
            ),
            if (_isLoading) const LoadingScreen(),
            if (_isMapLoading)
              ModalBarrier(
                color: Colors.black.withOpacity(0.3),
                dismissible: false,
              ),
          ],
        ),
      ),
    );
  }
}
