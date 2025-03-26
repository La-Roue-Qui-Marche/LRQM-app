import 'package:flutter/material.dart';
import '../Utils/config.dart';

class LoadingScreen extends StatelessWidget {
  final String? text;

  const LoadingScreen({super.key, this.text});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(Config.COLOR_BACKGROUND), // Set background color to light grey
      body: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/pictures/LogoSimpleAnimated.gif',
                    width: 60.0, // Set width to 50px
                  ),
                  if (text != null) ...[
                    const SizedBox(height: 32),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0), // Add padding
                      child: Text(
                        text!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(Config.COLOR_APP_BAR),
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
    );
  }
}
