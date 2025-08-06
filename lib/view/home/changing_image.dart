import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:kealthy/view/home/Calorie.dart';
import 'package:kealthy/view/home/bmi_calculator.dart';
import 'package:shimmer/shimmer.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ImageData {
  final String imageUrl;
  final String title;
  final String? data;
  final String? productName; // Optional product name for "Did You Know?"

  ImageData({
    required this.imageUrl,
    required this.title,
    this.data,
    this.productName,
  });
}

// Riverpod provider for list of image data
final imageDataProvider = StateNotifierProvider<ImageNotifier, List<ImageData>>(
  (ref) => ImageNotifier(ref: ref),
);

final carouselIndexProvider = StateProvider<int>((ref) => 0);

class ChangingImageWidget extends ConsumerStatefulWidget {
  const ChangingImageWidget({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ChangingImageWidgetState createState() => _ChangingImageWidgetState();
}

class _ChangingImageWidgetState extends ConsumerState<ChangingImageWidget> {
  late PageController _pageController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _startAutoScroll();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final imageList = ref.read(imageDataProvider);
      for (final image in imageList) {
        if (image.imageUrl.isNotEmpty) {
          precacheImage(CachedNetworkImageProvider(image.imageUrl), context);
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final imageList = ref.read(imageDataProvider);
    for (final image in imageList) {
      if (image.imageUrl.isNotEmpty) {
        precacheImage(CachedNetworkImageProvider(image.imageUrl), context);
      }
    }
  }

  void _startAutoScroll() {
    _timer?.cancel(); // Ensure any existing timer is canceled
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      final currentIndex = ref.read(carouselIndexProvider);
      final imageList = ref.read(imageDataProvider);
      if (imageList.isNotEmpty) {
        final nextIndex = (currentIndex + 1) % imageList.length;
        ref.read(carouselIndexProvider.notifier).state = nextIndex;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  /// Stop scrolling when the user taps on an image
  void _stopAutoScroll() {
    _timer?.cancel(); // Stop the auto-scroll timer
  }

  /// Restart scrolling after a delay when the user stops interacting
  void _restartAutoScroll() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 20),
        () => _startAutoScroll()); // Restart after delay
  }

  /// Modify the onTap method to stop scrolling when tapped
  Future<void> _navigateBasedOnImageIndex(
      BuildContext context, int index) async {
    _stopAutoScroll(); // Stop auto-scrolling when user interacts

    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BmiTrackerPage()),
        );
        break;

      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CalorieIntakePage()),
        );
        break;
      default:
        break;
    }

    _restartAutoScroll(); // Restart auto-scrolling after navigation
  }

  @override
  Widget build(BuildContext context) {
    final imageDataList = ref.watch(imageDataProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    double tileWidth;
    double tileHeight;

    if (screenWidth < 600) {
      tileWidth = screenWidth;
      tileHeight = 180;
    } else if (screenWidth < 900) {
      tileWidth = screenWidth;
      tileHeight = 500;
    } else {
      tileWidth = screenWidth;
      tileHeight = 500;
    }

    if (imageDataList.isEmpty) {
      // Show shimmer and placeholder bubbles
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(20)),
                width: tileWidth,
                height: tileHeight,
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          SmoothPageIndicator(
            controller: _pageController,
            count: 2,
            effect: const ExpandingDotsEffect(
              dotHeight: 5,
              dotWidth: 5,
              activeDotColor: Color.fromARGB(255, 65, 88, 108),
              dotColor: Color.fromARGB(255, 120, 142, 162),
              spacing: 4.0,
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          height: tileHeight,
          child: GestureDetector(
            onPanDown: (_) => _stopAutoScroll(),
            onPanCancel: () => _restartAutoScroll(),
            child: PageView.builder(
              controller: _pageController,
              itemCount: imageDataList.length,
              onPageChanged: (index) {
                ref.read(carouselIndexProvider.notifier).state = index;
              },
              itemBuilder: (context, index) {
                final imageData = imageDataList[index];
                return GestureDetector(
                  onTap: () {
                    _stopAutoScroll();
                    _navigateBasedOnImageIndex(context, index);
                    _restartAutoScroll();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: imageData.imageUrl.isEmpty
                            ? Container(
                                height: tileHeight,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        imageData.title,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      if (imageData.productName != null &&
                                          imageData
                                              .productName!.isNotEmpty) ...[
                                        Text(
                                          imageData.productName!,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 2),
                                      Text(
                                        imageData.data ?? '',
                                        style: const TextStyle(fontSize: 12),
                                        textAlign: TextAlign.start,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : CachedNetworkImage(
                                imageUrl: imageData.imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                placeholder: (context, url) =>
                                    Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(color: Colors.grey[300]),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error, color: Colors.red),
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        SmoothPageIndicator(
          controller: _pageController,
          count: imageDataList.isEmpty ? 5 : imageDataList.length,
          effect: const ExpandingDotsEffect(
            dotHeight: 5,
            dotWidth: 5,
            activeDotColor: Color.fromARGB(255, 65, 88, 108),
            dotColor: Color.fromARGB(255, 120, 142, 162),
            spacing: 4.0,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }
}

class ImageNotifier extends StateNotifier<List<ImageData>> {
  ImageNotifier({required Ref ref}) : super([]) {
    _loadImagesAndTitlesFromFirestore();
  }

  Future<void> _loadImagesAndTitlesFromFirestore() async {
    try {
      List<ImageData> loadedImages = [];

      // Fetch random "What is it?" from Products collection, and also get product name
      final productSnapshot =
          await FirebaseFirestore.instance.collection('Products').get();
      final whatIsItEntries = productSnapshot.docs
          .where((doc) =>
              doc.data()['What is it?'] != null &&
              (doc.data()['What is it?'] as String).trim().isNotEmpty)
          .map((doc) => {
                'whatIsIt': doc.data()['What is it?'] as String,
                'productName': doc.data()['Name'] as String?,
              })
          .toList();

      // Load carousel images from 'Carousel' collection
      final snapshot =
          await FirebaseFirestore.instance.collection('Carousel').get();

      for (var doc in snapshot.docs) {
        final imageUrls = List<String>.from(doc['Image']);
        final titles = List<String>.from(doc['Title']);
        if (imageUrls.length == titles.length) {
          for (int i = 0; i < imageUrls.length; i++) {
            loadedImages.add(ImageData(
              imageUrl: imageUrls[i],
              title: titles[i],
            ));
          }
        } else {
          print('Error: The number of images and titles do not match.');
        }
      }

      // Prepend "Did You Know?" card if available
      if (whatIsItEntries.isNotEmpty) {
        whatIsItEntries.shuffle();
        final entry = whatIsItEntries.first;
        loadedImages.insert(
          0,
          ImageData(
            imageUrl: '',
            title: 'Did You Know?',
            data: entry['whatIsIt'],
            productName: entry['productName'],
          ),
        );
      }

      print(
          'Total images loaded (including Did You Know): ${loadedImages.length}');
      state = loadedImages;
    } catch (e) {
      print("Error loading images and titles from Firestore: $e");
    }
  }
}

//  Future<void> _launchFacebook() async {
//     const fbAppUrl =
//         'fb://facewebmodal/f?href=https://www.facebook.com/share/1938WAtaiE/';
//     const fbWebUrl =
//         'https://www.facebook.com/profile.php?id=61571096468965&mibextid=ZbWKwL';

//     if (await canLaunchUrl(Uri.parse(fbAppUrl))) {
//       await launchUrl(Uri.parse(fbAppUrl));
//     } else {
//       await launchUrl(Uri.parse(fbWebUrl),
//           mode: LaunchMode.externalApplication);
//     }
//   }

//   Future<void> _launchInstagram() async {
//     const fbAppUrl = 'instagram://user?username=kealthy.life';
//     const fbWebUrl =
//         'https://www.instagram.com/kealthy.life?igsh=MXVqa2hicG4ydzB5cQ==';

//     if (await canLaunchUrl(Uri.parse(fbAppUrl))) {
//       await launchUrl(Uri.parse(fbAppUrl));
//     } else {
//       await launchUrl(Uri.parse(fbWebUrl),
//           mode: LaunchMode.externalApplication);
//     }
//   }

//   Future<void> _launchX() async {
//     const appUrl = 'twitter://user?screen_name=Kealthy_life';
//     const webUrl = 'https://x.com/Kealthy_life';

//     if (await canLaunchUrl(Uri.parse(appUrl))) {
//       await launchUrl(Uri.parse(appUrl));
//     } else {
//       await launchUrl(Uri.parse(webUrl), mode: LaunchMode.externalApplication);
//     }
//   }
