import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/notifications/feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';

// StateNotifier for tracking whether to show the feedback alert
class ReviewAlertNotifier extends StateNotifier<bool> {
  ReviewAlertNotifier() : super(false);

  void setShowAlert(bool value) => state = value;
}

// StateNotifier for tracking if the review alert has been shown
class HasShownReviewNotifier extends StateNotifier<bool> {
  HasShownReviewNotifier() : super(false);

  void setHasShown() => state = true;
}

// Providers
final reviewAlertProvider = StateNotifierProvider<ReviewAlertNotifier, bool>(
  (ref) => ReviewAlertNotifier(),
);

final hasShownReviewAlertProvider =
    StateNotifierProvider<HasShownReviewNotifier, bool>(
  (ref) => HasShownReviewNotifier(),
);

class OrderFeedbackAlert extends ConsumerStatefulWidget {
  const OrderFeedbackAlert({super.key});

  @override
  ConsumerState<OrderFeedbackAlert> createState() => _OrderFeedbackAlertState();
}

class _OrderFeedbackAlertState extends ConsumerState<OrderFeedbackAlert>
    with AutomaticKeepAliveClientMixin {
  String? latestOrderId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _checkOrderCompletionTime();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(
      const AssetImage('lib/assets/images/PHOTO-2025-02-15-15-01-53.jpg'),
      context,
    );
  }

  Future<void> _checkOrderCompletionTime() async {
    final prefs = await SharedPreferences.getInstance();
    final String? orderTimeString = prefs.getString('order_completed_time');
    latestOrderId =
        prefs.getString('latest_order_id'); // Get the latest order ID

    if (orderTimeString != null) {
      final DateTime orderTime = DateTime.parse(orderTimeString);
      final Duration timeElapsed = DateTime.now().difference(orderTime);

      if (timeElapsed.inSeconds >= 10800) {
        ref.read(reviewAlertProvider.notifier).setShowAlert(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final shouldShowAlert = ref.watch(reviewAlertProvider);

    if (!shouldShowAlert || latestOrderId == null) {
      return const SizedBox.shrink();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ref.read(hasShownReviewAlertProvider)) {
        _showOrderFeedbackDialog(context, ref, latestOrderId!);
        ref.read(hasShownReviewAlertProvider.notifier).setHasShown();
      }
    });

    return const SizedBox.shrink();
  }

  void _showOrderFeedbackDialog(
      BuildContext context, WidgetRef ref, String orderId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.grey[100],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          titlePadding: const EdgeInsets.all(16),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          actionsPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          title: Column(
            children: [
              Image.asset(
                'lib/assets/images/PHOTO-2025-02-15-15-01-53.jpg',
                height: 100,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 10),
              Text(
                "Help us improve by sharing your feedback",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceAround,
          actions: [
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('order_completed_time');
                await prefs.remove('latest_order_id');
                ref.read(reviewAlertProvider.notifier).setShowAlert(false);
                Navigator.pop(context);
              },
              child: Text(
                'No thanks',
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('order_completed_time');
                await prefs.remove('latest_order_id');
                ref.read(reviewAlertProvider.notifier).setShowAlert(false);
                Navigator.pop(context);
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => FeedbackPage(orderId: orderId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF273847),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Sure',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
