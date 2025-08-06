import 'dart:convert';
import 'package:http/http.dart' as http;

class DistanceService {
  static const String _apiKey = "AIzaSyD1MUoakZ0mm8WeFv_GK9k_zAWdGk5r1hA";

  Future<double?> getDrivingDistanceInKm({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/distancematrix/json?'
      'units=metric'
      '&origins=$startLat,$startLng'
      '&destinations=$endLat,$endLng'
      '&key=$_apiKey'
      "&mode=walking"
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['rows'] != null &&
            data['rows'].isNotEmpty &&
            data['rows'][0]['elements'] != null &&
            data['rows'][0]['elements'].isNotEmpty &&
            data['rows'][0]['elements'][0]['status'] == "OK") {
          final distanceInMeters =
              data['rows'][0]['elements'][0]['distance']['value'];
          return distanceInMeters / 1000.0;
        } else {
          print("No valid distance data returned from API.");
          return null;
        }
      } else {
        print("Error from Distance Matrix API: ${response.statusCode}");
        print("Response: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Error calling Distance Matrix API: $e");
      return null;
    }
  }
}