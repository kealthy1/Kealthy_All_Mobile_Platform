import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

// StateNotifier for managing the current index
class ImageIndexNotifier extends StateNotifier<int> {
  ImageIndexNotifier(super.initialIndex);

  void setIndex(int newIndex) {
    state = newIndex;
  }
}

// Provider for image index management
final imageIndexProvider = StateNotifierProvider<ImageIndexNotifier, int>(
  (ref) => ImageIndexNotifier(0),
);

class ImageZoomPage extends ConsumerStatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const ImageZoomPage({
    super.key,
    required this.imageUrls,
    required this.initialIndex,
  });

  @override
  _ImageZoomPageState createState() => _ImageZoomPageState();
}

class _ImageZoomPageState extends ConsumerState<ImageZoomPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late PageController _pageController;
  late List<ImageProvider> _cachedImages;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _cachedImages =
        widget.imageUrls.map((url) => CachedNetworkImageProvider(url)).toList();

    // Delay the provider update to avoid modifying it during widget build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(imageIndexProvider.notifier).setIndex(widget.initialIndex);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final provider in _cachedImages) {
      precacheImage(provider, context);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    ref.watch(imageIndexProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // --------------------------------------------------
          // Main Image Gallery
          // --------------------------------------------------
          Expanded(
            child: PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),
              backgroundDecoration: const BoxDecoration(color: Colors.white),
              itemCount: widget.imageUrls.length,
              pageController: _pageController,
              onPageChanged: (index) {
                ref.read(imageIndexProvider.notifier).setIndex(index);
              },
              builder: (context, index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider: _cachedImages[index],
                  minScale: PhotoViewComputedScale.contained,
                  maxScale: PhotoViewComputedScale.covered * 2.5,
                  heroAttributes: PhotoViewHeroAttributes(tag: index),
                  filterQuality: FilterQuality.high,
                );
              },
            ),
          ),

          Consumer(builder: (context, ref, child) {
            final selectedIndex = ref.watch(imageIndexProvider);

            return Container(
              margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.imageUrls.length,
                itemBuilder: (context, index) {
                  final isSelected = (selectedIndex == index);

                  return GestureDetector(
                    onTap: () {
                      // Instantly update the index to prevent delay
                      ref.read(imageIndexProvider.notifier).setIndex(index);

                      // Jump directly to page instead of animation to prevent delay
                      _pageController.jumpToPage(index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(
                          milliseconds: 200), // Smooth transition
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              isSelected ? Colors.orange : Colors.transparent,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: widget.imageUrls[index],
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }
}
