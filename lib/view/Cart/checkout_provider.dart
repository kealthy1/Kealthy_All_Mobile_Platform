import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy/view/Cart/address_model.dart';
import 'package:kealthy/view/Cart/cart_controller.dart';
import 'package:kealthy/view/Cart/instruction_container.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'package:intl/intl.dart';

// --- ETA domain model ---
class EtaInfo {
  final int prepMinutes;
  final int travelMinutes;
  final double distanceKm;
  final double speedKmph;
  final DateTime readyAt;
  final DateTime eta;

  const EtaInfo({
    required this.prepMinutes,
    required this.travelMinutes,
    required this.distanceKm,
    required this.speedKmph,
    required this.readyAt,
    required this.eta,
  });
}

// Round minutes up to nearest 5
int _roundUp5(int m) => ((m + 4) ~/ 5) * 5;

// Optional: compute km from coordinates if you have them
double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371.0; // Earth radius (km)
  double dLat = _deg2rad(lat2 - lat1);
  double dLon = _deg2rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_deg2rad(lat1)) *
          math.cos(_deg2rad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return R * c;
}

double _deg2rad(double d) => d * math.pi / 180.0;

EtaInfo computeEta({
  double? distanceKm, // pass this if you already have distance
  double? fromLat, // or provide coordinates to compute distance
  double? fromLng,
  double? toLat,
  double? toLng,
  DateTime? clock,
  int prepMinutes = 30, // your fixed prep time
  double defaultSpeedKmph = 22, // average urban delivery speed
}) {
  final now = (clock ?? DateTime.now()).toLocal();

  double km = distanceKm ?? 0.0;
  if (km <= 0 &&
      fromLat != null &&
      fromLng != null &&
      toLat != null &&
      toLng != null) {
    km = _haversineKm(fromLat, fromLng, toLat, toLng);
  }
  // Guard against negative/no data
  km = km.isNaN || km.isInfinite ? 0.0 : math.max(0.0, km);

  // You can get fancy with a dynamic speed model; start simple:
  final speed = defaultSpeedKmph;

  final travelRawMin = (km / speed) * 60.0; // minutes
  final travelMinutes = km <= 0 ? 0 : _roundUp5(travelRawMin.ceil());

  final readyAt = now.add(Duration(minutes: prepMinutes));
  final eta = readyAt.add(Duration(minutes: travelMinutes));

  return EtaInfo(
    prepMinutes: prepMinutes,
    travelMinutes: travelMinutes,
    distanceKm: km,
    speedKmph: speed,
    readyAt: readyAt,
    eta: eta,
  );
}

// Optional Riverpod helper: give it a distance (km) and get EtaInfo
// Use like: ref.watch(etaInfoProvider(distanceKm))
final etaInfoProvider = Provider.family<EtaInfo, double?>((ref, distanceKm) {
  return computeEta(distanceKm: distanceKm);
});

// If you store restaurant and user coordinates, you can add a second family provider:
class LatLng {
  final double lat, lng;
  const LatLng(this.lat, this.lng);
}

final etaFromCoordsProvider =
    Provider.family<EtaInfo, ({LatLng from, LatLng to})>((ref, p) {
  return computeEta(
      fromLat: p.from.lat,
      fromLng: p.from.lng,
      toLat: p.to.lat,
      toLng: p.to.lng);
});

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
  // Fetch cart items
  final cartItems = ref.watch(cartProvider);

  final prefs = await SharedPreferences.getInstance();
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
