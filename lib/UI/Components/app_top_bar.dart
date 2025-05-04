// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:lrqm/ui/log_screen.dart';
import 'package:lrqm/geo/geolocation.dart';
import 'package:lrqm/utils/config.dart';

class AppTopBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final bool showInfoButton;
  final bool showBackButton;
  final bool showLogoutButton;
  final bool showCloseButton;
  final VoidCallback? onBack;
  final VoidCallback? onClose;
  final VoidCallback? onInfo;
  final VoidCallback? onLogout;
  final GeolocationController? geolocation;

  const AppTopBar({
    super.key,
    required this.title,
    this.showInfoButton = true,
    this.showBackButton = false,
    this.showLogoutButton = true,
    this.showCloseButton = false,
    this.onBack,
    this.onClose,
    this.onInfo,
    this.onLogout,
    this.geolocation,
  });

  @override
  // ignore: library_private_types_in_public_api
  _AppTopBarState createState() => _AppTopBarState();

  @override
  Size get preferredSize => const Size.fromHeight(50.0);
}

class _AppTopBarState extends State<AppTopBar> {
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
    return Stack(
      children: [
        GestureDetector(
          onTap: _incrementInfoButtonClickCount,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: const Color(Config.backgroundColor),
                  width: 1.0,
                ),
              ),
            ),
            child: SafeArea(
              top: true,
              bottom: false,
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
                              height: 22,
                              fit: BoxFit.contain,
                            ),
                    ),

                    // Center: Title
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60),
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
                              padding: const EdgeInsets.only(right: 4.0),
                              child: _buildIconButton(
                                onTap: widget.onInfo ?? () {},
                                icon: 'assets/icons/info.svg',
                              ),
                            ),
                          if (_showShareButton)
                            _buildIconButton(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const LogScreen()));
                              },
                              iconData: Icons.developer_mode,
                            ),
                          if (widget.showLogoutButton)
                            _buildIconButton(
                              onTap: widget.onLogout ?? () {},
                              icon: 'assets/icons/sign-out.svg',
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
        ),
      ],
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
                  size: 26,
                  color: Colors.black87,
                ),
        ),
      ),
    );
  }
}
