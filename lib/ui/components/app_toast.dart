import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AppToast with WidgetsBindingObserver {
  static final AppToast _instance = AppToast._internal();
  factory AppToast() => _instance;

  AppToast._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  static String? _pendingMessage;
  static Color _pendingColor = Colors.black;
  static Toast _pendingLength = Toast.LENGTH_SHORT;
  static bool _isAppInForeground = true;

  /// Show a green success toast
  static void showSuccess(String message) {
    _show(message, backgroundColor: Colors.green);
  }

  /// Show a red error toast
  static void showError(String message) {
    _show(message, backgroundColor: Colors.red, toastLength: Toast.LENGTH_LONG);
  }

  /// Show a blue informational toast (longer)
  static void showInfo(String message) {
    _show(message, backgroundColor: Colors.blue, toastLength: Toast.LENGTH_LONG);
  }

  static void _show(
    String message, {
    required Color backgroundColor,
    Toast toastLength = Toast.LENGTH_SHORT,
  }) {
    _pendingMessage = message;
    _pendingColor = backgroundColor;
    _pendingLength = toastLength;

    if (_isAppInForeground) {
      _showPendingToast();
    }
  }

  static void _showPendingToast() {
    if (_pendingMessage != null) {
      Fluttertoast.cancel();
      Fluttertoast.showToast(
        msg: _pendingMessage!,
        toastLength: _pendingLength,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: _pendingLength == Toast.LENGTH_LONG ? 5 : 2,
        backgroundColor: _pendingColor,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      _pendingMessage = null; // Ensure it's only shown once
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppInForeground = state == AppLifecycleState.resumed;

    if (_isAppInForeground && _pendingMessage != null) {
      Future.delayed(const Duration(milliseconds: 300), _showPendingToast);
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
