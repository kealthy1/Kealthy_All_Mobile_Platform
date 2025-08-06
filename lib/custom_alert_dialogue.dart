import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomAlertDialog {
  static void show({
    required BuildContext context,
    required String title,
    required String message,
    String cancelText = "Cancel",
    String confirmText = "OK",
    VoidCallback? onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          content: Text(
            message,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
          ),
          actions: [
            // Cancel Button
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text(
                cancelText,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Confirm Button
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                if (onConfirm != null) {
                  onConfirm(); // Execute custom function if provided
                }
              },
              child: Text(
                confirmText,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
