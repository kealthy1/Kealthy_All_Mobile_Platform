import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Lottie.asset(
                'lib/assets/animations/Animation - 1746689928824.json',
                width: 200,
                height: 200,
                fit: BoxFit.fill,
              ),
              const SizedBox(height: 24),
              const Text(
                "We'll Be Back Soon!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "The system is under maintenance.\nPlease check back shortly.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
