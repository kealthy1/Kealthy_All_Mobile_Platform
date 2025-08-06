import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kealthy/view/notifications/notification_page.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';

final offersNotificationProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final database = FirebaseFirestore.instance;

  yield* database
      .collection('offers')
      .orderBy('timestamp', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList());
});

class DismissedOffersNotifier extends StateNotifier<Set<String>> {
  DismissedOffersNotifier() : super({}) {
    _loadDismissedOffers();
  }

  Future<void> _loadDismissedOffers() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedList = prefs.getStringList('dismissedOffers') ?? [];
    state = dismissedList.toSet();
  }

  Future<void> _saveDismissedOffers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('dismissedOffers', state.toList());
  }

  void dismiss(String offerId) {
    state = {...state, offerId};
    _saveDismissedOffers();
  }
}

final dismissedOffersProvider =
    StateNotifierProvider<DismissedOffersNotifier, Set<String>>(
        (ref) => DismissedOffersNotifier());

class OffersNotificationPage extends ConsumerStatefulWidget {
  const OffersNotificationPage({super.key});

  @override
  ConsumerState<OffersNotificationPage> createState() =>
      _OffersNotificationPageState();
}

class _OffersNotificationPageState
    extends ConsumerState<OffersNotificationPage> {
  @override
  Widget build(BuildContext context) {
    final offersAsync = ref.watch(offersNotificationProvider);
    final dismissedOffers = ref.watch(dismissedOffersProvider);

    return offersAsync.when(
      loading: () => const Center(child: CupertinoActivityIndicator()),
      error: (_, __) => const Center(child: Text("Error loading offers")),
      data: (offers) {
        final filteredOffers = offers
            .where((offer) => !dismissedOffers.contains(offer['id']))
            .toList();

        if (filteredOffers.isEmpty) {
          return buildNoNotifications();
        }

        return ListView.builder(
          itemCount: filteredOffers.length,
          itemBuilder: (context, index) {
            final offer = filteredOffers[index];
            final imageUrl = offer['ImageUrl'] as String?;

            return GestureDetector(
              onTap: () {
                final route = offer['route'] as String?;
                if (route != null && route.isNotEmpty) {
                  if (route == "pop") {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushNamed(context, route);
                  }
                }
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imageUrl != null)
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              child: CachedNetworkImage(
                                imageUrl: imageUrl,
                                width: double.infinity,
                                height: 160,
                                fit: BoxFit.cover,
                                placeholder: (context, url) =>
                                    Shimmer.fromColors(
                                  baseColor: Colors.grey.shade300,
                                  highlightColor: Colors.grey.shade100,
                                  child: Container(
                                    width: double.infinity,
                                    height: 160,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(12)),
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12.0, vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  offer['title'] ?? '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  offer['body'] ?? '',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.8,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 1,
                      right: 1,
                      child: IconButton(
                        icon: const Icon(
                          CupertinoIcons.clear_circled_solid,
                          size: 20,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          ref
                              .read(dismissedOffersProvider.notifier)
                              .dismiss(offer['id']);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
