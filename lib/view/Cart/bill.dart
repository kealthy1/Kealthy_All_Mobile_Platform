import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/Cart/row_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BillDetailsWidget extends StatefulWidget {
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
  State<BillDetailsWidget> createState() => _BillDetailsWidgetState();
}

class _BillDetailsWidgetState extends State<BillDetailsWidget> {
  final TextEditingController _couponController = TextEditingController();
  String _couponStatus = '';
  Color _couponStatusColor = Colors.black;
  double _couponDiscount = 0.0;
  bool _isLoading = false;

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon() async {
    final String enteredCode = _couponController.text.trim().toUpperCase();
    if (enteredCode.isEmpty) {
      setState(() {
        _couponStatus = 'Please enter a coupon code.';
        _couponStatusColor = Colors.orange;
      });
      return;
    }

    if (enteredCode == 'EXPIRED') {
      setState(() {
        _couponStatus = 'Coupon code is expired.';
        _couponStatusColor = Colors.red;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _couponStatus = '';
    });

    try {
      final QuerySnapshot query =
          await FirebaseFirestore.instance.collection('CouponCodes').get();
      final Map<String, dynamic>? data = query.docs.isNotEmpty
          ? query.docs.first.data() as Map<String, dynamic>
          : null;

      if (data == null) {
        setState(() {
          _couponStatus = 'No coupon codes found.';
          _couponStatusColor = Colors.red;
          _couponDiscount = 0.0;
        });
        return;
      }

      bool isMatch = false;
      double discount = 0.0;

      for (var entry in data.entries) {
        final value = entry.value.toString().toUpperCase();
        if (value == enteredCode) {
          isMatch = true;
          // Extract discount percentage from the coupon code (e.g., "DAILYFAN20" -> 20)
          final percentageMatch = RegExp(r'(\d+)').firstMatch(enteredCode);
          if (percentageMatch != null) {
            discount = double.tryParse(percentageMatch.group(0)!) ?? 0.0;
          }
          break;
        }
      }

      if (!isMatch) {
        setState(() {
          _couponStatus = 'Invalid coupon code.';
          _couponStatusColor = Colors.red;
          _couponDiscount = 0.0;
        });
        return;
      }

      if (discount < 10 || discount > 45) {
        setState(() {
          _couponStatus = 'Invalid discount percentage.';
          _couponStatusColor = Colors.red;
          _couponDiscount = 0.0;
        });
        return;
      }

      setState(() {
        _couponDiscount = discount;
        _couponStatus = 'Coupon applied successfully! $discount% off.';
        _couponStatusColor = Colors.green;
      });
    } catch (e) {
      setState(() {
        _couponStatus = 'Error applying coupon. Please try again.';
        _couponStatusColor = Colors.red;
        _couponDiscount = 0.0;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Calculate the discounted delivery fee
    double discountedFee =
        _calculateDiscountedFee(widget.itemTotal, widget.distanceInKm);

    // Check if free delivery is unlocked
    bool isFreeDelivery = (discountedFee == 0 &&
        widget.itemTotal >= 199 &&
        widget.distanceInKm <= 7);

    // Original delivery fee (without discount)
    double originalFee = widget.distanceInKm * 10;

    // Fixed handling fee
    double handlingFee = 5;

    // Product discount logic: Only apply discount if offerDiscount > 0
    double productDiscount = widget.offerDiscount > 0
        ? (widget.itemTotal >= 50 ? 50 : widget.itemTotal)
        : 0;
    double adjustedItemTotal = widget.itemTotal - productDiscount;

    // Apply coupon discount if > 0
    double couponDiscountAmount = 0.0;
    if (_couponDiscount > 0) {
      couponDiscountAmount = (adjustedItemTotal * _couponDiscount / 100);
      adjustedItemTotal -= couponDiscountAmount;
    }

    // Total amount to pay
    double finalTotalToPay = adjustedItemTotal + discountedFee + handlingFee;

    // Pass the calculated total up if callback is provided
    if (widget.onTotalCalculated != null) {
      widget.onTotalCalculated!(finalTotalToPay);
      debugPrint(
          '✅ Final To Pay passed to Checkout: ₹${finalTotalToPay.toStringAsFixed(0)}');
    }

    // Dynamic delivery message
    String deliveryMessage = _getDeliveryMessage(
        widget.itemTotal, widget.distanceInKm, discountedFee, originalFee);
    Color messageColor =
        _getMessageColor(widget.itemTotal, widget.distanceInKm);

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
                label: "Item Total",
                value: "₹${widget.itemTotal.toStringAsFixed(0)}"),
            const SizedBox(height: 5),

            if (widget.offerDiscount > 0) ...[
              RowTextWidget(
                  label: "FIRST01 Offer",
                  colr: Colors.green,
                  value: "-₹${productDiscount.toStringAsFixed(0)}"),
              const SizedBox(height: 5),
              RowTextWidget(
                  label: "Discounted Price",
                  colr: Colors.black,
                  value:
                      "₹${(widget.itemTotal - productDiscount).toStringAsFixed(0)}"),
              const SizedBox(height: 5),
            ],

            // Coupon Section
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _couponController,
                    decoration: InputDecoration(
                      hintText: 'Enter coupon code',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _applyCoupon,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Apply'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_couponStatus.isNotEmpty) ...[
              Text(
                _couponStatus,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: _couponStatusColor,
                ),
              ),
              const SizedBox(height: 5),
            ],
            if (_couponDiscount > 0) ...[
              RowTextWidget(
                  label: "Coupon Discount ($_couponDiscount%)",
                  colr: Colors.green,
                  value: "-₹${couponDiscountAmount.toStringAsFixed(0)}"),
              const SizedBox(height: 5),
            ],

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Delivery Fee | ${widget.distanceInKm.toStringAsFixed(2)} km",
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
