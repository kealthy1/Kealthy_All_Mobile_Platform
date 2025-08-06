import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy/view/Cart/address_model.dart';
import 'package:kealthy/view/Cart/cart_controller.dart';
import 'package:kealthy/view/Cart/instruction_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

double calculateDeliveryFee(double itemTotal, double distanceInKm) {
  double deliveryFee = 0;

  if (itemTotal >= 199) {
    if (distanceInKm <= 7) {
      deliveryFee = 0;
    } else {
      deliveryFee = 8 * (distanceInKm - 7);
    }
  } else {
    if (distanceInKm <= 7) {
      deliveryFee = 50;
    } else {
      deliveryFee = 50 + 10 * (distanceInKm - 7);
    }
  }

  return deliveryFee.roundToDouble();
}

final finalTotalProvider = StateProvider<double>((ref) => 0.0);

final firstOrderProvider = AsyncNotifierProvider<FirstOrderNotifier, bool>(() {
  return FirstOrderNotifier();
});

class FirstOrderNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    return false;
  }

  Future<void> checkFirstOrder(String phoneNumber) async {
    state = const AsyncLoading();

    bool hasOrderFromApi = false;
    bool hasOrderFromRealtime = false;

    // 1. Check API
    try {
      final url =
          Uri.parse('https://api-jfnhkjk4nq-uc.a.run.app/orders/$phoneNumber');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        hasOrderFromApi = data.isNotEmpty;
      } else if (response.statusCode == 404) {
        hasOrderFromApi = false;
      } else {
        hasOrderFromApi = true; // assume order exists on error
      }
    } catch (e) {
      print('API check failed: $e');
      hasOrderFromApi = true; // assume error means order exists
    }

    try {
      final database = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: 'https://kealthy-90c55-dd236.firebaseio.com/',
      );
      final ordersSnapshot = await database
          .ref('orders')
          .orderByChild('phoneNumber')
          .equalTo(phoneNumber)
          .get();

      hasOrderFromRealtime = ordersSnapshot.exists;
    } catch (e) {
      print('Realtime DB check failed: $e');
      hasOrderFromRealtime = true; // assume error means order exists
    }

    // 3. Result
    final isFirstOrder = !(hasOrderFromApi || hasOrderFromRealtime);
    state = AsyncData(isFirstOrder);
  }
}

double calculateFinalTotal(
  double itemTotal,
  double distanceInKm,
) {
  double handlingFee = 5;
  double deliveryFee = calculateDeliveryFee(itemTotal, distanceInKm);

  double totalDeliveryFee = deliveryFee;

  double finalTotal = itemTotal + totalDeliveryFee + handlingFee;

  return finalTotal.roundToDouble();
}

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

String getSelectedInstructions(WidgetRef ref) {
  List<String> instructions = [];

  if (ref.watch(selectionProvider(1))) {
    instructions.add("Avoid Ringing Bell");
  }
  if (ref.watch(selectionProvider(2))) {
    instructions.add("Leave at Door");
  }
  if (ref.watch(selectionProvider(3))) {
    instructions.add("Leave with Guard");
  }
  if (ref.watch(selectionProvider(4))) {
    instructions.add("Avoid Calling");
  }
  if (ref.watch(selectionProvider(5))) {
    instructions.add("Pet at home");
  }

  print("Selected Instruction States:");
  print("Avoid Ringing Bell: ${ref.watch(selectionProvider(1))}");
  print("Leave at Door: ${ref.watch(selectionProvider(2))}");
  print("Leave with Guard: ${ref.watch(selectionProvider(3))}");
  print("Avoid Calling: ${ref.watch(selectionProvider(4))}");
  print("Final Selected Delivery Instructions: $instructions");

  return instructions.join(", ");
}
