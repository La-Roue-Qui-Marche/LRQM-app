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

  const TopAppBar({
    super.key,
    required this.title,
    this.showInfoButton = true,
    this.isRecording = false, // Default to false,
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
          borderRadius: BorderRadius.zero,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
            child: Row(
              children: [
                if (widget.showInfoButton)
                  IconButton(
                    icon: SvgPicture.asset(
                      'assets/icons/info.svg',
                      color: Colors.black87,
                      width: 20,
                      height: 20,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const InfoScreen()),
                      );
                    },
                  ),
                const Spacer(),
                const Text(
                  "Accueil",
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    overflow: TextOverflow.ellipsis,
                  ),
                  maxLines: 1,
                ),
                const Spacer(),
                if (_showShareButton)
                  IconButton(
                    icon: const Icon(
                      Icons.developer_mode,
                      color: Colors.black87,
                      size: 20,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ShareLog()),
                      );
                    },
                  ),
                IconButton(
                  icon: SvgPicture.asset(
                    'assets/icons/sign-out.svg',
                    color: Colors.black87,
                    width: 20,
                    height: 20,
                  ),
                  onPressed: () async {
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
                              SnackBar(
                                  content: Text("Échec de l'arrêt de la mesure (ID: $measureId): ${stopResult.error}")),
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
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
