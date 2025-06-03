import 'dart:async';
import 'package:flutter/material.dart';

import 'package:lrqm/utils/config.dart';
import 'package:lrqm/ui/components/app_toast.dart';

class LoadingScreen extends StatefulWidget {
  final String? text;
  final Duration? timeout;
  final VoidCallback? onTimeout;
  final String? timeoutMessage;

  const LoadingScreen({
    super.key,
    this.text,
    this.timeout,
    this.onTimeout,
    this.timeoutMessage,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _setupTimeout();
  }

  void _setupTimeout() {
    if (widget.timeout != null && widget.onTimeout != null) {
      _timeoutTimer = Timer(widget.timeout!, () {
        if (mounted) {
          if (widget.timeoutMessage != null) {
            AppToast.showError(widget.timeoutMessage!);
          } else {
            AppToast.showError("Temps de chargement dépassé. Veuillez réessayer.");
          }
          widget.onTimeout!();
        }
      });
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(Config.backgroundColor),
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: Stack(
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/pictures/LogoSimpleAnimated.gif',
                      width: 48.0,
                    ),
                    if (widget.text != null) ...[
                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Text(
                          widget.text!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(Config.primaryColor),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
