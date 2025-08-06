import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kealthy/view/orders/polymer.dart';
import 'package:latlong2/latlong.dart';

/// **Fetches the destination (customer) location for an order**
final destinationLocationProvider =
    StreamProvider.family<LatLng?, String>((ref, orderId) {
  final databaseRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://kealthy-90c55-dd236.firebaseio.com',
  ).ref();

  return databaseRef.child('orders').onValue.map((event) {
    final snapshot = event.snapshot;

    if (snapshot.exists) {
      final ordersData = snapshot.value as Map<dynamic, dynamic>;

      if (ordersData.containsKey(orderId)) {
        final orderData = ordersData[orderId] as Map<dynamic, dynamic>;

        if (orderData.containsKey('selectedLatitude') &&
            orderData.containsKey('selectedLongitude')) {
          return LatLng(
              orderData['selectedLatitude'], orderData['selectedLongitude']);
        }
      }
    }
    return null;
  });
});

/// **Fetches the delivery partner's real-time location for an order**
final currentLocationProvider =
    StreamProvider.family<LatLng?, String>((ref, String orderId) async* {
  final databaseRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://kealthy-90c55-dd236.firebaseio.com',
  ).ref();

  try {
    final orderSnapshot = await databaseRef.child('orders').get();

    if (orderSnapshot.exists) {
      final ordersData = orderSnapshot.value as Map<dynamic, dynamic>;

      if (ordersData.containsKey(orderId)) {
        final orderData = ordersData[orderId] as Map<dynamic, dynamic>;

        if (orderData.containsKey('assignedto')) {
          final assignedTo = orderData['assignedto'] ?? '';

          final userStream = FirebaseFirestore.instance
              .collection('DeliveryUsers')
              .doc(assignedTo)
              .snapshots();

          await for (final userSnapshot in userStream) {
            if (userSnapshot.exists) {
              final data = userSnapshot.data();

              if (data != null && data['currentLocation'] != null) {
                final geoPoint = data['currentLocation'] as GeoPoint;
                yield LatLng(geoPoint.latitude, geoPoint.longitude);
              } else {
                yield null;
              }
            } else {
              yield null;
            }
          }
        }
      }
    }
    yield null;
  } catch (e) {
    print('Error fetching current location: $e');
    yield null;
  }
});

/// **Fetches the route points for an order**
final routeProvider =
    StreamProvider.family<List<LatLng>, String>((ref, String orderId) async* {
  final destinationLocation =
      await ref.read(destinationLocationProvider(orderId).future);

  if (destinationLocation != null) {
    final currentLocationStream =
        ref.watch(currentLocationProvider(orderId).stream);
    LatLng? lastRecalculatedLocation;
    const deviationThreshold = 100.0; // meters

    await for (final currentLocation in currentLocationStream) {
      if (currentLocation != null) {
        if (lastRecalculatedLocation == null ||
            _distanceBetween(currentLocation, lastRecalculatedLocation) >
                deviationThreshold) {
          lastRecalculatedLocation = currentLocation;

          final routePoints = await fetchRoute(
            LatLng(currentLocation.latitude, currentLocation.longitude),
            LatLng(destinationLocation.latitude, destinationLocation.longitude),
          );

          yield routePoints.isNotEmpty ? routePoints : [];
        }
      }
    }
  }
});

/// **Calculates the distance between two points using the Haversine formula**
double _distanceBetween(LatLng point1, LatLng point2) {
  const earthRadius = 6371000; // meters
  final lat1Rad = point1.latitude * (pi / 180);
  final lat2Rad = point2.latitude * (pi / 180);
  final deltaLat = (point2.latitude - point1.latitude) * (pi / 180);
  final deltaLon = (point2.longitude - point1.longitude) * (pi / 180);

  final a = (sin(deltaLat / 2) * sin(deltaLat / 2)) +
      cos(lat1Rad) * cos(lat2Rad) * (sin(deltaLon / 2) * sin(deltaLon / 2));
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));

  return earthRadius * c;
}

/// **Calculates estimated delivery time based on current and destination location**
int calculateDeliveryTime(
  LatLng currentLocation,
  LatLng destinationLocation, {
  double averageSpeedKmPerHour = 30,
}) {
  double distanceInMeters =
      _distanceBetween(currentLocation, destinationLocation);
  double averageSpeedMetersPerSecond = (averageSpeedKmPerHour * 1000) / 3600;
  double timeInSeconds = distanceInMeters / averageSpeedMetersPerSecond;
  return (timeInSeconds / 60).ceil();
}

/// **Formats an order ID to display only the last 9 digits**
String getLast9Digits(String orderId) {
  return orderId.length > 9 ? orderId.substring(orderId.length - 9) : orderId;
}
