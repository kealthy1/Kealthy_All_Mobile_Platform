import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart'; // <-- NEW
import 'package:kealthy/view/Cart/cart_controller.dart';
import 'package:kealthy/view/Cart/checkout.dart';
import 'package:kealthy/view/Cart/checkout_provider.dart';
import 'package:kealthy/view/Cart/slot.dart';
import 'package:kealthy/view/Cart/time_provider.dart';
import 'package:kealthy/view/Toast/toast_helper.dart';
import 'package:kealthy/view/address/adress.dart';
// import 'package:kealthy_food/view/Cart/cart.dart';
// import 'package:kealthy_food/view/home/title.dart';
import 'package:ntp/ntp.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimePage extends ConsumerStatefulWidget {
  const TimePage({super.key});

  @override
  ConsumerState<TimePage> createState() => _TimePageState();
}

class _TimePageState extends ConsumerState<TimePage> {
  late TextEditingController preferredTimeController;
  @override
  void initState() {
    super.initState();
    checkTimeBoundaries(ref);
    preferredTimeController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('phoneNumber') ?? '';
      final firstOrderNotifier = ref.read(firstOrderProvider.notifier);
      await firstOrderNotifier.checkFirstOrder(phone);
    });
  }

  @override
  void dispose() {
    preferredTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final isInstantDeliveryVisible =
    //     ref.watch(isInstantDeliveryVisibleProvider);
    // final isInstantDeliverySelected =
    //     ref.watch(isInstantDeliverySelectedProvider);
    // final isSlotContainerVisible = ref.watch(isSlotContainerVisibleProvider);
    final addressAsyncValue = ref.watch(addressProvider);
    final isLoading = ref.watch(timePageLoaderProvider);
    final loaderNotifier = ref.read(timePageLoaderProvider.notifier);

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          surfaceTintColor: Colors.white,
          backgroundColor: Colors.white,
          title: Text(
            'Select Delivery Time',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 18,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Address Container
                addressAsyncValue.when(
                  loading: () => const Center(
                      child: CupertinoActivityIndicator(
                    color: Colors.black,
                  )),
                  error: (error, stackTrace) => Center(
                    child: Text(
                      "Failed to load address.",
                      style: GoogleFonts.poppins(
                          color: Colors.black, fontSize: 16),
                    ),
                  ),
                  data: (selectedAddress) {
                    if (selectedAddress == null) {
                      return Center(
                        child: Text(
                          "No address selected.",
                          style: GoogleFonts.poppins(color: Colors.black),
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
                          Row(
                            children: [
                              Text(
                                'Delivery',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () async {
                                  final result =
                                      await Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddressPage(),
                                    ),
                                  );
                                  if (result == true) {
                                    ref.invalidate(addressProvider);
                                  }
                                },
                                child: Text(
                                  'Change',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            selectedAddress.type,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            "${selectedAddress.name}, ${selectedAddress.selectedRoad}",
                            style: GoogleFonts.poppins(
                                fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Padding(
                //   padding: const EdgeInsets.symmetric(horizontal: 8),
                //   child: Text(
                //     'Select Delivery Time',
                //     style: GoogleFonts.poppins(
                //       fontWeight: FontWeight.w500,
                //       color: Colors.black,
                //       fontSize: 16,
                //     ),
                //   ),
                // ),
                // const SizedBox(height: 10),

                // Instant Delivery Container
                // AnimatedSwitcher(
                //   duration: const Duration(milliseconds: 300),
                //   child: isInstantDeliveryVisible
                //       ? FutureBuilder<String>(
                //           future: calculateEstimatedDeliveryTime(),
                //           builder: (context, snapshot) {
                //             return Container(
                //               decoration: BoxDecoration(
                //                 color: Colors.white,
                //                 borderRadius: BorderRadius.circular(10),
                //                 boxShadow: [
                //                   BoxShadow(
                //                     color: Colors.grey.withOpacity(0.2),
                //                     blurRadius: 5,
                //                     spreadRadius: 1,
                //                     offset: const Offset(0, 1),
                //                   ),
                //                 ],
                //               ),
                //               child: Row(
                //                 mainAxisAlignment: MainAxisAlignment.spaceAround,
                //                 children: [
                //                   Expanded(
                //                     child: Padding(
                //                       padding: const EdgeInsets.all(15.0),
                //                       child: Column(
                //                         crossAxisAlignment:
                //                             CrossAxisAlignment.start,
                //                         children: [
                //                           Row(
                //                             children: [
                //                               Text(
                //                                 "Instant Delivery",
                //                                 style: GoogleFonts.poppins(
                //                                   fontSize: 18,
                //                                   fontWeight: FontWeight.w500,
                //                                   color: Colors.black,
                //                                 ),
                //                               ),
                //                               const SizedBox(width: 5),
                //                               const Icon(
                //                                 Icons.flash_on,
                //                                 color: Colors.amber,
                //                               ),
                //                             ],
                //                           ),
                //                           Text(
                //                             snapshot.connectionState ==
                //                                     ConnectionState.waiting
                //                                 ? 'Loading..'
                //                                 : "Estimated Delivery Time: ${snapshot.data}",
                //                             style: GoogleFonts.poppins(
                //                               fontSize: 10,
                //                               fontWeight: FontWeight.w500,
                //                               color: Colors.black87,
                //                             ),
                //                           ),
                //                         ],
                //                       ),
                //                     ),
                //                   ),
                //                   Text(
                //                     '₹50',
                //                     style: GoogleFonts.poppins(
                //                       color: Colors.black,
                //                       fontSize: 12,
                //                       fontWeight: FontWeight.w500,
                //                     ),
                //                   ),
                //                   Checkbox(
                //                     value: isInstantDeliverySelected,
                //                     onChanged: (value) {
                //                       ref
                //                           .read(isInstantDeliverySelectedProvider
                //                               .notifier)
                //                           .state = value!;
                //                       ref
                //                           .read(isSlotContainerVisibleProvider
                //                               .notifier)
                //                           .state = !value;
                //                     },
                //                     activeColor:
                //                         const Color.fromARGB(255, 65, 88, 108),
                //                     checkColor: Colors.white,
                //                   ),
                //                 ],
                //               ),
                //             );
                //           },
                //         )
                //       : const SizedBox.shrink(),
                // ),
                // if (isSlotContainerVisible && isInstantDeliveryVisible)
                //   const SizedBox(height: 20),
                // if (isSlotContainerVisible && isInstantDeliveryVisible)
                //   const CenteredTitleWidget(title: "OR"),
                // // if (isSlotContainerVisible && isInstantDeliveryVisible)
                //   const SizedBox(height: 20),
                // // Slot Selection Container
                // if (isSlotContainerVisible)

                const SizedBox(height: 20),
                const SlotSelectionContainer(),
                const SizedBox(height: 20),
                Text(
                  'Delivery Suggestions (Optional)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: preferredTimeController,
                  decoration: InputDecoration(
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    hintText: 'Eg: Deliver between 1:00 PM -  2:00 PM',
                    hintStyle: GoogleFonts.poppins(fontSize: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),

        // Bottom Sheet
        bottomSheet: Container(
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
            onPressed: isLoading
                ? null
                : () async {
                    loaderNotifier.state = true;
                    // ---- PATCH BEGIN: Cart empty check ----
                    final cartItems = ref.read(cartProvider);
                    if (cartItems.isEmpty) {
                      ToastHelper.showErrorToast('Your cart is expired!');
                      loaderNotifier.state = false;
                      return;
                    }
                    // ---- PATCH END ----
                    try {
                      final selectedSlot = ref.read(selectedSlotProvider);
                      final selectedAddress =
                          ref.read(addressProvider).asData?.value;
                      // final isInstantDeliverySelected =
                      //     ref.read(isInstantDeliverySelectedProvider);

                      if (selectedAddress == null) {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => const AddressPage(),
                          ),
                        );
                        return;
                      }

                      String deliveryTime = "";

                      // if (isInstantDeliverySelected) {
                      //   deliveryTime = await calculateEstimatedDeliveryTime();
                      // } else
                      if (selectedSlot != null) {
                        DateTime currentTime = await NTP.now();
                        DateTime slotStart = selectedSlot[
                            "start"]!; // ✅ Correctly extracting DateTime
                        DateTime slotEnd = selectedSlot["end"]!;

                        final slotConfig = await FirebaseFirestore.instance
                            .collection('slot')
                            .doc('slotcutoff')
                            .get();

                        final minLeadTime = slotConfig.data()?['time'] ?? 60;

                        if (slotStart.difference(currentTime).inMinutes <
                            minLeadTime) {
                          ToastHelper.showErrorToast(
                            'Selected slot is not available. Please select a valid slot.',
                          );
                          return;
                        }

                        deliveryTime =
                            "${DateFormat('MMM d').format(slotStart)}, ${DateFormat('hh:mm a').format(slotStart)} - ${DateFormat('hh:mm a').format(slotEnd)}";
                      } else {
                        ToastHelper.showErrorToast(
                            'Please select a delivery slot or instant delivery.');
                        return;
                      }

                      // The firstOrder check is now handled in initState

                      final baseTotal =
                          calculateTotalPrice(ref.read(cartProvider));
                      // final double instantDeliveryfee =
                      //     isInstantDeliverySelected ? 50.0 : 0.0;
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => CheckoutPage(
                            preferredTime: preferredTimeController.text,
                            // offerDiscount: 0.0,
                            itemTotal: baseTotal,
                            cartItems: ref.read(cartProvider),
                            deliveryTime: deliveryTime,
                            // instantDeliveryfee: instantDeliveryfee,
                          ),
                        ),
                      );
                    } catch (e) {
                      print("Error: $e");
                    } finally {
                      loaderNotifier.state = false;
                    }
                  },
            child: isLoading
                ? const CupertinoActivityIndicator(
                    color: Colors.white,
                  )
                : Text(
                    'Confirm Time',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  double calculateTotalPrice(List<CartItem> cartItems) {
    return cartItems.fold(0, (sum, item) => sum + item.price * item.quantity);
  }
}
