import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AppToast with WidgetsBindingObserver {
  static final AppToast _instance = AppToast._internal();

  factory AppToast() => _instance;

  AppToast._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  static String? _lastMessage;
  static Color? _lastBackgroundColor;
  static Toast? _lastToastLength;

  /// Show a green success toast
  static void showSuccess(String message) {
    _show(message, backgroundColor: Colors.green);
  }

  /// Show a red error toast
  static void showError(String message) {
    _show(message, backgroundColor: Colors.red);
  }

  /// Show a blue informational toast (longer)
  static void showInfo(String message) {
    _show(message, backgroundColor: Colors.blue, toastLength: Toast.LENGTH_LONG);
  }

  /// Internal toast logic
  static void _show(
    String message, {
    required Color backgroundColor,
    Toast toastLength = Toast.LENGTH_SHORT,
  }) {
    // Cancel any existing toast
    Fluttertoast.cancel();

    // Save details to show later if needed
    _lastMessage = message;
    _lastBackgroundColor = backgroundColor;
    _lastToastLength = toastLength;

    // Show the toast
    Fluttertoast.showToast(
      msg: message,
      toastLength: toastLength,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: toastLength == Toast.LENGTH_LONG ? 5 : 2,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  /// Re-show the last toast (if any)
  static void showLastToast() {
    if (_lastMessage != null && _lastBackgroundColor != null && _lastToastLength != null) {
      _show(
        _lastMessage!,
        backgroundColor: _lastBackgroundColor!,
        toastLength: _lastToastLength!,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 500), () {
        // Give time for UI to settle before showing toast
        showLastToast();
      });
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
