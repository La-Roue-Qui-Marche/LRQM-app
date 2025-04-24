// ignore_for_file: use_build_context_synchronously

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:transparent_image/transparent_image.dart';

import '../API/NewMeasureController.dart';
import '../Data/ContributorsData.dart';
import '../Data/UserData.dart';
import '../Utils/Permission.dart';
import '../Utils/config.dart';
import 'Components/app_toast.dart';
import 'Components/button_action.dart';
import 'Components/InfoCard.dart';
import 'Components/TextModal.dart';
import 'Components/TopAppBar.dart';
import 'LoadingScreen.dart';
import 'WorkingScreen.dart';

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/pictures/DrawScan-AI.png'), context);
  }

  void _launchCamera() async {
    try {
      final granted = await PermissionHelper.requestCameraPermission();
      if (!granted) {
        showTextModal(
          context,
          "Accès à la caméra refusé",
          "Va dans les paramètres pour autoriser l'application à utiliser la caméra.",
          showConfirmButton: true,
          onConfirm: () async => openAppSettings(),
        );
        return;
      }
      setState(() => _isCameraOpen = true);
    } catch (e) {
      showTextModal(
        context,
        "Erreur caméra",
        "Une erreur s'est produite. Vérifie les paramètres du téléphone.",
        showConfirmButton: true,
        onConfirm: _launchCamera,
      );
    }
  }

  void _quitCamera() {
    setState(() => _isCameraOpen = false);
    controller.stop();
  }

  void _handleBarcode(BarcodeCapture barcodes) {
    if (!mounted) return;

    final value = barcodes.barcodes.firstOrNull?.displayValue;
    if (value == Config.qrCodeStartContent) {
      _startSession();
    }
  }

  void _startSession() async {
    controller.stop();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LoadingScreen(text: "À vos marques, prêts, partez !"),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));
    await ContributorsData.saveContributors(widget.contributors);
    final userId = await UserData.getUserId();

    if (userId == null) {
      log("User ID is null. Cannot start measure.");
      AppToast.showError("Utilisateur introuvable.");
      Navigator.pop(context); // Retour depuis LoadingScreen
      return;
    }

    final result = await NewMeasureController.startMeasure(
      userId,
      contributorsNumber: widget.contributors,
    );

    if (result.hasError) {
      AppToast.showError("Impossible de démarrer la mesure. Veuillez réessayer.");
      Navigator.pop(context);
      return;
    }

    AppToast.showSuccess("Mesure démarrée, c'est parti !");
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WorkingScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    log("Dispose");
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(Config.backgroundColor),
      appBar: _isCameraOpen
          ? null
          : const TopAppBar(
              title: "Scanner",
              showBackButton: true,
              showInfoButton: false,
              showLogoutButton: false,
            ),
      body: Stack(
        children: [
          _buildBody(context),
          if (_isCameraOpen) _buildCameraOverlay() else _buildCameraButton(),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        decoration: const BoxDecoration(color: Colors.white),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: GestureDetector(
                onDoubleTap: _startSession,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  width: MediaQuery.of(context).size.width * 0.45,
                  child: FadeInImage(
                    placeholder: MemoryImage(kTransparentImage),
                    image: const AssetImage('assets/pictures/DrawScan-AI.png'),
                    fit: BoxFit.contain,
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
    );
  }

  Widget _buildCameraButton() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 48.0),
        child: ButtonAction(
          icon: Icons.camera_alt,
          text: "Ouvrir la caméra",
          onPressed: _launchCamera,
        ),
      ),
    );
  }

  Widget _buildCameraOverlay() {
    return Stack(
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
    );
  }
}
