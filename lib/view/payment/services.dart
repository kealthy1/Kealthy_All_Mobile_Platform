// order_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:kealthy/view/Toast/toast_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class OrderService {
  /// Decrements the SOH (Stock On Hand) for each item in the order.
  static Future<void> decrementSOHForItems(dynamic address) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final WriteBatch batch = firestore.batch();

      for (final item in address.cartItems) {
        final productName = item.name;
        final quantityPurchased = item.quantity ?? 1;

        final querySnapshot = await firestore
            .collection('Products')
            .where('Name', isEqualTo: productName)
            .get();

        for (final doc in querySnapshot.docs) {
          final docRef = doc.reference;
          final docData = doc.data();
          final currentSOH = docData['SOH'] ?? 0;

          final updatedSOH = (currentSOH - quantityPurchased) < 0
              ? 0
              : (currentSOH - quantityPurchased);

          // Check if offer is active (deal_of_the_day or deal_of_the_week)
          final isOfferActive = docData['deal_of_the_day'] == true ||
              docData['deal_of_the_week'] == true;
          final currentOfferSOH = docData['offer_soh'] ?? 0;
          final updatedOfferSOH = (currentOfferSOH - quantityPurchased) < 0
              ? 0
              : (currentOfferSOH - quantityPurchased);

          // Always update SOH
          batch.update(docRef, {'SOH': updatedSOH});
          // If offer is active, also update offer_soh
          if (isOfferActive) {
            batch.update(docRef, {'offer_soh': updatedOfferSOH});
          }
        }
      }

      await batch.commit();
      print('SOH decremented successfully.');
    } catch (e) {
      print('Error decrementing SOH: $e');
      rethrow;
    }
  }

  Future<void> sendPaymentFailureNotification({
    required String token,
    required String userName,
    String? orderId,
  }) async {
    print("📨 Preparing to send notification to $token...");

    const String apiUrl =
        'https://api-jfnhkjk4nq-uc.a.run.app/sendPaymentFailureNotification';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'userName': userName,
          'orderId': orderId ?? '',
        }),
      );

      print("📬 Response Status: ${response.statusCode}");
      print("📬 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        print("✅ Notification sent: ${response.body}");
      } else {
        print("❌ Failed to send: ${response.body}");
      }
    } catch (e) {
      print("❌ Error sending notification: $e");
    }
  }

  Future<void> sendPaymentSuccessNotification({
    required String token,
    required String userName,
    String? orderId,
  }) async {
    print("📨 Preparing to send notification to $token...");

    const String apiUrl =
        'https://api-jfnhkjk4nq-uc.a.run.app/sendPaymentSuccessNotification';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'userName': userName,
          'orderId': orderId ?? '',
        }),
      );

      print("📬 Response Status: ${response.statusCode}");
      print("📬 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        print("✅ Notification sent: ${response.body}");
      } else {
        print("❌ Failed to send: ${response.body}");
      }
    } catch (e) {
      print("❌ Error sending notification: $e");
    }
  }

  /// Creates a Razorpay order via your backend’s `/create-order` route, with full order data.
  static Future<String> createRazorpayOrder({
    required double totalAmount,
    required dynamic address,
    required String packingInstructions,
    required String deliveryInstructions,
    required String deliveryTime,
    required String preferredTime,
    required double deliveryFee,
    required bool isSubscription, // pass this flag from frontend
  }) async {
    try {
      const String backendUrl = 'https://api-jfnhkjk4nq-uc.a.run.app';
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phoneNumber') ?? 'Unknown';
      final orderId = _generateOrderId();
      final orderTime = DateTime.now().toIso8601String();

      Map<String, dynamic> orderData;

      if (isSubscription) {
        final String planTitle =
            prefs.getString('subscription_plan_title') ?? '';
        final String productName =
            prefs.getString('subscription_product_name') ?? '';
        final String startDate =
            prefs.getString('subscription_start_date') ?? '';
        final String endDate = prefs.getString('subscription_end_date') ?? '';
        final double subscriptionQty =
            prefs.getDouble('subscription_qty') ?? 0.0;
        final bool subscriptionType =
            prefs.getBool('subscription_type') ?? false;
        final double baserate = prefs.getDouble('sub_baseRate') ?? 0.0;
        final int handlingFee = prefs.getInt('sub_handlingFee') ?? 0;

        orderData = {
          "Name": address.name ?? 'Unknown Name',
          "type": "subscription",
          "assignedto": "NotAssigned",
          "DA": "Waiting",
          "DAMOBILE": "Waiting",
          "createdAt": orderTime,
          "distance": address.distance ?? 0.0,
          "landmark": address.landmark ?? '',
          "orderId": orderId,
          "paymentmethod": 'Prepaid',
          "fcm_token": prefs.getString("fcm_token") ?? '',
          "phoneNumber": phoneNumber,
          "selectedDirections": address.selectedInstruction ?? 0.0,
          "selectedLatitude": address.selectedLatitude ?? 0.0,
          "selectedLongitude": address.selectedLongitude ?? 0.0,
          "selectedRoad": address.selectedRoad ?? '',
          "selectedSlot": deliveryTime,
          "selectedType": address.type ?? '',
          "status": "Order Placed",
          "totalAmountToPay": totalAmount.round(),
          "deliveryFee": deliveryFee,
          "item_ean": "8908024418004",
          "planTitle": planTitle,
          "productName": productName,
          "BaseRate": baserate,
          "handlingCharge": handlingFee,
          "startDate": startDate,
          "endDate": endDate,
          "subscriptionQty": subscriptionQty,
          "alternateDay": subscriptionType,
        };
      } else {
        orderData = {
          "Name": address.name ?? 'Unknown Name',
          "type": "Normal",
          "assignedto": "NotAssigned",
          "DA": "Waiting",
          "DAMOBILE": "Waiting",
          "cookinginstrcutions": packingInstructions,
          "createdAt": orderTime,
          "deliveryInstructions": deliveryInstructions,
          "distance": address.distance ?? 0.0,
          "landmark": address.landmark ?? '',
          "orderId": orderId,
          "orderItems": address.cartItems.map((item) {
            return {
              "item_name": item.name ?? '',
              "item_price": item.price ?? 0.0,
              "item_quantity": item.quantity ?? 1,
              "item_ean": item.ean ?? '',
              "item_category": item.type ?? ''
            };
          }).toList(),
          "paymentmethod": "Online Payment",
          "fcm_token": prefs.getString("fcm_token") ?? '',
          "phoneNumber": phoneNumber,
          "selectedDirections": address.selectedInstruction ?? 0.0,
          "selectedLatitude": address.selectedLatitude ?? 0.0,
          "selectedLongitude": address.selectedLongitude ?? 0.0,
          "selectedRoad": address.selectedRoad ?? '',
          "selectedSlot": deliveryTime,
          "selectedType": address.type ?? '',
          "status": "Order Placed",
          "totalAmountToPay": totalAmount.round(),
          "deliveryFee": deliveryFee,
          "preferredTime": preferredTime,
          "device": 'android',
        };
      }

      final response = await http.post(
        Uri.parse('$backendUrl/create-order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': totalAmount.round(),
          'currency': 'INR',
          'receipt': 'receipt_$orderId',
          'orderData': orderData,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final razorpayOrderId = data['orderId'];
        await prefs.setString('RazorpayorderId', razorpayOrderId);
        await prefs.setString('order_id', orderId);
        await prefs.setString('latest_order_id', orderId);
        await prefs.setString('order_completed_time', orderTime);
        return razorpayOrderId;
      } else {
        ToastHelper.showErrorToast(
            'Failed to create Razorpay order. Please try again.');
        throw Exception('Failed to create order: ${response.body}');
      }
    } catch (e) {
      print("❌ Error creating Razorpay order: $e");
      ToastHelper.showErrorToast('Something went wrong!');
      rethrow;
    }
  }

  /// Removes the Razorpay order ID from SharedPreferences
  static Future<void> removeRazorpayOrderId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('RazorpayorderId');
    print("✅ Razorpay Order ID removed from SharedPreferences");
  }

  static Future<void> saveOrderToFirebase({
    // required double offerDiscount,
    required String preferredTime,
    required dynamic address,
    required double totalAmount,
    required double deliveryFee,
    required String packingInstructions,
    required String deliveryInstructions,
    required String deliveryTime,
    required String paymentMethod,
    // required double instantDeliveryFee,
  }) async {
    try {
      final database = FirebaseDatabase.instanceFor(
        databaseURL: 'https://kealthy-90c55-dd236.firebaseio.com/',
        app: Firebase.app(),
      );
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phoneNumber') ?? 'Unknown';

      // Generate Unique Order ID
      final orderId = _generateOrderId();
      await prefs.setString('order_id', orderId);
      await prefs.setString('latest_order_id', orderId);

      final now = DateTime.now();
      final orderTime =
          DateFormat('d/M/yyyy, h:mm:ss a').format(now).toLowerCase();
      await prefs.setString('order_completed_time', orderTime);

      final orderData = {
        "Name": address.name ?? 'Unknown Name',
        "type": "Normal",
        "assignedto": "NotAssigned",
        "DA": "Waiting",
        "DAMOBILE": "Waiting",
        "cookinginstrcutions": packingInstructions,
        "createdAt": orderTime,
        "deliveryInstructions": deliveryInstructions,
        "distance": address.distance ?? 0.0,
        "landmark": address.landmark ?? '',
        "orderId": orderId,
        "orderItems": address.cartItems.map((item) {
          return {
            "item_name": item.name ?? '',
            "item_price": item.price ?? 0.0,
            "item_quantity": item.quantity ?? 1,
            "item_ean": item.ean ?? '',
            "item_category": item.type ?? ''
          };
        }).toList(),
        "paymentmethod": paymentMethod,
        "fcm_token": prefs.getString("fcm_token") ?? '',
        "phoneNumber": phoneNumber,
        "selectedDirections": address.selectedInstruction ?? 0.0,
        "selectedLatitude": address.selectedLatitude ?? 0.0,
        "selectedLongitude": address.selectedLongitude ?? 0.0,
        "selectedRoad": address.selectedRoad ?? '',
        "selectedSlot": deliveryTime,
        "selectedType": address.type ?? '',
        "status": "Order Placed",
        "totalAmountToPay": totalAmount.round(), // returns int
        "deliveryFee": deliveryFee,
        "preferredTime": preferredTime,
        "device": 'android', // or 'Android' based on your app logic
        // "offerDiscount": offerDiscount,
        // "instantDeliveryfee": instantDeliveryFee,
      };

      // Save to Realtime Database
      await database.ref().child('orders').child(orderId).set(orderData);
      print('Order saved successfully with orderId = $orderId');

      // Decrement stock
      await decrementSOHForItems(address);

      // Optionally save a notification doc to Firestore
      // await saveNotificationToFirestore(orderId, address.cartItems);
    } catch (error, stackTrace) {
      print('Error saving order: $error');
      print('StackTrace: $stackTrace');
      rethrow; // or handle the error with a custom logic
    }
  }

  /// Saves a subscription order in Firebase Realtime Database.
  // static Future<void> saveSubscriptionOrderToFirebase({
  //   required dynamic address,
  //   required double totalAmount,
  //   required double deliveryFee,
  //   required String packingInstructions,
  //   required String deliveryInstructions,
  //   required String deliveryTime,
  //   required String paymentMethod,
  //   // required double instantDeliveryFee,
  // }) async {
  //   try {
  //     final database = FirebaseDatabase.instanceFor(
  //       databaseURL: 'https://kealthy-90c55-dd236.firebaseio.com/',
  //       app: Firebase.app(),
  //     );
  //     final prefs = await SharedPreferences.getInstance();
  //     final phoneNumber = prefs.getString('phoneNumber') ?? 'Unknown';

  //     final orderId = _generateOrderId();
  //     await prefs.setString('subscription_order_id', orderId);
  //     await prefs.setString('latest_order_id', orderId);

  //     final orderTime = DateTime.now().toIso8601String();
  //     await prefs.setString('order_completed_time', orderTime);

  //     final String planTitle = prefs.getString('subscription_plan_title') ?? '';
  //     final String productName =
  //         prefs.getString('subscription_product_name') ?? '';
  //     final String startDate = prefs.getString('subscription_start_date') ?? '';
  //     final String endDate = prefs.getString('subscription_end_date') ?? '';
  //     final double subscriptionQty = prefs.getDouble('subscription_qty') ?? 0.0;
  //     final bool subscriptionType = prefs.getBool('subscription_type') ?? false;

  //     final orderData = {
  //       "Name": address.name ?? 'Unknown Name',
  //       "type": "subscription",
  //       "assignedto": "NotAssigned",
  //       "DA": "Waiting",
  //       "DAMOBILE": "Waiting",
  //       "createdAt": orderTime,
  //       "distance": address.distance ?? 0.0,
  //       "landmark": address.landmark ?? '',
  //       "orderId": orderId,
  //       "paymentmethod": 'Prepaid',
  //       "fcm_token": prefs.getString("fcm_token") ?? '',
  //       "phoneNumber": phoneNumber,
  //       "selectedDirections": address.selectedInstruction ?? 0.0,
  //       "selectedLatitude": address.selectedLatitude ?? 0.0,
  //       "selectedLongitude": address.selectedLongitude ?? 0.0,
  //       "selectedRoad": address.selectedRoad ?? '',
  //       "selectedSlot": deliveryTime,
  //       "selectedType": address.type ?? '',
  //       "status": "Order Placed",
  //       "totalAmountToPay": totalAmount.round(), // returns int
  //       "deliveryFee": deliveryFee.round(),
  //       "item_ean": "8908024418004",
  //       "planTitle": planTitle,
  //       "productName": productName,
  //       "startDate": startDate,
  //       "endDate": endDate,
  //       "subscriptionQty": subscriptionQty,
  //       "alternateDay": subscriptionType,
  //     };

  //     await database.ref().child('subscriptions').child(orderId).set(orderData);
  //     print('Subscription order saved successfully with orderId = $orderId');
  //   } catch (error, stackTrace) {
  //     print('Error saving subscription order: $error');
  //     print('StackTrace: $stackTrace');
  //     rethrow;
  //   }
  // }

  static Future<void> saveNotificationToFirestore(
    String orderId,
    List cartItems,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phoneNumber') ?? 'Unknown';
      final List<String> newProductNames =
          cartItems.map((item) => item.name.toString()).toList();

      final firestore = FirebaseFirestore.instance;

      // Fetch past notifications by this phone number
      final existingDocs = await firestore
          .collection('Notifications')
          .where('phoneNumber', isEqualTo: phoneNumber)
          .get();

      // Collect all previously notified product names
      final Set<String> alreadyNotifiedProducts = {};

      for (var doc in existingDocs.docs) {
        final data = doc.data();
        final List<dynamic> names = data['product_names'] ?? [];
        alreadyNotifiedProducts.addAll(names.map((e) => e.toString()));
      }

      // Find products that haven't been notified before
      final List<String> newProducts = newProductNames
          .where((name) => !alreadyNotifiedProducts.contains(name))
          .toList();

      if (newProducts.isEmpty) {
        print("🟡 Skipping: All products already have review notifications.");
        return;
      }

      // Save notification only for new (unrated) products
      final notificationData = {
        'body': "How was your experience? Give us a quick star rating!",
        'imageUrl':
            "https://firebasestorage.googleapis.com/v0/b/kealthy-90c55.appspot.com/o/feedback%2Fa-minimalistic-design-for-a-healthy-food_38vJ50AsTdOxv4Z5Wt32LA_8cxtpxqbSYaVP_s8Ygh7bQ.jpeg?alt=media&token=03691f32-6713-44cb-8cb4-edf94ebf645a",
        'order_id': orderId,
        'payload': "review_screen",
        'phoneNumber': phoneNumber,
        'product_names': newProducts,
        'timestamp': DateTime.now().toUtc(),
        'title': "Share Your Thoughts!",
      };

      await firestore.collection('Notifications').add(notificationData);
      print("✅ Notification data saved successfully!");
    } catch (e) {
      print("❌ Error saving notification data: $e");
    }
  }

  /// Helper: Generate a unique-ish Order ID
  static String _generateOrderId() {
    int timestamp = DateTime.now().millisecondsSinceEpoch;
    int randomNum = Random().nextInt(900000) + 100000;
    return '$randomNum$timestamp';
  }
}
