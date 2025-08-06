import 'package:kealthy/view/Cart/cart_controller.dart';

class Address {
  final String slot;
  final String type;
  final String name;
  final String landmark;
  final String instruction;
  final String distance;
  final List<CartItem> cartItems; // Ensure cart items exist
  final double selectedDistance;
  final double? selectedLatitude;
  final double? selectedLongitude;
  final String selectedRoad;
  final String selectedInstruction;

  Address({
    required this.slot,
    required this.type,
    required this.name,
    required this.landmark,
    required this.instruction,
    required this.distance,
    required this.cartItems,
    required this.selectedDistance,
    required this.selectedLatitude,
    required this.selectedLongitude,
    required this.selectedRoad,
    required this.selectedInstruction,
  });
}
