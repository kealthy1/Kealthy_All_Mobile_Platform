import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/Cart/cart_controller.dart';
import 'package:kealthy/view/product/product_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

/// Model that maps your Firestore document
class TrialDish {
  final String id;
  final String name;
  final int stock;
  final int price;
  final List<String> quantities;
  final Map<String, dynamic> quantityIds;
  final Map<String, num> quantityPrices;
  final Set<num> prices;
  Map<String, dynamic> productNames;
  final String ingredients;
  final String imageurl;
  final String what;
  final String nutrients;
  final String fiber;
  final String energy;
  final String protein;
  final String saturatedFat;
  final String totalFat;
  final String transFat;
  final String unsaturatedFat;
  final String whatisitusedfor;
  final String sugar;
  final String carbs;
  final Map<String, int>? quantitySoh;
  final String category;

  TrialDish({
    required this.id,
    required this.name,
    required this.stock,
    required this.price,
    required this.quantities,
    required this.quantityPrices,
    required this.productNames,
    required this.quantityIds,
    required this.prices,
    required this.ingredients,
    required this.imageurl,
    required this.what,
    required this.nutrients,
    required this.fiber,
    required this.energy,
    required this.protein,
    required this.saturatedFat,
    required this.totalFat,
    required this.transFat,
    required this.unsaturatedFat,
    required this.whatisitusedfor,
    required this.sugar,
    required this.carbs,
    this.quantitySoh,
    required this.category,
  });

  factory TrialDish.fromFirestore(
      String id,
      Map<String, dynamic> data,
      List<String> quantities,
      Map<String, num> quantityPrices,
      Map<String, dynamic> quantityIds,
      Map<String, int> quantitySoh,
      Map<String, dynamic> productNames) {
    // Create set of unique prices from quantityPrices
    final prices = quantityPrices.values.toSet();
    return TrialDish(
        id: id,
        name: data['Name'] ?? '',
        quantityIds: quantityIds,
        carbs: data['Total Carbohydrates (g)'] ?? '',
        sugar: data['Sugars (g)'] ?? '',
        unsaturatedFat: data['Unsaturated Fat (g)'] ?? '',
        transFat: data['Trans Fat (g)'] ?? '',
        totalFat: data['Total Fat (g)'] ?? '',
        saturatedFat: data['Saturated Fat (g)'] ?? '',
        protein: data['Protein (g)'] ?? '',
        what: data['What is it?'] ?? '',
        whatisitusedfor: data['What is it used for?'] ?? '',
        energy: data['Energy (kcal)'] ?? '',
        fiber: data['Dietary Fiber (g)'] ?? '',
        nutrients: data['Vendor Name'] ?? '',
        stock: data['SOH'] is int
            ? data['SOH']
            : int.tryParse(data['SOH']?.toString() ?? '0') ?? 0,
        price: data['Price'] is num
            ? data['Price']
            : int.tryParse(data['Price']?.toString() ?? '0') ?? 0,
        quantities: quantities,
        quantityPrices: quantityPrices,
        productNames: productNames,
        prices: prices,
        ingredients: (data['Ingredients'] as List?)?.join(', ') ?? '',
        imageurl: (data['ImageUrl'] is List && data['ImageUrl'].isNotEmpty)
            ? data['ImageUrl'][0]
            : '',
        quantitySoh: quantitySoh,
        category: data['Category']);
  }
}

final dishesProvider =
    StreamProvider.family<List<TrialDish>, String?>((ref, categoryName) async* {
  yield* FirebaseFirestore.instance
      .collection('Products')
      .where('Type', isEqualTo: categoryName)
      .snapshots()
      .map((snapshot) {
    final dishMap = <String, Map<String, dynamic>>{};
    final quantityMap = <String, List<String>>{};
    final priceMap = <String, Map<String, num>>{};
    final baseNameMap = <String, String>{};
    final quantitySohMap = <String, Map<String, int>>{};
    for (var doc in snapshot.docs) {
      final fullName = doc.data()['Name']?.toString() ?? '';
      final quantity = doc.data()['Qty']?.toString() ?? '';
      final baseProductName =
          doc.data()['BaseProductName']?.toString() ?? fullName;
      final data = Map<String, dynamic>.from(doc.data())..['id'] = doc.id;

      final baseName = RegExp(r'^(.*?)\s*\d+\s*[a-zA-Z]+$')
              .firstMatch(fullName)
              ?.group(1)
              ?.trim() ??
          baseProductName;

      if (!dishMap.containsKey(baseName)) {
        dishMap[baseName] = data;
        dishMap[baseName]!['Name'] = baseName;
      }

      // Collect unique quantities and prices for this base name
      if (quantity.isNotEmpty) {
        quantitySohMap[baseName] = quantitySohMap[baseName] ?? {};
        quantitySohMap[baseName]![quantity] =
            int.tryParse(doc.data()['SOH'].toString()) ?? 0;
        quantityMap[baseName] = quantityMap[baseName] ?? [];
        priceMap[baseName] = priceMap[baseName] ?? {};
        if (!quantityMap[baseName]!.contains(quantity)) {
          quantityMap[baseName]!.add(quantity);
          priceMap[baseName]![quantity] =
              (data['offer_price'] is num && data['offer_price'] > 0)
                  ? data['offer_price']
                  : (data['Price'] is num
                      ? data['Price']
                      : int.tryParse(data['Price']?.toString() ?? '0') ?? 0);
        }
      }

      baseNameMap[doc.id] = baseName;
    }

    return dishMap.entries.map((entry) {
      final baseName = entry.key;
      final quantities = quantityMap[baseName] ?? ['Default'];
      quantities.sort((a, b) {
        final aNum = int.tryParse(RegExp(r'\d+').stringMatch(a) ?? '') ?? 0;
        final bNum = int.tryParse(RegExp(r'\d+').stringMatch(b) ?? '') ?? 0;
        return bNum.compareTo(aNum);
      });
      final priceData = priceMap[baseName] ?? {};

      final quantityIds = <String, dynamic>{};
      final productNames = <String, dynamic>{};

      for (final qty in quantities) {
        final id = entry.value['id'];

        final name = entry.value['Name']?.toString() ?? baseName;

        productNames[qty] = {
          'id': id,
          'name': name,
        };

        quantityIds[qty] = id;
      }
      final quantityPrices =
          priceMap[baseName] ?? {quantities.first: entry.value['Price'] ?? 0};

      return TrialDish.fromFirestore(
        entry.value['id'] ?? '',
        entry.value,
        quantities,
        quantityPrices,
        quantityIds,
        quantitySohMap[baseName] ?? {},
        productNames,
      );
    }).toList();
  });
});

class FoodSubCategoryPage extends ConsumerStatefulWidget {
  final String categoryName;
  const FoodSubCategoryPage({
    super.key,
    required this.categoryName,
  });

  @override
  ConsumerState<FoodSubCategoryPage> createState() =>
      _FoodSubCategoryPageState();
}

class _FoodSubCategoryPageState extends ConsumerState<FoodSubCategoryPage> {
  final TextEditingController _suggestionController = TextEditingController();
  final Map<String, String?> _selectedQuantities = {};

  @override
  Widget build(BuildContext context) {
    final dishesAsync = ref.watch(dishesProvider(widget.categoryName));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categoryName,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        surfaceTintColor: Colors.white,
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
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: IconButton(
                        key: ValueKey<int>(itemCount),
                        icon: const Icon(CupertinoIcons.cart, size: 30),
                        onPressed: () => Navigator.pushNamed(context, '/cart'),
                      ),
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
                          constraints:
                              const BoxConstraints(minWidth: 18, minHeight: 18),
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
      body: dishesAsync.when(
        loading: () => const Center(child: CupertinoActivityIndicator()),
        error: (e, _) => const Center(child: Text("Error loading dishes")),
        data: (dishes) {
          print("Fetched dishes: ${dishes.length}");
          if (dishes.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('lib/assets/images/restaurant.png',
                        width: 60, color: Colors.black),
                    const SizedBox(height: 16),
                    Text(
                      'New dishes coming soon!',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'What would you like to add to this menu?',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _suggestionController,
                            decoration: const InputDecoration(
                              hintText: 'Suggest a dish...',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5))),
                            onPressed: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final phoneNumber =
                                  prefs.getString('phoneNumber') ?? 'Unknown';
                              final suggestion =
                                  _suggestionController.text.trim();

                              if (suggestion.isNotEmpty) {
                                await FirebaseFirestore.instance
                                    .collection('MenuSuggestions')
                                    .add({
                                  'suggestion': suggestion,
                                  'phoneNumber': phoneNumber,
                                  'timestamp': DateTime.now(),
                                });
                                _suggestionController.clear();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Thank you for your suggestion!')),
                                );
                              }
                            },
                            child: const Text(
                              'Submit',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: GridView.builder(
              itemCount: dishes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.65,
              ),
              itemBuilder: (context, index) {
                return _buildFoodItem(dishes[index]);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildFoodItem(TrialDish dish) {
    const till11 = [
      'Herbrost Chicken Veggie Bowl',
      'Buttercraft Beef Tenderloin Bowl',
      'Masalacraft Tuna Bowl',
      'Millet Pasta Veggie Bowl',
      'Mushroom Mix Thai Bowl',
      'Non-Veg Style Cauli Rice Bowl',
      'Quinoa & Tuna Fusion Bowl',
      'Soya Paneer Bowl',
      'Egg Veggie Power Salad',
      'Chicken Veggie Power Salad',
    ];

    const after11 = [
      'Herbrost Beef Tenderloin Bowl',
      'Buttercraft Chicken Bowl',
      'Herbrost Tuna Fish Bowl',
      'Millet Pasta Chicken Bowl',
      'Tuna & Vegetable Protein Bowl',
      'Mushroom Mix Conti Bowl',
      'Veg Style Cauli Rice Bowl',
      'Soya Paneer Bowl',
      'Egg Veggie Power Salad',
      'Chicken Veggie Power Salad',
    ];

    const common = [
      'Soya Paneer Bowl',
      'Egg Veggie Power Salad',
      'Chicken Veggie Power Salad',
    ];

    final isTill11 = till11.contains(dish.name);
    final isAfter11 = after11.contains(dish.name);
    final isCommon = common.contains(dish.name);

    final currentHour = DateTime.now().hour + DateTime.now().minute / 60.0;

    bool isInSlot1 = currentHour >= 17.0 || currentHour < 11.0;
    bool isInSlot2 = currentHour >= 11.0 && currentHour < 17.0;

    final isInList = isTill11 || isAfter11 || isCommon;

    final isAvailableNow = !isInList ||
        isCommon ||
        (isTill11 && isInSlot1) ||
        (isAfter11 && isInSlot2);

    _selectedQuantities[dish.id] ??= dish.quantities.first;

    final availableQuantities = dish.quantities
        .where((q) => (dish.quantitySoh?[q] ?? dish.stock) > 0)
        .toList()
      ..sort((a, b) => (dish.quantityPrices[b] ?? dish.price)
          .compareTo(dish.quantityPrices[a] ?? dish.price));
    if (!availableQuantities.contains(_selectedQuantities[dish.id])) {
      _selectedQuantities[dish.id] =
          availableQuantities.isNotEmpty ? availableQuantities.first : null;
    }
    final selectedQuantity = _selectedQuantities[dish.id];
    final selectedPrice = selectedQuantity != null
        ? dish.quantityPrices[selectedQuantity] ?? dish.price
        : dish.price;

    final isOutOfStock =
        dish.quantitySoh?.values.every((soh) => soh <= 0) ?? dish.stock == 0;

    return IgnorePointer(
      ignoring: isOutOfStock || !isAvailableNow,
      child: Opacity(
        opacity: (isOutOfStock || !isAvailableNow) ? 0.5 : 1,
        child: GestureDetector(
          onTap: () {
            if (isAvailableNow && !isOutOfStock) {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => ProductPage(
                      productIds: dish.quantityIds,
                      prices: dish.quantityPrices,
                      productId: dish.id,
                      quantities: dish.quantities,
                      selectedQuantity: _selectedQuantities[dish.id],
                      productName: dish.productNames),
                ),
              );
            }
          },
          child: Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (dish.imageurl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: CachedNetworkImage(
                          imageUrl: dish.imageurl,
                          width: double.infinity,
                          height: MediaQuery.of(context).size.width * 0.32,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: double.infinity,
                              height: 200,
                              color: Colors.white,
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            height: 200,
                            color: Colors.grey[200],
                            child: const Center(
                                child: Icon(Icons.image_not_supported)),
                          ),
                        ),
                      ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Text(
                        overflow: TextOverflow.ellipsis,
                        maxLines: 3,
                        dish.name,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          "\u20B9$selectedPrice",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            color: !isOutOfStock ? Colors.black87 : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        DropdownButton<String>(
                          value: availableQuantities
                                  .contains(_selectedQuantities[dish.id])
                              ? _selectedQuantities[dish.id]
                              : (availableQuantities.isNotEmpty
                                  ? availableQuantities.first
                                  : null),
                          items: (availableQuantities.toList()
                                ..sort((a, b) {
                                  final aNum = int.tryParse(
                                          RegExp(r'\d+').stringMatch(a) ??
                                              '') ??
                                      0;
                                  final bNum = int.tryParse(
                                          RegExp(r'\d+').stringMatch(b) ??
                                              '') ??
                                      0;
                                  return bNum.compareTo(aNum);
                                }))
                              .map((String quantity) {
                            final isAvailable =
                                (dish.quantitySoh?[quantity] ?? dish.stock) > 0;

                            return DropdownMenuItem<String>(
                              value: quantity,
                              enabled: isAvailable,
                              child: IgnorePointer(
                                ignoring: !isAvailable,
                                child: Opacity(
                                  opacity: !isAvailable ? 0.5 : 1,
                                  child: Text(
                                    quantity,
                                    style: GoogleFonts.poppins(
                                        fontSize: 14, color: Colors.black),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: dish.stock > 0
                              ? (String? newValue) {
                                  setState(() {
                                    _selectedQuantities[dish.id] = newValue!;
                                    print(
                                        '🔄 Selected quantity for ${dish.name}: $newValue, Price: ${dish.quantityPrices[newValue]}');
                                  });
                                }
                              : null,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (isOutOfStock)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Out of Stock',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
