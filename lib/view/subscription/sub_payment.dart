import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:kealthy/view/payment/Online_payment.dart';
import 'package:kealthy/view/payment/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final subscriptionLoadingProvider = StateProvider<bool>((ref) => false);

class SubscriptionPaymentPage extends ConsumerWidget {
  final String title;
  final DateTime startDate;
  final String endDate;
  final int quantity;
  final Map<String, DateTime> slot;
  final dynamic address;
  final double totalAmount;
  final String productName;
  final bool isAlternateDay;
  final double baseRate;
  final int handlingCharge; // Added handling charge parameter

  const SubscriptionPaymentPage(
      {super.key,
      required this.title,
      required this.startDate,
      required this.endDate,
      required this.quantity,
      required this.slot,
      required this.address,
      required this.totalAmount,
      required this.productName,
      required this.isAlternateDay,
      required this.baseRate,
      required this.handlingCharge,
      x});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        title: const Text("Make Payment"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Review Your Subscription",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text("Plan: $title"),
                  Text("Product: $productName"),
                  Text("Base price: ${baseRate.toStringAsFixed(0)}/-"),
                  Text(
                      "Start Date: ${DateFormat('MMMM d, y').format(startDate)}"),
                  Text("End Date: $endDate"),
                  Text("Quantity: $quantity L"),
                  Text(
                      "Handling Charge: ₹${handlingCharge.toStringAsFixed(0)}"),
                  const SizedBox(height: 12),
                  const Text("Delivery Slot",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                      "${DateFormat('h:mm a').format(slot['start']!)} - ${DateFormat('h:mm a').format(slot['end']!)}"),
                  const SizedBox(height: 12),
                  const Text("Delivery Address",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(address.type),
                  Text("${address.name}, ${address.selectedRoad}"),
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                const Text("To Pay : ",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                Text("₹${totalAmount.toStringAsFixed(0)}",
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 65, 88, 108),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final isLoading = ref.read(subscriptionLoadingProvider);
                  if (isLoading) return;
                  ref.read(subscriptionLoadingProvider.notifier).state = true;

                  print('Subscription Payment Details:');
                  print('Title: $title');
                  print('Product Name: $productName');
                  print(
                      'Start Date: ${DateFormat('yyyy-MM-dd').format(startDate)}');
                  print('End Date: $endDate');
                  print('Quantity: $quantity');
                  print('Slot: ${slot['start']} - ${slot['end']}');
                  print(
                      'Address: ${address.name}, ${address.selectedRoad}, Type: ${address.type}');
                  print('Total Amount: $totalAmount');
                  print('Alternate Day Preference: $isAlternateDay');

                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('subscription_plan_title', title);
                  await prefs.setString(
                      'subscription_product_name', productName);
                  await prefs.setString('subscription_start_date',
                      DateFormat('d MMMM y').format(startDate));
                  await prefs.setString('subscription_end_date', endDate);
                  await prefs.setDouble(
                      'subscription_qty', quantity.toDouble());
                  await prefs.setBool('subscription_type', isAlternateDay);
                  await prefs.setDouble('sub_baseRate', baseRate);
                  await prefs.setInt('sub_handlingFee', handlingCharge);

                  final formattedSlot =
                      '${DateFormat('h:mm a').format(slot['start']!)} - ${DateFormat('h:mm a').format(slot['end']!)}';
                  await prefs.setString(
                      'subscription_delivery_slot', formattedSlot);

                  final razorpayOrderId =
                      await OrderService.createRazorpayOrder(
                          totalAmount: totalAmount,
                          address: address,
                          packingInstructions: '',
                          deliveryInstructions: '',
                          deliveryTime: '',
                          preferredTime: '',
                          isSubscription: true,
                          deliveryFee: 0);
                  print(formattedSlot);

                  ref.read(subscriptionLoadingProvider.notifier).state = false;

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OnlinePaymentProcessing(
                        preferredTime: '',
                        // offerDiscount: 0,
                        totalAmount: totalAmount,
                        packingInstructions: '',
                        deliveryInstructions: '',
                        address: address,
                        deliverytime: formattedSlot,
                        deliveryFee: 0,
                        // instantDeliveryFee: 0,
                        razorpayOrderId: razorpayOrderId,
                        orderType: 'subscription',
                      ),
                    ),
                  );
                },
                child: ref.watch(subscriptionLoadingProvider)
                    ? const CupertinoActivityIndicator(
                        radius: 12.0,
                        color: Colors.white,
                      )
                    : const Text("Proceed to Payment"),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
