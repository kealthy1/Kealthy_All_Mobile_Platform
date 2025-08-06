// login_status_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginStatusNotifier extends StateNotifier<bool> {
  LoginStatusNotifier() : super(false) {
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.containsKey('phoneNumber');
  }

  Future<void> login(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('phoneNumber', phoneNumber);
    state = true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('phoneNumber');
    state = false;
  }
}

final loginStatusProvider =
    StateNotifierProvider<LoginStatusNotifier, bool>((ref) {
  return LoginStatusNotifier();
});