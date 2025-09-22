// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kealthy/view/Cart/bill.dart';
import 'package:kealthy/view/Cart/cart_controller.dart';
import 'package:kealthy/view/Cart/checkout_provider.dart';
import 'package:kealthy/view/Cart/instruction_container.dart';
import 'package:kealthy/view/address/adress.dart';
import 'package:kealthy/view/food/food_subcategory.dart';
import 'package:kealthy/view/payment/payment.dart';

final isProceedingToPaymentProvider = StateProvider<bool>((ref) => false);

// Fixed origin (restaurant/start)
const double _ORIGIN_LAT = 10.010065327275328;
const double _ORIGIN_LNG = 76.38417832553387;

class _Eta {
  final int prepMin;
  final int travelMin;
  final DateTime readyAt; // now + prep
  final DateTime arrivesAt; // readyAt + travel
  final double distanceKm; // for display/debug
  const _Eta({
    required this.prepMin,
    required this.travelMin,
    required this.readyAt,
    required this.arrivesAt,
    required this.distanceKm,
  });
}

double _deg2rad(double d) => d * math.pi / 180.0;
double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
  const R = 6371.0; // km
  final dLat = _deg2rad(lat2 - lat1);
  final dLon = _deg2rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_deg2rad(lat1)) *
          math.cos(_deg2rad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return R * c;
}

// Round up to nearest 5 minutes (looks nicer + buffers a bit)
int _roundUp5(num m) => (((m.ceil()) + 4) ~/ 5) * 5;

/// Calculate ETA with 30m prep + distance-based travel
///
/// Pass either:
///   - [distanceKm] if you already have the distance in kilometers, OR
///   - [destLat]/[destLng] to compute Haversine distance from the fixed origin.
///
/// If your distance is in meters, pass [distanceIsMeters: true].
_Eta _calcEta({
  double? distanceKm,
  bool distanceIsMeters = false,
  double? destLat,
  double? destLng,
  int prepMinutes = 30, // fixed prep time
  double speedKmph = 22, // average city speed
}) {
  // Use one 'now' to avoid drift between computations
  final now = DateTime.now().toLocal();

  // Normalize distance (prefer provided value; else compute via coords)
  double km = distanceKm ?? 0.0;
  if (distanceIsMeters) km = km / 1000.0;
  if ((km <= 0 || !km.isFinite) && destLat != null && destLng != null) {
    km = _haversineKm(_ORIGIN_LAT, _ORIGIN_LNG, destLat, destLng);
  }
  if (!km.isFinite || km < 0) km = 0.0;

  // Travel minutes (rounded up to 5)
  final travelRawMin = (km / speedKmph) * 60.0;
  final travelMin = km <= 0 ? 0 : _roundUp5(travelRawMin);

  // Build times
  final readyAt = now.add(Duration(minutes: prepMinutes));
  final arrivesAt = readyAt.add(Duration(minutes: travelMin));

  // Debug if you like
  // print('[ETA] km=$km prep=$prepMinutes travel=$travelMin now=$now ready=$readyAt arrive=$arrivesAt');

  return _Eta(
    prepMin: prepMinutes,
    travelMin: travelMin,
    readyAt: readyAt,
    arrivesAt: arrivesAt,
    distanceKm: km,
  );
}

class CheckoutPage extends ConsumerStatefulWidget {
  String? preferredTime;
  final double itemTotal;
  final List<CartItem> cartItems;
  final String deliveryTime;

  CheckoutPage({
    super.key,
    required this.itemTotal,
    required this.cartItems,
    required this.deliveryTime,
    this.preferredTime = '',
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

  double? distanceinKm = 0.0;
  double calculateTotalPrice(List<CartItem> cartItems) {
    return cartItems.fold(0, (sum, item) => sum + item.price * item.quantity);
  }

  @override
  Widget build(BuildContext context) {
    final firstOrderAsync = ref.watch(firstOrderProvider);

    double finalToPay = 0.0;
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
        body: Consumer(builder: (context, ref, _) {
          return Padding(
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
                      Row(
                        children: [
                          Text(
                            'Address',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Spacer(),
                          Visibility(
                            visible: true,
                            child: GestureDetector(
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  CupertinoPageRoute(
                                    builder: (context) => const AddressPage(),
                                  ),
                                );
                                ref.invalidate(addressProvider);
                              },
                              child: Card(
                                elevation: 1,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(
                                    'Change',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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
                              distanceinKm = double.tryParse(
                                  selectedAddress!.distance.toString())!;

                              final eta = _calcEta(
                                distanceKm: distanceinKm,
                              );
                              if (selectedAddress == null) {
                                return Text(
                                  "No address selected",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                );
                              }

                              distanceinKm =
                                  double.tryParse(selectedAddress.distance) ??
                                      0.0;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Address Card
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 5),
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
                                            DeliveryTimeRow(eta: eta),
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
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 3),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        border: Border.all(
                                            color: Colors.grey.shade300),
                                      ),
                                      child: TextField(
                                        controller:
                                            packingInstructionsController,
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
                                            icon: Icons
                                                .notifications_off_outlined,
                                            label: "Avoid Ringing Bell",
                                            id: 1,
                                          ),
                                          SizedBox(width: 10),
                                          InstructionContainer(
                                            icon:
                                                Icons.door_front_door_outlined,
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
                                    distanceInKm: distanceinKm!,
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
          );
        }),
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
                          distanceinKm =
                              double.tryParse(selectedAddress.distance) ?? 0.0;

                          final double normalDeliveryFee = calculateDeliveryFee(
                              widget.itemTotal, distanceinKm!);
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

class DeliveryTimeRow extends StatelessWidget {
  final _Eta eta;
  const DeliveryTimeRow({super.key, required this.eta});

  String _fmt(DateTime t) => DateFormat('h:mm a').format(t);
  String _mins(int m) => '$m min${m == 1 ? '' : 's'}';

  @override
  Widget build(BuildContext context) {
    final dim = Colors.black.withOpacity(.65);
    return Padding(
      padding: const EdgeInsets.fromLTRB(3, 12, 14, 12),
      child: Column(
        children: [
          // Left chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(.2)),
            ),
            child: Row(children: [
              Icon(Icons.local_fire_department_rounded,
                  size: 16, color: Colors.black.withOpacity(.7)),
              const SizedBox(width: 6),
              Text('Prep',
                  style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.black.withOpacity(.58),
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Text(_mins(eta.prepMin),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(.2)),
            ),
            child: Row(children: [
              Icon(Icons.delivery_dining_rounded,
                  size: 16, color: Colors.black.withOpacity(.7)),
              const SizedBox(height: 10),
              Text('Travel',
                  style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.black.withOpacity(.58),
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Text(
                eta.travelMin > 0
                    ? '${_mins(eta.travelMin)} · ${eta.distanceKm.toStringAsFixed(1)} km'
                    : 'You are nearby!',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(children: [
              const SizedBox(width: 6),
              const Icon(Icons.timer_rounded, size: 16),
              const SizedBox(width: 6),
              Text('Ready ${_fmt(eta.readyAt)}', style: TextStyle(color: dim)),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              const SizedBox(width: 8),
              const Icon(Icons.schedule_send_rounded, size: 16),
              const SizedBox(width: 6),
              Text('Delivery Time : ${_fmt(eta.arrivesAt)}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ]),
          ]),
        ],
      ),
    );
  }
}
