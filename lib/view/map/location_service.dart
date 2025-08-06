import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

enum MapProviderType {
  google,
  mapbox,
}

final mapTypeProvider = StateProvider<MapProviderType>((ref) => MapProviderType.google);

class LocationHelper {
  /// **Fetches the user's current location.**
  static Future<Position?> getCurrentLocation() async {
  try {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }

    if (permission == LocationPermission.deniedForever) return null;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high, // Use high accuracy
    ).timeout(
      const Duration(seconds: 10), // 👈 manually add timeout
      onTimeout: () {
        throw TimeoutException('Location request timed out.');
      },
    );

    return position;
  } catch (e) {
    print('Error getting location: $e');
    return null;
  }
}

  /// **Fetches suggested locations based on user input.**
  static Future<List<String>> suggestLocations(String query) async {
    List<String> suggestions = [];
    try {
      final List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        suggestions = await Future.wait(locations.map((location) async {
          final placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );
          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;
            return "${placemark.street ?? ''}, ${placemark.administrativeArea ?? ''}, ${placemark.country ?? ''}";
          }
          return '';
        }).toList());
      }
    } catch (e) {
      print('Error in getting suggestions: $e');
    }
    return suggestions;
  }

  /// **Searches for a location using Google Places API.**
  static Future<LatLng?> searchLocation(String placeId) async {
    try {
      final response = await http.get(Uri.parse(
          'https://maps.googleapis.com/maps/api/place/details/json?placeid=$placeId&key=AIzaSyD1MUoakZ0mm8WeFv_GK9k_zAWdGk5r1hA'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'OK' && data['result'] != null) {
          final geometry = data['result']['geometry'];
          final location = geometry['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
      print('Error in searching location: Could not find results.');
      return null;
    } catch (e) {
      print('Error in searching location: $e');
      return null;
    }
  }

  /// **Reverse geocoding: Converts LatLng to an address.**
  static Future<String> getAddressFromLatLng(LatLng position) async {
    try {
      final List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        List<String> addressParts = [];

        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          addressParts.add(placemark.locality!);
        }
        if (placemark.postalCode != null && placemark.postalCode!.isNotEmpty) {
          addressParts.add(placemark.postalCode!);
        }
        if (placemark.administrativeArea != null &&
            placemark.administrativeArea!.isNotEmpty) {
          addressParts.add(placemark.administrativeArea!);
        }
        if (placemark.country != null && placemark.country!.isNotEmpty) {
          addressParts.add(placemark.country!);
        }

        return addressParts.join(', ');
      }
    } on PlatformException catch (e) {
      print('Error in reverse geocoding: $e');
    }
    return 'Unknown Address';
  }
}