import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AppToast {
  static void showSuccess(String message) {
    _show(message, backgroundColor: Colors.green);
  }

  static void showError(String message) {
    _show(message, backgroundColor: Colors.red);
  }

  static void showInfo(String message) {
    _show(message, backgroundColor: Colors.blue, toastLength: Toast.LENGTH_LONG);
  }

  static void _show(String message, {required Color backgroundColor, Toast toastLength = Toast.LENGTH_SHORT}) {
    Fluttertoast.cancel(); // reset last toast

    Fluttertoast.showToast(
      msg: message,
      toastLength: toastLength,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 2,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      fontSize: 16.0, // This disables OS scaling for the toast text
    );
  }
}
