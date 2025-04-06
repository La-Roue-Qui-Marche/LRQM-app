import 'package:flutter/material.dart';
import '../../Utils/config.dart';

class DiscardButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;

  const DiscardButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon = Icons.close, // Default icon set to close
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, // Full width
      height: 48.0, // Set height to match the "Oui" button
      decoration: BoxDecoration(
        border: Border.all(color: const Color(Config.COLOR_APP_BAR), width: 1.0), // Outline with COLOR_APP_BAR
        borderRadius: BorderRadius.circular(8.0), // Same radius as ActionButton
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white, // Center transparent
          shadowColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, color: const Color(Config.COLOR_APP_BAR), size: 18),
            if (icon != null) const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(color: Color(Config.COLOR_APP_BAR), fontSize: 16), // Text color in COLOR_APP_BAR
            ),
          ],
        ),
      ),
    );
  }
}
