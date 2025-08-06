import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy/view/Toast/toast_helper.dart';
import 'package:kealthy/view/product/all_products.dart';
import 'package:kealthy/view/product/product_page.dart';
import 'package:kealthy/view/product/provider.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ntp/ntp.dart';

class DealOfTheDayPage extends StatelessWidget {
  const DealOfTheDayPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF3E0),
        surfaceTintColor: Colors.white,
        title: Text('Deal of the Day',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            )),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Products')
            .where('deal_of_the_day', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CupertinoActivityIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                children: [
                  Lottie.asset(
                    'lib/assets/animations/Animation - 1748512107253.json',
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                  Text('No Deals Available',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      )),
                ],
              ),
            );
          }

          final now = DateTime.now(); // fallback if NTP fails
          final validProducts = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final offerSohRaw = data['offer_soh'];
            final offerEndDate = data['offer_end_date'];
            final offerSoh = int.tryParse(offerSohRaw.toString()) ?? 0;
            DateTime? endDate;
            if (offerEndDate is Timestamp) {
              endDate = offerEndDate.toDate();
            } else if (offerEndDate is String) {
              endDate = DateTime.tryParse(offerEndDate);
            }
            return !(offerSoh == 0 &&
                endDate != null &&
                endDate.isBefore(DateTime(now.year, now.month, now.day)));
          }).toList();
          // Update expired/invalid offers in Firestore
          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final offerSohRaw = data['offer_soh'];
            final offerEndDate = data['offer_end_date'];
            final offerSoh = int.tryParse(offerSohRaw.toString()) ?? 0;
            DateTime? endDate;
            if (offerEndDate is Timestamp) {
              endDate = offerEndDate.toDate();
            } else if (offerEndDate is String) {
              endDate = DateTime.tryParse(offerEndDate);
            }
            if (offerSoh == 0 ||
                endDate != null &&
                    endDate.isBefore(DateTime(now.year, now.month, now.day))) {
              FirebaseFirestore.instance
                  .collection('Products')
                  .doc(doc.id)
                  .update({
                'deal_of_the_day': false,
                'offer_price': 0,
              });
            }
          }
          final products = validProducts;

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 columns
              mainAxisSpacing: 16,
              crossAxisSpacing: 10,
              childAspectRatio: 0.6,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final data = products[index].data() as Map<String, dynamic>;
              final imageUrl =
                  (data['ImageUrl'] is List && data['ImageUrl'].isNotEmpty)
                      ? data['ImageUrl'][0]
                      : null;
              final name = data['Name'] ?? 'No Name';
              final price = data['Price'] ?? 0;
              final offerPrice = data['offer_price'];
              final qty = data['Qty'] ?? '';

              return GestureDetector(
                onTap: () async {
                  // Fetch current time from NTP
                  final now = await NTP.now();
                  // Retrieve and parse offer_end_date
                  final offerEndDate = data['offer_end_date'];
                  DateTime? endDate;
                  if (offerEndDate is Timestamp) {
                    endDate = offerEndDate.toDate();
                  } else if (offerEndDate is String) {
                    endDate = DateTime.tryParse(offerEndDate);
                  }
                  final offerSohRaw = data['offer_soh'];
                  final offerSoh = int.tryParse(offerSohRaw.toString()) ?? 0;
                  if (offerSoh == 0 ||
                      endDate != null &&
                          endDate.isBefore(
                              DateTime(now.year, now.month, now.day))) {
                    ToastHelper.showErrorToast("Offer has expired.");
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductPage(
                        productId: products[index].id,
                         
                      ),
                    ),
                  );
                },
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              child: imageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: imageUrl,
                                      height: 130,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          Shimmer.fromColors(
                                        baseColor: Colors.grey[300]!,
                                        highlightColor: Colors.grey[100]!,
                                        child: Container(color: Colors.white),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          const Icon(Icons.image_not_supported),
                                    )
                                  : Container(
                                      height: 130,
                                      width: double.infinity,
                                      color: Colors.grey.shade300,
                                      child:
                                          const Icon(Icons.image_not_supported),
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: IntrinsicHeight(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height:
                                        50, // enough to fit two lines of text
                                    child: Text(
                                      name,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        textStyle: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  const Spacer(),
                                  const SizedBox(width: 5),
                                  Row(
                                    children: [
                                      offerPrice != null && offerPrice < price
                                          ? Text(
                                              '\u20B9$price',
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: Colors.red,
                                                decoration:
                                                    TextDecoration.lineThrough,
                                              ),
                                            )
                                          : const SizedBox(),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '\u20B9$offerPrice/-',
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.green.shade800,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Discount percentage
                                      const Spacer(),
                                      Text(qty,
                                          maxLines: 2,
                                          style: GoogleFonts.poppins(
                                            textStyle: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w400,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          )),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Consumer(
                        builder: (context, ref, child) {
                          final averageStarsAsync = ref.watch(
                              averageStarsProvider(data['Name'] ?? 'No Name'));
                          return averageStarsAsync.when(
                            data: (rating) {
                              if (rating == 0.0) {
                                return const SizedBox(); // Hide badge if rating is 0
                              }
                              return ClipPath(
                                clipper: LeftRibbonClipper(),
                                child: Container(
                                  height: 25,
                                  width:
                                      MediaQuery.of(context).size.width * 0.13,
                                  decoration: const BoxDecoration(
                                    color: Color.fromARGB(255, 67, 168, 70),
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.star,
                                          size: 14, color: Colors.yellow),
                                      Text(
                                        rating.toStringAsFixed(1),
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            loading: () => const SizedBox(),
                            error: (error, _) => const SizedBox(),
                          );
                        },
                      ),
                    ),
                    if (offerPrice != null && offerPrice < price)
                      Positioned(
                        bottom: 115,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                          ),
                          child: Text(
                            '${(((price - offerPrice) / price) * 100).round()}% off',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
