import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kealthy/view/BottomNavBar/bottom_nav_bar.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForceUpdatePage extends StatelessWidget {
  // Hardcoded App Store URL for the update
  static const String googlePlayUrl =
      'https://play.google.com/store/apps/details?id=com.COTOLORE.Kealthy';

  const ForceUpdatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _shouldForceUpdate(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CupertinoActivityIndicator()));
        }

        final bool shouldUpdate = snapshot.data == true;

        if (!shouldUpdate) {
          return const BottomNavBar(); // or your default landing page
        }

        return Scaffold(
          backgroundColor: Colors.blueGrey[50],
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'lib/assets/animations/Download App Update.json',
                    width: 200,
                    height: 200,
                    fit: BoxFit.fill,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Update Required",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Please update the app to continue using it.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      final url = Uri.parse(googlePlayUrl);
                      debugPrint("Launching app URL: $googlePlayUrl");
                      if (await canLaunchUrl(url)) {
                        await launchUrl(url,
                            mode: LaunchMode.externalApplication);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Could not launch the update URL')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 12),
                    ),
                    child: const Text(
                      "Update Now",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _shouldForceUpdate() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final localVersion = packageInfo.version;

    final doc = await FirebaseFirestore.instance
        .collection('config')
        .doc('android')
        .get();
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
}
