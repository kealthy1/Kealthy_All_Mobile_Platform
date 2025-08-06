import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy/view/Login/login_page.dart';

import 'package:shared_preferences/shared_preferences.dart';

final ordersListProvider =
    StateProvider<List<Map<String, dynamic>>>((ref) => []);

final expandedStatesProvider = StateProvider<List<bool>>((ref) => []);

final firebaseDatabaseProvider = Provider<FirebaseDatabase>((ref) {
  return FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://kealthy-90c55-dd236.firebaseio.com/',
  );
});

class OrderRepository {
  final FirebaseDatabase database;
  OrderRepository(this.database);

  Future<void> loadOrders(WidgetRef ref) async {
    ref.read(loadingProvider.notifier).state = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phoneNumber') ?? '';
      if (phoneNumber.isEmpty) {
        ref.read(loadingProvider.notifier).state = false;
        return;
      }

      database
          .ref()
          .child('orders')
          .orderByChild('phoneNumber')
          .equalTo(phoneNumber)
          .onValue
          .listen((event) async {
        final snapshot = event.snapshot.value as Map?;
        if (snapshot == null || snapshot.isEmpty) {
          ref.read(ordersListProvider.notifier).state = [];
          ref.read(expandedStatesProvider.notifier).state = [];
          ref.read(loadingProvider.notifier).state = false;
          return;
        }

        List<Map<String, dynamic>> ordersList = [];
        snapshot.forEach((key, value) {
          ordersList.add(Map<String, dynamic>.from(value));
        });

        await fetchDeliveryPartners(ordersList);

        ref.read(ordersListProvider.notifier).state = ordersList;
        ref.read(expandedStatesProvider.notifier).state =
            List<bool>.filled(ordersList.length, true);
        ref.read(loadingProvider.notifier).state = false;
      });
    } catch (e) {
      print('Error loading orders: $e');
      ref.read(loadingProvider.notifier).state = false;
    }
  }

  Future<void> fetchDeliveryPartners(
      List<Map<String, dynamic>> ordersList) async {
    for (var order in ordersList) {
      String assignedTo = order['assignedto'] ?? '';
      order['assignedto'] = await fetchDeliveryPartnerName(assignedTo);
    }
  }

  Future<String?> fetchDeliveryPartnerName(String assignedTo) async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot = await FirebaseFirestore
          .instance
          .collection('DeliveryUsers')
          .doc(assignedTo)
          .get();

      if (snapshot.exists) {
        return snapshot.data()?['Name'];
      }
    } catch (e) {
      print('Error fetching delivery partner name: $e');
    }
    return null;
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final database = ref.read(firebaseDatabaseProvider);
  return OrderRepository(database);
});

class OrderItem {
  final String itemName;
  final double itemPrice;
  final int itemQuantity;

  OrderItem({
    required this.itemName,
    required this.itemPrice,
    required this.itemQuantity,
  });

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      itemName: data['item_name']?.toString() ?? 'Unknown Item',
      itemPrice: (data['item_price'] as num?)?.toDouble() ?? 0.0,
      itemQuantity: (data['item_quantity'] as int?) ?? 0,
    );
  }
}

class OrderData {
  final String name;
  final String assignedTo;
  final String distance;
  final String orderId;
  final String phoneNumber;
  final String date;
  final String time;
  final double totalAmountToPay;
  final List<OrderItem> orderItems;

  OrderData({
    required this.name,
    required this.assignedTo,
    required this.distance,
    required this.orderId,
    required this.phoneNumber,
    required this.totalAmountToPay,
    required this.orderItems,
    required this.date,
    required this.time,
  });
  factory OrderData.fromMap(Map<String, dynamic> data) {
    List<OrderItem> items = (data['orderItems'] as List<dynamic>? ?? [])
        .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
        .toList();

    return OrderData(
      name: data['Name']?.toString() ?? 'Unknown Name',
      assignedTo: data['assignedTo']?.toString() ?? 'Unknown',
      distance: data['distance']?.toString() ?? '0',
      orderId: data['orderId']?.toString() ?? 'Unknown',
      phoneNumber: data['phoneNumber']?.toString() ?? 'Unknown',
      totalAmountToPay: (data['totalAmountToPay'] as num?)?.toDouble() ?? 0.0,
      orderItems: items,
      date: data['date']?.toString() ?? '',
      time: data['time']?.toString() ?? '',
    );
  }
}

class OrderDataNotifier extends StateNotifier<AsyncValue<List<OrderData>?>> {
  OrderDataNotifier() : super(const AsyncValue.loading());

  Future<void> fetchOrderData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phoneNumber = prefs.getString('phoneNumber');

      if (phoneNumber == null) {
        state = AsyncValue.error("Unable to load orders.", StackTrace.current);
        return;
      }

      final apiUrl = "https://api-jfnhkjk4nq-uc.a.run.app/orders/$phoneNumber";
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        final List<dynamic> responseData = jsonDecode(response.body)['orders'];

        if (responseData.isEmpty) {
          state = const AsyncValue.data([]);
          return;
        }

        final orders = responseData
            .map((data) => OrderData.fromMap(data as Map<String, dynamic>))
            .toList();

        state = AsyncValue.data(orders);
      } else if (response.statusCode == 404) {
        state = const AsyncValue.data([]);
      } else {
        throw Exception("Failed to fetch orders: ${response.body}");
      }
    } catch (e) {
      state = AsyncValue.error(e.toString(), StackTrace.current);
    }
  }
}

final orderDataProvider =
    StateNotifierProvider<OrderDataNotifier, AsyncValue<List<OrderData>?>>(
        (ref) => OrderDataNotifier());
