import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/Cart/checkout_provider.dart';
import 'package:kealthy/view/address/adress.dart';
import 'package:kealthy/view/subscription/dietType.dart';
import 'package:kealthy/view/subscription/lunch_sub_payment.dart';

class MealsSubConfirmationPage extends ConsumerWidget {
  final String title;
  final String description;
  final double baseRate;
  final int durationDays;
  final String productName;
  final DietType dietType; // Added to explicitly pass diet type
  final bool isTwoMeals; // Added to determine selectedQty

  const MealsSubConfirmationPage({
    super.key,
    required this.title,
    required this.description,
    required this.baseRate,
    required this.durationDays,
    required this.productName,
    required this.dietType,
    required this.isTwoMeals,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Pricing logic
    const int handlingChargePerDay = 5;
    final int handlingCharge = handlingChargePerDay * durationDays;
    final int selectedQty = isTwoMeals ? 2 : 1; // Derive from isTwoMeals
    final double totalAmount = (dietType == DietType.veg
            ? (durationDays == 30 ? 6000.0 : 3000.0)
            : (durationDays == 30 ? 7500.0 : 4000.0)) *
        selectedQty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Confirm Subscription"),
        surfaceTintColor: Colors.white,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title,
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                const Row(
                                  children: [
                                    Icon(Icons.local_shipping_outlined,
                                        size: 16, color: Colors.green),
                                    SizedBox(width: 4),
                                    Text(
                                      'Free Delivery',
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.green),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'lib/assets/images/kitchen logo5.png',
                                height: 64,
                                width: 64,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Consumer(
                        builder: (context, ref, _) {
                          final addressAsyncValue = ref.watch(addressProvider);

                          return addressAsyncValue.when(
                            loading: () => const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.black),
                            ),
                            error: (error, stackTrace) => const Center(
                              child: Text(
                                "Failed to load address.",
                                style: TextStyle(
                                    color: Colors.black, fontSize: 16),
                              ),
                            ),
                            data: (selectedAddress) {
                              if (selectedAddress == null ||
                                  selectedAddress.name == null ||
                                  selectedAddress.selectedRoad.isEmpty) {
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.15),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: GestureDetector(
                                    onTap: () async {
                                      final result =
                                          await Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const AddressPage(),
                                        ),
                                      );
                                      if (result == true) {
                                        ref.invalidate(addressProvider);
                                      }
                                    },
                                    child: Row(
                                      children: [
                                        const Icon(Icons.add,
                                            color: Color.fromARGB(
                                                255, 65, 88, 108)),
                                        const SizedBox(width: 12.0),
                                        Text('Select address',
                                            style: GoogleFonts.poppins(
                                                color: Colors.black,
                                                fontWeight: FontWeight.w500)),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              return Container(
                                padding: const EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 5,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
                                      const Text(
                                        'Delivery',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () async {
                                          final result =
                                              await Navigator.pushReplacement(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const AddressPage(),
                                            ),
                                          );
                                          if (result == true) {
                                            ref.invalidate(addressProvider);
                                          }
                                        },
                                        child: const Text(
                                          'Change',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ]),
                                    Text(
                                      selectedAddress.selectedRoad ?? 'Unknown',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "${selectedAddress.name}, ${selectedAddress.selectedRoad.isEmpty ? '' : '${selectedAddress.selectedRoad}, '}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text("Total Amount :",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  Text("₹${(totalAmount - handlingCharge).toStringAsFixed(0)}",
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text("Handling Charge : ₹5 x $durationDays Days",
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black54)),
                  const Spacer(),
                  Text("₹${handlingCharge.toStringAsFixed(0)}",
                      style:
                          const TextStyle(fontSize: 14, color: Colors.black54)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Text("To Pay :",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Text("₹${totalAmount.toStringAsFixed(0)}",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 65, 88, 108),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final address = ref.read(addressProvider).asData?.value;
                    if (address == null ||
                        address.name.isEmpty ||
                        address.selectedRoad.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Please select or add a delivery address.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MealsSubPaymentPage(
                          title: title,
                          quantity: selectedQty,
                          address: address,
                          baseRate: baseRate,
                          handlingCharge: handlingCharge,
                          totalAmount: totalAmount,
                          productName: productName,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text("Confirm Subscription"),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
