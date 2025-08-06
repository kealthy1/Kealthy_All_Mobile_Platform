import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_update/in_app_update.dart';

import 'version_check.dart';

final versionUpdateAvailableProvider = StateProvider<bool>((ref) => false);

Future<void> checkVersionUpdate(WidgetRef ref) async {
  if (Platform.isAndroid) {
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();
      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        ref.read(versionUpdateAvailableProvider.notifier).state = true;
      }
    } catch (_) {}
  } else if (Platform.isIOS) {
    final currentVersion = await VersionCheckService.getCurrentVersion();
    final latestVersion = await VersionCheckService.fetchLatestVersion();
    if (latestVersion != null &&
        VersionCheckService.isUpdateAvailable(currentVersion, latestVersion)) {
      ref.read(versionUpdateAvailableProvider.notifier).state = true;
    }
  }
}
