// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:transparent_image/transparent_image.dart';

import 'package:lrqm/api/measure_controller.dart';
import 'package:lrqm/data/contributors_data.dart';
import 'package:lrqm/data/user_data.dart';
import 'package:lrqm/utils/permission_helper.dart';
import 'package:lrqm/utils/config.dart';
import 'package:lrqm/ui/components/app_toast.dart';
import 'package:lrqm/ui/components/button_action.dart';
import 'package:lrqm/ui/components/card_info.dart';
import 'package:lrqm/ui/components/modal_bottom_text.dart';
import 'package:lrqm/ui/components/app_top_bar.dart';
import 'package:lrqm/ui/loading_screen.dart';
import 'package:lrqm/ui/working_screen.dart';

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
  bool _isLoading = false; // Add state variable for loading

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/pictures/DrawScan-AI.png'), context);
  }

  void _launchCamera() async {
    try {
      final granted = await PermissionHelper.requestCameraPermission();
      if (!granted) {
        showModalBottomText(
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
      showModalBottomText(
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

    setState(() => _isLoading = true);

    try {
      await Future.delayed(const Duration(seconds: 1));
      await ContributorsData.saveContributors(widget.contributors);
      final userId = await UserData.getUserId();

      if (userId == null) {
        log("User ID is null. Cannot start measure.");
        AppToast.showError("Utilisateur introuvable.");
        setState(() => _isLoading = false);
        return;
      }

      final result = await MeasureController.startMeasure(
        userId,
        contributorsNumber: widget.contributors,
      );

      if (result.hasError) {
        AppToast.showError("Impossible de démarrer la mesure. Veuillez réessayer.");
        setState(() => _isLoading = false);
        return;
      }

      AppToast.showSuccess("Mesure démarrée, c'est parti !");
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WorkingScreen()),
        (route) => false,
      );
    } catch (e) {
      log("Error starting session: $e");
      AppToast.showError("Une erreur est survenue. Veuillez réessayer.");
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    log("Dispose");
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
      child: Scaffold(
        backgroundColor: const Color(Config.backgroundColor),
        appBar: _isCameraOpen || _isLoading
            ? null
            : const AppTopBar(
                title: "Scanner",
                showBackButton: true,
                showInfoButton: false,
                showLogoutButton: false,
              ),
        body: Stack(
          children: [
            _buildBody(context),
            if (_isCameraOpen) _buildCameraOverlay() else _buildCameraButton(),
            // Add loading screen overlay
            if (_isLoading)
              LoadingScreen(
                text: "À vos marques, prêts, partez !",
                timeout: const Duration(seconds: 10),
                onTimeout: () {
                  setState(() => _isLoading = false);
                },
                timeoutMessage: "Temps de chargement dépassé. Veuillez réessayer.",
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(top: 0),
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
                  width: MediaQuery.of(context).size.width * 0.55,
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: FadeInImage(
                    placeholder: MemoryImage(kTransparentImage),
                    image: const AssetImage('assets/pictures/DrawScan-AI.png'),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const CardInfo(
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
