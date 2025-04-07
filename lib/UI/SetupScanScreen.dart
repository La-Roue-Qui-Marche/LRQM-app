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
    Future.delayed(const Duration(milliseconds: 800), () async {
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
      var status = await Permission.camera.request();
      if (status.isDenied || status.isPermanentlyDenied) {
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
      backgroundColor: const Color(Config.COLOR_BACKGROUND),
      body: Padding(
        padding: const EdgeInsets.only(top: 0.0),
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 48.0, left: 0.0, right: 0.0),
                child: Container(
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
                        child: GestureDetector(
                          onDoubleTap: _startSessionDirectly,
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.5,
                            child: const Image(
                              image: AssetImage('assets/pictures/DrawScan-removebg.png'),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
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
