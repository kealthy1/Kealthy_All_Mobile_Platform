import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kealthy/view/notifications/notification_page.dart';
import 'package:kealthy/view/notifications/notification_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_fonts/google_fonts.dart';

final hasShownReviewAlertProvider =
    StateNotifierProvider<HasShownReviewNotifier, bool>((ref) {
  return HasShownReviewNotifier();
});

class HasShownReviewNotifier extends StateNotifier<bool> {
  HasShownReviewNotifier() : super(false);

  static Future<List<Map<String, dynamic>>> filterUnratedNotificationsOnce(
    List<Map<String, dynamic>> notifications,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final seenProducts = <String>{};

    final filtered = <Map<String, dynamic>>[];

    for (final notif in notifications) {
      final productNames = notif['product_names'] as List<dynamic>? ?? [];
      final hasUnrated = productNames.any((name) {
        final wasRated = prefs.getBool('rated_$name') ?? false;
        final wasSeen = seenProducts.contains(name);
        return !wasRated && !wasSeen;
      });

      if (hasUnrated) {
        filtered.add(notif);
        seenProducts.addAll(productNames.map((e) => e.toString()));
      }
    }

    return filtered;
  }
}

class ReviewAlert extends ConsumerWidget {
  const ReviewAlert({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationProvider);

    if (notificationsAsync is! AsyncData) return const SizedBox.shrink();

    final notifications = notificationsAsync.value ?? [];

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: (() async {
        if (notifications.isEmpty) return <Map<String, dynamic>>[];

        final delivered = <Map<String, dynamic>>[];

        for (final notif in notifications) {
          final orderId = notif['order_id'] ?? '';
          final existsAsync =
              await ref.read(orderExistsProvider(orderId).future);
          if (!existsAsync) {
            delivered.add(notif);
          }
        }

        return await HasShownReviewNotifier.filterUnratedNotificationsOnce(
            delivered);
      })(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final newestNotification = snapshot.data!.first;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showReviewDialog(context, ref, newestNotification);
        });

        return const SizedBox.shrink();
      },
    );
  }

  static void _showReviewDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> notification,
  ) {
    final productNames = notification['product_names'] as List<dynamic>? ?? [];
    final orderId = notification['order_id'] ?? '';

    if (productNames.isEmpty || orderId.isEmpty) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: Text(
            "Love It or Leave It?",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF273847),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final productImageAsync =
                      ref.watch(productImageProvider(productNames.first));
                  return productImageAsync.when(
                    data: (imageUrl) {
                      if (imageUrl == null || imageUrl.isEmpty) {
                        return const Icon(Icons.image, size: 80);
                      }
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: imageUrl,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor: Colors.grey[300]!,
                            highlightColor: Colors.grey[100]!,
                            child: Container(
                              width: 100,
                              height: 100,
                              color: Colors.grey[300],
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.image_not_supported, size: 80),
                        ),
                      );
                    },
                    loading: () => Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[300],
                      ),
                    ),
                    error: (error, stack) => const Icon(Icons.error),
                  );
                },
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Text(
                  "Tell us what you think about your recent purchase by leaving a star rating ⭐",
                  textAlign: TextAlign.justify,
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                for (final product in productNames) {
                  await prefs.setBool('rated_$product', true);
                }
                Navigator.pop(dialogContext);
              },
              child: Text(
                "Not Now",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: const Color(0xFF273847),
              ),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                for (final product in productNames) {
                  await prefs.setBool('rated_$product', true);
                }
                Navigator.pop(dialogContext);
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                      builder: (_) =>
                          const NotificationTabPage(initialIndex: 1)),
                );
              },
              child: Text(
                "Rate Now",
                style: GoogleFonts.poppins(
                  fontSize: 14,
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
