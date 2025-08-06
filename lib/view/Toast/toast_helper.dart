import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class ToastHelper {
  static void showToast({
    required String message,
    ToastGravity gravity = ToastGravity.TOP,
    Color backgroundColor = Colors.black,
    Color textColor = Colors.white,
    double fontSize = 14.0,
  }) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: gravity,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: fontSize,
    );
  }

  static void showSuccessToast(String message) {
    showToast(
      message: message,
      backgroundColor: Colors.green,
    );
  }

  static void showErrorToast(String message) {
    showToast(
      message: message,
      backgroundColor: Colors.black,
    );
  }

  static void showInfoToast(String message) {
    showToast(
      message: message,
      backgroundColor: Colors.blueAccent,
    );
  }

  static void showWarningToast(String message) {
    showToast(
      message: message,
      backgroundColor: Colors.orange,
    );
  }
}
