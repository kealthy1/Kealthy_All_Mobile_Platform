import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/Toast/toast_helper.dart';
import 'package:kealthy/view/notifications/notification_page.dart';
import 'package:kealthy/view/notifications/rating_provider.dart';
import 'package:kealthy/view/notifications/review_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class RatingPage extends ConsumerWidget {
  final List<String> productNames;
  final String orderId;
  final List<String> productImages;

  const RatingPage({
    super.key,
    required this.productNames,
    required this.orderId,
    required this.productImages,
  });

  Future<void> submitReviews(BuildContext context, WidgetRef ref) async {
    // Collect only products that have been rated (rating > 0)
    final productsToSubmit = productNames.where((productName) {
      final double rating = ref.read(ratingProvider)[productName] ?? 0;
      return rating > 0;
    }).toList();

    // If no product is rated, show one toast and stay on page.
    if (productsToSubmit.isEmpty) {
      ToastHelper.showErrorToast('Please rate a product!');
      return;
    }

    // Show an AlertDialog while submitting the reviews.
    ref.read(isSubmittingProvider.notifier).state = true;
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          content: Row(
            children: [
              const CupertinoActivityIndicator(
                color: Colors.black,
              ),
              const SizedBox(width: 20),
              Text(
                "Submitting your reviews...",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );

    bool allSuccess = true;
    // Submit reviews only for products that were rated.
    for (var productName in productsToSubmit) {
      bool success = await _submitReview(context, ref, productName);
      if (!success) {
        allSuccess = false;
      }
    }

    Navigator.of(context).pop(); // Close the AlertDialog
    ref.read(isSubmittingProvider.notifier).state = false;

    // Show only one success or error toast.
    if (allSuccess) {
      ToastHelper.showSuccessToast('Thanks for sharing your thoughts!');
    } else {
      ToastHelper.showErrorToast('Failed to submit reviews !');
    }

    Navigator.pop(context);
  }

// _submitReview returns a bool for success/failure and does not show its own toast.
  Future<bool> _submitReview(
      BuildContext context, WidgetRef ref, String productName) async {
    final double? rating = ref.read(ratingProvider)[productName];
    final String review = (ref.read(reviewProvider)[productName] ?? '').trim();

    if (rating == null || rating == 0) return false;

    try {
      final prefs = await SharedPreferences.getInstance();
      final String customerName =
          prefs.getString('selectedName') ?? 'Anonymous';

      final Map<String, dynamic> reviewData = {
        "productName": productName,
        "starCount": rating.toInt(),
        "customerName": customerName,
        "feedback": review,
        "createdAt": DateTime.now().toIso8601String(),
      };

      final response = await http.post(
        Uri.parse("https://api-jfnhkjk4nq-uc.a.run.app/rate"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(reviewData),
      );

      if (response.statusCode == 200) {
        await deleteProductFromOrder(orderId, productName);
        ref.invalidate(notificationProvider);
        ref.read(ratingProvider.notifier).updateRating(productName, 0);
        ref.read(reviewProvider.notifier).updateReview(productName, '');
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> deleteProductFromOrder(
      String orderId, String productName) async {
    final firestore = FirebaseFirestore.instance;

    try {
      final querySnapshot = await firestore
          .collection('Notifications')
          .where('order_id', isEqualTo: orderId)
          .get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        List<dynamic> productNames = List.from(data['product_names'] ?? []);

        if (productNames.contains(productName)) {
          if (productNames.length > 1) {
            productNames.remove(productName);
            await firestore.collection('Notifications').doc(doc.id).update({
              'product_names': productNames,
            });
          } else {
            await firestore.collection('Notifications').doc(doc.id).delete();
          }
        }
      }
    } catch (e) {
      print('❌ Error deleting product from Firestore: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSubmitting = ref.watch(isSubmittingProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          "Share Your Feedback",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF273847),
          ),
        ),
      ),
      body: ListView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: productNames.length,
        itemBuilder: (context, index) {
          return ReviewCard(
            productName: productNames[index],
            productImage: productImages[index],
            orderId: orderId,
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: isSubmitting ? null : () => submitReviews(context, ref),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF273847),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            "Submit Reviews",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
