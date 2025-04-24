import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AppToast {
  static void showSuccess(String message) {
    _show(message, backgroundColor: Colors.green);
  }

  static void showError(String message) {
    _show(message, backgroundColor: Colors.red);
  }

  static void _show(String message, {required Color backgroundColor}) {
    Fluttertoast.cancel(); // reset last toast

    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 2,
      backgroundColor: backgroundColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
