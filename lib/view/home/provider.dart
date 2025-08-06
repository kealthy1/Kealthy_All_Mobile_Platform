import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:kealthy/view/Cart/cart_controller.dart';
import 'package:kealthy/view/address/provider.dart';
import 'package:kealthy/view/map/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

/// 🔹 **State Providers**
final newsletterSubscribedProvider = StateProvider<bool>((ref) => false);
final hasShownReviewAlertProvider = StateProvider<bool>((ref) => false);
final selectedItemProvider = StateProvider<CartItem?>((ref) => null);
final tapPositionProvider = StateProvider<Offset?>((ref) => null);
final overlayEntryProvider = StateProvider<OverlayEntry?>((ref) => null);
final cartVisibilityProvider = StateProvider<bool>((ref) => true);
final locationPermissionProvider =
    StateProvider<LocationPermission>((ref) => LocationPermission.denied);
final locationPermissionGrantedProvider = StateProvider<bool>((ref) => false);
final hasLocationPermissionProvider = StateProvider<bool>((ref) => false);
final cachedLocationProvider =
    StateProvider<Map<String, String>?>((ref) => null);

/// 🔹 **Cart Provider (Shared across all pages)**
// final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
//   return CartNotifier();
// });

/// 🔹 **Location Providers**
final locationProvider = StateProvider<String?>((ref) => null);
final locationTypeProvider = StateProvider<String?>((ref) => "Select address");
final totalItemsProvider = StateProvider<int>((ref) => 0);

final rainingStatusStreamProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return FirebaseFirestore.instance
      .collection('RainStatus')
      .doc('status')
      .snapshots()
      .map((snapshot) {
    final data = snapshot.data();
    if (data == null) {
      return {'isRaining': false, 'message': ''};
    }
    return {
      'isRaining': data['isRaining'] ?? false,
      'message': data['message'] ?? '',
    };
  });
});

/// 🔹 **Fetch Phone Number from Shared Preferences**
Future<String?> getStoredPhoneNumber() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('phoneNumber');
}

/// 🔹 **Live Orders Provider**
final liveOrdersProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final prefs = await SharedPreferences.getInstance();
  final phoneNumber = prefs.getString('phoneNumber');

  if (phoneNumber == null || phoneNumber.isEmpty) {
    yield [];
    return;
  }

  final database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://kealthy-90c55-dd236.firebaseio.com/',
  ).ref('orders');

  yield* database.onValue.map((event) {
    final data = event.snapshot.value as Map?;
    if (data == null) return [];

    return data.entries
        .where((entry) =>
            entry.value['phoneNumber'] == phoneNumber &&
            (entry.value['assignedTo'] != 'none'))
        .map<Map<String, dynamic>>((entry) =>
            Map<String, dynamic>.from(entry.value as Map<dynamic, dynamic>))
        .toList();
  });
});

Future<Map<String, String>> getSelectedAddressOrCurrentLocation(
    FutureProviderRef<Map<String, String>> ref) async {
  print("🔁 Starting location fetch process");

  final prefs = await SharedPreferences.getInstance();

  // Helper: cache if location is valid
  void cache(Map<String, String> result) {
    if (result['address'] != 'Locating...') {
      ref.read(cachedLocationProvider.notifier).state = result;
      print("📦 Cached location: $result");
    }
  }

  // Retry logic
  int retryCount = 0;
  const maxRetries = 3;
  const retryDelay = Duration(seconds: 3);

  Future<Map<String, String>> fetchLocation() async {
    final selectedAddress = ref.read(selectedLocationProvider);
    if (selectedAddress != null && selectedAddress.isNotEmpty) {
      final result = {
        "addressType": prefs.getString('selectedType') ?? "Selected Address",
        "address": selectedAddress,
      };
      cache(result);
      return result;
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        final result = {
          "addressType": "Location Service Disabled",
          "address": "Please enable location services",
        };
        cache(result);
        return result;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 6));

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 5));

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final userLocation = place.street?.isNotEmpty == true
            ? place.street!
            : place.subLocality?.isNotEmpty == true
                ? place.subLocality!
                : place.locality?.isNotEmpty == true
                    ? place.locality!
                    : "Locating...";

        await prefs.setString('user_location', userLocation);
        ref.read(locationProvider.notifier).state = userLocation;

        final result = {"address": userLocation};
        cache(result);
        return result;
      }
    } catch (e) {
      print("❌ Location fetch error: $e");
    }

    final cached = ref.read(cachedLocationProvider);
    if (cached != null) {
      print("Returning cached location: $cached");
      return cached;
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return {
        "addressType": "Location Disabled",
        "address": "Enable location for better experience",
      };
    }

    return {"address": "Locating..."};
  }

  // Retry loop
  while (retryCount < maxRetries) {
    try {
      final result = await fetchLocation();
      return result;
    } catch (e) {
      print("Retry $retryCount failed: $e");
      retryCount++;
      if (retryCount < maxRetries) {
        await Future.delayed(retryDelay);
      }
    }
  }

  return {"address": "Locating..."};
}

Future<void> checkLocationPermission(WidgetRef ref) async {
  LocationPermission permission = await Geolocator.checkPermission();
  ref.read(locationPermissionProvider.notifier).state = permission;

  if (permission == LocationPermission.always ||
      permission == LocationPermission.whileInUse) {
    ref.read(hasLocationPermissionProvider.notifier).state = true;
    ref.invalidate(locationDataProvider);

    // Fetch the latest location
    await LocationHelper.getCurrentLocation();
  } else if (permission == LocationPermission.denied) {
    // 🔥 Request location permission (ONLY ask, don't show the bottom sheet)
    await Geolocator.requestPermission();
  } else if (permission == LocationPermission.deniedForever) {
    // ❌ Do nothing if denied forever (no bottom sheet)
    print(
        "⚠️ Location permission permanently denied, user must enable manually.");
  } else if (permission == LocationPermission.unableToDetermine) {
    // ❌ Do nothing if unable to determine
    print("⚠️ Unable to determine location permission.");
  }
}

// FutureProvider to fetch image URLs
final homeImageUrlsProvider = FutureProvider<List<String>>((ref) async {
  final bannerDocs =
      await FirebaseFirestore.instance.collection('banners').get();
  final productDocs =
      await FirebaseFirestore.instance.collection('products').limit(10).get();

  final bannerUrls = bannerDocs.docs.map((doc) => doc['image'] as String);
  final productUrls = productDocs.docs.map((doc) => doc['image'] as String);

  return [...bannerUrls, ...productUrls];
});

final locationDataProvider = FutureProvider<Map<String, String>>((ref) async {
  ref.watch(selectedLocationProvider); // re-run on address selection change

  final result = await getSelectedAddressOrCurrentLocation(ref);

  // 🧠 Auto-retry if it's still "Locating..."
  if (result['address'] == 'Locating...') {
    Future.delayed(const Duration(seconds: 5), () {
      ref.invalidateSelf(); // ✅ auto-trigger retry
    });
  }

  return result;
});
