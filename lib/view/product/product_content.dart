import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:kealthy/view/product/add_to_cart.dart';
import 'package:kealthy/view/product/fullscreen.dart';
import 'package:kealthy/view/product/info_card.dart';
import 'package:kealthy/view/product/product_page.dart';
import 'package:kealthy/view/product/provider.dart';
import 'package:kealthy/view/product/review_section.dart';
import 'package:kealthy/view/product/text.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ProductContent extends ConsumerWidget {
  final PageController pageController;
  Map<String, num>? prices;
  final Map<String, dynamic> docData;
  final String productId;
  final List<String>? quantities;
  String? selectedQuantity;
  final Function(String) onQuantitySelected;
  final double? rating;
  Map<String, dynamic>? productIDs;
  Map<String, dynamic>? productNames;

  ProductContent({
    super.key,
    required this.docData,
    this.prices,
    required this.pageController,
    required this.productId,
    this.quantities,
    this.selectedQuantity,
    required this.onQuantitySelected,
    this.rating,
    this.productIDs,
    this.productNames,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedQty = ref.watch(selectedQuantityProvider);
    var productName;
    var productPrice;
    var offerPrice;
    if (prices != null) {
      productName =
          (productNames?[selectedQty]?['name'] ?? '').toString() ?? '';
      productPrice = prices![selectedQty] is num
          ? prices![selectedQty]
          : int.tryParse(prices![selectedQty]?.toString() ?? '0') ?? 0;
      offerPrice = (docData['offer_price'] is num
          ? docData['offer_price']
          : double.tryParse(docData['offer_price']?.toString() ?? '0') ?? 0);
    } else {
      productName = docData['Name'] ?? 'No Name';
      productPrice = (docData['Price'] is int || docData['Price'] is double)
          ? docData['Price']
          : int.tryParse(docData['Price']?.toString() ?? '0') ?? 0;

      offerPrice =
          (docData['offer_price'] is int || docData['offer_price'] is double)
              ? docData['offer_price']
              : double.tryParse(docData['offer_price']?.toString() ?? '0') ?? 0;
    }

    final hasOffer = offerPrice > 0;

    final productBrand = docData['Brand Name'] ?? 'No Name';
    final productQty = selectedQty ?? '';
    final productWhatIs = docData['What is it?'] ?? '';
    final productUseFor = docData['What is it used for?'] ?? '';
    final productEAN = docData['EAN'] ?? '';
    final productImageUrl = (docData['ImageUrl'] is List<dynamic> &&
            (docData['ImageUrl'] as List).isNotEmpty)
        ? docData['ImageUrl'][0]
        : '';
    final productOrigin = docData['Orgin'] ?? '';
    final productBestBefore = docData['Best Before'] ?? '';
    final productSoh = (docData['SOH'] is int)
        ? docData['SOH']
        : int.tryParse(docData['SOH']?.toString().split('.')[0] ?? '0') ?? 0;
    final productType = docData['Type'] ?? '';
    final bool needsFormatting = docData['needFormatting'] ?? false;

    // Best before date formatting
    String formattedDate = productBestBefore;
    if (needsFormatting && productBestBefore.isNotEmpty) {
      try {
        final parsedDate = DateTime.parse(productBestBefore);
        formattedDate = DateFormat('dd-MM-yyyy').format(parsedDate);
      } catch (e) {
        formattedDate = productBestBefore;
      }
    }

    // Macro and micro fields
    final Map<String, String> macrosMap = {
      'Protein (g)': docData['Protein (g)'] ?? 'Not Applicable',
      'Total Fat (g)': docData['Total Fat (g)'] ?? 'Not Applicable',
      'Carbs (g)': docData['Total Carbohydrates (g)'] ?? 'Not Applicable',
      'Sugars (g)': docData['Sugars (g)'] ?? 'Not Applicable',
      'Cholesterol (mg)': docData['Cholesterol (mg)'] ?? 'Not Applicable',
      'Added Sugars (g)': docData['Added Sugars (g)'] ?? 'Not Applicable',
    };
    final Map<String, String> microsMap = {
      'Sodium (mg)': docData['Sodium (mg)'] ?? 'Not Applicable',
      'Iron (mg)': docData['Iron (mg)'] ?? 'Not Applicable',
      'Calcium (mg)': docData['Calcium (mg)'] ?? 'Not Applicable',
      'Copper (mg)': docData['Copper (mg)'] ?? 'Not Applicable',
      'Magnesium (mg)': docData['Magnesium (mg)'] ?? 'Not Applicable',
      'Phosphorus (mg)': docData['Phosphorus (mg)'] ?? 'Not Applicable',
      'Potassium (mg)': docData['Potassium (mg)'] ?? 'Not Applicable',
      'Zinc (mg)': docData['Zinc (mg)'] ?? 'Not Applicable',
      'Manganese (mg)': docData['Manganese (mg)'] ?? 'Not Applicable',
      'Selenium (mcg)': docData['Selenium (mcg)'] ?? 'Not Applicable',
    };
    final List<dynamic> productFSSAI = docData['FSSAI'] ?? [];
    final fssiList = productFSSAI.map((e) => e.toString()).toList();
    final List<dynamic> rawIngredients = docData['Ingredients'] ?? [];
    final ingredientsList = rawIngredients.map((e) => e.toString()).toList();

    final validIngredientsList =
        ingredientsList.where((e) => e != "Not Applicable").toList();
    final filteredMacrosMap = Map.fromEntries(
      macrosMap.entries.where((entry) => entry.value != "Not Applicable"),
    );
    final filteredMicrosMap = Map.fromEntries(
      microsMap.entries.where((entry) => entry.value != "Not Applicable"),
    );

    return SingleChildScrollView(
      child: Column(
        children: [
          // Image carousel
          AspectRatio(
            aspectRatio: 10 / 10.5,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                PageView.builder(
                  controller: pageController,
                  itemCount: docData['ImageUrl']?.length ?? 1,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageZoomPage(
                            imageUrls:
                                docData['ImageUrl']?.cast<String>() ?? [],
                            initialIndex: index,
                          ),
                        ),
                      ),
                      child: InteractiveViewer(
                        clipBehavior: Clip.none,
                        panEnabled: true,
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: CachedNetworkImage(
                          imageUrl: docData['ImageUrl']?[index] ?? '',
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(color: Colors.grey[300]),
                          ),
                          errorWidget: (_, __, ___) => const Icon(Icons.error),
                        ),
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: SmoothPageIndicator(
                    controller: pageController,
                    count: docData['ImageUrl']?.length ?? 1,
                    effect: const ExpandingDotsEffect(
                      dotHeight: 10,
                      dotWidth: 10,
                      activeDotColor: Color.fromARGB(255, 65, 88, 108),
                      dotColor: Color.fromARGB(255, 120, 142, 162),
                      spacing: 4.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Product details
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: const BoxDecoration(color: Colors.white),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        productName,
                        overflow: TextOverflow.visible,
                        style: GoogleFonts.poppins(
                          textStyle: const TextStyle(
                              fontSize: 19.5,
                              color: Colors.black,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
                // Rating display
                Consumer(
                  builder: (context, ref, child) {
                    final averageStarsAsync =
                        ref.watch(averageStarsProvider(productName));
                    return averageStarsAsync.when(
                      data: (rating) {
                        if (rating == 0.0) {
                          return const SizedBox();
                        }
                        int fullStars = rating.floor();
                        bool hasHalfStar = rating - fullStars >= 0.5;
                        return Row(
                          children: [
                            Text(
                              rating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            ...List.generate(
                                fullStars,
                                (index) => const Icon(Icons.star,
                                    color: Colors.orange, size: 16)),
                            if (hasHalfStar)
                              const Icon(Icons.star_half,
                                  color: Colors.orange, size: 20),
                            ...List.generate(
                              5 - fullStars - (hasHalfStar ? 1 : 0),
                              (index) => const Icon(Icons.star_border,
                                  color: Colors.orange, size: 20),
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox(),
                      error: (error, _) => const Text('N/A'),
                    );
                  },
                ),
                const SizedBox(height: 20),
                // Price and quantity selection
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasOffer)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.shade700,
                            ),
                            child: Text(
                              '${(((productPrice! - offerPrice) / productPrice) * 100).round()}% off',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (hasOffer)
                              Padding(
                                padding: const EdgeInsets.only(right: 5.0),
                                child: Text(
                                  '\u20B9$productPrice',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.red,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ),
                            const Baseline(
                              baseline: 17,
                              baselineType: TextBaseline.alphabetic,
                              child: Text(
                                '\u20B9',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                            Text(
                              hasOffer ? '$offerPrice/-' : '$productPrice/-',
                              style: const TextStyle(
                                  fontSize: 23,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Text(
                          '(Inclusive of all taxes)',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: FirebaseFirestore.instance
                          .collection('Products')
                          .where(
                            'Name',
                            isEqualTo: selectedQuantity != null &&
                                    selectedQuantity!.isNotEmpty
                                ? "$productName $selectedQuantity"
                                : productName,
                          )
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                              height: 40,
                              child:
                                  Center(child: CupertinoActivityIndicator()));
                        }
                        if (snapshot.hasError) {
                          return const SizedBox(
                            height: 40,
                            child:
                                Center(child: Text('Error loading quantities')),
                          );
                        }

                        final firestoreQuantities = snapshot.data?.docs
                                .map((doc) =>
                                    doc.data()['Qty']?.toString() ?? '')
                                .where((qty) => qty.isNotEmpty)
                                .toSet() ??
                            {};

                        var quantitySoh = <String, int>{};
                        for (final doc in snapshot.data?.docs ?? []) {
                          final qty = doc.data()['Qty']?.toString() ?? '';
                          if (qty.isNotEmpty) {
                            quantitySoh[qty] = (doc.data()['SOH'] is int)
                                ? doc.data()['SOH']
                                : int.tryParse(doc
                                            .data()['SOH']
                                            ?.toString()
                                            .split('.')[0] ??
                                        '0') ??
                                    0;
                          }
                        }

                        final allQuantities = {
                          if (docData['Qty'] != null &&
                              docData['Qty'].isNotEmpty)
                            docData['Qty'],
                          ...?quantities,
                          ...firestoreQuantities,
                        }..removeWhere((e) => e.isEmpty);

                        // Sort quantities by numerical value (largest first)
                        final sortedQuantities = allQuantities.toList()
                          ..sort((a, b) {
                            final aNum = int.tryParse(
                                    RegExp(r'\d+').stringMatch(a) ?? '') ??
                                0;
                            final bNum = int.tryParse(
                                    RegExp(r'\d+').stringMatch(b) ?? '') ??
                                0;
                            return bNum.compareTo(aNum); // Largest first
                          });

                        return AddToCartSection(
                          productName: productName,
                          productPrice: hasOffer ? offerPrice : productPrice,
                          productEAN: productEAN,
                          soh: productSoh,
                          imageurl: productImageUrl,
                          type: productType,
                          quantityName: productQty,
                          quantitySoh: quantitySoh,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Quantity selection
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('Products')
                      .where('BaseProductName', isEqualTo: productName)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                          height: 40,
                          child: Center(child: CupertinoActivityIndicator()));
                    }
                    if (snapshot.hasError) {
                      return const SizedBox(
                        height: 40,
                        child: Center(child: Text('Error loading quantities')),
                      );
                    }
                    final firestoreQuantities = snapshot.data?.docs
                            .map((doc) => doc.data()['Qty']?.toString() ?? '')
                            .where((qty) => qty.isNotEmpty)
                            .toSet() ??
                        {};

                    final allQuantities = {
                      if (docData['Qty'] != null && docData['Qty'].isNotEmpty)
                        docData['Qty'],
                      ...?quantities,
                      ...firestoreQuantities,
                    }..removeWhere((e) => e.isEmpty);

                    // Sort quantities by numerical value (largest first)
                    final sortedQuantities = allQuantities.toList()
                      ..sort((a, b) {
                        final aNum =
                            int.tryParse(RegExp(r'\d+').stringMatch(a) ?? '') ??
                                0;
                        final bNum =
                            int.tryParse(RegExp(r'\d+').stringMatch(b) ?? '') ??
                                0;
                        return bNum.compareTo(aNum); // Largest first
                      });

                    if (sortedQuantities.isEmpty)
                      return const SizedBox(height: 5);

                    return SizedBox(
                      height: 60,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Options:',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 5),
                          SizedBox(
                            height: 28,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: sortedQuantities.length,
                              separatorBuilder: (c, i) =>
                                  const SizedBox(width: 6),
                              itemBuilder: (context, index) {
                                final qty = sortedQuantities[index];
                                final isSelected =
                                    qty == ref.watch(selectedQuantityProvider);

                                final docInfo = snapshot.data!.docs
                                    .where((doc) => doc.data()['Qty'] == qty)
                                    .toList()
                                    .firstOrNull;
                                final docId = docInfo?.id;

                                return GestureDetector(
                                  onTap: (!isSelected)
                                      ? () {
                                          ref
                                              .read(selectedQuantityProvider
                                                  .notifier)
                                              .state = qty;

                                          if (docId != null) {
                                            onQuantitySelected(docId);
                                          } else {
                                            print(
                                                'docId is null — cannot call onQuantitySelected');
                                          }
                                        }
                                      : null,
                                  child: Container(
                                    width: 60,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.blue.shade100
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.grey.shade400,
                                        width: 2,
                                      ),
                                    ),
                                    child: Text(
                                      qty,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: isSelected
                                            ? Colors.blue
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 30),
                // Macros, Micros, Ingredients
                Row(
                  children: [
                    if (filteredMacrosMap.isNotEmpty)
                      Expanded(
                        child: InfoCard(
                          icon: Icons.energy_savings_leaf,
                          label: 'Macros',
                          names: filteredMacrosMap.keys.toList(),
                          backgroundColor: Colors.blue.shade50,
                          onMorePressed: () {
                            final detailsString = filteredMacrosMap.entries
                                .map((e) => '${e.key}: ${e.value}')
                                .join('\n');
                            showDetailsDialog(
                              context: context,
                              label: 'Macros',
                              details: detailsString,
                              backgroundColor: Colors.white,
                            );
                          },
                        ),
                      ),
                    const SizedBox(width: 5),
                    if (filteredMicrosMap.isNotEmpty)
                      Expanded(
                        child: InfoCard(
                          icon: Icons.grain,
                          label: 'Micros',
                          names: filteredMicrosMap.keys.toList(),
                          backgroundColor: Colors.green.shade50,
                          onMorePressed: () {
                            final detailsString = filteredMicrosMap.entries
                                .map((e) => '${e.key}: ${e.value}')
                                .join('\n');
                            showDetailsDialog(
                              context: context,
                              label: 'Micronutrients',
                              details: detailsString,
                              backgroundColor: Colors.white,
                            );
                          },
                        ),
                      ),
                    const SizedBox(width: 5),
                    if (validIngredientsList.isNotEmpty)
                      Expanded(
                        child: InfoCard(
                          icon: Icons.restaurant_menu,
                          label: 'Ingredients',
                          names: validIngredientsList,
                          backgroundColor: Colors.yellow.shade50,
                          onMorePressed: () {
                            final detailsString =
                                validIngredientsList.join('\n');
                            showDetailsDialog(
                              context: context,
                              label: 'Ingredients',
                              details: detailsString,
                              backgroundColor: Colors.white,
                            );
                          },
                        ),
                      ),
                    const SizedBox(width: 10),
                  ],
                ),
                const SizedBox(height: 30),
                // Additional product info
                const Divider(),
                Row(
                  children: [
                    const ReusableText(
                      text: 'Brand: ',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    ReusableText(text: productBrand, fontSize: 16),
                  ],
                ),
                const SizedBox(height: 10),
                if (productWhatIs.isNotEmpty) ...[
                  Text(
                    'What is it?',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black,
                      ),
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  ReusableText(text: productWhatIs, fontSize: 14),
                  const SizedBox(height: 20),
                ],
                if (productUseFor.isNotEmpty) ...[
                  Text(
                    'What is it used for?',
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  ReusableText(text: productUseFor, fontSize: 14),
                  const SizedBox(height: 10),
                  Theme(
                    data: Theme.of(context).copyWith(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    child: ExpansionTile(
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                        side: BorderSide.none,
                      ),
                      collapsedShape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                        side: BorderSide.none,
                      ),
                      tilePadding: EdgeInsets.zero,
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Other Product Info",
                            style: GoogleFonts.poppins(
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          ReusableText(
                              text: 'EAN Code: $productEAN', fontSize: 14),
                          if (fssiList.isNotEmpty)
                            ReusableText(
                                text: 'FSSAI: ${fssiList.join('\n')}',
                                fontSize: 14),
                        ],
                      ),
                      children: [
                        const SizedBox(height: 10),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: ReusableText(
                            text:
                                'Sourced & Marketed by: Cotolore Enterprises LLP, 15/293 - C, Muriyankara-Pinarmunda Milma Road, Peringala (PO), Ernakulam, 683565, Kerala, India.',
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ReusableText(
                            text: 'Country of Origin: $productOrigin',
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: ReusableText(
                            text:
                                'Best Within: $formattedDate from the date of packaging',
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const ReusableText(
                          text:
                              'Disclaimer: The image(s) shown are representative of the actual product While every effort has been made to maintain accurate and up to date product related content, it is recommended to read product labels, batch and manufacturing/packing details along with warnings and directions before using or consuming a packed product.',
                          fontSize: 14,
                        ),
                        const SizedBox(height: 10),
                        const ReusableText(
                          text:
                              'Customer Service: For Queries/Feedback/Complaints, contact our customer care executive at 8848673425.',
                          fontSize: 14,
                        ),
                        const SizedBox(height: 10),
                        const ReusableText(
                          text:
                              'Address: Cotolore Enterprises LLP, 15/293 - C, Muriyankara-Pinarmunda Milma Road, Peringala (PO), Ernakulam, 683565, Kerala, India.',
                          fontSize: 14,
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
                ReviewsSection(productName: productName),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
