import 'package:flutter/material.dart';

import 'package:lrqm/utils/config.dart';

class ButtonAction extends StatelessWidget {
  final IconData? icon;
  final String text;
  final VoidCallback onPressed;

  const ButtonAction({
    super.key,
    this.icon = Icons.check,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(Config.accentColor),
          elevation: 0,
          shadowColor: Colors.black.withOpacity(0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(
                icon,
                color: const Color(Config.backgroundColor),
                size: 22,
              ),
            if (icon != null) const SizedBox(width: 10),
            MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(Config.backgroundColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
