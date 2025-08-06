import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final subscriptionOrderProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final phoneNumber = prefs.getString('phoneNumber');
  if (phoneNumber == null) return [];

  final dbRef = FirebaseDatabase.instanceFor(
    databaseURL: 'https://kealthy-90c55-dd236.firebaseio.com/',
    app: Firebase.app(),
  ).ref("subscriptions");
  final snapshot =
      await dbRef.orderByChild("phoneNumber").equalTo(phoneNumber).get();

  if (snapshot.exists) {
    return snapshot.children
        .map((doc) => Map<String, dynamic>.from(doc.value as Map))
        .toList();
  }
  return [];
});

class SubscriptionOrderDetailsPage extends ConsumerWidget {
  const SubscriptionOrderDetailsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(subscriptionOrderProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Subscriptions',
          style: GoogleFonts.poppins(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      backgroundColor: Colors.white,
      body: orderAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) =>
            Center(child: Text('Error: $e', style: GoogleFonts.poppins())),
        data: (orders) {
          if (orders.isEmpty) {
            return Center(
                child: Text('No subscriptions found',
                    style: GoogleFonts.poppins()));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderData = orders[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildRow('Order ID', orderData['orderId'] ?? ''),
                      buildRow('Plan Title', orderData['planTitle'] ?? ''),
                      buildRow('Product', orderData['productName'] ?? ''),
                      buildRow('Qty', "${orderData['subscriptionQty']} L"),
                      buildRow('Start Date', orderData['startDate'] ?? ''),
                      buildRow('End Date', orderData['endDate'] ?? ''),
                      buildRow('Slot', orderData['selectedSlot'] ?? ''),
                      buildRow('Phone Number', orderData['phoneNumber'] ?? ''),
                      buildRow(
                        'Alternate Day',
                        orderData['alternateDay'] == true ? 'Yes' : 'No',
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(
                              top: BorderSide(color: Colors.grey.shade300)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Amount',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                            Text(
                              '₹${orderData['totalAmountToPay']}',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              ': $value',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
