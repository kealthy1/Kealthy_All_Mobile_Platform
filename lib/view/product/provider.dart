import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';


final ratingCacheProvider = StateNotifierProvider<RatingCacheNotifier, Map<String, double>>(
  (ref) => RatingCacheNotifier(),
);

class RatingCacheNotifier extends StateNotifier<Map<String, double>> {
  RatingCacheNotifier() : super({});

  void set(String productName, double rating) {
    state = {...state, productName: rating};
  }

  double? get(String productName) => state[productName];
}

final averageStarsProvider = FutureProvider.family<double, String>((ref, productName) async {
  final cache = ref.read(ratingCacheProvider.notifier);
  final cached = cache.get(productName);

  if (cached != null) {
    print('✅ Using cached rating for "$productName": $cached');
    return cached;
  }

  try {
    final encodedProductName = Uri.encodeComponent(productName);
    const apiUrl = "https://api-jfnhkjk4nq-uc.a.run.app/rate";
    final fullUrl = '$apiUrl/$encodedProductName';

    print('🌐 Fetching rating from: $fullUrl');
    final response = await http.get(Uri.parse(fullUrl));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final rating = double.tryParse(data['averageStars'].toString()) ?? 0.0;
      cache.set(productName, rating); // ✅ Save to cache
      return rating;
    } else {
      print('⚠️ No rating found for "$productName" (status: ${response.statusCode})');
      return 0.0;
    }
  } catch (e) {
    print('❌ Error fetching rating for "$productName": $e');
    return 0.0;
  }
});