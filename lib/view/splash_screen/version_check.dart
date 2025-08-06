import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:in_app_update/in_app_update.dart';
import 'package:lottie/lottie.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class InAppUpdateService {
  static final InAppUpdateService _instance = InAppUpdateService._internal();

  factory InAppUpdateService() => _instance;

  InAppUpdateService._internal();
  Future<void> checkForUpdate(BuildContext context) async {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      debugPrint("🔍 Update availability: ${updateInfo.updateAvailability}");
      debugPrint(
          "🔍 Immediate update allowed: ${updateInfo.immediateUpdateAllowed}");

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (updateInfo.immediateUpdateAllowed) {
          try {
            await InAppUpdate.performImmediateUpdate();
          } catch (e) {
            debugPrint("⛔️ performImmediateUpdate failed: $e");
            // ignore: use_build_context_synchronously
            _showBlockerDialog(context);
          }
        } else {
          debugPrint("⛔️ Immediate update not allowed. Showing custom dialog.");
          _showBlockerDialog(
              // ignore: use_build_context_synchronously
              context); // <-- show it anyway if update is available
        }
      } else {
        debugPrint("✅ App is up-to-date.");
      }
    } catch (e) {
      debugPrint("❌ In-app update check failed: $e");
      _showBlockerDialog(
          // ignore: use_build_context_synchronously
          context); // Optional: handle totally failed checks here
    }
  }

  

  void _showBlockerDialog(BuildContext context) {
    showDialog(
      //barrierColor: Colors.white,
      barrierDismissible: false,
      context: context,
      builder: (_) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: Column(
            children: const [
              Icon(Icons.system_update, color: Colors.redAccent, size: 50),
              SizedBox(height: 10),
              Text(
                "Update Required",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Text(
            "A new version is available. Please update to continue using the app.",
            textAlign: TextAlign.center,
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                await launchUrl(Uri.parse(
                  'https://play.google.com/store/apps/details?id=com.COTOLORE.Kealthy',
                ));
              },
              child: const Text("Update Now"),
            ),
          ],
        ),
      ),
    );
  }
  
// Future<void> checkForUpdate(BuildContext context) async {
  //   try {
  //     final updateInfo = await InAppUpdate.checkForUpdate();

  //     if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
  //       if (updateInfo.immediateUpdateAllowed) {
  //         // 🚫 User cannot skip this update once started
  //         await InAppUpdate.performImmediateUpdate().catchError((e) {
  //           debugPrint("⛔️ Immediate update cancelled or failed: $e");
  //           _showBlockerDialog(context); // Force update on cancel
  //           return AppUpdateResult.inAppUpdateFailed;
  //         });
  //       } else {
  //         _showBlockerDialog(context); // Immediate not allowed
  //       }
  //     } else {
  //       debugPrint("✅ App is up-to-date.");
  //     }
  //   } catch (e) {
  //     debugPrint("❌ In-app update check failed: $e");
  //     _showBlockerDialog(context); // Network failure or unsupported
  //   }
  // }
  // static Future<String> getLocalVersion() async {
  //   final PackageInfo packageInfo = await PackageInfo.fromPlatform();
  //   return packageInfo.version;
  // }

  // static Future<String> getPlayStoreVersion() async {
  //   try {
  //     final doc = await FirebaseFirestore.instance
  //         .collection('version')
  //         .doc('android')
  //         .get();

  //     if (doc.exists) {
  //       return doc['latest_version']; // Expects: "1.1.67"
  //     } else {
  //       throw Exception('Version document not found.');
  //     }
  //   } catch (e) {
  //     throw Exception('Error fetching Firestore version: $e');
  //   }
  // }

  // bool _isUpdateAvailable(String local, String remote) {
  //   final localParts = local.split('.').map(int.parse).toList();
  //   final remoteParts = remote.split('.').map(int.parse).toList();

  //   for (int i = 0; i < remoteParts.length; i++) {
  //     final remoteVal = remoteParts[i];
  //     final localVal = i < localParts.length ? localParts[i] : 0;

  //     if (remoteVal > localVal) return true;
  //     if (remoteVal < localVal) return false;
  //   }
  //   return false;
  // }

  // void _showMandatoryUpdateDialog(
  //     BuildContext context, String remoteVersion, String localVersion) {
  //   showDialog(
  //     barrierDismissible: false,
  //     context: context,
  //     builder: (_) => WillPopScope(
  //       onWillPop: () async => false,
  //       child: AlertDialog(
  //         backgroundColor: Colors.white,
  //         shape:
  //             RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
  //         title: Column(
  //           children: [
  //             Icon(CupertinoIcons.info_circle_fill,
  //                 color: Colors.redAccent, size: 50),
  //             SizedBox(height: 10),
  //             Text("Update Required",
  //                 textAlign: TextAlign.center,
  //                 style: GoogleFonts.poppins(
  //                     fontSize: 20,
  //                     fontWeight: FontWeight.bold,
  //                     color: Colors.black)),
  //           ],
  //         ),
  //         content: Text(
  //           "A new version $remoteVersion is available!\n\nYour current version is $localVersion.\nPlease update to continue.",
  //           textAlign: TextAlign.center,
  //           style: GoogleFonts.poppins(fontSize: 16, color: Colors.black54),
  //         ),
  //         actionsAlignment: MainAxisAlignment.center,
  //         actions: [
  //           ElevatedButton(
  //             onPressed: () async {
  //               await launchUrl(Uri.parse(
  //                 'https://play.google.com/store/apps/details?id=com.COTOLORE.Kealthy',
  //               ));
  //             },
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.redAccent,
  //               shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(12)),
  //             ),
  //             child: Text("Update",
  //                 style: GoogleFonts.poppins(
  //                     fontSize: 16,
  //                     fontWeight: FontWeight.bold,
  //                     color: Colors.white)),
  //           )
  //         ],
  //       ),
  //     ),
  //   );
  // }

  //'https://play.google.com/store/apps/details?id=com.COTOLORE.Kealthy',
}

class VersionCheckService {
  static const String appStoreId =
      "6740621148"; // Replace with your actual App Store ID

  static Future<String?> fetchLatestVersion() async {
    // DEBUG
    print("🔍 [VersionCheckService] _fetchLatestVersion() called...");

    try {
      final url =
          Uri.parse("https://itunes.apple.com/in/lookup?id=$appStoreId");
      print("🌐 [VersionCheckService] GET → $url");

      final response = await http.get(url);
      print("📥 [VersionCheckService] Response code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print("📄 [VersionCheckService] Response body: $jsonData");

        if (jsonData['resultCount'] > 0) {
          final storeVersion = jsonData['results'][0]['version'];
          print(
              "✅ [VersionCheckService] Latest App Store version: $storeVersion");
          return storeVersion;
        } else {
          print(
              "⚠️ [VersionCheckService] resultCount=0, no app found in the App Store for this ID.");
        }
      } else {
        print(
            "❌ [VersionCheckService] Failed to fetch version. HTTP status: ${response.statusCode}");
      }
    } catch (e) {
      print("❌ [VersionCheckService] Error fetching latest version: $e");
    }

    // If we got here, something failed
    return null;
  }

  static Future<String> getCurrentVersion() async {
    print("🔍 [VersionCheckService] _getCurrentVersion() called...");
    final packageInfo = await PackageInfo.fromPlatform();
    print(
        "✅ [VersionCheckService] Current installed version: ${packageInfo.version}");
    return packageInfo.version;
  }

  static Future<void> checkForUpdate(BuildContext context) async {
    print("🔔 [VersionCheckService] checkForUpdate() called...");
    String currentVersion = await getCurrentVersion();
    String? latestVersion = await fetchLatestVersion();

    print(
        "🔖 [VersionCheckService] currentVersion=$currentVersion | latestVersion=$latestVersion");

    if (latestVersion == null) {
      print(
          "⚠️ [VersionCheckService] latestVersion is null. No update dialog will show.");
      return;
    }

    bool needsUpdate = isUpdateAvailable(currentVersion, latestVersion);
    print("🤔 [VersionCheckService] _isUpdateAvailable=$needsUpdate");

    if (needsUpdate) {
      print("💡 [VersionCheckService] Showing update dialog...");
      await _showUpdateDialog(context, latestVersion);
    } else {
      print("✅ [VersionCheckService] No update required.");
    }
  }

  static bool isUpdateAvailable(String currentVersion, String latestVersion) {
    // DEBUG
    print(
        "🔍 [VersionCheckService] _isUpdateAvailable() → Comparing $currentVersion to $latestVersion");

    final currentParts = currentVersion.split('.').map(int.tryParse).toList();
    final latestParts = latestVersion.split('.').map(int.tryParse).toList();

    for (int i = 0; i < latestParts.length; i++) {
      final latestPart = latestParts[i] ?? 0;
      final currentPart = i < currentParts.length ? (currentParts[i] ?? 0) : 0;

      if (latestPart > currentPart) {
        // A higher number in the same position means a newer version
        return true;
      } else if (latestPart < currentPart) {
        // Current version is actually ahead (which typically shouldn't happen in production)
        return false;
      }
      // If they are equal, continue comparing next position
    }
    return false;
  }

  static Future<void> _showUpdateDialog(
      BuildContext context, String latestVersion) async {
    await Future.delayed(
        const Duration(milliseconds: 300)); // Small delay for smooth transition
    await showModalBottomSheet(
      context: context,
      isDismissible: false,
      isScrollControlled: true,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => WillPopScope(
        onWillPop: () async {
          print("🚫 [VersionCheckService] Back button pressed, ignoring...");
          return false;
        },
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Update Available",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Lottie.asset(
                'lib/assets/animations/Download App Update.json',
                width: 200,
                height: 200,
                fit: BoxFit.fill,
              ),
              const SizedBox(height: 12),
              Text(
                "A new version ($latestVersion) is available. Please update to continue.",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.start,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                onPressed: () {
                  
                  const storeUrl =
                      "https://apps.apple.com/in/app/id$appStoreId";
                  print(
                      "➡️ [VersionCheckService] Opening App Store URL: $storeUrl");
                  launchUrl(
                    Uri.parse(storeUrl),
                    mode: LaunchMode.externalApplication,
                  );
                },
                child: Text(
                  "Update Now",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
    print("🕒 [VersionCheckService] Update bottom sheet closed.");
  }
}

