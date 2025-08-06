import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:kealthy/view/Cart/address_model.dart';
import 'package:kealthy/view/Cart/cart_controller.dart';

import 'package:ntp/ntp.dart';
import 'package:shared_preferences/shared_preferences.dart';

final isInstantDeliverySelectedProvider = StateProvider<bool>((ref) => false);
final allProductsStreamProvider = StreamProvider.autoDispose((ref) {
  return FirebaseFirestore.instance
      .collection('Products')
      .where('SOH', isGreaterThan: 0)
      .snapshots();
});

final categoryStreamProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final firestore = FirebaseFirestore.instance;
  await for (final snapshot
      in firestore.collection('categories').orderBy('Categories').snapshots()) {
    final categories = snapshot.docs.map((doc) {
      return {
        'Categories': doc.data()['Categories'],
        'image': doc.data()['imageurl'],
      };
    }).toList();
    yield categories;
  }
});

final addressProvider = FutureProvider.autoDispose<Address?>((ref) async {
  final prefs = await SharedPreferences.getInstance();

  // Fetch cart items
  final cartItems = ref.watch(cartProvider);

  // Retrieve and print all relevant values for debugging
  final fetchedSlot = prefs.getString('selected_slot') ?? '';
  final fetchedType = prefs.getString('selectedType') ?? '';
  final fetchedName = prefs.getString('selectedName') ?? '';
  final fetchedLandmark = prefs.getString('selectedLandmark') ?? '';
  final fetchedInstruction = prefs.getString('selectedInstruction') ?? '';
  final fetchedRoad = prefs.getString('selectedRoad') ?? '';

  // Numeric values
  final fetchedDistance = prefs.getDouble('selectedDistance') ?? 0.0;
  final fetchedSelectedDistance = prefs.getDouble('selectedDistance') ?? 0.0;
  final fetchedSelectedLatitude = prefs.getDouble('selectedLatitude') ?? 0.0;
  final fetchedSelectedLongitude = prefs.getDouble('selectedLongitude') ?? 0.0;

  // Debug
  print('--- Fetched Address Data ---');
  print('Slot: $fetchedSlot');
  print('Type: $fetchedType');
  print('Name: $fetchedName');
  print('Landmark: $fetchedLandmark');
  print('Instruction: $fetchedInstruction');
  print('Road: $fetchedRoad');
  print('Distance: $fetchedDistance km');
  print('Selected Distance: $fetchedSelectedDistance km');
  print('Selected Latitude: $fetchedSelectedLatitude');
  print('Selected Longitude: $fetchedSelectedLongitude');
  print('Selected Road: $fetchedRoad');
  print('Selected Instruction: $fetchedInstruction');
  print('-----------------------------');

  return Address(
    slot: fetchedSlot,
    type: fetchedType,
    name: fetchedName,
    landmark: fetchedLandmark,
    instruction: fetchedInstruction,
    distance: fetchedDistance.toString(),
    cartItems: cartItems,
    selectedDistance: fetchedSelectedDistance,
    selectedLatitude: fetchedSelectedLatitude,
    selectedLongitude: fetchedSelectedLongitude,
    selectedRoad: fetchedRoad,
    selectedInstruction: fetchedInstruction,
  );
});

Future<String> calculateEstimatedDeliveryTime() async {
  try {
    final prefs = await SharedPreferences.getInstance();

    // Safely fetch and parse latitude and longitude
    double? latitude = prefs.getDouble('selectedLat') ??
        double.tryParse(prefs.getString('selectedLatitude') ?? '');
    double? longitude = prefs.getDouble('selectedLong') ??
        double.tryParse(prefs.getString('selectedLongitude') ?? '');

    // Constants for restaurant location and delivery calculation
    const restaurantLatitude = 10.010279427438405;
    const restaurantLongitude = 76.38426666931349;
    const cookingTimeMinutes = 15;
    const averageSpeedMetersPerSecond = 11.11;

    // Calculate the distance
    double distanceInMeters = Geolocator.distanceBetween(
      restaurantLatitude,
      restaurantLongitude,
      latitude!,
      longitude!,
    );

    // Calculate travel time in minutes
    double travelTimeMinutes =
        (distanceInMeters / averageSpeedMetersPerSecond) / 60;

    // Total estimated time
    int totalTimeMinutes = cookingTimeMinutes + travelTimeMinutes.round();

    // Fetch the current time
    DateTime currentTime;
    try {
      currentTime = await NTP.now();
    } catch (e) {
      print("Error fetching NTP time: $e");
      currentTime = DateTime.now();
    }

    DateTime estimatedDeliveryTime =
        currentTime.add(Duration(minutes: totalTimeMinutes));

    // Format the estimated delivery time
    String formattedTime = DateFormat('hh:mm a').format(estimatedDeliveryTime);

    // Save estimated time in shared preferences
    prefs.setString('estimated_delivery_time', formattedTime);

    return "$formattedTime ($totalTimeMinutes min)";
  } catch (e) {
    print("Error in calculating delivery time: $e");
    return "Error calculating delivery time.";
  }
}
