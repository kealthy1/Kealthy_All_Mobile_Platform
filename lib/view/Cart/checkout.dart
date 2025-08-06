import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/Cart/bill.dart';
import 'package:kealthy/view/Cart/cart_controller.dart';
import 'package:kealthy/view/Cart/checkout_provider.dart';
import 'package:kealthy/view/Cart/instruction_container.dart';
import 'package:kealthy/view/food/food_subcategory.dart';
import 'package:kealthy/view/payment/payment.dart';

final isProceedingToPaymentProvider = StateProvider<bool>((ref) => false);

// Asynchronous Provider for Address

// Checkout Page
class CheckoutPage extends ConsumerStatefulWidget {
  final String preferredTime;
  final double itemTotal;
  final List<CartItem> cartItems;
  final String deliveryTime;

  const CheckoutPage({
    super.key,
    required this.itemTotal,
    required this.cartItems,
    required this.deliveryTime,
    required this.preferredTime,
  });

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final TextEditingController packingInstructionsController =
      TextEditingController();

  @override
  void dispose() {
    packingInstructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firstOrderAsync = ref.watch(firstOrderProvider);

    double finalToPay = 0.0;
    // Watch the addressProvider
    ref.watch(addressProvider);
    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          surfaceTintColor: Colors.white,
          backgroundColor: Colors.white,
          title: Text(
            "Checkout",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 17),
          child: firstOrderAsync.when(
            loading: () => const Center(
              child: CupertinoActivityIndicator(color: Color(0xFF273847)),
            ),
            error: (e, _) => Center(
              child: Text(
                "Error loading offer status: $e",
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.red),
              ),
            ),
            data: (isFirstOrder) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Address',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ref.watch(addressProvider).when(
                          loading: () => const Center(
                            child: CupertinoActivityIndicator(
                              color: Color(0xFF273847),
                            ),
                          ),
                          error: (e, _) => Text(
                            "Error loading address: $e",
                            style: GoogleFonts.poppins(
                                fontSize: 14, color: Colors.red),
                          ),
                          data: (selectedAddress) {
                            if (selectedAddress == null) {
                              return Text(
                                "No address selected",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              );
                            }

                            final double distanceInKm =
                                double.tryParse(selectedAddress.distance) ??
                                    0.0;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Address Card
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 5),
                                  child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withOpacity(0.2),
                                          spreadRadius: 2,
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(15.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            selectedAddress.type,
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            "${selectedAddress.name} , ${selectedAddress.selectedRoad}",
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.poppins(
                                              color: Colors.black,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            '${selectedAddress.distance} km',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(height: 5),
                                          Text(
                                            'Delivery Time: ${widget.deliveryTime}',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Packing Instructions
                                Text(
                                  'Packing Instructions',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8.0),
                                      border: Border.all(
                                          color: Colors.grey.shade300),
                                    ),
                                    child: TextField(
                                      controller: packingInstructionsController,
                                      maxLines: 3,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.black,
                                      ),
                                      cursorColor: Colors.black,
                                      decoration: InputDecoration(
                                        hintText:
                                            "Don't send cutleries, tissues, straws, etc.",
                                        hintStyle: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 15,
                                          vertical: 10,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Delivery Instructions
                                Text(
                                  'Delivery Instructions',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: 5,
                                      horizontal: 3,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        InstructionContainer(
                                          icon:
                                              Icons.notifications_off_outlined,
                                          label: "Avoid Ringing Bell",
                                          id: 1,
                                        ),
                                        SizedBox(width: 10),
                                        InstructionContainer(
                                          icon: Icons.door_front_door_outlined,
                                          label: "Leave at Door",
                                          id: 2,
                                        ),
                                        SizedBox(width: 10),
                                        InstructionContainer(
                                          icon: Icons.person_outlined,
                                          label: "Leave with Guard",
                                          id: 3,
                                        ),
                                        SizedBox(width: 10),
                                        InstructionContainer(
                                          icon: Icons.phone_disabled_outlined,
                                          label: "Avoid Calling",
                                          id: 4,
                                        ),
                                        SizedBox(width: 10),
                                        InstructionContainer(
                                          icon: Icons.pets_outlined,
                                          label: "Pet at home",
                                          id: 5,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 10),
                                if (isFirstOrder)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                          color: Colors.green.shade400),
                                    ),
                                    child: Row(
                                      children: [
                                        const Text(
                                          '🎉',
                                          style: TextStyle(fontSize: 25),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            "Congratulations! You get ₹${widget.itemTotal >= 50 ? 50 : widget.itemTotal.toStringAsFixed(0)} off on your first order.",
                                            style: GoogleFonts.poppins(
                                              color: Colors.green.shade800,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Offer section

                                const SizedBox(height: 15),

                                // Final bill
                                BillDetailsWidget(
                                  itemTotal: widget.itemTotal,
                                  distanceInKm: distanceInKm,
                                  offerDiscount: isFirstOrder
                                      ? (widget.itemTotal >= 50
                                          ? 50.0
                                          : widget.itemTotal)
                                      : 0.0,
                                  onTotalCalculated: (value) {
                                    finalToPay = value;
                                  },
                                ),

                                const SizedBox(height: 150),
                              ],
                            );
                          },
                        ),
                  ],
                ),
              );
            },
          ),
        ),
        bottomSheet: Consumer(
          builder: (context, ref, _) {
            final isProceeding = ref.watch(isProceedingToPaymentProvider);

            // Collect all trial dishes from all types in the cart
            final cartTypes = widget.cartItems.map((item) => item.type).toSet();
            final trialDishesByType = {
              for (var type in cartTypes) type: ref.watch(dishesProvider(type)),
            };

            final isAnyLoading = trialDishesByType.values
                .any((asyncValue) => asyncValue is AsyncLoading);

            // final allTrialDishes = trialDishesByType.values
            //     .whereType<AsyncData<List<TrialDish>>>()
            //     .expand((async) => async.value)
            //     .toList();

            // final trialDishNames = allTrialDishes.map((d) => d.name).toSet();

            // final containsTrial = widget.cartItems
            //     .any((item) => trialDishNames.contains(item.name));

            return Container(
              width: double.infinity,
              height: 90,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 65, 88, 108),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: isAnyLoading || isProceeding
                    ? null
                    : () async {
                        final currentCartItems = ref.read(cartProvider);
                        if (currentCartItems.isEmpty) return;

                        ref.read(isProceedingToPaymentProvider.notifier).state =
                            true;

                        // final initialPaymentMethod = containsTrial
                        //     ? 'Online Payment'
                        //     : 'Cash on Delivery';

                        final instructions = getSelectedInstructions(ref);
                        final packingInstructions =
                            packingInstructionsController.text;

                        final selectedAddress =
                            await ref.read(addressProvider.future);

                        if (selectedAddress != null) {
                          final double distanceInKm =
                              double.tryParse(selectedAddress.distance) ?? 0.0;

                          final double normalDeliveryFee = calculateDeliveryFee(
                              widget.itemTotal, distanceInKm);

                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => PaymentPage(
                                preferredTime: widget.preferredTime,
                                totalAmount: finalToPay,
                                instructions: instructions,
                                address: selectedAddress,
                                deliverytime: widget.deliveryTime,
                                packingInstructions: packingInstructions,
                                deliveryfee: normalDeliveryFee,
                                initialPaymentMethod: '',
                              ),
                            ),
                          );
                        }

                        ref.read(isProceedingToPaymentProvider.notifier).state =
                            false;
                      },
                child: isProceeding
                    ? const CupertinoActivityIndicator(color: Colors.white)
                    : Text(
                        'Proceed to Payment',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}
