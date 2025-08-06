import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/Cart/cart_controller.dart';
import 'package:kealthy/view/product/all_products.dart';
import 'package:shimmer/shimmer.dart';

class SubCategoryPage extends StatefulWidget {
  final String categoryName; // e.g., "Personal Care"

  const SubCategoryPage({required this.categoryName, super.key});

  @override
  State<SubCategoryPage> createState() => _SubCategoryPageState();
}

class _SubCategoryPageState extends State<SubCategoryPage> {
  @override
  Widget build(BuildContext context) {
    // ignore: sized_box_for_whitespace
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            surfaceTintColor: Colors.white,
            title: Text(
              widget
                  .categoryName, // Displays "Personal Care" (the parent category)
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
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('SubCategory')
                  .where('Category', isEqualTo: widget.categoryName)
                  .snapshots(),
              builder: (context, snapshot) {
                // 1. Handle loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CupertinoActivityIndicator(
                          color: Color.fromARGB(255, 65, 88, 108)));
                }
                // 2. Handle empty data
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                      child: Text(
                    "No subcategories available",
                    style: GoogleFonts.poppins(),
                  ));
                }

                // 3. We have data
                final subcategories = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: subcategories.length,
                  itemBuilder: (context, index) {
                    final subcategoryDoc = subcategories[index];
                    final subcategoryName =
                        subcategoryDoc['Subcategory'] ?? 'No Subcategory Name';
                    final imageUrl = subcategoryDoc['ImageUrl'] ?? '';
                    final title = subcategoryDoc['Title'] ?? 'No Title';

                    return GestureDetector(
                      onTap: () {
                        // On tap, navigate to the products list
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => AllProductsPage(
                              subcategoryName: subcategoryName,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 3, vertical: 2),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.grey,
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.white,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: imageUrl.isNotEmpty &&
                                              Uri.tryParse(imageUrl)
                                                      ?.hasAbsolutePath ==
                                                  true
                                          ? CachedNetworkImage(
                                              imageUrl: imageUrl,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Shimmer.fromColors(
                                                baseColor: Colors.grey[300]!,
                                                highlightColor:
                                                    Colors.grey[100]!,
                                                child: Container(
                                                  width: 80,
                                                  height: 80,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(
                                                Icons.error,
                                                color: Colors.red,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.image_not_supported,
                                              size: 40,
                                              color: Colors.grey),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      subcategoryName,
                                      style: GoogleFonts.poppins(
                                        color: Colors.black,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      title,
                                      style: GoogleFonts.poppins(
                                        color: Colors.black45,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // floatingActionButton removed
        ),
        // ignore: prefer_const_constructors
      ],
    );
  }
}
