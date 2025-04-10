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
    this.icon = Icons.close,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
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
              style: const TextStyle(color: Color(Config.COLOR_APP_BAR), fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
