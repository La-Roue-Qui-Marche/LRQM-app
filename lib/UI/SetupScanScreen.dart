import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../Utils/config.dart';
import 'LoadingScreen.dart';
import 'Components/InfoCard.dart';
import 'Components/ActionButton.dart';
import 'WorkingScreen.dart';
import 'Components/TextModal.dart';
import '../Data/ContributorsData.dart';
import '../API/NewMeasureController.dart';
import '../Data/UserData.dart';
import 'Components/TopAppBar.dart';
import '../Utils/Permission.dart';

class SetupScanScreen extends StatefulWidget {
  final int contributors;

  const SetupScanScreen({super.key, required this.contributors});

  @override
  State<SetupScanScreen> createState() => _SetupScanScreenState();
}

class _SetupScanScreenState extends State<SetupScanScreen> {
  final MobileScannerController controller = MobileScannerController(
    torchEnabled: false,
    autoStart: true,
  );

  bool _isCameraOpen = false;

  void _navigateToLoadingScreen() async {
    controller.stop();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const LoadingScreen(
          text: "À vos marques, prêts, partez !",
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 2), () async {
      await ContributorsData.saveContributors(widget.contributors);
      int? userId = await UserData.getUserId();
      if (userId != null) {
        await NewMeasureController.startMeasure(userId, contributorsNumber: widget.contributors);
      } else {
        log("User ID is null. Cannot start measure.");
      }
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WorkingScreen()),
        (route) => false,
      );
    });
  }

  void _handleBarcode(BarcodeCapture barcodes) {
    if (mounted && barcodes.barcodes.isNotEmpty && barcodes.barcodes.first.displayValue == Config.QR_CODE_S_VALUE) {
      _navigateToLoadingScreen();
    }
  }

  void _launchCamera() async {
    try {
      bool isGranted = await PermissionHelper.requestCameraPermission();
      if (!isGranted) {
        showTextModal(
          context,
          "Accès à la caméra refusé",
          "On dirait que l'accès à la caméra est bloqué. Va dans les paramètres de ton téléphone et autorise l'application à utiliser la caméra. Appuie sur OK être redirigé.",
          showConfirmButton: true,
          onConfirm: () async {
            await openAppSettings();
          },
        );
        return;
      }

      setState(() {
        _isCameraOpen = true;
      });
    } catch (e) {
      showTextModal(
        context,
        "Erreur d'accès à la caméra",
        "Une erreur inattendue s'est produite. Vérifie les paramètres de ton téléphone pour autoriser l'application à utiliser la caméra. Appuie sur OK pour réessayer.",
        showConfirmButton: true,
        onConfirm: _launchCamera,
      );
    }
  }

  void _quitCamera() {
    setState(() {
      _isCameraOpen = false;
    });
    controller.stop();
  }

  void _startSessionDirectly() {
    _navigateToLoadingScreen();
  }

  @override
  void dispose() {
    super.dispose();
    log("Dispose");
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(Config.COLOR_BACKGROUND),
      appBar: _isCameraOpen
          ? null // Hide the TopAppBar when the camera is open
          : TopAppBar(
              title: "Scanner",
              showBackButton: true,
              showInfoButton: false,
              showLogoutButton: false,
            ),
      body: Padding(
        padding: const EdgeInsets.only(top: 0.0),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 6.0, left: 0.0, right: 0.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(0.0), // Add rounded border
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: GestureDetector(
                          onDoubleTap: _startSessionDirectly,
                          child: Container(
                            padding: const EdgeInsets.all(16.0), // Add padding
                            width: MediaQuery.of(context).size.width * 0.45,
                            child: const Image(
                              image: AssetImage('assets/pictures/DrawScan-AI.png'),
                            ),
                          ),
                        ),
                      ),
                      const InfoCard(
                        title: "Le petit oiseau va sortir !",
                        data: "Prend en photo le QR code pour démarrer ta session",
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!_isCameraOpen)
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 48.0),
                  child: ActionButton(
                    icon: Icons.camera_alt,
                    text: "Ouvrir la caméra",
                    onPressed: _launchCamera,
                  ),
                ),
              ),
            if (_isCameraOpen)
              Stack(
                children: [
                  MobileScanner(
                    controller: controller,
                    onDetect: _handleBarcode,
                  ),
                  Positioned(
                    top: 40,
                    right: 10,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 32),
                      onPressed: _quitCamera,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
