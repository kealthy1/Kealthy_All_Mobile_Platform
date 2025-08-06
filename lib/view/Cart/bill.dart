import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/Cart/row_text.dart';

class BillDetailsWidget extends StatelessWidget {
  final double itemTotal;
  final double distanceInKm;
  // final double instantDeliveryFee;
  final double offerDiscount;
  final void Function(double)? onTotalCalculated;

  const BillDetailsWidget({
    super.key,
    required this.itemTotal,
    required this.distanceInKm,
    // required this.instantDeliveryFee,
    this.offerDiscount = 0.0,
    this.onTotalCalculated,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate the discounted delivery fee
    double discountedFee = _calculateDiscountedFee(itemTotal, distanceInKm);

    // Check if free delivery is unlocked
    bool isFreeDelivery =
        (discountedFee == 0 && itemTotal >= 199 && distanceInKm <= 7);

    // Original delivery fee (without discount)
    double originalFee = distanceInKm * 10;

    // Fixed handling fee
    double handlingFee = 5;

    // Product discount logic: Only apply discount if offerDiscount > 0
    double productDiscount =
        offerDiscount > 0 ? (itemTotal >= 50 ? 50 : itemTotal) : 0;
    double adjustedItemTotal = itemTotal - productDiscount;

    // Total amount to pay
    double finalTotalToPay = adjustedItemTotal + discountedFee + handlingFee;
    //double finalTotalToPay = 1;

    // Pass the calculated total up if callback is provided
    if (onTotalCalculated != null) {
      onTotalCalculated!(finalTotalToPay);
      debugPrint(
          '✅ Final To Pay passed to Checkout: ₹${finalTotalToPay.toStringAsFixed(0)}');
    }

    // Dynamic delivery message
    String deliveryMessage = _getDeliveryMessage(
        itemTotal, distanceInKm, discountedFee, originalFee);
    Color messageColor = _getMessageColor(itemTotal, distanceInKm);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 1),
            ),
          ],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              "Bill Details",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 10),

            // Dynamic Delivery Message
            if (deliveryMessage.isNotEmpty)
              Text(
                deliveryMessage,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: messageColor,
                ),
              ),
            const SizedBox(height: 10),

            // Item Total
            RowTextWidget(
                label: "Item Total", value: "₹${itemTotal.toStringAsFixed(0)}"),
            const SizedBox(height: 5),

            if (offerDiscount > 0) ...[
              RowTextWidget(
                  label: "FIRST01 Offer",
                  colr: Colors.green,
                  value: "₹${productDiscount.toStringAsFixed(0)}"),
              const SizedBox(height: 5),
              RowTextWidget(
                  label: "Discounted Price",
                  colr: Colors.black,
                  value: "₹${adjustedItemTotal.toStringAsFixed(0)}"),
              const SizedBox(height: 5),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Delivery Fee | ${distanceInKm.toStringAsFixed(2)} km",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (originalFee > discountedFee && !isFreeDelivery)
                      Text(
                        '₹${originalFee.toStringAsFixed(0)} ',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    const SizedBox(width: 5),
                    if (isFreeDelivery)
                      Text(
                        'Free',
                        style: GoogleFonts.poppins(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      )
                    else
                      Text(
                        '₹${discountedFee.toStringAsFixed(0)}',
                        style: GoogleFonts.poppins(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 5),

            // Handling Fee
            RowTextWidget(
                label: "Handling Fee",
                value: "₹${handlingFee.toStringAsFixed(0)}"),
            const SizedBox(height: 5),

            // Instant Delivery Fee
            // if (instantDeliveryFee > 0)
            //   RowTextWidget(
            //       label: "Instant Delivery Fee",
            //       value: "₹${instantDeliveryFee.toStringAsFixed(0)}"),

            const Divider(),
            const SizedBox(height: 5),

            // Final To Pay
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "To Pay",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  "₹${finalTotalToPay.toStringAsFixed(0)}",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// **Calculates the delivery fee based on total price & distance**
  double _calculateDiscountedFee(double itemTotal, double distanceInKm) {
    double fee = 0.0;

    if (itemTotal >= 199) {
      if (distanceInKm <= 7) {
        fee = 0;
      } else if (distanceInKm <= 15) {
        fee = (distanceInKm - 7) * 8;
      } else {
        fee = ((distanceInKm - 15) * 12) + ((15 - 7) * 8);
      }
    } else {
      if (distanceInKm <= 7) {
        fee = 50;
      } else if (distanceInKm <= 15) {
        fee = 50 + ((distanceInKm - 7) * 10);
      } else {
        fee = 50 + (8 * 10) + ((distanceInKm - 15) * 12);
      }
    }
    return fee;
  }

  /// **Generates a message based on order total and distance**
  String _getDeliveryMessage(double itemTotal, double distanceInKm,
      double discountedFee, double originalFee) {
    double neededForFreeDelivery = 199 - itemTotal;
    if (itemTotal >= 199 && distanceInKm <= 7) {
      return 'You Unlocked A Free Delivery 🎉';
    } else if (itemTotal < 199 && distanceInKm <= 7) {
      return 'Purchase for ₹${neededForFreeDelivery.toStringAsFixed(0)} more to unlock Free Delivery!';
    } else if (itemTotal < 199 && distanceInKm > 7 && distanceInKm <= 15) {
      return 'Purchase for ₹${neededForFreeDelivery.toStringAsFixed(0)} more and pay delivery fee ₹${((distanceInKm - 7) * 8).toStringAsFixed(0)}/- Only';
    } else if (itemTotal >= 199 && distanceInKm > 7) {
      double savings = originalFee - discountedFee;
      return 'Unlocked A Discounted Delivery Fee ! You saved ₹${savings.toStringAsFixed(0)} on This Order!  🎉';
    }
    return '';
  }

  /// **Determines the color of the delivery message**
  Color _getMessageColor(double itemTotal, double distanceInKm) {
    if (itemTotal >= 199 && distanceInKm <= 7) {
      return Colors.green;
    } else if (itemTotal < 199) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}
