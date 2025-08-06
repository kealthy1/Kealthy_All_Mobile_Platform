import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// ✅ State Providers
final selectedLocationProvider = StateProvider<String?>((ref) => null);
final isLoadingProvider = StateProvider<bool>((ref) => false);
final customerNameProvider = StateProvider<String?>((ref) => null);

// ✅ Optimized Address Future Provider with Caching
final addressFutureProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>?>((ref) async {
  return await getCachedOrFetchAddresses();
});

// ✅ Fetch from API if needed, otherwise use cached data
Future<List<Map<String, dynamic>>?> getCachedOrFetchAddresses() async {
  final prefs = await SharedPreferences.getInstance();
  final phoneNumber = prefs.getString('phoneNumber');

  if (phoneNumber == null) {
    print('📌 Phone number not found in SharedPreferences');
    return null;
  }

  // ✅ Try fetching from SharedPreferences first
  final cachedData = prefs.getString('cachedAddresses');
  if (cachedData != null) {
    print('✅ Loaded addresses from cache');
    return List<Map<String, dynamic>>.from(jsonDecode(cachedData));
  }

  // ✅ If cache is empty, fetch from API
  return await fetchAndCacheAddresses(phoneNumber);
}

// ✅ Fetch and Cache API Data
Future<List<Map<String, dynamic>>?> fetchAndCacheAddresses(String phoneNumber) async {
  final apiUrl = "https://api-jfnhkjk4nq-uc.a.run.app/getalladdresses?phoneNumber=$phoneNumber";
  
  try {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      
      if (jsonData is Map && jsonData.containsKey('data') && jsonData['data'] is List) {
        final List<Map<String, dynamic>> addresses = jsonData['data'].cast<Map<String, dynamic>>();

        // ✅ Save fetched data to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        prefs.setString('cachedAddresses', jsonEncode(addresses));
        print('✅ API Response cached');

        return addresses;
      } else {
        print('⚠️ Unexpected JSON format: $jsonData');
        return [];
      }
    } else {
      print('❌ API Error: ${response.statusCode}');
      return [];
    }
  } catch (e) {
    print('❌ Error fetching addresses: $e');
    return [];
  }
}

// ✅ Delete Address and Clear Cache
Future<void> deleteAddress(String phoneNumber, String type, WidgetRef ref,  BuildContext context) async {
  try {
    ref.read(isLoadingProvider.notifier).state = true;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevents tapping outside
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Prevents back button press
        child: const Center(
          child: CupertinoActivityIndicator(
                                  color: Colors.white)
        ),
      ),
    );

    final response = await http.delete(
      Uri.parse('https://api-jfnhkjk4nq-uc.a.run.app/deleteaddress?phoneNumber=$phoneNumber&type=$type'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      print('✅ Address deleted successfully');

      final prefs = await SharedPreferences.getInstance();
      String? selectedType = prefs.getString('selectedType');

      if (selectedType == type) {
        await _clearSelectedAddressFromPrefs();
        ref.read(selectedLocationProvider.notifier).state = null;
      }

      // ✅ Clear cached addresses and refetch
      await prefs.remove('cachedAddresses');
      ref.invalidate(addressFutureProvider);
    } else {
      print('❌ Failed to delete address: ${response.body}');
    }
  } catch (e) {
    print('❌ Error deleting address: $e');
  } finally {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
    ref.read(isLoadingProvider.notifier).state = false;
  }
}

// ✅ Clear Selected Address in SharedPreferences
Future<void> _clearSelectedAddressFromPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('selectedAddress');
  await prefs.remove('selected_slot');
  await prefs.remove('selectedType');
  await prefs.remove('selectedName');
  await prefs.remove('selectedLandmark');
  await prefs.remove('selectedInstruction');
  await prefs.remove('selectedDistance');
  await prefs.remove('selectedLat');
  await prefs.remove('selectedLong');
  print('✅ SharedPreferences cleared successfully');
}

// ✅ Save Selected Address Function
Future<void> saveSelectedAddress({
  required WidgetRef ref,
  required SharedPreferences prefs,
  required String address,
  required String name,
  required String type,
  required String landmark,
  required String instructions,
  required double latitude,
  required double longitude,
  required double distance,
}) async {
  await prefs.setString('selectedRoad', address);
  await prefs.setString('selectedType', type);
  await prefs.setString('selectedName', name);
  await prefs.setString('selectedLandmark', landmark);
  await prefs.setString('selectedInstruction', instructions);
  await prefs.setDouble('selectedLatitude', latitude);
  await prefs.setDouble('selectedLongitude', longitude);
  await prefs.setDouble('selectedDistance', distance);

  ref.read(selectedLocationProvider.notifier).state = address;
  ref.read(customerNameProvider.notifier).state = name;

  print("✅ Address saved: $name, $address");
}

// ✅ Check If Phone Number Exists
Future<bool> checkPhoneNumber() async {
  final prefs = await SharedPreferences.getInstance();
  final phoneNumber = prefs.getString('phoneNumber');
  return phoneNumber != null;
}

// ✅ Format Address Using Geocoding
Future<String?> formatAddress(Position? position) async {
  if (position == null) return null;
  try {
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    if (placemarks.isNotEmpty) {
      Placemark place = placemarks[0];
      return "${place.street}";
    } else {
      return "Address not found";
    }
  } on PlatformException catch (e) {
    print('Error in reverse geocoding: $e');
    return "Error getting address";
  } catch (e) {
    print('Error in formatAddress: $e');
    return "Error getting address";
  }
}