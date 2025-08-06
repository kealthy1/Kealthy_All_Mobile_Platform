import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:kealthy/view/BottomNavBar/bottom_nav_bar.dart';

class OtpState {
  final String? otp;
  final String? verificationId;
  final bool isLoading;
  final String? error;
  final int timerValue;

  OtpState({
    this.otp,
    this.verificationId,
    this.isLoading = false,
    this.error,
    this.timerValue = 60,
  });

  OtpState copyWith({
    String? otp,
    String? verificationId,
    bool? isLoading,
    String? error,
    int? timerValue,
  }) {
    return OtpState(
      otp: otp ?? this.otp,
      verificationId: verificationId ?? this.verificationId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      timerValue: timerValue ?? this.timerValue,
    );
  }
}


class OtpNotifier extends StateNotifier<OtpState> {
  OtpNotifier() : super(OtpState());
  Timer? _timer;

  void setOtp(String otp) {
    state = state.copyWith(otp: otp);
  }

  void startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timerValue > 0) {
        state = state.copyWith(timerValue: state.timerValue - 1);
      } else {
        _timer?.cancel();
      }
    });
  }

  void resetTimer() {
    if (_timer != null) {
      _timer!.cancel();
    }
    state = state.copyWith(timerValue: 60);
    startTimer();
  }

  Future<void> verifyOtp(
      String verificationId, String otp, BuildContext context,
      {Function? onSuccess}) async {
    state = state.copyWith(isLoading: true);
    const url = 'https://api-jfnhkjk4nq-uc.a.run.app/verify-otp';

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'verificationId': verificationId,
          'otp': otp,
        }),
      );

      if (response.statusCode == 200) {
        state = OtpState();
        if (onSuccess != null) {
          onSuccess();
        }
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BottomNavBar()),
        );
      } else {
        state = state.copyWith(error: 'OTP verification failed');
      }
    } catch (e) {
      state = state.copyWith(error: 'An error occurred');
    }
  }

  Future<void> resendOtp(String phoneNumber) async {
    const url = 'https://api-jfnhkjk4nq-uc.a.run.app/send-otp';
    state = state.copyWith(isLoading: true);

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'phoneNumber': phoneNumber}),
      );

      if (response.statusCode == 200) {
        state = OtpState();
        resetTimer();
      } else {
        state = state.copyWith(error: 'Failed to resend OTP');
      }
    } catch (e) {
      state = state.copyWith(error: 'An error occurred while resending OTP');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
