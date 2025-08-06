import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy/view/BottomNavBar/bottom_nav_bar.dart';
import 'package:kealthy/view/Login/login_notifier.dart';
import 'package:kealthy/view/Login/otp_state.dart';
import 'package:kealthy/view/profile%20page/provider.dart';

import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

final otpProvider =
    StateNotifierProvider<OtpNotifier, OtpState>((ref) => OtpNotifier());

// ignore: must_be_immutable
class OTPScreen extends ConsumerStatefulWidget {
  final String verificationId;
  final String phoneNumber;
  bool isTestMode;

  OTPScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    this.isTestMode = false, // 🔹 Default false for real users
  });

  @override
  ConsumerState<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends ConsumerState<OTPScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final String testOtp = "2552"; // 🔹 Fixed OTP for Apple review
  final String testNumber = "8848673425"; // 🔹 Apple test number

  @override
  void initState() {
    super.initState();
    ref.read(otpProvider.notifier).startTimer();

    // 🔹 If Apple is reviewing, auto-fill OTP and login
    if (widget.phoneNumber == testNumber) {
      widget.isTestMode = true; // 🔹 Set test mode to true
      _otpController.text = testOtp;

      // 🔹 Save test mode flag in SharedPreferences
      _setTestModeFlag(true);

      Future.delayed(const Duration(milliseconds: 500), () {
        _verifyOtp();
      });
    } else {
      _setTestModeFlag(false); // 🔹 Ensure test mode is disabled for real users
    }
  }

// 🔹 Function to store test mode flag
  Future<void> _setTestModeFlag(bool isTestMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTestMode', isTestMode);
  }

// 🔹 Function to retrieve test mode flag
  Future<bool> _getTestModeFlag() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isTestMode') ?? false;
  }

  Future<void> _savePhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();

    String cleanedPhoneNumber =
        widget.phoneNumber.replaceAll('+91', '').replaceAll(' ', '');
    await prefs.setString('phoneNumber', cleanedPhoneNumber);
    print('Phone number saved: $cleanedPhoneNumber');

    // API to save phone number in MongoDB
    const String apiUrl = "https://api-jfnhkjk4nq-uc.a.run.app/login";
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': cleanedPhoneNumber}),
      );
      if (response.statusCode == 200) {
        print('Phone number saved to MongoDB');
      } else {
        print('Failed to save phone number: ${response.body}');
      }
    } catch (e) {
      print('Error saving phone number: $e');
    }
  }

  void _verifyOtp() async {
    final enteredOtp = _otpController.text.trim();
    final verificationId = widget.verificationId;

    // 🔹 Retrieve test mode flag dynamically
    bool isTestMode = await _getTestModeFlag();

    if (isTestMode || enteredOtp == testOtp) {
      print('Test Mode Login Successful!');
      await _savePhoneNumber(); // Save test number as login
      await ref.read(loginStatusProvider.notifier).login(widget.phoneNumber);

      await ref.read(profileProvider.notifier).loadProfileData();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BottomNavBar()),
      );
      return;
    }

    // 🔹 Normal OTP verification
    ref.read(otpProvider.notifier).verifyOtp(
        verificationId, enteredOtp, context,
        onSuccess: _savePhoneNumber);

    await ref.read(loginStatusProvider.notifier).login(widget.phoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(otpProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Enter OTP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('OTP sent to ${widget.phoneNumber}'),
            const SizedBox(height: 50),
            Form(
              key: _formKey,
              child: PinCodeTextField(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                controller: _otpController,
                cursorColor: Colors.black,
                appContext: context,
                length: 4,
                onChanged: (value) {},
                onCompleted: (otp) {
                  if (_formKey.currentState?.validate() == true) {
                    _verifyOtp();
                  }
                },
                pinTheme: PinTheme(
                  borderWidth: 2,
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(10),
                  fieldHeight: 50,
                  activeColor: Colors.black,
                  inactiveColor: Colors.grey,
                  selectedColor: Colors.black,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            if (otpState.error != null) ...[
              const SizedBox(height: 10),
              Text(
                otpState.error!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            const SizedBox(height: 20),
            otpState.isLoading
                ? const CupertinoActivityIndicator(
                    color: Color.fromARGB(255, 65, 88, 108),
                  )
                : ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() == true) {
                        _verifyOtp();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 65, 88, 108),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 15.0, horizontal: 30.0),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  ),
            const SizedBox(height: 20),
            otpState.timerValue == 0
                ? TextButton(
                    onPressed: () {
                      ref
                          .read(otpProvider.notifier)
                          .resendOtp(widget.phoneNumber);
                      ref.read(otpProvider.notifier).startTimer();
                    },
                    child: const Text(
                      'Resend',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ),
                  )
                : Text(
                    'Resend OTP in ${otpState.timerValue} seconds',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
