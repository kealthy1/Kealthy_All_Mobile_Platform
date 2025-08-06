import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:kealthy/view/Cart/cart.dart';
import 'package:ntp/ntp.dart';
import 'package:shared_preferences/shared_preferences.dart';

final isInstantDeliveryVisibleProvider = StateProvider<bool>((ref) => true);
final timePageLoaderProvider = StateProvider<bool>((ref) => false);

Future<void> checkTimeBoundaries(WidgetRef ref) async {
  try {
    // Fetch current time using NTP
    DateTime currentTime = await NTP.now();

    final startBoundary = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
      9,
    );
    final endBoundary = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
      18,
    );

    // Determine if Instant Delivery is visible
    final isVisible =
        currentTime.isAfter(startBoundary) && currentTime.isBefore(endBoundary);

    // Update state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(isInstantDeliveryVisibleProvider.notifier).state = isVisible;
      if (!isVisible) {
        // Immediately uncheck the box if outside 9AM–6PM
        ref.read(isInstantDeliverySelectedProvider.notifier).state = false;
        ref.read(isSlotContainerVisibleProvider.notifier).state = true;
      }
    });
  } catch (e) {
    print("Error checking time boundaries: $e");
  }
}

Future<String> calculateEstimatedDeliveryTime() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    double? latitude = prefs.getDouble('selectedLatitude');
    double? longitude = prefs.getDouble('selectedLongitude');

    const restaurantLatitude = 10.010279427438405;
    const restaurantLongitude = 76.38426666931349;
    const cookingTimeMinutes = 15;
    const averageSpeedMetersPerSecond = 11.11;

    double distanceInMeters = Geolocator.distanceBetween(
      restaurantLatitude,
      restaurantLongitude,
      latitude!,
      longitude!,
    );
    double travelTimeMinutes =
        (distanceInMeters / averageSpeedMetersPerSecond) / 60;
    int totalTimeMinutes = cookingTimeMinutes + travelTimeMinutes.round();

    DateTime currentTime = await NTP.now();
    DateTime estimatedDeliveryTime = currentTime.add(
      Duration(minutes: totalTimeMinutes),
    );

    String formattedTime = DateFormat('hh:mm a').format(estimatedDeliveryTime);
    String result = "$formattedTime ($totalTimeMinutes min)";
    return result;
  } catch (e) {
    return "Error calculating delivery time";
  }
}
