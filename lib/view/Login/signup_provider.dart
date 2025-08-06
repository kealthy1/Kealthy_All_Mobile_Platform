import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Represents all UI state for the sign-up/OTP screen.
class SignUpData {
  final bool acceptedTerms;
  final bool acceptedPrivacy;
  final String otp;

  SignUpData({
    this.acceptedTerms = false,
    this.acceptedPrivacy = false,
    this.otp = '',
  });

  /// Whether user can press "Continue" button.
  bool get canShowContinueButton {
    return otp.length == 4 && acceptedTerms && acceptedPrivacy;
  }

  /// Copies the current state with any updated fields.
  SignUpData copyWith({
    bool? acceptedTerms,
    bool? acceptedPrivacy,
    String? otp,
  }) {
    return SignUpData(
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      acceptedPrivacy: acceptedPrivacy ?? this.acceptedPrivacy,
      otp: otp ?? this.otp,
    );
  }
}

/// Notifier to mutate SignUpData
class SignUpNotifier extends StateNotifier<SignUpData> {
  SignUpNotifier() : super(SignUpData());

  void toggleAcceptedTerms(bool value) {
    state = state.copyWith(acceptedTerms: value);
  }

  void toggleAcceptedPrivacy(bool value) {
    state = state.copyWith(acceptedPrivacy: value);
  }

  void updateOtp(String newOtp) {
    state = state.copyWith(otp: newOtp);
  }

  void resetCheckboxes() {
    state = state.copyWith(acceptedTerms: false, acceptedPrivacy: false);
  }
}

/// Riverpod provider to expose SignUpNotifier & SignUpData
final signUpProvider = StateNotifierProvider<SignUpNotifier, SignUpData>(
  (ref) => SignUpNotifier(),
);