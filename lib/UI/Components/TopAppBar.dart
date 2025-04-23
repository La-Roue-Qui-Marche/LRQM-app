// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  final bool showBackButton;
  final bool showLogoutButton;
  final bool showCloseButton; // <-- New parameter
  final VoidCallback? onBack;
  final VoidCallback? onClose; // <-- New parameter

  const TopAppBar({
    super.key,
    required this.title,
    this.showInfoButton = true,
    this.showBackButton = false,
    this.showLogoutButton = true,
    this.showCloseButton = false, // <-- New parameter
    this.onBack,
    this.onClose, // <-- New parameter
  });

  @override
  // ignore: library_private_types_in_public_api
  _TopAppBarState createState() => _TopAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(50.0);
}

class _TopAppBarState extends State<TopAppBar> {
  int _infoButtonClickCount = 0;
  bool _showShareButton = false;

  void _incrementInfoButtonClickCount() {
    setState(() {
      _infoButtonClickCount++;
      if (_infoButtonClickCount >= 5) {
        _showShareButton = true;
      }
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
              blurRadius: 4,
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Left side: Back button OR Logo
                Align(
                  alignment: Alignment.centerLeft,
                  child: widget.showBackButton
                      ? _buildIconButton(
                          onTap: () {
                            if (widget.onBack != null) {
                              widget.onBack!();
                            } else {
                              Navigator.of(context).pop();
                            }
                          },
                          icon: 'assets/icons/angle-left.svg',
                        )
                      : Image.asset(
                          'assets/pictures/LogoText.png',
                          height: 26,
                          fit: BoxFit.contain,
                        ),
                ),

                // Center: Title
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 60), // Added padding to avoid overlap
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                // Right side: Info + Share + Logout + Close
                Align(
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.showInfoButton)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0), // 👈 Added space after info button
                          child: _buildIconButton(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const InfoScreen()));
                            },
                            iconData: Icons.info_outline, // changed to Material icon
                          ),
                        ),
                      if (_showShareButton)
                        _buildIconButton(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ShareLog()));
                          },
                          iconData: Icons.developer_mode,
                        ),
                      if (widget.showLogoutButton)
                        _buildIconButton(
                          onTap: () => _showLogoutConfirmation(context),
                          iconData: Icons.logout, // changed to Material icon
                        ),
                      if (widget.showCloseButton)
                        _buildIconButton(
                          onTap: () {
                            if (widget.onClose != null) {
                              widget.onClose!();
                            }
                          },
                          iconData: Icons.close,
                        ),
                    ],
                  ),
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
                  // ignore: deprecated_member_use
                  color: Colors.black87,
                )
              : Icon(
                  iconData,
                  size: 26, // increased from 22 to 26
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
    );
  }
}
