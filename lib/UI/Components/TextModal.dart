import 'package:flutter/material.dart';
import '../../Utils/config.dart';
import 'ActionButton.dart';
import 'DiscardButton.dart';

void showTextModal(BuildContext context, String title, String message,
    {bool showConfirmButton = false,
    VoidCallback? onConfirm,
    bool showDiscardButton = false,
    VoidCallback? onDiscard}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(Config.COLOR_APP_BAR),
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  color: Color(Config.COLOR_APP_BAR),
                  fontSize: 16,
                ),
                textAlign: TextAlign.left,
              ),
              if (showConfirmButton || showDiscardButton) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (showDiscardButton)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: DiscardButton(
                            text: "Annuler",
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ),
                    if (showConfirmButton)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: ActionButton(
                            text: "OK",
                            onPressed: () {
                              Navigator.of(context).pop();
                              if (onConfirm != null) {
                                onConfirm();
                              }
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  });
}
