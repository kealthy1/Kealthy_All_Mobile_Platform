import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserRatingNotifier extends StateNotifier<Map<String, double>> {
  UserRatingNotifier() : super({});

  void updateRating(String productName, double rating) {
    state = {...state, productName: rating}; // Only stores user's selection
  }
}

class AverageRatingNotifier extends StateNotifier<Map<String, double>> {
  AverageRatingNotifier() : super({});

  Future<void> getAverageStars({
    required String productName,
    required String apiUrl,
  }) async {
    try {
      final response = await http.get(Uri.parse('$apiUrl/$productName'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        double averageStars = double.parse(data['averageStars'].toString());

        state = {
          ...state,
          productName: averageStars
        }; // Only stores fetched rating
      } else {
        print('Failed to fetch average stars: ${response.body}');
      }
    } catch (e) {
      print('Error fetching average stars: $e');
    }
  }
}

final averageRatingProvider =
    StateNotifierProvider<AverageRatingNotifier, Map<String, double>>(
        (ref) => AverageRatingNotifier());

final userRatingProvider =
    StateNotifierProvider<UserRatingNotifier, Map<String, double>>(
        (ref) => UserRatingNotifier());

// **Rating Notifier**
class RatingNotifier extends StateNotifier<Map<String, double>> {
  RatingNotifier() : super({});

  void updateRating(String productName, double rating) {
    state = {...state, productName: rating};
  }

  Future<void> getAverageStars({
    required String productName,
    required String apiUrl,
  }) async {
    try {
      final encodedProductName = Uri.encodeComponent(productName);
      final fullUrl = '$apiUrl/$encodedProductName';

      print('Fetching rating from: $fullUrl');

      final response = await http.get(Uri.parse(fullUrl));

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        double averageStars = double.parse(data['averageStars'].toString());

        state = {...state, productName: averageStars};
      } else {
        print('⚠️ Failed to fetch average stars: ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching average stars: $e');
    }
  }
}

final ratingProvider =
    StateNotifierProvider<RatingNotifier, Map<String, double>>(
        (ref) => RatingNotifier());

/// **Review Notifier**
class ReviewNotifier extends StateNotifier<Map<String, String>> {
  ReviewNotifier() : super({});

  void updateReview(String productName, String review) {
    state = {...state, productName: review};
  }
}

final reviewProvider =
    StateNotifierProvider<ReviewNotifier, Map<String, String>>(
        (ref) => ReviewNotifier());

/// **Loading Indicator Provider**
final isSubmittingProvider = StateProvider<bool>((ref) => false);

/// **Tracks whether user is currently typing (to prevent frequent updates)**
final isTypingProvider = StateProvider<Map<String, bool>>((ref) => {});