import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:kealthy/view/Cart/cart_controller.dart';
import 'package:kealthy/view/product/product_page.dart';
import 'package:kealthy/view/product/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

final cartVisibilityProvider = StateProvider<bool>((ref) => true);
final ratingsMapProvider = StateProvider.family<Map<String, double>, String>(
    (ref, subcategoryName) => {});
final selectedTypeProvider =
    StateProvider.family<String?, String>((ref, subcategory) => null);

// Provider for the search query.
final searchQueryProvider = StateProvider<String>((ref) => '');

// Provider to fetch distinct product types based on subcategory.
final productTypesProvider = FutureProvider.family<List<String>, String>(
  (ref, subcategory) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Products')
        .where('Subcategory', isEqualTo: subcategory)
        .get();

    final types = snapshot.docs
        .map((doc) => doc.data()['Type'] as String?)
        .where((type) => type != null)
        .cast<String>()
        .toSet()
        .toList();

    return types;
  },
);

final allProductsProvider = FutureProvider.family<
    List<QueryDocumentSnapshot<Map<String, dynamic>>>, String>(
  (ref, subcategory) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Products')
        .where('Subcategory', isEqualTo: subcategory)
        .get();
    return snapshot.docs;
  },
);

// Provider to manage loading state during search.
final isLoadingProvider = StateProvider<bool>((ref) => false);

class AllProductsPage extends ConsumerStatefulWidget {
  final String subcategoryName;

  const AllProductsPage({super.key, required this.subcategoryName});

  @override
  _AllProductsPageState createState() => _AllProductsPageState();
}

class _AllProductsPageState extends ConsumerState<AllProductsPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    Future.microtask(() {
      if (mounted) {
        _initRatingsAndCache();
      }
    });
  }

  Future<void> _initRatingsAndCache() async {
    if (!mounted) return;
    ref.read(searchQueryProvider.notifier).state = "";

    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'ratings_${widget.subcategoryName}';

    final cachedData = prefs.getString(cacheKey);
    if (!mounted) return;

    if (cachedData != null) {
      final cachedMap = json.decode(cachedData) as Map<String, dynamic>;
      final mapped =
          cachedMap.map((k, v) => MapEntry(k, (v as num).toDouble()));

      if (!mounted) return;
      ref.read(ratingsMapProvider(widget.subcategoryName).notifier).state =
          mapped;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('Products')
        .where('Subcategory', isEqualTo: widget.subcategoryName)
        .get();

    if (!mounted) return;

    final names = snapshot.docs
        .map((doc) => doc.data()['Name']?.toString() ?? '')
        .toList();

    final updatedRatings = <String, double>{};
    for (final name in names) {
      final rating = await ref.read(averageStarsProvider(name).future);
      updatedRatings[name] = rating;
    }

    await prefs.setString(cacheKey, json.encode(updatedRatings));

    if (!mounted) return;
    ref.read(ratingsMapProvider(widget.subcategoryName).notifier).state =
        updatedRatings;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ref = this.ref;
    final searchQuery = ref.watch(searchQueryProvider).toLowerCase().trim();
    final isLoading = ref.watch(isLoadingProvider);
    final allProducts = ref.watch(allProductsProvider(widget.subcategoryName));
    // final productTypes =
    //     ref.watch(productTypesProvider(widget.subcategoryName));
    final selectedType =
        ref.watch(selectedTypeProvider(widget.subcategoryName));
    final ratingsMap = ref.watch(ratingsMapProvider(widget.subcategoryName));

    // Reset the search query when the page is rebuilt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Only reset if not triggered by a search
      if (searchQuery.isNotEmpty) return;
      ref.read(searchQueryProvider.notifier).state = ""; // Reset search query
    });

    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              iconSize: 26,
              onPressed: () {
                ref.read(searchQueryProvider.notifier).state = '';
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back)),
          surfaceTintColor: Colors.white,
          title: Text(
            widget.subcategoryName,
            style: GoogleFonts.poppins(
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Colors.black),
          elevation: 0,
          actions: [
            Consumer(
              builder: (context, ref, _) {
                final cartItems = ref.watch(cartProvider);
                final itemCount = cartItems.fold<int>(
                    0, (total, item) => total + item.quantity);

                return Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Stack(
                    children: [
                      IconButton(
                        icon: const Icon(CupertinoIcons.cart, size: 30),
                        onPressed: () {
                          Navigator.pushNamed(context, '/cart');
                        },
                      ),
                      if (itemCount > 0)
                        Positioned(
                          right: 3,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                                minWidth: 18, minHeight: 18),
                            child: Text(
                              '$itemCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        backgroundColor: Colors.white,
        body: Column(
          children: [
            // Search Bar with Loading Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          ref.read(isLoadingProvider.notifier).state = true;
                          ref.read(searchQueryProvider.notifier).state = value;
                          Future.delayed(const Duration(milliseconds: 500), () {
                            ref.read(isLoadingProvider.notifier).state = false;
                          });
                        },
                        decoration: InputDecoration(
                          constraints: const BoxConstraints(maxHeight: 40.0),
                          hintText: 'Search for products',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.black54,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          prefixIcon: const Icon(CupertinoIcons.search,
                              color: Colors.green),
                          suffixIcon: isLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(
                                      10.0), // Adjust padding to position the spinner
                                  child: SizedBox(
                                      width: 6,
                                      height: 6,
                                      child: CupertinoActivityIndicator(
                                          color: Color.fromARGB(
                                              255, 65, 88, 108))),
                                )
                              : null, // Show nothing if not searching
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: allProducts.when(
                loading: () => const Center(
                    child: CupertinoActivityIndicator(
                        color: Color.fromARGB(255, 65, 88, 108))),
                error: (error, stack) => Center(
                  child: Text(
                    "Error: $error",
                    style: GoogleFonts.poppins(),
                  ),
                ),
                data: (products) {
                  // Filter products based on search query and selected type
                  final filteredProducts = products.where((product) {
                    final data = product.data();
                    final productName =
                        data['Name']?.toString().toLowerCase() ?? '';

                    return (searchQuery.isEmpty ||
                            productName.contains(searchQuery)) &&
                        (selectedType == null || data['Type'] == selectedType);
                  }).toList();
                  if (filteredProducts.isEmpty) {
                    return Center(
                      child: Column(
                        children: [
                          const Icon(CupertinoIcons.exclamationmark_circle,
                              size: 50, color: Colors.black),
                          const SizedBox(height: 10),
                          Text("No products available",
                              style: GoogleFonts.poppins()),
                        ],
                      ),
                    );
                  }

                  // Pre-cache first image of each product
                  for (final product in filteredProducts) {
                    final data = product.data();
                    final imageUrls = data['ImageUrl'] ?? [];
                    if (imageUrls.isNotEmpty && imageUrls[0] is String) {
                      precacheImage(
                          CachedNetworkImageProvider(imageUrls[0]), context);
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: filteredProducts.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 columns
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.6,
                      ),
                      itemBuilder: (context, index) {
                        final data = filteredProducts[index].data();
                        final productqty = data['Qty'] ?? '0';
                        final productNameRaw = data['Name'] ?? 'No Name';
                        final price = data['Price'] ?? '0';
                        final imageUrls = data['ImageUrl'] ?? [];
                        final firstImageUrl = imageUrls.isNotEmpty
                            ? imageUrls[0]
                            : 'https://via.placeholder.com/150';

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProductPage(
                                    productId: filteredProducts[index].id , ),
                                    

                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              // Main product container
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: Colors.grey.shade300),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 5,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Product Image.
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(10),
                                          topRight: Radius.circular(10),
                                        ),
                                        child: CachedNetworkImage(
                                          imageUrl: firstImageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Shimmer.fromColors(
                                            baseColor: Colors.grey[300]!,
                                            highlightColor: Colors.grey[100]!,
                                            child:
                                                Container(color: Colors.white),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.error,
                                                  color: Colors.red),
                                        ),
                                      ),
                                    ),
                                    // Product Info.
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: IntrinsicHeight(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(
                                              height:
                                                  70, // enough to fit two lines of text
                                              child: Text(
                                                '$productNameRaw $productqty',
                                                maxLines: 3,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.poppins(
                                                  textStyle: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            // SizedBox(
                                            //   height: 18,
                                            //   child: Consumer(
                                            //     builder: (context, ref, child) {
                                            //       final averageStarsAsync = ref
                                            //           .watch(averageStarsProvider(
                                            //               productNameRaw));

                                            //       return averageStarsAsync.when(
                                            //         data: (rating) {
                                            //           if (rating == 0.0) {
                                            //             return const SizedBox(); // Hide stars if rating is 0
                                            //           }

                                            //           int fullStars = rating
                                            //               .floor(); // Get integer part (e.g., 3 from 3.8)
                                            //           bool hasHalfStar = rating -
                                            //                   fullStars >=
                                            //               0.5; // Check if it needs a half-star

                                            //           return Row(
                                            //             children: [
                                            //               Text(
                                            //                 rating
                                            //                     .toStringAsFixed(
                                            //                         1),
                                            //                 style: GoogleFonts
                                            //                     .poppins(
                                            //                   fontSize: 14,
                                            //                   color:
                                            //                       Colors.black54,
                                            //                 ),
                                            //               ),

                                            //               // Generate full stars
                                            //               ...List.generate(
                                            //                 fullStars,
                                            //                 (index) => const Icon(
                                            //                     Icons.star,
                                            //                     color:
                                            //                         Colors.orangeAccent,
                                            //                     size: 16),
                                            //               ),

                                            //               // Show half-star if needed
                                            //               if (hasHalfStar)
                                            //                 const Icon(
                                            //                     Icons.star_half,
                                            //                     color:
                                            //                         Colors.yellowAccent,
                                            //                     size: 20),

                                            //               // Show empty stars to keep alignment
                                            //               ...List.generate(
                                            //                 5 -
                                            //                     fullStars -
                                            //                     (hasHalfStar
                                            //                         ? 1
                                            //                         : 0),
                                            //                 (index) => const Icon(
                                            //                     Icons.star_border,
                                            //                     color:
                                            //                         Colors.yellowAccent,
                                            //                     size: 20),
                                            //               ),

                                            //               // Show the numeric rating next to stars
                                            //             ],
                                            //           );
                                            //         },
                                            //         loading: () => Container(),
                                            //         error: (error, _) =>
                                            //             const Text('N/A'),
                                            //       );
                                            //     },
                                            //   ),
                                            // ),
                                            // const SizedBox(
                                            //   height: 8,
                                            // ),
                                            const SizedBox(
                                              height: 10,
                                            ),

                                            const Spacer(),
                                            Row(
                                              children: [
                                                Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      if (data[
                                                                  'offer_price'] !=
                                                              null &&
                                                          double.tryParse(data[
                                                                      'offer_price']
                                                                  .toString()) !=
                                                              null &&
                                                          double.parse(data[
                                                                      'offer_price']
                                                                  .toString()) >
                                                              0)
                                                        Row(
                                                          children: [
                                                            Text(
                                                              '\u20B9$price',
                                                              style:
                                                                  const TextStyle(
                                                                fontSize: 12,
                                                                color:
                                                                    Colors.red,
                                                                decoration:
                                                                    TextDecoration
                                                                        .lineThrough,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 5),
                                                            Text(
                                                              '\u20B9${data['offer_price']}/-',
                                                              style: TextStyle(
                                                                fontSize: 15,
                                                                color: Colors
                                                                    .green
                                                                    .shade800,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                          ],
                                                        )
                                                      else
                                                        Text(
                                                          '\u20B9$price/-',
                                                          style: TextStyle(
                                                            fontSize: 15,
                                                            color: Colors
                                                                .green.shade800,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                    ]),
                                               
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Discount percentage Positioned badgeAdd commentMore actions
                              if (data['offer_price'] != null &&
                                  double.tryParse(
                                          data['offer_price'].toString()) !=
                                      null &&
                                  double.parse(data['offer_price'].toString()) >
                                      0)
                                Positioned(
                                  bottom: 109,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade700,
                                    ),
                                    child: Text(
                                      '${(((double.parse(price.toString()) - double.parse(data['offer_price'].toString())) / double.parse(price.toString())) * 100).round()}% off',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              // Rating badge positioned after the main container but before SOH badge
                              (() {
                                final productName =
                                    data['Name']?.toString() ?? '';
                                final rating = ratingsMap[productName] ?? 0.0;
                                if (rating > 0.0) {
                                  return Positioned(
                                    child: ClipPath(
                                      clipper: LeftRibbonClipper(),
                                      child: Container(
                                        height: 25,
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.13,
                                        decoration: const BoxDecoration(
                                          color:
                                              Color.fromARGB(255, 67, 168, 70),
                                        ),
                                        alignment: Alignment.center,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              rating.toStringAsFixed(1),
                                              style: GoogleFonts.poppins(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const Icon(Icons.star,
                                                size: 13, color: Colors.yellow),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              })(),
                              if ((data['SOH'] ?? 1) <= 4)
                                Positioned(
                                  top: 0,
                                  right: 0,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.only(
                                      topRight: Radius.circular(10),
                                    ),
                                    child: Container(
                                      height: 46,
                                      width: 38,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0, vertical: 4.0),
                                      decoration: const BoxDecoration(
                                        color: Color.fromARGB(255, 201, 82, 74),
                                      ),
                                      alignment: Alignment.center,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: (data['SOH'] ?? 1) == 0
                                            ? [
                                                Text('OUT',
                                                    style: GoogleFonts.poppins(
                                                        color: Colors.white,
                                                        fontSize: 6,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                Text('OF',
                                                    style: GoogleFonts.poppins(
                                                        color: Colors.white,
                                                        fontSize: 7,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                Text('STOCK',
                                                    style: GoogleFonts.poppins(
                                                        color: Colors.white,
                                                        fontSize: 6,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ]
                                            : [
                                                Text('ONLY',
                                                    style: GoogleFonts.poppins(
                                                        color: Colors.white,
                                                        fontSize: 6,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                Text('${data['SOH']}',
                                                    style: GoogleFonts.poppins(
                                                        color: Colors.white,
                                                        fontSize: 7,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                Text('LEFT',
                                                    style: GoogleFonts.poppins(
                                                        color: Colors.white,
                                                        fontSize: 6,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
    );
  }
}

// Custom clipper for left ribbon badgeAdd commentMore actions
class LeftRibbonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width - 10, 0);
    path.lineTo(size.width, size.height / 2);
    path.lineTo(size.width - 10, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
