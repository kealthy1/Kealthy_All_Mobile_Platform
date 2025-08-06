import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/Cart/cart_controller.dart';
import 'package:kealthy/view/product/alert_dialogue.dart';
import 'package:kealthy/view/product/product_content.dart';

final currentPageProvider = StateProvider<int>((ref) => 0);
final selectedQuantityProvider = StateProvider<String?>((ref) => null);
final currentProductIdProvider = StateProvider<String?>((ref) => null);

class ProductPage extends ConsumerStatefulWidget {
  final String productId;
  final List<String>? quantities;
  Map<String, num>? prices;
  final String? selectedQuantity;
  Map<String, dynamic>? productIds;
  Map<String, dynamic>? productName;

  ProductPage(
      {super.key,
      required this.productId,
      this.quantities,
      this.prices,
      this.selectedQuantity,
      this.productIds,
      this.productName});

  @override
  ConsumerState<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends ConsumerState<ProductPage>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pageController = PageController();
    // Initialize currentProductIdProvider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentProductIdProvider.notifier).state = widget.productId;
      ref.read(selectedQuantityProvider.notifier).state =
          widget.selectedQuantity ??
              (widget.quantities?.isNotEmpty ?? false
                  ? widget.quantities!.first
                  : '');
      print(
          '🔄 Initialized selectedQuantityProvider with: ${ref.read(selectedQuantityProvider)}, productId: ${ref.read(currentProductIdProvider)}');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
    super.dispose();
  }

  void onQuantitySelected(String newProductId, String newQuantity) {
    ref.read(currentProductIdProvider.notifier).state = newProductId;
    ref.read(selectedQuantityProvider.notifier).state = newQuantity;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final selectedQuantity = ref.watch(selectedQuantityProvider);
    final currentProductId =
        ref.watch(currentProductIdProvider) ?? widget.productId;

    return Scaffold(
      appBar: AppBar(
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
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return ScaleTransition(scale: animation, child: child);
                      },
                      child: IconButton(
                        key: ValueKey<int>(itemCount),
                        icon: const Icon(CupertinoIcons.cart, size: 30),
                        onPressed: () {
                          Navigator.pushNamed(context, '/cart');
                        },
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
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('Products')
                  .doc(currentProductId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CupertinoActivityIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                      child: Text(
                    'Error: ${snapshot.error}',
                    style: GoogleFonts.poppins(),
                  ));
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return Center(
                      child: Column(
                    children: [
                      const Icon(CupertinoIcons.exclamationmark_circle,
                          size: 50, color: Colors.black),
                      const SizedBox(height: 10),
                      Text(
                        'Product not found.',
                        style: GoogleFonts.poppins(),
                      ),
                    ],
                  ));
                }
                final docData = snapshot.data!.data()!;
                return ProductContent(
                  productIDs: widget.productIds,
                  productNames: widget.productName,
                  prices: widget.prices,
                  docData: docData,
                  pageController: _pageController,
                  productId: currentProductId,
                  quantities: widget.quantities,
                  selectedQuantity: selectedQuantity,
                  onQuantitySelected: (newProductId) {
                    final newQty = docData['Qty'] ?? selectedQuantity;
                    onQuantitySelected(newProductId, newQty);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

void showDetailsDialog({
  required BuildContext context,
  required String label,
  required String details,
  required Color backgroundColor,
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return DetailsDialog(
        label: label,
        details: details,
        backgroundColor: backgroundColor,
      );
    },
  );
}