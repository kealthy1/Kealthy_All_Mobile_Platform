import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class UserService {
  static const String apiUrl = 'https://api-jfnhkjk4nq-uc.a.run.app/getUserDetails';

  // Fetch User Details
  static Future<Map<String, String>> getUserDetails(String phoneNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ 1️⃣ Check if data exists in SharedPreferences
      final storedName = prefs.getString('user_name');
      final storedEmail = prefs.getString('user_email');

      if (storedName != null && storedEmail != null) {
        return {
          'name': storedName,
          'email': storedEmail,
        };
      }

      // ✅ 2️⃣ Make API request if no cached data
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"phoneNumber": phoneNumber}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final user = data['user'] ?? {};

        final name = user['name'] ?? '';
        final email = user['email'] ?? '';

        // ✅ 3️⃣ Store in SharedPreferences for faster access next time
        await prefs.setString('user_name', name);
        await prefs.setString('user_email', email);

        return {'name': name, 'email': email};
      } else {
        throw Exception("Failed to fetch user details: ${response.body}");
      }
    } catch (e) {
      print("Error fetching user details: $e");
      return {'name': '', 'email': ''};
    }
  }

  // ✅ 4️⃣ Update User Details and Store in SharedPreferences
  static Future<void> updateUserDetails(String phoneNumber, String name, String email) async {
  try {
    final prefs = await SharedPreferences.getInstance();

    final response = await http.post(
      Uri.parse('https://api-jfnhkjk4nq-uc.a.run.app/updateUserDetails'), // Ensure the API URL is correct
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "phoneNumber": phoneNumber, // Send phone number along with name & email
        "name": name,
        "email": email,
      }),
    );

    if (response.statusCode == 200) {
      // ✅ Store details only if the API call is successful
      await prefs.setString('user_name', name);
      await prefs.setString('user_email', email);
      print("✅ User details updated successfully in backend and locally.");
    } else {
      throw Exception("Failed to update user details: ${response.body}");
    }
  } catch (e) {
    print("❌ Error updating user details: $e");
  }
}
}