import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/Login/login_page.dart';
import 'package:kealthy/view/orders/provider.dart';
import 'package:kealthy/view/orders/track.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LiveOrdersTab extends ConsumerStatefulWidget {
  const LiveOrdersTab({super.key});

  @override
  _LiveOrdersTabState createState() => _LiveOrdersTabState();
}

class _LiveOrdersTabState extends ConsumerState<LiveOrdersTab> {
  bool isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeState());
  }

  @override
  void dispose() {
    isDisposed = true;
    super.dispose();
  }

  Future<void> _initializeState() async {
    await ref.read(orderRepositoryProvider).loadOrders(ref);
  }

  String getLast9Digits(String orderId) {
    return orderId.length > 9 ? orderId.substring(orderId.length - 9) : orderId;
  }

  @override
  Widget build(BuildContext context) {
    final ordersList = ref.watch(ordersListProvider);
    final expandedStates = ref.watch(expandedStatesProvider);
    final isLoading = ref.watch(loadingProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        toolbarHeight: 1,
      ),
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(
              child: CupertinoActivityIndicator(
              color: Color.fromARGB(255, 65, 88, 108),
            ))
          : ordersList.isEmpty
              ? Center(
                  child: Text(
                  'No orders found',
                  style: GoogleFonts.poppins(),
                ))
              : ListView.builder(
                  itemCount: ordersList.length,
                  itemBuilder: (context, index) {
                    final order = ordersList[index];
                    final orderId = order['orderId'];
                    final status = order['status'];
                    final deliveryPartnerName =
                        order['assignedto'] ?? 'Not Assigned';
                    final phoneNumber = order['DAMOBILE'] ?? '';
                    final address = order['selectedRoad'] ?? '';
                    final orderItems = order['orderItems'] ?? [];
                    final selectedSlot = order['selectedSlot'] ?? '';
                    // final instantDeliveryfee = double.tryParse(
                    //         order['instantDeliveryfee']?.toString() ?? '0') ??
                    //     0;
                    // final deliveryfee = double.tryParse(
                    //         order['deliveryFee']?.toString() ?? '0') ??
                    //     0;
                    final totalAmount = order['totalAmountToPay'] ?? '';

                    // Calculate subtotal of items
                    // final double subtotal = orderItems.fold(0.0, (sum, item) {
                    //   final quantity = (item['item_quantity'] ?? 1).toDouble();
                    //   final price = (item['item_price'] ?? 0).toDouble();
                    //   return sum + (price * quantity);
                    // });
                    // Handling fee
                    //const int handlingFee = 5;

                    final expanded = expandedStates[index];

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
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
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                            expansionTileTheme: const ExpansionTileThemeData(
                              backgroundColor: Colors.white,
                              collapsedBackgroundColor: Colors.white,
                            ),
                          ),
                          child: ExpansionTile(
                            initiallyExpanded: expanded,
                            onExpansionChanged: (bool expanded) {
                              final updatedStates =
                                  List<bool>.from(expandedStates);
                              updatedStates[index] = expanded;
                              ref.read(expandedStatesProvider.notifier).state =
                                  updatedStates;
                            },
                            title: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Order details on left
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Order ID: ${getLast9Digits(orderId)}',
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
                                        status,
                                        style: GoogleFonts.poppins(
                                          textStyle: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                // Optionally, you can place something on the right side of the title row
                                // e.g., an icon or short text. If not used, it remains blank.
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Partner Name Row
                                    Row(
                                      children: [
                                        const Icon(
                                          CupertinoIcons.person,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            'Partner: $deliveryPartnerName',
                                            style: GoogleFonts.poppins(
                                              textStyle: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Spacer(),
                                        if (status != 'Delivered' &&
                                            deliveryPartnerName !=
                                                'Not Assigned')
                                          IconButton(
                                            onPressed: () {
                                              FlutterPhoneDirectCaller
                                                  .callNumber(phoneNumber);
                                            },
                                            icon: const Icon(
                                              Icons.phone,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),

                                    // Delivery time row
                                    Row(
                                      children: [
                                        const Icon(
                                          CupertinoIcons.time,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            'Delivery Time: $selectedSlot',
                                            style: GoogleFonts.poppins(
                                              textStyle: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 5),
                                    const Divider(),

                                    // --- Order details header ---
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
                                    const SizedBox(height: 15),

                                    Column(
                                      children: orderItems.map<Widget>((item) {
                                        final quantity =
                                            (item['item_quantity'] ?? 1)
                                                .toDouble();
                                        final price = (item['item_price'] ?? 0)
                                            .toDouble();
                                        final lineTotal = quantity * price;

                                        // Build row for each item
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 2.0),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              // Left side: quantity + item name
                                              Expanded(
                                                child: Row(
                                                  children: [
                                                    // Quantity container
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 6,
                                                          vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .grey.shade300,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                        border: Border.all(
                                                          color: Colors
                                                              .grey.shade500,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        '${item['item_quantity']}',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          textStyle:
                                                              const TextStyle(
                                                            fontSize: 10,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    // Item name
                                                    Expanded(
                                                      child: Text(
                                                        '× ${item['item_name']}',
                                                        style:
                                                            GoogleFonts.poppins(
                                                          textStyle:
                                                              const TextStyle(
                                                            fontSize: 13,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              // Right side: item price
                                              Text(
                                                '₹${lineTotal.toStringAsFixed(0)}',
                                                style: GoogleFonts.poppins(
                                                  textStyle: const TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    // const SizedBox(height: 20),
                                    // Row(
                                    //   children: [
                                    //     Text('Subtotal:',
                                    //         style: GoogleFonts.poppins(
                                    //           textStyle: const TextStyle(
                                    //             fontSize: 13,
                                    //             fontWeight: FontWeight.bold,
                                    //           ),
                                    //         )),
                                    //         const Spacer(),
                                    //         Text('₹${subtotal.toStringAsFixed(0)}',
                                    //         style: GoogleFonts.poppins(
                                    //           textStyle: const TextStyle(
                                    //             fontSize: 13,
                                    //             fontWeight: FontWeight.bold,
                                    //           ),
                                    //         )),
                                    //   ],
                                    // ),
                                    const SizedBox(height: 20),
                                    // Handling fee
                                    // Row(
                                    //   children: [
                                    //     Text(
                                    //       'Delivery Fee:',
                                    //       style: GoogleFonts.poppins(
                                    //         textStyle: const TextStyle(
                                    //           fontSize: 13,
                                    //           fontWeight: FontWeight.bold,
                                    //         ),
                                    //       ),
                                    //     ),
                                    //     const Spacer(),
                                    //     deliveryfee > 0
                                    //         ? Text(
                                    //             '₹${deliveryfee.toStringAsFixed(0)}',
                                    //             style: const TextStyle(
                                    //               fontSize: 13,
                                    //               fontWeight: FontWeight.bold,
                                    //             ),
                                    //           )
                                    //         : Text(
                                    //             'Free',
                                    //             style: GoogleFonts.poppins(
                                    //               textStyle: const TextStyle(
                                    //                 fontSize: 13,
                                    //                 fontWeight: FontWeight.bold,
                                    //                 color: Colors.green,
                                    //               ),
                                    //             ),
                                    //           ),
                                    //   ],
                                    // ),
                                    // Handling fee
                                    // if (instantDeliveryfee > 0)
                                    //   Padding(
                                    //     padding: const EdgeInsets.only(top: 20),
                                    //     child: Row(
                                    //       children: [
                                    //         Text(
                                    //           'Instant Delivery Fee:',
                                    //           style: GoogleFonts.poppins(
                                    //             textStyle: const TextStyle(
                                    //               fontSize: 13,
                                    //               fontWeight: FontWeight.bold,
                                    //             ),
                                    //           ),
                                    //         ),
                                    //         const Spacer(),
                                    //         Text(
                                    //           '₹${instantDeliveryfee.toStringAsFixed(0)}',
                                    //           style: const TextStyle(
                                    //             fontSize: 13,
                                    //             fontWeight: FontWeight.bold,
                                    //           ),
                                    //         ),
                                    //       ],
                                    //     ),
                                    //   ),

                                    // const SizedBox(height: 20),
                                    // // Handling fee
                                    // Row(
                                    //   children: [
                                    //     Text(
                                    //       'Handling fee:',
                                    //       style: GoogleFonts.poppins(
                                    //         textStyle: const TextStyle(
                                    //           fontSize: 13,
                                    //           fontWeight: FontWeight.bold,
                                    //         ),
                                    //       ),
                                    //     ),
                                    //     const Spacer(),
                                    //     const Text(
                                    //       '₹$handlingFee',
                                    //       style: TextStyle(
                                    //         fontSize: 13,
                                    //         fontWeight: FontWeight.bold,
                                    //       ),
                                    //     ),
                                    //   ],
                                    // ),
                                    // const SizedBox(height: 10),
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
                                          '₹${totalAmount.toStringAsFixed(0)}',
                                          style: GoogleFonts.poppins(
                                            textStyle: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Track Order Button (conditionally displayed)
                                    if (status != 'Delivered' &&
                                        deliveryPartnerName != 'Not Assigned')
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          backgroundColor: const Color.fromARGB(
                                              255, 65, 88, 108),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            CupertinoModalPopupRoute(
                                              builder: (context) =>
                                                  TrackOrderPage(
                                                orderId: orderId,
                                                deliveryBoy:
                                                    deliveryPartnerName,
                                                address: address,
                                                phoneNumber: phoneNumber,
                                                status: status,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          'Track Order',
                                          style: GoogleFonts.poppins(
                                            textStyle: const TextStyle(
                                              color: Color(0xFFF4F4F5),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 15),

                                    // Company and FSSAI info
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
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
