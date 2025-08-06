import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FeedbackService {
  static const String apiUrl = "https://api-jfnhkjk4nq-uc.a.run.app/feedback";

  Future<void> saveFeedbackToServer({
    required double deliveryRating,
    required double websiteRating,
    required String satisfactionText,
    String? additionalFeedback,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final PhoneNumber = prefs.getString("phoneNumber");

      if (PhoneNumber == null) {
        throw Exception("PhoneNumber not found in SharedPreferences");
      }

      final Map<String, dynamic> feedbackData = {
        'deliveryRating': deliveryRating,
        'APPrating': websiteRating,
        'additionalFeedback': additionalFeedback,
        'satisfactionText': satisfactionText,
        'PhoneNumber': PhoneNumber,
      };

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(feedbackData),
      );

      if (response.statusCode == 201) {
        print("Feedback saved successfully!");
      } else {
        print("Failed to save feedback: ${response.statusCode}");
        print("Error: ${response.body}");
        throw Exception("Failed to save feedback");
      }
    } catch (e) {
      print("Error saving feedback: $e");
      throw Exception("Error saving feedback: $e");
    }
  }
}