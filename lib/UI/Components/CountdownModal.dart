import 'dart:async';
import 'package:flutter/material.dart';
import '../../Data/EventData.dart';
import '../../Utils/config.dart';

void showCountdownModal(BuildContext context, String title, {required DateTime startDate}) async {
  String? eventName = await EventData.getEventName();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      isDismissible: false, // Prevent dismissing the modal by tapping outside
      enableDrag: false, // Disable swipe-to-dismiss
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      builder: (BuildContext context) {
        return CountdownModalContent(
          title: title,
          startDate: startDate,
          eventName: eventName,
        );
      },
    );
  });
}

class CountdownModalContent extends StatefulWidget {
  final String title;
  final DateTime startDate;
  final String? eventName;

  const CountdownModalContent({
    required this.title,
    required this.startDate,
    this.eventName,
    Key? key,
  }) : super(key: key);

  @override
  _CountdownModalContentState createState() => _CountdownModalContentState();
}

class _CountdownModalContentState extends State<CountdownModalContent> {
  late Timer _timer;
  String _countdown = "";

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _updateCountdown();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _updateCountdown();
      if (DateTime.now().isAfter(widget.startDate)) {
        timer.cancel();
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    });
  }

  void _updateCountdown() {
    Duration difference = widget.startDate.difference(DateTime.now());
    setState(() {
      _countdown = "${difference.inDays} J : "
          "${difference.inHours.remainder(24).toString().padLeft(2, '0')} H : "
          "${difference.inMinutes.remainder(60).toString().padLeft(2, '0')} M : "
          "${difference.inSeconds.remainder(60).toString().padLeft(2, '0')} S";
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              color: Color(Config.COLOR_APP_BAR),
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            "L'évènement \"${widget.eventName}\" n'a pas encore démarré."
            "Pas de stress, on compte les secondes ensemble jusqu'au top départ ! ",
            style: const TextStyle(
              color: Color(Config.COLOR_APP_BAR),
              fontSize: 16,
            ),
            textAlign: TextAlign.left,
          ),
          const SizedBox(height: 32),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(Config.COLOR_APP_BAR).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              _countdown,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(Config.COLOR_APP_BAR),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
