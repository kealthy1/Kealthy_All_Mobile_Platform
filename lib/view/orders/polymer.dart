import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

Future<List<LatLng>> fetchRoute(LatLng origin, LatLng destination) async {
  const apiKey = 'AIzaSyD1MUoakZ0mm8WeFv_GK9k_zAWdGk5r1hA';
  final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['routes'] != null && data['routes'].isNotEmpty) {
        final route = data['routes'][0]['overview_polyline']['points'];

        final decodedPoints = _decodePolyline(route);

        return decodedPoints;
      }
    }
  } catch (e) {
    print('Error fetching route: $e');
  }

  return [];
}

List<LatLng> _decodePolyline(String polyline) {
  var points = <LatLng>[];
  var index = 0;
  int lat = 0, lng = 0;

  while (index < polyline.length) {
    var shift = 0, result = 0;
    int byte;

    do {
      byte = polyline.codeUnitAt(index++) - 63;
      result |= (byte & 0x1F) << shift;
      shift += 5;
    } while (byte >= 0x20);

    int deltaLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lat += deltaLat;

    shift = 0;
    result = 0;

    do {
      byte = polyline.codeUnitAt(index++) - 63;
      result |= (byte & 0x1F) << shift;
      shift += 5;
    } while (byte >= 0x20);

    int deltaLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    lng += deltaLng;

    points.add(LatLng(lat / 1E5, lng / 1E5));
  }

  return points;
}