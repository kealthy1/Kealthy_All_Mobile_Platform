import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/orders/provider.dart';

class OrderCard extends ConsumerWidget {
  const OrderCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.read(orderDataProvider.notifier).fetchOrderData();

    final orderDataAsync = ref.watch(orderDataProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: orderDataAsync.when(
        data: (orders) {
          if (orders == null || orders.isEmpty) {
            return Center(
              child: Text(
                "No orders found",
                style: GoogleFonts.poppins(),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            itemCount: orders.length,
            itemBuilder: (context, idx) {
              final orderData = orders[idx];
              // Similar to live_orders.dart, use 9 digits for orderId
              String getLast9Digits(String orderId) {
                return orderId.length > 9
                    ? orderId.substring(orderId.length - 9)
                    : orderId;
              }

              // final double subtotal = orderData.orderItems.fold(0.0, (sum, item) {
              //   return sum + (item.itemQuantity * item.itemPrice);
              // });
              // const int handlingFee = 5;
              // Delivery fee, instant delivery fee, etc, are not in the past order model? We'll show only subtotal, handling, and total.
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 4,
                        spreadRadius: 2,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
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
                                  Text(
                                    'Order ID: ${getLast9Digits(orderData.orderId)}',
                                    style: GoogleFonts.poppins(
                                      textStyle: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    "Delivered",
                                    style: GoogleFonts.poppins(
                                      textStyle: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            // Date on right
                            Text(
                              orderData.date,
                              style: GoogleFonts.poppins(
                                textStyle: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Divider(
                          color: Colors.grey.shade300,
                          thickness: 1,
                        ),
                        Text(
                          'Order details',
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Items list
                        Column(
                          children: orderData.orderItems.map<Widget>((item) {
                            // final double lineTotal = item.itemQuantity * item.itemPrice;
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Left: quantity + item name
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade300,
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                                color: Colors.grey.shade500),
                                          ),
                                          child: Text(
                                            '${item.itemQuantity}',
                                            style: GoogleFonts.poppins(
                                              textStyle: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        // Item name
                                        Expanded(
                                          child: Text(
                                            '× ${item.itemName}',
                                            style: GoogleFonts.poppins(
                                              textStyle: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 10),
                        Divider(
                          color: Colors.grey.shade300,
                          thickness: 1,
                        ),
                        // Grand total
                        Row(
                          children: [
                            Text(
                              'Grand total:',
                              style: GoogleFonts.poppins(
                                textStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '₹${orderData.totalAmountToPay.toStringAsFixed(0)}',
                              style: GoogleFonts.poppins(
                                textStyle: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        Text(
                          'Cotolore enterprise LLP',
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              fontSize: 10,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'FSSAI: 21324181001125',
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              fontSize: 10,
                            ),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(
          child: CupertinoActivityIndicator(
            color: Color.fromARGB(255, 65, 88, 108),
          ),
        ),
        error: (err, stack) => Center(
          child: Text(
            "Error: $err",
            style: GoogleFonts.poppins(
              textStyle:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}
