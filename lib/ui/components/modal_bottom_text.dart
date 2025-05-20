import 'package:flutter/material.dart';

import 'package:lrqm/ui/components/button_action.dart';
import 'package:lrqm/ui/components/button_discard.dart';
import 'package:lrqm/utils/config.dart';

void showModalBottomText(
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
          child: MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: _ModalBottomTextContent(
                title: title,
                message: message,
                showConfirmButton: showConfirmButton,
                onConfirm: onConfirm,
                showDiscardButton: showDiscardButton,
                onDiscard: onDiscard,
                dropdownItems: dropdownItems,
                onDropdownChanged: onDropdownChanged,
                selectedDropdownValue: selectedDropdownValue,
              ),
            ),
          ),
        );
      },
    );
  });
}

class _ModalBottomTextContent extends StatefulWidget {
  final String title;
  final String message;
  final bool showConfirmButton;
  final VoidCallback? onConfirm;
  final bool showDiscardButton;
  final VoidCallback? onDiscard;
  final List<dynamic>? dropdownItems;
  final Function(dynamic)? onDropdownChanged;
  final dynamic selectedDropdownValue;

  const _ModalBottomTextContent({
    required this.title,
    required this.message,
    this.showConfirmButton = false,
    this.onConfirm,
    this.showDiscardButton = false,
    this.onDiscard,
    this.dropdownItems,
    this.onDropdownChanged,
    this.selectedDropdownValue,
  });

  @override
  _ModalBottomTextContentState createState() => _ModalBottomTextContentState();
}

class _ModalBottomTextContentState extends State<_ModalBottomTextContent> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 24),
        if (widget.dropdownItems == null)
          Text(
            widget.message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
            textAlign: TextAlign.left,
          ),
        if (widget.dropdownItems != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: DropdownButtonFormField<dynamic>(
              value: widget.selectedDropdownValue,
              hint: Text(
                widget.message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.left,
              ),
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(Config.primaryColor),
              ),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(Config.primaryColor),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(Config.primaryColor),
                    width: 2,
                  ),
                ),
              ),
              dropdownColor: Colors.white,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
              items: widget.dropdownItems!.map((item) {
                return DropdownMenuItem(
                  value: item,
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
                    child: Text(
                      item.toString(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (newValue) {
                if (widget.onDropdownChanged != null) {
                  widget.onDropdownChanged!(newValue);
                }
              },
            ),
          ),
        const SizedBox(height: 24),
        if (widget.showConfirmButton || widget.showDiscardButton)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (widget.showDiscardButton)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.0),
                    child: ButtonDiscard(
                      text: "Annuler",
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (widget.onDiscard != null) {
                          widget.onDiscard!();
                        }
                      },
                    ),
                  ),
                ),
              if (widget.showConfirmButton)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 0.0),
                    child: ButtonAction(
                      text: "OK",
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (widget.onConfirm != null) {
                          widget.onConfirm!();
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
