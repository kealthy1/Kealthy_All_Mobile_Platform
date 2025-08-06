import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy/view/BottomNavBar/bottom_nav_bar.dart';
import 'package:kealthy/view/Login/login_page.dart';
import 'package:kealthy/view/splash_screen/maintanance.dart';
import 'package:kealthy/view/splash_screen/required_update.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.delayed(const Duration(seconds: 3));

    final shouldUpdate = await _shouldForceUpdate();
    if (!mounted) return;

    if (shouldUpdate) {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(
          builder: (_) => const ForceUpdatePage(),
        ),
      );
      return;
    }

    final isUnderMaintenance = await _checkMaintenanceStatus();
    if (!mounted) return;

    if (isUnderMaintenance) {
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (_) => const MaintenanceScreen()),
      );
    } else {
      final prefs = await SharedPreferences.getInstance();
      final storedPhone = prefs.getString('phoneNumber') ?? '';

      // ✅ Set phone number into provider
      ref.read(phoneNumberProvider.notifier).state = storedPhone;

      Navigator.pushReplacement(
        context,
        CupertinoModalPopupRoute(
          builder: (_) =>
              storedPhone.isNotEmpty ? BottomNavBar() : const LoginFields(),
        ),
      );
    }
  }

  Future<bool> _shouldForceUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final localVersion = packageInfo.version;

    final doc =
        await FirebaseFirestore.instance.collection('config').doc('iOS').get();
    if (!doc.exists) return false;

    final remoteVersion = doc['latest_version'];

    List<int> parseVersion(String version) =>
        version.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    final localParts = parseVersion(localVersion);
    final remoteParts = parseVersion(remoteVersion);

    for (int i = 0; i < remoteParts.length; i++) {
      if (i >= localParts.length || remoteParts[i] > localParts[i]) return true;
      if (remoteParts[i] < localParts[i]) return false;
    }

    return false;
  }

  Future<bool> _checkMaintenanceStatus() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('maintenance')
          .doc('status')
          .get();
      return doc.data()?['maintenance'] == true;
    } catch (e) {
      print("⚠️ Maintenance check failed: $e");
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('lib/assets/images/splash.gif'),
              fit: BoxFit.fill,
            ),
          ),
        ),
      ),
    );
  }
}
