import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy/main.dart';
import 'package:kealthy/view/BottomNavBar/bottom_nav_bar_proivder.dart';
import 'package:kealthy/view/home/home.dart';
import 'package:kealthy/view/profile%20page/profile.dart';

class BottomNavBar extends ConsumerStatefulWidget {
  const BottomNavBar({super.key});

  @override
  ConsumerState<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends ConsumerState<BottomNavBar> {
  DateTime? _lastBackPressTime;

  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    final currentIndex = ref.read(bottomNavProvider);

    if (currentIndex != 0) {
      ref.read(bottomNavProvider.notifier).setIndex(0);
      return false;
    }

    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;

      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text("Press back again to exit"),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black87,
        ),
      );

      return false; // Do not exit yet
    }

    return true; // Exit app
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavProvider);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            IndexedStack(
              index: currentIndex,
              children: const [
                HomePage(),
                ProfilePage(),
              ],
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,
          currentIndex: currentIndex,
          onTap: (index) {
            ref.read(bottomNavProvider.notifier).setIndex(index);
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.black54,
          unselectedItemColor: Colors.grey,
          elevation: 0.5,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(
                CupertinoIcons.home,
                color: Color.fromARGB(255, 65, 88, 108),
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                CupertinoIcons.person,
                color: Color.fromARGB(255, 65, 88, 108),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
