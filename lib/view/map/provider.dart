import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kealthy/view/BottomNavBar/bottom_nav_bar.dart';
import 'package:kealthy/view/address/adress_model.dart';
import 'package:kealthy/view/address/provider.dart';
import 'package:kealthy/view/map/distance_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final showMapProvider = FutureProvider<bool>((ref) async {
  await Future.delayed(const Duration(milliseconds: 300));
  return true;
});

final isFetchingLocationProvider = StateProvider<bool>((ref) => false);

final addressTypes = ['Home', 'Work', 'Other'];
final searchTextProvider = StateProvider<String>((ref) => '');

final selectedAddressTypeProvider = StateProvider<String?>((ref) => null);

//Provider for Address Details (Remember to replace with your actual implementation)
final addressDetailsProvider =
    StateNotifierProvider<AddressDetailsNotifier, AddressDetails?>(
        (ref) => AddressDetailsNotifier());

class AddressDetailsNotifier extends StateNotifier<AddressDetails?> {
  AddressDetailsNotifier() : super(null);

  void update(AddressDetails details) {
    state = details;
  }
}

class AddressSaveNotifier extends StateNotifier<bool> {
  AddressSaveNotifier() : super(false);

  void setLoading(bool isLoading) {
    state = isLoading;
  }
}

final addressSaveProvider =
    StateNotifierProvider<AddressSaveNotifier, bool>((ref) {
  return AddressSaveNotifier();
});

// Providers
final locationProvider =
    StateNotifierProvider<LocationNotifier, Position?>((ref) {
  return LocationNotifier();
});

final mapControllerProvider =
    StateProvider<GoogleMapController?>((ref) => null);
final suggestionsProvider = StateProvider<List<String>>((ref) {
  return [];
});

final selectedPositionProvider = StateProvider<LatLng?>((ref) => null);
final selectedContainerIndexProvider =
    StateProvider<int>((ref) => -1); // -1 indicates no selection

final isSearchingProvider = StateProvider<bool>((ref) => false);
final addressProviders = StateProvider<String?>((ref) => null);

class LocationNotifier extends StateNotifier<Position?> {
  LatLng? selectedPosition;
  LocationNotifier() : super(null) {
    getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        forceAndroidLocationManager: true,
        timeLimit: const Duration(seconds: 30),
      );
      state = position;
      selectedPosition = LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting location: $e');
    }
  }
}

Future<void> saveOrUpdateAddress(
  AddressDetails addressDetails,
  double latitude,
  double longitude,
  String? addressType,
  bool isUpdate,
  String? existingAddressId,
  WidgetRef ref,
  BuildContext context,
) async {
  final prefs = await SharedPreferences.getInstance();
  final phoneNumber = prefs.getString('phoneNumber') ?? '';

  final double? distanceInKm = await DistanceService().getDrivingDistanceInKm(
    startLat: 10.010099620051944, // Restaurant latitude
    startLng: 76.38422358870001, // Restaurant longitude
    endLat: latitude,
    endLng: longitude,
  );
  final double distanceValue = distanceInKm ?? 0.0;

  final addressData = addressDetails.toJson();
  addressData['phoneNumber'] = phoneNumber;
  addressData['latitude'] = latitude;
  addressData['longitude'] = longitude;
  addressData['type'] = addressType;
  addressData['distance'] = distanceValue; // Save distance to MongoDB
  print(phoneNumber);
  print(addressType);

  if (isUpdate && existingAddressId != null) {
    addressData['_id'] = existingAddressId;
  }

  ref.read(addressSaveProvider.notifier).setLoading(true);

  try {
    final url = isUpdate
        ? 'https://api-jfnhkjk4nq-uc.a.run.app/editaddress'
        : 'https://api-jfnhkjk4nq-uc.a.run.app/address';

    final response = isUpdate
        ? await http.put(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(addressData),
          )
        : await http.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(addressData),
          );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('${isUpdate ? 'Address updated' : 'Address saved'} successfully');

      await saveSelectedAddress(
        ref: ref,
        prefs: prefs,
        address: addressDetails.flatRoomArea ?? '',
        name: addressDetails.name ?? '',
        type: addressDetails.addressType ?? '',
        landmark: addressDetails.landmark ?? '',
        instructions: addressDetails.otherInstructions ?? '',
        latitude: latitude,
        longitude: longitude,
        distance: distanceValue, // You can update this value as needed
      );

      ref.invalidate(addressFutureProvider);
      final updatedAddresses = await fetchAndCacheAddresses(phoneNumber);
      if (updatedAddresses != null) {
        ref.invalidate(addressFutureProvider);
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const BottomNavBar()),
        (route) => false,
      );
    } else {
      print(
          'Failed to ${isUpdate ? 'update' : 'save'} address: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Failed to ${isUpdate ? 'update' : 'save'} address: ${response.reasonPhrase}'),
        ),
      );
    }
  } catch (e) {
    print('Error ${isUpdate ? 'updating' : 'saving'} address: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Error saving address. Please try again later.'),
      ),
    );
  } finally {
    ref.read(addressSaveProvider.notifier).setLoading(false);
  }
}
