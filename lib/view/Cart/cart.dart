import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/Cart/cart_controller.dart';
import 'package:kealthy/view/Cart/provider.dart';
import 'package:kealthy/view/Cart/time.dart';
import 'package:kealthy/view/Toast/toast_helper.dart';
import 'package:kealthy/view/address/adress.dart';
import 'package:kealthy/view/address/provider.dart';
import 'package:kealthy/view/food/food_subcategory.dart';
import 'package:kealthy/view/product/add_to_cart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

final slotAvailabilityProvider =
    StateProvider<bool>((ref) => true); // Default: slot available

final isInstantDeliverySelectedProvider = StateProvider<bool>((ref) => false);

final isSlotContainerVisibleProvider = StateProvider<bool>((ref) => true);

class SelectedLocationNotifier extends StateNotifier<String?> {
  SelectedLocationNotifier() : super(null) {
    _loadSelectedAddress();
  }

  Future<void> _loadSelectedAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAddress = prefs.getString('selectedAddress');
    print('m$savedAddress');
    if (savedAddress != null) {
      state = savedAddress;
    }
  }
}

class CartPage extends ConsumerWidget {
  const CartPage({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final selectedAddress = ref.watch(selectedLocationProvider);
    final allProductsSnapshot = ref.watch(allProductsStreamProvider);

    allProductsSnapshot.whenData((snapshot) {
      final productSohMap = {
        for (var doc in snapshot.docs)
          doc.data()['Name'].toString():
              int.tryParse(doc.data()['SOH'].toString()) ?? 0,
      };
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final item in cartItems) {
          final fullName = item.quantityName.isNotEmpty
              ? '${item.name} ${item.quantityName}'
              : item.name;

          final soh = productSohMap[item.name] ?? 0;

          if (soh == 0) {
            ref.read(cartProvider.notifier).removeItem(
                  item.name,
                  quantityName:
                      item.quantityName.isNotEmpty ? item.quantityName : null,
                );
          }
        }
      });
    });

    return SafeArea(
      top: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          surfaceTintColor: Colors.white,
          backgroundColor: Colors.white,
          title: Text(
            'Cart',
            style: GoogleFonts.poppins(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: cartItems.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'lib/assets/images/empty-cart-2.png',
                      width: 200,
                    ),
                    Text(
                      'Your cart is empty!',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(10.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 1, vertical: 1),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withValues(alpha: 0.2),
                                spreadRadius: 1,
                                blurRadius: 5,
                                offset: const Offset(0, 1),
                              ),
                            ],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 20,
                            ),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: cartItems.length,
                            itemBuilder: (context, index) {
                              final item = cartItems[index];
                              final trialDishesAsync =
                                  ref.watch(dishesProvider(item.type));
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Product Image
                                        Column(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: CachedNetworkImage(
                                                imageUrl: item.imageUrl,
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    Container(
                                                  width: 60,
                                                  height: 60,
                                                  color:
                                                      const Color(0xFFF4F4F5),
                                                  child: const Center(
                                                      child:
                                                          CupertinoActivityIndicator()),
                                                ),
                                                errorWidget:
                                                    (context, url, error) =>
                                                        Container(
                                                  width: 60,
                                                  height: 60,
                                                  color:
                                                      const Color(0xFFF4F4F5),
                                                  child: const Icon(
                                                      Icons.broken_image,
                                                      color: Colors.grey),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Stack(
                                              children: [
                                                GestureDetector(
                                                  onTap: ref
                                                          .read(cartProvider
                                                              .notifier)
                                                          .isRemoving(item.name)
                                                      ? null
                                                      : () {
                                                          ref
                                                              .read(cartProvider
                                                                  .notifier)
                                                              .removeItem(
                                                                item.name,
                                                                quantityName: item
                                                                        .quantityName
                                                                        .isNotEmpty
                                                                    ? item
                                                                        .quantityName
                                                                    : null,
                                                              );
                                                        },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              5),
                                                      border: Border.all(
                                                        color: Colors
                                                            .grey.shade300,
                                                      ),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              5.0),
                                                      child: Text(
                                                        'Remove',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 8,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                if (ref
                                                    .read(cartProvider.notifier)
                                                    .isRemoving(item.name))
                                                  const Positioned.fill(
                                                    child: Align(
                                                      alignment: Alignment
                                                          .bottomCenter,
                                                      child:
                                                          LinearProgressIndicator(
                                                        minHeight: 2,
                                                        color: Colors.grey,
                                                        backgroundColor:
                                                            Colors.transparent,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 10),
                                        // Product Name, Price, Remove Button
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      item.name,
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        fontSize: 14,
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '₹${item.price}',
                                                style: GoogleFonts.poppins(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 18,
                                                  color: Colors.black,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        // Quantity + Price Column
                                        Column(
                                          children: [
                                            Stack(
                                              children: [
                                                Container(
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFFF4F4F5),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            10),
                                                    border: Border.all(
                                                      color:
                                                          const Color.fromARGB(
                                                              255, 65, 88, 108),
                                                    ),
                                                  ),
                                                  child: Center(
                                                      child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.remove,
                                                          color: Colors.black,
                                                        ),
                                                        onPressed: ref
                                                                .read(cartProvider
                                                                    .notifier)
                                                                .isLoading(
                                                                    item.name)
                                                            ? null
                                                            : () {
                                                                if (item.quantity >
                                                                    1) {
                                                                  ref
                                                                      .read(cartProvider
                                                                          .notifier)
                                                                      .decrementItem(
                                                                        item.name,
                                                                        quantityName: item.quantityName.isNotEmpty
                                                                            ? item.quantityName
                                                                            : null,
                                                                      );
                                                                } else {
                                                                  ref
                                                                      .read(cartProvider
                                                                          .notifier)
                                                                      .removeItem(
                                                                        item.name,
                                                                        quantityName: item.quantityName.isNotEmpty
                                                                            ? item.quantityName
                                                                            : null,
                                                                      );
                                                                }
                                                              },
                                                      ),
                                                      Text(
                                                        '${item.quantity}',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.black,
                                                        ),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(
                                                          Icons.add,
                                                          color: item.quantity >=
                                                                      2 &&
                                                                  isTrialDish(
                                                                      item.name,
                                                                      trialDishesAsync)
                                                              ? Colors.grey
                                                              : Colors.black,
                                                        ),
                                                        onPressed: () async {
                                                          if (ref
                                                              .read(cartProvider
                                                                  .notifier)
                                                              .isLoading(
                                                                  item.name)) {
                                                            return;
                                                          }

                                                          if (item.quantity >=
                                                              item.soh) {
                                                            ToastHelper
                                                                .showErrorToast(
                                                              'Limit reached: Only ${item.soh} left in stock.',
                                                            );
                                                            return;
                                                          }

                                                          if (isTrialDish(
                                                              item.name,
                                                              trialDishesAsync)) {
                                                            final prefs =
                                                                await SharedPreferences
                                                                    .getInstance();
                                                            final phoneNumber =
                                                                prefs.getString(
                                                                        'phoneNumber') ??
                                                                    '';

                                                            final alreadyOrderedToday =
                                                                await getTodayOrderedQuantity(
                                                              phoneNumber:
                                                                  phoneNumber,
                                                              productName:
                                                                  item.name,
                                                            );

                                                            final totalIfAdded =
                                                                alreadyOrderedToday +
                                                                    item.quantity;

                                                            if (totalIfAdded >=
                                                                2) {
                                                              ToastHelper
                                                                  .showErrorToast(
                                                                'Daily limit reached: Only 2 quantities allowed per day for this dish.',
                                                              );
                                                              return;
                                                            }
                                                          }

                                                          await ref
                                                              .read(cartProvider
                                                                  .notifier)
                                                              .incrementItem(
                                                                item.name,
                                                                quantityName: item
                                                                        .quantityName
                                                                        .isNotEmpty
                                                                    ? item
                                                                        .quantityName
                                                                    : null,
                                                              );
                                                        },
                                                      ),
                                                    ],
                                                  )),
                                                ),
                                                if (ref
                                                    .read(cartProvider.notifier)
                                                    .isLoading(item.name))
                                                  const Positioned.fill(
                                                    child: Align(
                                                      alignment: Alignment
                                                          .bottomCenter,
                                                      child: Padding(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                          horizontal: 6,
                                                          vertical: 1,
                                                        ),
                                                        child:
                                                            LinearProgressIndicator(
                                                          minHeight: 2,
                                                          color: Color.fromARGB(
                                                              255, 65, 88, 108),
                                                          backgroundColor:
                                                              Colors
                                                                  .transparent,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              '₹${item.price * item.quantity}',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (index != cartItems.length - 1)
                                      const Divider(
                                          thickness: 1,
                                          color: Color(0xFFE0E0E0)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 150),
                    ],
                  ),
                ),
              ),
        bottomSheet: cartItems.isEmpty
            ? null
            : Container(
                width: double.infinity,
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Total Amount',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '₹${calculateTotalPrice(cartItems)}',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: MediaQuery.of(context).size.width,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 65, 88, 108),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          try {
                            // If no address is selected, go to address page
                            if (selectedAddress == null) {
                              Navigator.push(
                                context,
                                CupertinoPageRoute(
                                  builder: (context) => const AddressPage(),
                                ),
                              );
                              return;
                            }

                            // Otherwise, go to time page
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => const TimePage(),
                              ),
                            );
                          } catch (e) {
                            print("Error navigating to CheckoutPage: $e");
                          }
                        },
                        child: Text(
                          selectedAddress == null
                              ? 'Select Address'
                              : 'Continue',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ),
      ),
    );
  }

  double calculateTotalPrice(List<CartItem> cartItems) {
    return cartItems.fold(0, (sum, item) => sum + item.price * item.quantity);
  }
}
