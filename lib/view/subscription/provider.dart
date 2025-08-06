import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy/view/subscription/model.dart';

final quantityProvider = StateProvider.family<int, String>((ref, title) => 1);

final fromDateProvider = StateProvider<DateTime?>((ref) => null);
final selectedSlotProvider =
    StateProvider<Map<String, DateTime>?>((ref) => null);
final isSlotExpandedProvider = StateProvider<bool>((ref) => false);

// Future<bool> isSlotAvailable(String selectedSlotLabel) async {
//   final databaseRef = FirebaseDatabase.instanceFor(
//     app: FirebaseDatabase.instance.app,
//     databaseURL: 'https://kealthy-90c55-dd236.firebaseio.com/',
//   ).ref().child('orders');

//   final snapshot = await databaseRef
//       .orderByChild('selectedSlot')
//       .equalTo(selectedSlotLabel)
//       .get();

//   final existingOrders = snapshot.children.length;
//   return existingOrders < 10;
// }

Future<void> pickDate(BuildContext context, WidgetRef ref,
    {required bool isFrom}) async {
  final DateTime now = DateTime.now();
  final DateTime tomorrow = now.add(const Duration(days: 1));

  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: tomorrow,
    firstDate: tomorrow,
    lastDate: now.add(const Duration(days: 365)),
    builder: (context, child) => Theme(
      data: ThemeData.light(), // Optional: customize theme
      child: child!,
    ),
  );

  if (picked != null) {
    ref.read(fromDateProvider.notifier).state = picked;
  }
}

final subscriptionPlansProvider =
    FutureProvider<List<SubscriptionPlan>>((ref) async {
  final snapshot =
      await FirebaseFirestore.instance.collection('SubscriptionPlans').get();

  return snapshot.docs
      .map((doc) => SubscriptionPlan.fromFirestore(doc.data()))
      .toList();
});
