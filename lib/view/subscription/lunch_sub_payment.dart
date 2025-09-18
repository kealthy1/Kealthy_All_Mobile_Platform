import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:kealthy/view/Cart/cart_controller.dart';
import 'package:kealthy/view/food/food_subcategory.dart';
import 'package:kealthy/view/payment/Online_payment.dart';
import 'package:kealthy/view/payment/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final subscriptionLoadingProvider = StateProvider<bool>((ref) => false);

class MealsSubPaymentPage extends ConsumerWidget {
  final String title;
  final int quantity;
  final dynamic address;
  final double totalAmount;
  final String productName;
  final double baseRate;
  final int handlingCharge;

  const MealsSubPaymentPage({
    super.key,
    required this.title,
    required this.quantity,
    required this.address,
    required this.totalAmount,
    required this.productName,
    required this.baseRate,
    required this.handlingCharge,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        title: const Text("Make Subscription Payment"),
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
                  Text("Base price: ₹${baseRate.toStringAsFixed(0)}/day"),
                  Text("Quantity: $quantity"),
                  Text(
                      "Handling Charge: ₹${handlingCharge.toStringAsFixed(0)}"),
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
            SafeArea(
              child: SizedBox(
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

                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('subscription_plan_title', title);
                    await prefs.setString(
                        'subscription_product_name', productName);
                    await prefs.setDouble(
                        'subscription_qty', quantity.toDouble());
                    await prefs.setDouble('sub_baseRate', baseRate);
                    await prefs.setInt('sub_handlingFee', handlingCharge);
                    final cartItems = ref.read(cartProvider);
                    final cartTypes =
                        cartItems.map((item) => item.type).toSet();
                    final trialDishesByType = {
                      for (var type in cartTypes)
                        type: ref.read(dishesProvider(type)),
                    };

                    final allTrialDishes = trialDishesByType.values
                        .whereType<AsyncData<List<TrialDish>>>()
                        .expand((async) => async.value)
                        .toList();
                    final trialcategory =
                        allTrialDishes.map((d) => d.category).toList();
                    final razorpayOrderId =
                        await OrderService.createRazorpayOrder(
                      category: trialcategory.isNotEmpty
                          ? trialcategory.first
                          : 'Unknown',
                      totalAmount: totalAmount,
                      address: address,
                      packingInstructions: '',
                      deliveryInstructions: '',
                      deliveryTime: '',
                      preferredTime: '',
                      isSubscription: true,
                      deliveryFee: 0,
                    );

                    ref.read(subscriptionLoadingProvider.notifier).state =
                        false;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OnlinePaymentProcessing(
                          preferredTime: '',
                          totalAmount: totalAmount,
                          packingInstructions: '',
                          deliveryInstructions: '',
                          address: address,
                          deliverytime: '',
                          deliveryFee: 0,
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
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
