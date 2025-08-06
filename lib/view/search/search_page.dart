import 'dart:async';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/product/product_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

/// Product model
class Product {
  final String id;
  final String name;
  final String qty;
  final String brandName;
  final String price;
  final List<dynamic> imageUrls;

  Product({
    required this.id,
    required this.name,
    required this.qty,
    required this.brandName,
    required this.price,
    required this.imageUrls,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['Name'] ?? 'Unknown Product',
      qty: data['Qty']?.toString() ?? '0',
      price: data['Price']?.toString() ?? '0',
      brandName: data['Brand Name'] ?? '',
      imageUrls: data['ImageUrl'] is List ? data['ImageUrl'] as List : [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'qty': qty,
        'brandName': brandName,
        'price': price,
        'imageUrls': imageUrls,
      };

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      qty: json['qty'],
      brandName: json['brandName'],
      price: json['price'],
      imageUrls: List<dynamic>.from(json['imageUrls']),
    );
  }
}

final isSearchingProvider = StateProvider<bool>((ref) => false);
final loadedProductCountProvider = StateProvider<int>((ref) => 11);

/// Providers
final productsProvider = StateProvider<List<Product>>((ref) => []);
final searchQueryProvider = StateProvider<String>((ref) => "");
final recentSearchesProvider =
    StateNotifierProvider<RecentSearchesNotifier, List<Product>>(
  (ref) => RecentSearchesNotifier(),
);

/// Recent Searches Notifier
class RecentSearchesNotifier extends StateNotifier<List<Product>> {
  RecentSearchesNotifier() : super([]) {
    _loadRecentSearches(); // Load recent searches on initialization
  }

  void addRecentSearch(Product product) {
    if (!state.any((p) => p.id == product.id)) {
      state = [product, ...state.take(4)]; // Limit to the last 5 searches
    }
  }

  void removeRecentSearch(Product product) {
    state = state.where((p) => p.id != product.id).toList();
  }

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final recentSearchesJson = prefs.getStringList('recentSearches') ?? [];
    state = recentSearchesJson
        .map((jsonString) => Product.fromJson(json.decode(jsonString)))
        .toList();
  }
}

/// Search Page
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  late Future<List<Product>> _productsFuture;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _productsFuture = _fetchAllProducts();

    // Reset the search query when entering the page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchQueryProvider.notifier).state = ""; // Clear search query
      _searchController.clear(); // Clear search bar
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Fetch all products
  Future<List<Product>> _fetchAllProducts() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final snapshot = await firestore.collection('Products').get();

      if (snapshot.docs.isEmpty) {
        print("⚠️ Firestore: No products found in the 'Products' collection.");
        return [];
      }

      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        print("✅ Firestore Data: ${doc.id} => $data");

        return Product.fromFirestore(doc); // Use the updated Product model
      }).toList();

      print("✅ Loaded ${products.length} products.");
      ref.read(productsProvider.notifier).state = products;

      return products;
    } catch (e, stackTrace) {
      print("❌ Error fetching products: $e");
      print(stackTrace);
      return [];
    }
  }

  List<Product> _paginateProducts(List<Product> products, int count) {
    return products.take(count).toList();
  }

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);
    final products = ref.watch(productsProvider);
    final recentSearches = ref.watch(recentSearchesProvider);

    // Filter products based on the search query
    final trimmedQuery = searchQuery.trim().toLowerCase();

    final filteredProducts = trimmedQuery.isEmpty
        ? products
        : products.where((product) {
            final lowerName = product.name.toLowerCase();
            final lowerBrandName = product.brandName.toLowerCase();

            return lowerName.contains(trimmedQuery) ||
                lowerBrandName.contains(trimmedQuery);
          }).toList()
      ..sort((a, b) {
        if (a.name.toLowerCase().startsWith(trimmedQuery)) {
          return -1; // Prioritize exact matches
        } else if (b.name.toLowerCase().startsWith(trimmedQuery)) {
          return 1;
        }
        return a.name.compareTo(b.name);
      });

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        title: Text(
          'Search Healthy Products',
          style: GoogleFonts.poppins(
            color: Colors.black,
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: FutureBuilder<List<Product>>(
          future: _productsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CupertinoActivityIndicator(
                      color: Color.fromARGB(255, 65, 88, 108)));
            } else if (snapshot.hasError) {
              return Center(
                  child: Text(
                "Error loading products",
                style: GoogleFonts.poppins(),
              ));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                  child: Text(
                "No products found.",
                style: GoogleFonts.poppins(),
              ));
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildSearchBar(),
                  if (recentSearches.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      "Recent Searches",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildRecentSearches(recentSearches),
                  ],
                  const SizedBox(height: 20),
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.6,
                            ),
                            itemCount: (ref.watch(loadedProductCountProvider) <
                                    filteredProducts.length)
                                ? _paginateProducts(
                                            filteredProducts,
                                            ref.watch(
                                                loadedProductCountProvider))
                                        .length +
                                    1
                                : _paginateProducts(filteredProducts,
                                        ref.watch(loadedProductCountProvider))
                                    .length,
                            itemBuilder: (context, index) {
                              final paginated = _paginateProducts(
                                  filteredProducts,
                                  ref.watch(loadedProductCountProvider));

                              // 👇 Last tile will be Load More button
                              if (index == paginated.length &&
                                  ref.watch(loadedProductCountProvider) <
                                      filteredProducts.length) {
                                return GestureDetector(
                                  onTap: () {
                                    ref
                                        .read(
                                            loadedProductCountProvider.notifier)
                                        .state += 11;
                                  },
                                  child: Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "Load More",
                                          style: GoogleFonts.poppins(
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        const Icon(
                                          CupertinoIcons
                                              .arrow_right_circle_fill,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final product = paginated[index];
                              final imageUrl = product.imageUrls.isNotEmpty
                                  ? product.imageUrls.first.toString()
                                  : '';

                              return GestureDetector(
                                onTap: () {
                                  ref
                                      .read(recentSearchesProvider.notifier)
                                      .addRecentSearch(product);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ProductPage(productId: product.id,quantities: [product.qty],),
                                          
                                    ),
                                  );
                                },
                                child: IntrinsicHeight(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 3)
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius:
                                                const BorderRadius.vertical(
                                                    top: Radius.circular(8)),
                                            child: CachedNetworkImage(
                                              imageUrl: imageUrl,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                              placeholder: (context, url) =>
                                                  Shimmer.fromColors(
                                                baseColor: Colors.grey[300]!,
                                                highlightColor:
                                                    Colors.grey[100]!,
                                                child: Container(
                                                    color: Colors.white),
                                              ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      Container(
                                                color: Colors.grey.shade200,
                                                child: const Icon(
                                                    Icons.broken_image),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              SizedBox(
                                                height: 50,
                                                child: Text(
                                                  product.name,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 16,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(
                                                  height:
                                                      6), // reserve space for rating if needed
                                              Row(
                                                children: [
                                                  Text(
                                                    '₹ ${product.price}',
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 15,
                                                      color:
                                                          Colors.green.shade800,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  Text(
                                                    product.qty,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 12,
                                                      color: Colors.black,
                                                      fontWeight:
                                                          FontWeight.w400,
                                                    ),
                                                  ),
                                                ],
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
                        ),
                      ],
                    ),
                  )
                ],
              );
            }
          },
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final isSearching = ref.watch(isSearchingProvider);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _focusNode,
        cursorHeight: 20,
        onChanged: (value) async {
          // Trigger the loading state
          ref.read(isSearchingProvider.notifier).state = true;
          await Future.delayed(
              const Duration(milliseconds: 500)); // Simulate delay
          ref.read(searchQueryProvider.notifier).state = value;
          // Stop loading state after processing
          ref.read(isSearchingProvider.notifier).state = false;
        },
        decoration: InputDecoration(
          constraints: const BoxConstraints(maxHeight: 40.0),
          hintText: 'Search for products',
          hintStyle: GoogleFonts.poppins(
            color: Colors.black54,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: const Icon(CupertinoIcons.search, color: Colors.green),
          suffixIcon: isSearching
              ? const Padding(
                  padding: EdgeInsets.all(
                      10.0), // Adjust padding to position the spinner
                  child: SizedBox(
                      width: 6,
                      height: 6,
                      child: CupertinoActivityIndicator(
                          color: Color.fromARGB(255, 65, 88, 108))),
                )
              : null, // Show nothing if not searching
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildRecentSearches(List<Product> recentSearches) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: recentSearches.map((product) {
          return GestureDetector(
            onTap: () {
              ref
                  .read(recentSearchesProvider.notifier)
                  .addRecentSearch(product);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductPage(productId: product.id, ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(
                      width: 10,
                    ),
                    GestureDetector(
                      onTap: () {
                        ref
                            .read(recentSearchesProvider.notifier)
                            .removeRecentSearch(product);
                      },
                      child: const Icon(
                        CupertinoIcons.clear_circled,
                        size: 25,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
