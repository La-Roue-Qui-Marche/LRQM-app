import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_svg/flutter_svg.dart';
import '../../Utils/config.dart';
import '../ShareLog.dart';
import '../LoginScreen.dart';
import '../InfoScreen.dart';
import '../../Data/DataUtils.dart';
import '../../Data/MeasureData.dart';
import '../../API/NewMeasureController.dart';
import 'TextModal.dart';

class TopAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final bool showInfoButton;
  final bool isRecording;
  final bool showBackButton; // Add showBackButton argument

  const TopAppBar({
    super.key,
    required this.title,
    this.showInfoButton = true,
    this.isRecording = false,
    this.showBackButton = false, // Default to false
  });

  @override
  _TopAppBarState createState() => _TopAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(60.0);
}

class _TopAppBarState extends State<TopAppBar> {
  int _infoButtonClickCount = 0;
  bool _showShareButton = false;
  bool _isDotExpanded = true;
  Timer? _dotAnimationTimer;

  @override
  void initState() {
    super.initState();
    if (widget.isRecording) {
      _startDotAnimation();
    }
  }

  void _startDotAnimation() {
    _dotAnimationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _isDotExpanded = !_isDotExpanded;
      });
    });
  }

  @override
  void didUpdateWidget(covariant TopAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && _dotAnimationTimer == null) {
      _startDotAnimation();
    } else if (!widget.isRecording && _dotAnimationTimer != null) {
      _dotAnimationTimer?.cancel();
      _dotAnimationTimer = null;
      setState(() {
        _isDotExpanded = true;
      });
    }
  }

  @override
  void dispose() {
    _dotAnimationTimer?.cancel();
    super.dispose();
  }

  void _incrementInfoButtonClickCount() {
    setState(() {
      _infoButtonClickCount++;
      if (_infoButtonClickCount >= 5) {
        _showShareButton = true;
      }
    });
  }

  void _resetInfoButtonClickCount() {
    setState(() {
      _infoButtonClickCount = 0;
      _showShareButton = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _incrementInfoButtonClickCount,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          top: true,
          bottom: false,
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                if (widget.showBackButton) // Conditionally show the back button
                  _buildIconButton(
                    onTap: () {
                      Navigator.of(context).pop(); // Navigate back
                    },
                    icon: 'assets/icons/angle-left.svg', // Back button icon
                  ),
                if (widget.showBackButton) const SizedBox(width: 8),
                if (widget.showInfoButton) // Conditionally show the info button
                  _buildIconButton(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const InfoScreen()));
                    },
                    icon: 'assets/icons/info.svg', // Info button icon
                  ),
                if (widget.showInfoButton) const SizedBox(width: 8),
                Expanded(
                  child: Center(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (_showShareButton)
                  _buildIconButton(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => ShareLog()));
                    },
                    iconData: Icons.developer_mode, // Native Flutter icon
                  ),
                if (_showShareButton) const SizedBox(width: 8),
                _buildIconButton(
                  onTap: () {
                    _showLogoutConfirmation(context);
                  },
                  icon: 'assets/icons/sign-out.svg',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required VoidCallback onTap,
    String? icon,
    IconData? iconData,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: icon != null
              ? SvgPicture.asset(
                  icon,
                  width: 22,
                  height: 22,
                  color: Colors.black87,
                )
              : Icon(
                  iconData,
                  size: 22,
                  color: Colors.black87,
                ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showTextModal(
      context,
      'Confirmation',
      'Es-tu sûr de vouloir te déconnecter ?\n\n'
          'Cela supprimera toutes les données locales et arrêtera toute mesure en cours.',
      showConfirmButton: true,
      onConfirm: () async {
        if (await MeasureData.isMeasureOngoing()) {
          String? measureId = await MeasureData.getMeasureId();
          final stopResult = await NewMeasureController.stopMeasure();
          if (stopResult.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Échec de l'arrêt de la mesure (ID: $measureId): ${stopResult.error}")),
            );
            return;
          }
        }

        final cleared = await DataUtils.deleteAllData();
        if (cleared) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Login()),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Échec de la suppression des données utilisateur")),
          );
        }
      },
      showDiscardButton: true,
      onDiscard: () {
        Navigator.of(context).pop();
      },
    );
  }
}
