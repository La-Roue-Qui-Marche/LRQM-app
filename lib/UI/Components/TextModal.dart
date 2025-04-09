import 'package:flutter/material.dart';
import '../../Utils/config.dart';
import 'ActionButton.dart';
import 'DiscardButton.dart';

void showTextModal(
  BuildContext context,
  String title,
  String message, {
  bool showConfirmButton = false,
  VoidCallback? onConfirm,
  bool showDiscardButton = false,
  VoidCallback? onDiscard,
  List<dynamic>? dropdownItems,
  Function(dynamic)? onDropdownChanged,
  dynamic selectedDropdownValue,
}) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          top: false,
          bottom: true,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(Config.COLOR_APP_BAR),
                  ),
                  textAlign: TextAlign.left, // Changed from TextAlign.center to TextAlign.left
                ),
                const SizedBox(height: 16),
                if (dropdownItems == null) ...[
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.left, // Changed from TextAlign.center to TextAlign.left
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 0),
                    child: DropdownButtonFormField<dynamic>(
                      value: selectedDropdownValue,
                      hint: Text(
                        message,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.left, // Added textAlign property
                      ),
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Color(Config.COLOR_APP_BAR),
                      ),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(Config.COLOR_APP_BAR),
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(Config.COLOR_APP_BAR),
                            width: 2,
                          ),
                        ),
                      ),
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      items: dropdownItems.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(
                            item.toString(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (onDropdownChanged != null) {
                          onDropdownChanged(newValue);
                        }
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                if (showConfirmButton || showDiscardButton)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (showDiscardButton)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0.0),
                            child: DiscardButton(
                              text: "Annuler",
                              onPressed: () {
                                Navigator.of(context).pop();
                                if (onDiscard != null) {
                                  onDiscard();
                                }
                              },
                            ),
                          ),
                        ),
                      if (showConfirmButton)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 0.0),
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
            ),
          ),
        );
      },
    );
  });
}
