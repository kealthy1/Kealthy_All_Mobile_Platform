import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/Cart/cart.dart';
import 'package:kealthy/view/Cart/cart_controller.dart';

// Provider for total item count in cart
final cartItemCountProvider = StateProvider<int>((ref) => 0);

class CartContainer extends ConsumerWidget {
  const CartContainer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch totalItems count from the provider
    final cartItems = ref.watch(cartProvider);
    final totalItems =
        cartItems.fold<int>(0, (sum, item) => sum + item.quantity);

    // If no items in the cart, return an empty widget
    if (totalItems == 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        // Navigate to Cart page when tapped
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => const CartPage(),
          ),
        );
      },
      child: Container(
        height: 70,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          // color: Colors.white,
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 255, 255, 255), // Light blue
              Color.fromARGB(255, 255, 239, 221), // Lighter blue
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 3,
              spreadRadius: 5,
            ),
          ],
          // color: Color.fromARGB(
          //     255, 243, 240, 240), // This will be overridden by the gradient
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.circular(10),
          ),
        ),
        child: Row(
          children: [
            Image.asset(
              'lib/assets/images/bag.png',
              width: 30,
              color: Colors.black,
            ),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                'Cart',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              Text(
                '$totalItems item(s) selected',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.black,
                ),
              ),
            ]),
            const Spacer(),
            const SizedBox(width: 10),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 255, 255, 255),
                    Color.fromARGB(255, 255, 255, 255),
                    // Lighter blue
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                shape: BoxShape.circle,
                color: Colors
                    .grey.shade200, // Change if you want a different background
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.black,
                size: 18, // slightly smaller inside circle
              ),
            ),
          ],
        ),
      ),
    );
  }
}
