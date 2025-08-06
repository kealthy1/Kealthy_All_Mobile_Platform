import 'package:flutter_riverpod/flutter_riverpod.dart';

class SelectedLocation {
  final double latitude;
  final double longitude;
  final String address;

  SelectedLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class SelectedLocationNotifier extends StateNotifier<SelectedLocation?> {
  SelectedLocationNotifier() : super(null);

  void setLocation(double latitude, double longitude, String address) {
    state = SelectedLocation(
      latitude: latitude,
      longitude: longitude,
      address: address,
    );
  }

  void clearLocation() {
    state = null;
  }
}

