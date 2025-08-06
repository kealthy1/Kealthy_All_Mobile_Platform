import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:kealthy/view/BottomNavBar/bottom_nav_bar.dart';
import 'package:kealthy/view/Login/otp_state.dart';
import 'package:kealthy/view/Login/signup_provider.dart';
import 'package:kealthy/view/profile%20page/Terms_and_condition.dart';
import 'package:kealthy/view/profile%20page/privacy_policy.dart';

import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:shared_preferences/shared_preferences.dart';

final otpProvider =
    StateNotifierProvider<OtpNotifier, OtpState>((ref) => OtpNotifier());

// ignore: must_be_immutable
class SignUpScreen extends ConsumerStatefulWidget {
  final String verificationId;
  final String phoneNumber;
  bool isTestMode; // For Apple test flow

  SignUpScreen({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    this.isTestMode = false,
  });

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // For Apple’s review flow
  final String testOtp = "2552";
  final String testNumber = "9897969594";

  @override
  void initState() {
    super.initState();

    // Start the 60-sec timer from your existing OTP State.
    ref.read(otpProvider.notifier).startTimer();

    // If Apple is reviewing
    if (widget.phoneNumber == testNumber) {
      widget.isTestMode = true;
      _otpController.text = testOtp;

      _setTestModeFlag(true);
      // Auto-verify after a short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        _verifyOtp();
      });
    } else {
      _setTestModeFlag(false);
    }
  }

  // For storing "isTestMode" in SharedPreferences
  Future<void> _setTestModeFlag(bool isTestMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTestMode', isTestMode);
  }

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
    // Because we now store OTP in the signUpProvider, let's confirm
    // the text field is in sync. Alternatively, we could just rely on signUpProvider
    // for everything, but let's keep consistency:
    final enteredOtp = _otpController.text.trim();
    final verificationId = widget.verificationId;

    // Check if in test mode or Apple’s test OTP
    bool isTestMode = await _getTestModeFlag();
    if (isTestMode || enteredOtp == testOtp) {
      print('Test Mode Login Successful!');
      _savePhoneNumber();

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BottomNavBar()),
      );
      return;
    }

    // Normal OTP verification
    ref.read(otpProvider.notifier).verifyOtp(
        verificationId, enteredOtp, context,
        onSuccess: _savePhoneNumber);
  }

  @override
  Widget build(BuildContext context) {
    // 1) We watch the signUpProvider to get the checkbox states + OTP
    final signUpData = ref.watch(signUpProvider);
    // 2) We also watch the existing OTP state from your OtpNotifier
    final otpState = ref.watch(otpProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Enter OTP'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text('OTP sent to ${widget.phoneNumber}'),
              const SizedBox(height: 20),

              Form(
                key: _formKey,
                child: PinCodeTextField(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  controller: _otpController,
                  cursorColor: Colors.black,
                  appContext: context,
                  length: 4,

                  // Instead of setState, update signUpProvider's OTP
                  onChanged: (value) {
                    // keep local controller in sync, but more importantly
                    // update the Riverpod state
                    ref.read(signUpProvider.notifier).updateOtp(value);
                  },
                  onCompleted: (otp) {
                    if (_formKey.currentState?.validate() == true) {
                      // We do nothing here except refresh signUpProvider
                      ref.read(signUpProvider.notifier).updateOtp(otp);
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

              const SizedBox(height: 10),

              // Show error if any
              if (otpState.error != null) ...[
                const SizedBox(height: 10),
                Text(
                  otpState.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],

              const SizedBox(height: 20),

              // Two checkboxes for T&C and Privacy
              Row(
                children: [
                  Checkbox(
                    activeColor: Colors.black,
                    checkColor: Colors.white,
                    value: signUpData.acceptedTerms,
                    onChanged: (bool? value) {
                      ref
                          .read(signUpProvider.notifier)
                          .toggleAcceptedTerms(value ?? false);
                    },
                  ),
                  Text(
                    "I agree to",
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Flexible(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PrivacyPolicy(),
                          ),
                        );
                      },
                      child: const Text(
                        "Privacy Policy",
                        style: TextStyle(fontSize: 14, color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Checkbox(
                    activeColor: Colors.black,
                    checkColor: Colors.white,
                    value: signUpData.acceptedPrivacy,
                    onChanged: (bool? value) {
                      ref
                          .read(signUpProvider.notifier)
                          .toggleAcceptedPrivacy(value ?? false);
                    },
                  ),
                  Text(
                    "I agree to",
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  ),
                  const SizedBox(
                    width: 5,
                  ),
                  Flexible(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TermsAndCondition(),
                          ),
                        );
                      },
                      child: const Text(
                        "Terms and Conditions",
                        style: TextStyle(fontSize: 14, color: Colors.blue),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              otpState.isLoading
                  ? const CupertinoActivityIndicator(
                      color: Color.fromARGB(255, 65, 88, 108),
                    )
                  : ElevatedButton(
                      onPressed: ref.watch(signUpProvider).canShowContinueButton
                          ? () {
                              if (_formKey.currentState?.validate() == true) {
                                _verifyOtp();
                              }
                            }
                          : null, // When null, the button is disabled
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            ref.watch(signUpProvider).canShowContinueButton
                                ? const Color.fromARGB(255, 65, 88, 108)
                                : Colors.grey, // Disabled color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 15.0,
                          horizontal: 30.0,
                        ),
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
      ),
    );
  }
}
