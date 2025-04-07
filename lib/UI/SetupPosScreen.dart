import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io' show Platform;

import 'Components/InfoCard.dart';
import 'Components/ActionButton.dart';
import 'Components/TextModal.dart';
import 'Components/DynamicMapCard.dart';

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
  bool _isLoading = false;
  bool _isMapLoading = false;

  @override
  void initState() {
    super.initState();
    _requestPermissionAndFetchPosition();
  }

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
    final Uri geoUrl = Uri.parse('geo:0,0?q=${Config.LAT1},${Config.LON1}');
    final Uri fallbackUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Config.LAT1},${Config.LON1}');

    try {
      if (Platform.isAndroid) {
        if (await canLaunchUrl(geoUrl)) {
          await launchUrl(geoUrl);
        } else {
          await launchUrl(fallbackUrl);
        }
      } else if (Platform.isIOS) {
        final String iosMapsUrl = 'maps:${Config.LAT1},${Config.LON1}';
        final String appleMapsUrl = 'https://maps.apple.com/?q=${Config.LAT1},${Config.LON1}';

        if (await canLaunchUrl(Uri.parse(iosMapsUrl))) {
          await launchUrl(Uri.parse(iosMapsUrl));
        } else {
          await launchUrl(Uri.parse(appleMapsUrl));
        }
      } else {
        if (await canLaunchUrl(fallbackUrl)) {
          await launchUrl(fallbackUrl);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible d\'ouvrir l\'application de navigation ou Google Maps.')),
      );
      log("Error opening navigation: $e");
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Stack(
            children: [
              const DynamicMapCard(),
              Positioned(
                top: 10,
                right: 10,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.black, size: 24),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToSetupTeamScreen() async {
    setState(() {
      _isLoading = true;
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
          showTextModal(
            context,
            "Accès à la localisation refusé",
            "On dirait que l'accès à la localisation est bloqué. Va dans les paramètres de ton téléphone et active la localisation. Appuie sur OK pour être redirigé.",
            showConfirmButton: true,
            onConfirm: () async {
              await Geolocator.openAppSettings();
            },
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        setState(() {
          _isLoading = false;
        });
        return;
      }

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
        padding: const EdgeInsets.only(top: 0.0),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 48.0, left: 0.0, right: 0.0),
                child: Column(
                  children: [
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              IconButton(
                                icon: SvgPicture.asset(
                                  'assets/icons/angle-left.svg',
                                  color: Colors.black87,
                                  width: 32,
                                  height: 32,
                                ),
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
