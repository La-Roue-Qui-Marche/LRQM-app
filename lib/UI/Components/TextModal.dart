import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../Utils/config.dart';
import 'button_action.dart';
import 'button_discard.dart';

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
  DateTime? countdownStartDate,
  String? externalUrl,
  String? externalUrlLabel,
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
            child: _TextModalContent(
              title: title,
              message: message,
              showConfirmButton: showConfirmButton,
              onConfirm: onConfirm,
              showDiscardButton: showDiscardButton,
              onDiscard: onDiscard,
              dropdownItems: dropdownItems,
              onDropdownChanged: onDropdownChanged,
              selectedDropdownValue: selectedDropdownValue,
              countdownStartDate: countdownStartDate,
              externalUrl: externalUrl,
              externalUrlLabel: externalUrlLabel,
            ),
          ),
        );
      },
    );
  });
}

class _TextModalContent extends StatefulWidget {
  final String title;
  final String message;
  final bool showConfirmButton;
  final VoidCallback? onConfirm;
  final bool showDiscardButton;
  final VoidCallback? onDiscard;
  final List<dynamic>? dropdownItems;
  final Function(dynamic)? onDropdownChanged;
  final dynamic selectedDropdownValue;
  final DateTime? countdownStartDate;
  final String? externalUrl;
  final String? externalUrlLabel;

  const _TextModalContent({
    required this.title,
    required this.message,
    this.showConfirmButton = false,
    this.onConfirm,
    this.showDiscardButton = false,
    this.onDiscard,
    this.dropdownItems,
    this.onDropdownChanged,
    this.selectedDropdownValue,
    this.countdownStartDate,
    this.externalUrl,
    this.externalUrlLabel,
    super.key,
  });

  @override
  _TextModalContentState createState() => _TextModalContentState();
}

class _TextModalContentState extends State<_TextModalContent> {
  Timer? _timer; // Initialize _timer to null
  String _countdown = "";

  @override
  void initState() {
    super.initState();
    if (widget.countdownStartDate != null) {
      _startCountdown();
    }
  }

  void _startCountdown() {
    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _updateCountdown();
      if (DateTime.now().isAfter(widget.countdownStartDate!)) {
        timer.cancel();
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  void _updateCountdown() {
    Duration difference = widget.countdownStartDate!.difference(DateTime.now());
    setState(() {
      _countdown = "${difference.inDays} J : "
          "${difference.inHours.remainder(24).toString().padLeft(2, '0')} H : "
          "${difference.inMinutes.remainder(60).toString().padLeft(2, '0')} M : "
          "${difference.inSeconds.remainder(60).toString().padLeft(2, '0')} S";
    });
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Impossible d\'ouvrir $url');
    }
  }

  @override
  void dispose() {
    if (_timer != null) {
      _timer!.cancel(); // Check if _timer is not null before canceling
    }
    super.dispose();
  }

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
        if (widget.countdownStartDate == null) ...[
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
                  if (widget.onDropdownChanged != null) {
                    widget.onDropdownChanged!(newValue);
                  }
                },
              ),
            ),
        ] else ...[
          Text(
            widget.message,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(Config.primaryColor).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              _countdown,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(Config.primaryColor),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        if (widget.externalUrl != null) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: InkWell(
              onTap: () => _launchUrl(widget.externalUrl!),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start, // Align left
                  children: [
                    const Icon(Icons.open_in_new, color: Color(Config.primaryColor)),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        widget.externalUrlLabel ?? "S'inscrire sur le site web",
                        style: const TextStyle(
                          color: Color(Config.primaryColor),
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
