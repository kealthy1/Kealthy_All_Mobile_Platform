import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/notifications/rating_provider.dart';

import 'package:shimmer/shimmer.dart';

class ReviewCard extends ConsumerStatefulWidget {
  final String productName;
  final String productImage;
  final String orderId;

  const ReviewCard({
    super.key,
    required this.productName,
    required this.productImage,
    required this.orderId,
  });

  @override
  ConsumerState<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends ConsumerState<ReviewCard> {
  late TextEditingController _reviewController;

  @override
  void initState() {
    super.initState();
    _initializeController();
    Future.microtask(() => fetchAverageStars());
  }

  void _initializeController() {
    final reviewText = ref.read(reviewProvider)[widget.productName] ?? '';
    _reviewController = TextEditingController(text: reviewText);
  }

  Future<void> fetchAverageStars() async {
    const apiUrl = "https://api-jfnhkjk4nq-uc.a.run.app/rate";
    await ref.read(averageRatingProvider.notifier).getAverageStars(
          productName: widget.productName,
          apiUrl: apiUrl,
        );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _updateReview(String text) {
    ref
        .read(reviewProvider.notifier)
        .updateReview(widget.productName, text.trim());
  }

  void _onEditingComplete() {
    _updateReview(_reviewController.text);
    FocusScope.of(context).unfocus(); // ✅ Closes keyboard when editing is done
  }

  @override
  Widget build(BuildContext context) {
    final rating = ref.watch(ratingProvider)[widget.productName] ?? 0;
    final averageStars =
        ref.watch(averageRatingProvider)[widget.productName] ?? 0.0;

    return GestureDetector(
      onTap: () => FocusScope.of(context)
          .unfocus(), // ✅ Dismiss keyboard when tapping anywhere
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // **Product Image & Title**
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: CachedNetworkImage(
                      imageUrl: widget.productImage,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.grey[100]!,
                        child: Container(
                            width: 50, height: 50, color: Colors.grey[300]),
                      ),
                      errorWidget: (context, url, error) =>
                          const Icon(Icons.image_not_supported, size: 50),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.productName,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        averageStars == 0.0
                            ? const SizedBox()
                            : Row(
                                children: List.generate(5, (index) {
                                  return Icon(
                                    index < averageStars
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: Colors.amber,
                                    size: 18,
                                  );
                                }),
                              ),
                        const SizedBox(height: 5),
                        averageStars == 0.0
                            ? const SizedBox()
                            : Text(
                                averageStars.toStringAsFixed(1),
                                style: GoogleFonts.poppins(fontSize: 14),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Focus(
                onFocusChange: (hasFocus) {
                  if (!hasFocus) _onEditingComplete();
                },
                child: TextField(
                  controller: _reviewController,
                  maxLines: 2,
                  onChanged: (value) {
                    ref
                        .read(reviewProvider.notifier)
                        .updateReview(widget.productName, value);
                  },
                  onEditingComplete: _onEditingComplete,
                  decoration: InputDecoration(
                    hintText: "Love It or Not? Let Us Know!",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors.grey.shade300, // ✅ No focus color change
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: Colors
                            .grey.shade300, // ✅ Same border when not focused
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color:
                            Colors.grey.shade300, // ✅ Same border when focused
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // **Star Rating Selection (Fixed Issue)**
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 30,
                    ),
                    onPressed: () {
                      ref
                          .read(ratingProvider.notifier)
                          .updateRating(widget.productName, index + 1);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
