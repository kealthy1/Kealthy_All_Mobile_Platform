import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/BottomNavBar/bottom_nav_bar_proivder.dart';
import 'package:kealthy/view/Cart/cart_controller.dart';
import 'package:kealthy/view/Cart/checkout_provider.dart';
import 'package:kealthy/view/Login/login_notifier.dart';
import 'package:kealthy/view/Login/login_page.dart';
import 'package:kealthy/view/Toast/toast_helper.dart';
import 'package:kealthy/view/address/provider.dart';
import 'package:kealthy/view/profile%20page/getuserdetails.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// Define a Profile Model
class ProfileModel {
  final String name;
  final String email;
  final bool isLoading;

  ProfileModel({
    required this.name,
    required this.email,
    this.isLoading = false,
  });

  ProfileModel copyWith({
    String? name,
    String? email,
    bool? isLoading,
  }) {
    return ProfileModel(
      name: name ?? this.name,
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Profile Provider
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileModel>(
  (ref) => ProfileNotifier(ref),
);

class ProfileNotifier extends StateNotifier<ProfileModel> {
  final Ref ref;
  ProfileNotifier(this.ref)
      : super(ProfileModel(name: '', email: '', isLoading: true)) {
    final phone = ref.read(phoneNumberProvider);
    if (phone.isNotEmpty) {
      loadProfileData();
    } else {
      state = ProfileModel(name: '', email: '', isLoading: false);
    }
  }

  // ✅ 1️⃣ Load Profile from SharedPreferences (Fast Fetch)
  Future<void> loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = ref.read(phoneNumberProvider);

    if (phoneNumber.isEmpty) {
      state = ProfileModel(name: '', email: '', isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true);
    final storedName = prefs.getString('user_name') ?? '';
    final storedEmail = prefs.getString('user_email') ?? '';

    state =
        ProfileModel(name: storedName, email: storedEmail, isLoading: false);
    fetchProfileData();
  }

  // ✅ 2️⃣ Fetch Profile from API (Background Fetch)
  Future<void> fetchProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = ref.read(phoneNumberProvider);

    if (phoneNumber.isEmpty) return;

    try {
      state = state.copyWith(isLoading: true);
      final userDetails = await UserService.getUserDetails(phoneNumber);

      state = ProfileModel(
        name: userDetails['name'] ?? '',
        email: userDetails['email'] ?? '',
        isLoading: false,
      );

      prefs.setString('user_name', userDetails['name'] ?? '');
      prefs.setString('user_email', userDetails['email'] ?? '');
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  // ✅ 3️⃣ Update User Profile
  Future<void> updateUserData(String name, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phoneNumber');

      if (phoneNumber == null) return;

      await UserService.updateUserDetails(phoneNumber, name, email);

      // ✅ Update state
      state = state.copyWith(name: name, email: email);

      // ✅ Update SharedPreferences
      prefs.setString('user_name', name);
      prefs.setString('user_email', email);
    } catch (e) {
      debugPrint("❌ Error updating profile: $e");
    }
  }
}

Future<void> deleteAccount(WidgetRef ref, BuildContext context) async {
  bool confirmed = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            title: Text(
              "Delete Account",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              "Are you sure you want to delete your account? This action cannot be undone.",
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Cancel",
                    style: GoogleFonts.poppins(color: Colors.black)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: Text("Delete",
                    style: GoogleFonts.poppins(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ) ??
      false;

  if (!confirmed) return;

  try {
    ref.read(isLoadingProvider.notifier).state = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Colors.black),
              const SizedBox(height: 15),
              Text(
                "Deleting Account...",
                style: GoogleFonts.poppins(
                    fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      },
    );

    // Remove any artificial delay here if you want it faster
    // await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('phoneNumber');

    if (phoneNumber == null) {
      Navigator.pop(context); // close the "Deleting..." dialog
      return;
    }

    const deleteUrl = "https://api-jfnhkjk4nq-uc.a.run.app/delete";
    final response = await http.delete(
      Uri.parse(deleteUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phoneNumber': phoneNumber}),
    );

    Navigator.pop(context); // close the "Deleting..." dialog

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['success'] == false) {
        ToastHelper.showErrorToast(
            'Failed to delete account: ${data['message']}');
        return;
      }

      // Clear all saved data from SharedPreferences
      await prefs.clear();
      // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
      ref.read(profileProvider.notifier).state =
          ProfileModel(name: '', email: '', isLoading: false);
      ref.invalidate(selectedLocationProvider);
      ref.invalidate(phoneNumberProvider);
      ref.invalidate(customerNameProvider);
      ref.invalidate(cartProvider);
      ref.invalidate(addressProvider);
      ref.invalidate(bottomNavProvider);

      ToastHelper.showSuccessToast('Account deleted successfully.');

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginFields()),
        (route) => false,
      );
    } else {
      ToastHelper.showErrorToast('Failed to delete account. Try again later.');
    }
  } catch (e) {
    ToastHelper.showErrorToast('Error occurred while deleting account.');
    Navigator.pop(context); // close the "Deleting..." dialog on error
  } finally {
    ref.read(isLoadingProvider.notifier).state = false;
  }
}

final isLoggedInProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.containsKey('phoneNumber');
});

// Example: logout logic
Future<void> logoutUser(BuildContext context, WidgetRef ref) async {
  // Show a quick "Logging out" dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.black),
            SizedBox(height: 15),
            Text(
              "Logging out...",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    },
  );

  // Remove or reduce this delay if you want it instant
  // await Future.delayed(const Duration(seconds: 2));

  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  await prefs.remove('phoneNumber');

  await ref.read(loginStatusProvider.notifier).logout();

  // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
  ref.read(profileProvider.notifier).state =
      ProfileModel(name: '', email: '', isLoading: false);

  // Invalidate providers
  ref.invalidate(selectedLocationProvider);
  ref.invalidate(phoneNumberProvider);
  ref.invalidate(customerNameProvider);
  ref.invalidate(cartProvider);
  ref.invalidate(addressProvider);
  ref.invalidate(bottomNavProvider);

  Navigator.pop(context); // close the "Logging out" dialog

  Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (context) => const LoginFields(),
    ),
  );
}
