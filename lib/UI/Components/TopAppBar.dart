import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async'; // Ensure this import is present for Timer
import '../../Utils/config.dart';
import '../ShareLog.dart';
import '../LoginScreen.dart';
import '../InfoScreen.dart';
import '../../Data/DataUtils.dart';
import '../../Data/MeasureData.dart';
import '../../API/NewMeasureController.dart';

class TopAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final bool showInfoButton;
  final bool isRecording; // New parameter to indicate recording status

  const TopAppBar({
    super.key,
    required this.title,
    this.showInfoButton = true,
    this.isRecording = false, // Default to false,
  });

  @override
  _TopAppBarState createState() => _TopAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(60.0); // Reduced height for a compact look
}

class _TopAppBarState extends State<TopAppBar> {
  int _infoButtonClickCount = 0;
  bool _showShareButton = false;
  bool _isDotExpanded = true; // State to toggle dot size
  Timer? _dotAnimationTimer; // Timer for animation

  @override
  void initState() {
    super.initState();
    if (widget.isRecording) {
      _startDotAnimation(); // Start the animation when recording
    }
  }

  void _startDotAnimation() {
    _dotAnimationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _isDotExpanded = !_isDotExpanded; // Toggle the opacity state
      });
    });
  }

  @override
  void didUpdateWidget(covariant TopAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording && _dotAnimationTimer == null) {
      _startDotAnimation(); // Restart animation if recording starts
    } else if (!widget.isRecording && _dotAnimationTimer != null) {
      _dotAnimationTimer?.cancel();
      _dotAnimationTimer = null;
      setState(() {
        _isDotExpanded = true; // Reset opacity when not recording
      });
    }
  }

  @override
  void dispose() {
    _dotAnimationTimer?.cancel(); // Cancel the timer when widget is disposed
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
      onTap: _incrementInfoButtonClickCount, // Increment count on app bar tap
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.zero, // Removed border radius
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0), // Adjusted padding
            child: Row(
              children: [
                if (widget.isRecording) ...[
                  AnimatedOpacity(
                    duration: const Duration(seconds: 1),
                    opacity: _isDotExpanded ? 1.0 : 0.0,
                    child: Container(
                      width: 12.0,
                      height: 12.0,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Session en cours...",
                    style: TextStyle(
                      color: Color(Config.COLOR_APP_BAR),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ] else ...[
                  Image.asset(
                    'assets/pictures/LogoText.png', // Display the logo on the left
                    height: 28,
                  ),
                ],
                const Spacer(),
                if (_showShareButton)
                  IconButton(
                    icon: const Icon(Icons.developer_mode, color: Color(Config.COLOR_APP_BAR)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ShareLog()),
                      );
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.public, color: Color(Config.COLOR_APP_BAR)),
                  onPressed: () async {
                    final Uri url = Uri.parse('https://larouequimarche.ch/');
                    await launch(url.toString(), forceSafariVC: false, forceWebView: false);
                  },
                ),
                if (widget.showInfoButton)
                  IconButton(
                    icon: const Icon(Icons.info_outlined, color: Color(Config.COLOR_APP_BAR)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const InfoScreen()),
                      );
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.logout, color: Color(Config.COLOR_APP_BAR)),
                  onPressed: () async {
                    if (await MeasureData.isMeasureOngoing()) {
                      String? measureId = await MeasureData.getMeasureId();
                      final stopResult = await NewMeasureController.stopMeasure();
                      if (stopResult.error != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Failed to stop measure (ID: $measureId): ${stopResult.error}")),
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
                        const SnackBar(content: Text("Failed to clear user data")),
                      );
                    }
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
