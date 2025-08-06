import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy/view/Cart/cart_controller.dart';
import 'package:kealthy/view/payment/dialogue_helper.dart';
import 'package:kealthy/view/payment/services.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

class OnlinePaymentProcessing extends ConsumerStatefulWidget {
  final double totalAmount;
  final String packingInstructions;
  final String deliveryInstructions;
  final dynamic address;
  final String deliverytime;
  final double deliveryFee;
  // final double instantDeliveryFee;
  final String razorpayOrderId;
  final String orderType;
  final String preferredTime;
  // final double offerDiscount;

  const OnlinePaymentProcessing({
    super.key,
    required this.totalAmount,
    required this.packingInstructions,
    required this.deliveryInstructions,
    required this.address,
    required this.deliverytime,
    required this.deliveryFee,
    // required this.instantDeliveryFee,
    required this.razorpayOrderId,
    required this.orderType,
    required this.preferredTime,
    // required this.offerDiscount,
  });

  @override
  _OnlinePaymentProcessingState createState() =>
      _OnlinePaymentProcessingState();
}

class _OnlinePaymentProcessingState
    extends ConsumerState<OnlinePaymentProcessing> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    openCheckout(); // Start payment as soon as the widget loads
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final prefs = await SharedPreferences.getInstance();
    final fcmToken = prefs.getString("fcm_token") ?? '';
    final userName = widget.address.name ?? 'Unknown Name';
    final orderId = widget.razorpayOrderId;

    await OrderService.removeRazorpayOrderId();
    await OrderService.decrementSOHForItems(widget.address);
    await OrderService.saveNotificationToFirestore(
        orderId, widget.address.cartItems);

    // ✅ Order will now be saved by the backend webhook
    // Do NOT save order manually here anymore

    await OrderService().sendPaymentSuccessNotification(
      token: fcmToken,
      userName: userName,
      orderId: orderId,
    );

    // Clear the cart only if not a subscription
    if (widget.orderType != 'subscription') {
      ref.read(cartProvider.notifier).clearCart();
    }

    // Show success dialog from the new helper
    PaymentDialogHelper.showPaymentSuccessDialog(context, ref);
  }

  void _handlePaymentFailure(PaymentFailureResponse response) async {
    print("Payment Failed: ${response.code} | ${response.message}");

    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('phoneNumber') ?? 'Unknown';
    final fcmToken = prefs.getString("fcm_token") ?? '';
    final userName = widget.address.name ?? 'Unknown Name';
    final orderId = widget.razorpayOrderId;

    final failureOrderData = {
      "Name": widget.address.name ?? 'Unknown Name',
      "type": widget.orderType,
      "cookinginstrcutions": widget.packingInstructions,
      "createdAt": DateTime.now().toIso8601String(),
      "deliveryInstructions": widget.deliveryInstructions,
      "distance": widget.address.distance ?? 0.0,
      "landmark": widget.address.landmark ?? '',
      "orderId": widget.razorpayOrderId,
      "orderItems": widget.address.cartItems.map((item) {
        return {
          "item_name": item.name ?? '',
          "item_price": item.price ?? 0.0,
          "item_quantity": item.quantity ?? 1,
          "item_ean": item.ean ?? ''
        };
      }).toList(),
      "paymentmethod": "Online Payment",
      "fcm_token": prefs.getString("fcm_token") ?? '',
      "phoneNumber": phoneNumber,
      "selectedDirections": widget.address.selectedInstruction ?? 0.0,
      "selectedLatitude": widget.address.selectedLatitude ?? 0.0,
      "selectedLongitude": widget.address.selectedLongitude ?? 0.0,
      "selectedRoad": widget.address.selectedRoad ?? '',
      "selectedSlot": widget.deliverytime,
      "selectedType": widget.address.type ?? '',
      "status": "Order not placed",
      "totalAmountToPay": widget.totalAmount.round(),
      "deliveryFee": widget.deliveryFee,
      "failureReason": response.message ?? 'Unknown',
      "failureCode": response.code,
    };

    await FirebaseFirestore.instance
        .collection('FailedPayments')
        .add(failureOrderData);
    print("❌ Full failed order data saved to Firestore.");

    await OrderService().sendPaymentFailureNotification(
      token: fcmToken,
      userName: userName,
      orderId: orderId,
    );

    await OrderService.removeRazorpayOrderId();
    ref.read(cartProvider.notifier).clearCart();

    // Show failure dialog from the new helper
    PaymentDialogHelper.showPaymentFailureDialog(context);
  }

  Future<void> _handleExternalWallet(ExternalWalletResponse response) async {
    await OrderService.removeRazorpayOrderId();
    Navigator.pop(context);
  }

  void openCheckout() async {
    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('phoneNumber') ?? 'Unknown';
    final userName = prefs.getString('Name') ?? 'Test User';

    final storedOrderId = prefs.getString('RazorpayorderId') ?? '';
    if (storedOrderId.isEmpty) {
      print("❌ No stored Razorpay Order ID found");
      return;
    }

    try {
      final options = {
        'key': 'rzp_live_jA2MRdwkkUcT9v',
        //'key': 'rzp_test_xvodwFJzA6n4ei',
        'amount': widget.totalAmount
            .toStringAsFixed(0), // <-- If your server does the paise conversion
        'currency': 'INR',
        'name': 'Kealthy',
        'description': 'Kealthy',
        'image':
            'https://firebasestorage.googleapis.com/v0/b/kealthy-90c55.appspot.com/o/final-image-removebg-preview.png?alt=media&token=3184c1f9-2162-45e2-9bea-95519ef1519b',
        'order_id': storedOrderId,
        'prefill': {
          'contact': phoneNumber,
          'name': userName,
        },
        'method': {
          'upi': true,
          'card': true,
          'netbanking': true,
        },
        'upi': {'flow': 'intent'},
        if (!Platform.isIOS)
          'external': {
            'wallets': ['paytm', 'phonepe', 'gpay'],
          }
        else
          'external': {
            'wallets': ['paytm', 'phonepe'],
          },
      };

      _razorpay.open(options);
    } catch (e) {
      print('❌ Error opening Razorpay checkout: $e');
    }
  }

  @override
  void dispose() {
    _razorpay.clear(); // Clear all listeners
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.white,
        title: Text(
          "Processing Payment",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/images/shield.png',
              width: 50,
            ),
            const SizedBox(height: 20),
            Text(
              '🔐 Secure • Private • Protected',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
