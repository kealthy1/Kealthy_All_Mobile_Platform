import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:http/http.dart' as http;
import 'package:kealthy/view/BottomNavBar/bottom_nav_bar.dart';
import 'package:kealthy/view/Login/otp_screen.dart';
import 'package:kealthy/view/Login/sign_in.dart';
import 'package:kealthy/view/Toast/toast_helper.dart';

final loadingProvider = StateProvider<bool>((ref) => false);
final phoneNumberProvider = StateProvider<String>((ref) => '');

class LoginFields extends ConsumerStatefulWidget {
  const LoginFields({super.key});

  @override
  _LoginFieldsState createState() => _LoginFieldsState();
}

class _LoginFieldsState extends ConsumerState<LoginFields> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(loadingProvider);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Background Image with "Skip" Button on Top Right
              SizedBox(
                height: screenHeight * 0.5,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        "lib/assets/images/IMG_20250128_133645.jpg",
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 50, // Increased to ensure visibility
                      right: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black
                              .withOpacity(0.4), // Better visibility
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextButton(
                          onPressed: () {
                            _showGuestDialog(context);
                          },
                          child: Text(
                            "Skip",
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: screenHeight * 0.05,
                  left: screenWidth * 0.05,
                  right: screenWidth * 0.05,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Phone Number Input
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextFormField(
                          controller: _phoneController,
                          cursorColor: Colors.black,
                          keyboardType: TextInputType.phone,
                          onChanged: (value) {
                            ref.read(phoneNumberProvider.notifier).state =
                                value;
                          }, // Horizontally center
                          textAlignVertical:
                              TextAlignVertical.center, // Vertically center
                          decoration: const InputDecoration(
                            prefixIcon: Icon(
                              CupertinoIcons.phone,
                              color: Colors.black,
                            ),
                            hintText: 'Enter Phone Number',
                            hintStyle: TextStyle(
                              color: Colors.black54,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets
                                .zero, // Remove default padding if desired
                          ),
                          style: const TextStyle(color: Colors.black),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Continue Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  if (_phoneController.text.trim().isEmpty) {
                                    ToastHelper.showErrorToast(
                                        'Please enter your phone number');
                                  } else {
                                    _sendOtp();
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 65, 88, 108),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                vertical: 15.0, horizontal: 30.0),
                          ),
                          child: isLoading
                              ? const CupertinoActivityIndicator(
                                  color: Colors.white)
                              : const Text(
                                  'Continue',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 219, 219, 219),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGuestDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(
            "Continue as Guest?",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black,
            ),
          ),
          content: Text(
            "You won't be able to save preferences or place orders without logging in.",
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
          ),
          actions: [
            // Cancel Button
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text(
                "Cancel",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Continue as Guest Button
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BottomNavBar(),
                  ),
                );
              },
              child: Text(
                "Continue",
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

  // Function to send OTP
  Future<void> _sendOtp() async {
    ref.read(loadingProvider.notifier).state = true;

    final phoneNumber = _phoneController.text.trim();
    const testNumber = '9897969594'; // Apple test number
    const checkUserUrl =
        'https://api-jfnhkjk4nq-uc.a.run.app/checkUserExists?phoneNumber=';
    const otpUrl = 'https://api-jfnhkjk4nq-uc.a.run.app/send-otp';

    try {
      // 🔹 If Apple is testing, bypass OTP API and directly navigate
      if (phoneNumber == testNumber) {
        print('Test Mode Active: Skipping OTP Verification');
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder: (context) => OTPScreen(
              verificationId: 'test_verification_id', // Dummy verification ID
              phoneNumber: phoneNumber,
              isTestMode: true, // Pass a flag to indicate test mode
            ),
          ),
        );
        return;
      }

      // 1. Check if user exists
      final checkUserResponse = await http.get(
        Uri.parse('$checkUserUrl$phoneNumber'),
      );

      if (checkUserResponse.statusCode == 200) {
        final userData = jsonDecode(checkUserResponse.body);

        // We'll treat `userData['success'] && userData['message'] == "User found"`
        // as "existing user"
        final isExistingUser =
            userData['success'] == true && userData['message'] == 'User found';

        // 2. Send OTP (for both existing & new users)
        final otpResponse = await http.post(
          Uri.parse(otpUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'phoneNumber': phoneNumber}),
        );

        if (otpResponse.statusCode == 200) {
          final otpData = jsonDecode(otpResponse.body);
          final verificationId = otpData['verificationId'];
          print('OTP sent successfully! Response: ${otpResponse.body}');

          // 3. Navigate based on user existence
          if (isExistingUser) {
            // Existing user → go to normal OTP screen
            Navigator.pushReplacement(
              context,
              CupertinoPageRoute(
                builder: (context) => OTPScreen(
                  verificationId: verificationId,
                  phoneNumber: phoneNumber,
                ),
              ),
            );
          } else {
            // New user → go to SignUpScreen (or "SignIn" if that’s your naming)
            Navigator.pushReplacement(
              context,
              CupertinoPageRoute(
                builder: (context) => SignUpScreen(
                  phoneNumber: phoneNumber,
                  verificationId: verificationId,
                ),
              ),
            );
          }
        } else {
          print('Failed to send OTP: ${otpResponse.body}');
          _showErrorDialog('Failed to send OTP. Please try again.');
        }
      } else {
        print('Failed to check user: ${checkUserResponse.body}');
        _showErrorDialog('Failed to check user existence. Please try again.');
      }
    } catch (e) {
      print('Error: $e');
      _showErrorDialog('An unexpected error occurred. Please try again.');
    } finally {
      ref.read(loadingProvider.notifier).state = false;
    }
  }

  // Function to show error dialogs
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Error",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.black87, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: GoogleFonts.poppins(color: Colors.blue, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
