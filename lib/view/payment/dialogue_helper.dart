import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

import '../BottomNavBar/bottom_nav_bar.dart'; // Adjust the path to your BottomNavBar

final countdownProvider = StateProvider<int>((ref) => 5);

class PaymentDialogHelper {
  static void showPaymentSuccessDialog(BuildContext context, WidgetRef ref) {
    ref.read(countdownProvider.notifier).state = 5; // Reset countdown

    Timer? timer; // Declare timer to cancel it later

    showDialog(
      barrierColor: Colors.white,
      context: context,
      barrierDismissible: false, // Prevents user from closing manually
      builder: (context) {
        timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          final currentCount = ref.read(countdownProvider.notifier).state;
          if (currentCount <= 1) {
            timer.cancel(); // Stop the timer
            Navigator.of(context).pop(); // Close the dialog

            // Navigate to BottomNavBar
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const BottomNavBar()),
              (route) => false,
            );
          } else {
            ref.read(countdownProvider.notifier).state = currentCount - 1;
          }
        });

        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            content: Consumer(
              builder: (context, ref, child) {
                final countdown = ref.watch(countdownProvider);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Lottie Animation
                    SizedBox(
                      height: 150,
                      width: 150,
                      child: Lottie.asset(
                        'lib/assets/animations/Animation - 1731992471934.json',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Order placed!",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      "Redirecting in $countdown seconds...",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    ).then((_) {
      // Ensure the timer is canceled when dialog is dismissed early
      timer?.cancel();
    });
  }

  /// Shows a dialog indicating the payment/order has failed.
  static void showPaymentFailureDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.white, // Prevents tapping outside to dismiss
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 150,
                width: 150,
                child: Lottie.asset(
                  'lib/assets/animations/Animation - 1731995566846.json',
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Payment Failed!",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 65, 88, 108),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 65, 88, 108),
                  padding:
                      const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BottomNavBar(),
                    ),
                    (Route<dynamic> route) => false,
                  );
                },
                child: Text(
                  "Close",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void showCustomDialog(BuildContext context,
      {required String title, required String description}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.of(context).pop(),
          )
        ],
      ),
    );
  }
}
