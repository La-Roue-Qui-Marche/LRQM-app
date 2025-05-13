import 'package:flutter/material.dart';

import 'package:lrqm/utils/config.dart';

class ButtonDiscard extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  const ButtonDiscard({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon = Icons.close,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          shape: const RoundedRectangleBorder(),
          padding: const EdgeInsets.symmetric(vertical: 14.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(
                icon,
                color: const Color(Config.primaryColor),
                size: 20,
              ),
            if (icon != null) const SizedBox(width: 8),
            MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
