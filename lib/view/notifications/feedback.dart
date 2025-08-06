import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/Toast/toast_helper.dart';
import 'package:kealthy/view/notifications/feedback_api.dart';

final isLoadingProvider = StateProvider<bool>((ref) => false);

final feedbackProvider = StateNotifierProvider<FeedbackNotifier, FeedbackState>(
  (ref) => FeedbackNotifier(),
);

class FeedbackState {
  final int deliveryRating;
  final int appUsabilityRating;
  final String additionalFeedback;
  final String satisfactionText;
  final bool isSubmitEnabled;

  FeedbackState({
    this.deliveryRating = 0,
    this.appUsabilityRating = 0,
    this.additionalFeedback = '',
    this.satisfactionText = '',
    this.isSubmitEnabled = false,
  });

  FeedbackState copyWith({
    int? deliveryRating,
    int? appUsabilityRating,
    String? additionalFeedback,
    String? satisfactionText,
    bool? isSubmitEnabled,
  }) {
    return FeedbackState(
      deliveryRating: deliveryRating ?? this.deliveryRating,
      appUsabilityRating: appUsabilityRating ?? this.appUsabilityRating,
      additionalFeedback: additionalFeedback ?? this.additionalFeedback,
      satisfactionText: satisfactionText ?? this.satisfactionText,
      isSubmitEnabled: isSubmitEnabled ?? this.isSubmitEnabled,
    );
  }
}

class FeedbackNotifier extends StateNotifier<FeedbackState> {
  FeedbackNotifier() : super(FeedbackState());

  void setDeliveryRating(int rating) {
    state = state.copyWith(deliveryRating: rating);
    _checkIfCanSubmit();
  }

  void setAppUsabilityRating(int rating) {
    state = state.copyWith(appUsabilityRating: rating);
    _checkIfCanSubmit();
  }

  void setAdditionalFeedback(String feedback) {
    state = state.copyWith(additionalFeedback: feedback);
    _checkIfCanSubmit();
  }

  void setSatisfactionText(String text) {
    state = state.copyWith(satisfactionText: text);
    _checkIfCanSubmit();
  }

  void _checkIfCanSubmit() {
    bool canSubmit = state.deliveryRating > 0 &&
        state.appUsabilityRating > 0 &&
        state.satisfactionText.isNotEmpty &&
        state.additionalFeedback.isNotEmpty;

    state = state.copyWith(isSubmitEnabled: canSubmit);
  }

  bool validateFields() {
    return state.deliveryRating > 0 &&
        state.appUsabilityRating > 0 &&
        state.satisfactionText.isNotEmpty &&
        state.additionalFeedback.isNotEmpty;
  }

  Future<bool> submitFeedback(BuildContext context) async {
    if (!validateFields()) return false;

    final feedbackService = FeedbackService();

    try {
      await feedbackService.saveFeedbackToServer(
        deliveryRating: state.deliveryRating.toDouble(),
        websiteRating: state.appUsabilityRating.toDouble(),
        satisfactionText: state.satisfactionText,
        additionalFeedback: state.additionalFeedback,
      );

      ToastHelper.showSuccessToast('Feedback submitted successfully');

      return true;
    } catch (e) {
      ToastHelper.showErrorToast('Failed to submit feedback: $e');
      return false;
    }
  }
}

class FeedbackPage extends ConsumerWidget {
  final String orderId; // Capture order ID for tracking feedback

  const FeedbackPage({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackState = ref.watch(feedbackProvider);
    final feedbackNotifier = ref.read(feedbackProvider.notifier);
    final isLoading = ref.watch(isLoadingProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Give Your Feedback',
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Rate the Delivery Process"),
              _buildStarRating(feedbackState.deliveryRating,
                  feedbackNotifier.setDeliveryRating),
              const Divider(thickness: 1),
              _buildSectionTitle("Rate the App Usability"),
              _buildStarRating(feedbackState.appUsabilityRating,
                  feedbackNotifier.setAppUsabilityRating),
              const Divider(thickness: 1),
              _buildSectionTitle("How was your experience?"),
              _buildSatisfactionSelection(feedbackState.satisfactionText,
                  feedbackNotifier.setSatisfactionText),
              const Divider(thickness: 1),
              _buildSectionTitle("Any additional comments?"),
              TextField(
                cursorColor: Colors.black,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Type your feedback here...",
                  hintStyle: GoogleFonts.poppins(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: feedbackNotifier.setAdditionalFeedback,
              ),
              const SizedBox(height: 20),
              Center(
                child: isLoading
                    ? const CupertinoActivityIndicator(
                        color: Colors.black,
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: feedbackState.isSubmitEnabled
                              ? Colors.black
                              : Colors.grey,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: feedbackState.isSubmitEnabled
                            ? () async {
                                ref.read(isLoadingProvider.notifier).state =
                                    true;

                                final isSuccess = await feedbackNotifier
                                    .submitFeedback(context);
                                if (isSuccess) {
                                  Navigator.pop(context);
                                }

                                ref.read(isLoadingProvider.notifier).state =
                                    false;
                              }
                            : null,
                        child: Text(
                          'Submit',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStarRating(int rating, Function(int) onRatingSelected) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(5, (index) {
        return IconButton(
          icon: Icon(
            Icons.star,
            color: rating > index ? Colors.amber : Colors.grey,
            size: 30,
          ),
          onPressed: () => onRatingSelected(index + 1),
        );
      }),
    );
  }

  Widget _buildSatisfactionSelection(
      String selectedSatisfaction, Function(String) onSatisfactionSelected) {
    const List<Map<String, dynamic>> smileys = [
      {"icon": Icons.sentiment_very_dissatisfied, "text": "Very Dissatisfied"},
      {"icon": Icons.sentiment_dissatisfied, "text": "Dissatisfied"},
      {"icon": Icons.sentiment_neutral, "text": "Neutral"},
      {"icon": Icons.sentiment_satisfied, "text": "Satisfied"},
      {"icon": Icons.sentiment_very_satisfied, "text": "Very Satisfied"},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: smileys.map((smiley) {
        return Column(
          children: [
            IconButton(
              icon: Icon(
                smiley['icon'] as IconData,
                color: selectedSatisfaction == smiley['text']
                    ? Colors.blue
                    : Colors.grey,
                size: 30,
              ),
              onPressed: () => onSatisfactionSelected(smiley['text'] as String),
            ),
          ],
        );
      }).toList(),
    );
  }
}
